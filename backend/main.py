import os, json
from enum import Enum

from io import BytesIO
from typing import List

import uvicorn
from google import genai
from PIL import Image
from google.genai.types import GenerateContentConfig, ThinkingLevel
from fastapi import FastAPI, File, UploadFile
from pydantic import BaseModel
from google.genai import types

client = genai.Client(api_key=os.environ["API_KEY"])

with open("products.json", "r", encoding="utf-8") as f:
    ideal_names = json.load(f)

def products_on_image(image_data):
    img = Image.open(BytesIO(image_data))
    user_prompt = f"""
Ты — AI-ассистент инвентаризации.

Твоя задача — внимательно изучить фотографию и найти все продукты питания или товары на ней.

Для каждого продукта укажи только его качественные характеристики как продукта, а не как товара (к примеру, заместо \"Сыр плавленный 200гр Hochland\" просто напиши \"Сыр плавленный\").
Не угадывай то, чего не видно четко.

Представь все строго в формате JSON.
Используй следующие поля:
- items: список найденных объектов
- confidence_score: твоя уверенность в распознавании от 0 до 1
    """.strip()

    response = client.models.generate_content(
        model="gemini-3.1-flash-lite-preview",
        config=GenerateContentConfig(
            temperature=0,
            response_mime_type="application/json",
            max_output_tokens=1000,
            thinking_config=types.ThinkingConfig(
                thinking_level=ThinkingLevel.LOW,
            ),
        ),
        contents=[user_prompt, img]
    )

    return json.loads(response.text)

def normalize_products(items):
    user_prompt = f"""
Ты — эксперт по обработке данных и нормализации списков продуктов. 

Твоя задача: взять "Список 1" (пользовательский ввод) и сопоставить его со "Списком 2" (эталонные названия).

Правила обработки:
1. Для каждой строки из "Списка 1" найди наиболее подходящий аналог в "Списке 2".
2. Используй семантическое сходство (например, "картошка" -> "Картофель", "молоко 3.2%" -> "Молоко").
3. Если подходящее соответствие в "Списке 2" найдено — замени строку из "Списка 1" на название из "Списка 2".
4. Если в "Списке 2" нет ни одного подходящего продукта для строки из "Списка 1" — полностью удали эту строку.
5. На выходе выдай только очищенный список названий из "Списка 2". Не пиши никаких пояснений.

Представь все строго в формате JSON.
Используй следующие поля:
- items: список подобранных эталонных названий
- confidence_score: твоя уверенность в распознавании от 0 до 1

Список 1 (ввод):
{"\n".join(items)}

Список 2 (эталоны):
{"\n".join(ideal_names)}
    """.strip()

    response = client.models.generate_content(
        model="gemini-3.1-flash-lite-preview",
        config=GenerateContentConfig(
            temperature=0,
            response_mime_type="application/json",
            max_output_tokens=1000,
        ),
        contents=[user_prompt]
    )

    return json.loads(response.text)

def request_products(image_data):
    data = products_on_image(image_data)
    items = list(dict.fromkeys(data["items"]))
    data = normalize_products(items)
    items = list(dict.fromkeys(data["items"]))
    return items

def suggest_recipes(products, utilities, goal):
    products_list = ", ".join(products)
    utilities_list = ", ".join(utilities)

    user_prompt = f"""
Ты — профессиональный шеф-повар и нутрициолог. 
Твоя задача: составить 3 различных рецепта, {goal.description}.

Входные данные:
- Доступные продукты: {products_list}. (Можно использовать соль, перец и воду по умолчанию).
- Доступное оборудование: {utilities_list}. (Базовая посуда вроде ножей, досок и тарелок уже есть).

Требования к рецептам:
1. Используй ТОЛЬКО указанные продукты и оборудование.
2. Каждый рецепт должен соответствовать цели: {goal.value}.
3. Рассчитай примерное КБЖУ (калории, белки, жиры, углеводы).

Твой ответ должен быть СТРОГО в формате JSON, без лишнего текста, пояснений и Markdown-разметки (никаких ```json).
Структура JSON:
{{
    "recipes": [
        {{
            "name": "Название блюда",
            "description": "Краткое описание блюда",
            "cooking_steps": [
                {{
                    "description": "Описание шага, что нужно делать",
                    "time": <Время в секундах (Если шаг без таймера (к примеру, нарезать овощи) - просто поставь 0)>
                }}
            ],
            "cooking_time": <Время готовки в минутах>,
            "utilities": [
                "Список оборудования из предоставленного, которое было использовано"
            ],
            "calories": <Число ккал>,
            "protein": <Грамм белка>,
            "fat": <Грамм жиров>,
            "carbs": <Грамм углеводов>
        }}
    ]
}}
    """.strip()

    response = client.models.generate_content(
        model="gemini-3.1-flash-lite-preview",
        config=GenerateContentConfig(
            temperature=0.3,
            response_mime_type="application/json",
            max_output_tokens=3000,
        ),
        contents=[user_prompt]
    )

    return json.loads(response.text)


app = FastAPI()

@app.get("/products")
async def products():
    result = {
        "products": ideal_names
    }

    return result

@app.post("/process-image")
async def process_image(file: UploadFile = File(...)):
    image_data = await file.read()

    result = {
        "products": request_products(image_data)
    }

    return result

class NutritionGoal(str, Enum):
    LOSE_WEIGHT = "lose_weight"
    MAINTAIN = "maintain"
    GAIN_WEIGHT = "gain_weight"

    @property
    def description(self) -> str:
        mapping = {
            NutritionGoal.LOSE_WEIGHT: "направленных на похудение, с дефицитом калорий и низким содержанием жиров",
            NutritionGoal.MAINTAIN: "сбалансированных по калориям и БЖУ для поддержания веса",
            NutritionGoal.GAIN_WEIGHT: "высококалорийных, богатых белком и сложными углеводами для набора мышечной массы"
        }
        return mapping[self]

class RecipeRequest(BaseModel):
    products: List[str]
    utilities: List[str]
    goal: NutritionGoal

@app.post("/recipes")
async def get_recipes(request: RecipeRequest):
    return suggest_recipes(request.products, request.utilities, request.goal)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
