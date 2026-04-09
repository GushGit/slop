#  ТЕСТИРОВАНИЕ ЗАПРОСОВ К СЕРВЕРУ

import requests

# Конфигурация
BASE_URL = "http://127.0.0.1:8000"
IMAGE_PATH = "products.jpg"


def test_full_recipe_flow():
    # --- ШАГ 1: Распознаем продукты по фото ---
    print("--- Шаг 1: Распознавание продуктов ---")
    try:
        with open(IMAGE_PATH, "rb") as f:
            files = {"file": (IMAGE_PATH, f, "image/jpeg")}
            response_img = requests.post(f"{BASE_URL}/process-image", files=files)

        response_img.raise_for_status()  # Проверка на ошибки
        detected_data = response_img.json()

        # Предположим, ваш эндпоинт /process-image возвращает {"products": ["tomato", "egg", ...]}
        products = detected_data.get("products", [])
        print(f"Распознанные продукты: {products}")

    except Exception as e:
        print(f"Ошибка при обработке фото: {e}")
        return

    # --- ШАГ 2: Запрашиваем рецепты ---
    print("\n--- Шаг 2: Запрос рецептов ---")

    # Добавляем данные, которых нет на фото
    recipe_payload = {
        "products": products,  # Список из первого запроса
        "utilities": ["микроволновка"],  # Список инструментов
        "goal": "lose_weight"  # Наша цель из Enum
    }

    try:
        response_recipes = requests.post(
            f"{BASE_URL}/recipes",
            json=recipe_payload
        )
        response_recipes.raise_for_status()

        recipes_data = response_recipes.json()

        # Если в ответ пришел сформированный промпт (как в предыдущем шаге)
        if "generated_prompt" in recipes_data:
            print("Промпт успешно сгенерирован:")
            print("-" * 30)
            print(recipes_data["generated_prompt"])
            print("-" * 30)
        else:
            # Если уже пришел готовый JSON с рецептами
            print("Получены рецепты:")
            print(recipes_data)

    except Exception as e:
        print(f"Ошибка при получении рецептов: {e}")


if __name__ == "__main__":
    test_full_recipe_flow()