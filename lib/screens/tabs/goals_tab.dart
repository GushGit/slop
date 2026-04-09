import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/app_enums.dart';
import '../../models/day_nutrition_progress.dart';
import '../../models/nutrition_targets.dart';

class GoalsTab extends StatefulWidget {
  const GoalsTab({
    super.key,
    required this.goalMode,
    required this.weight,
    required this.height,
    required this.age,
    required this.activityMultiplier,
    required this.targets,
    required this.progress,
    required this.selectedProgressDate,
    required this.goalPeriodEndDate,
    required this.onGoalModeChanged,
    required this.onApplyForm,
    required this.onSelectProgressDate,
    required this.onPickGoalEndDate,
  });

  final GoalMode goalMode;
  final int weight;
  final int height;
  final int age;
  final double activityMultiplier;
  final NutritionTargets? targets;
  final List<DayNutritionProgress> progress;
  final DateTime? selectedProgressDate;
  final DateTime? goalPeriodEndDate;
  final ValueChanged<GoalMode> onGoalModeChanged;
  final void Function({
    required int weight,
    required int height,
    required int age,
    required double activityMultiplier,
  }) onApplyForm;
  final ValueChanged<DateTime> onSelectProgressDate;
  final ValueChanged<DateTime> onPickGoalEndDate;

  @override
  State<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends State<GoalsTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;
  late double _activityMultiplier;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  late DateTime _focusedDay;

  static const _activityOptions = <double>[1.2, 1.4, 1.6, 1.8];

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: '${widget.weight}');
    _heightController = TextEditingController(text: '${widget.height}');
    _ageController = TextEditingController(text: '${widget.age}');
    _activityMultiplier = widget.activityMultiplier;
    _focusedDay = widget.selectedProgressDate ?? DateTime.now();
  }

  @override
  void didUpdateWidget(covariant GoalsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weight != widget.weight) {
      _weightController.text = '${widget.weight}';
    }
    if (oldWidget.height != widget.height) {
      _heightController.text = '${widget.height}';
    }
    if (oldWidget.age != widget.age) {
      _ageController.text = '${widget.age}';
    }
    if (widget.selectedProgressDate != null && oldWidget.selectedProgressDate != widget.selectedProgressDate) {
      _focusedDay = widget.selectedProgressDate!;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = widget.selectedProgressDate ?? DateTime.now();
    final firstDay = widget.progress.first.date;
    final lastDay = widget.progress.last.date;

    final selectedDay = widget.progress.firstWhere(
      (day) {
        return isSameDay(day.date, selectedDate);
      },
      orElse: () => widget.progress.last,
    );

    final weeklyGroups = _chunkByWeek(widget.progress);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        Text('Режим питания', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        SegmentedButton<GoalMode>(
          segments: const [
            ButtonSegment(value: GoalMode.weightLoss, label: Text('Похудение')),
            ButtonSegment(value: GoalMode.maintain, label: Text('Поддержание')),
            ButtonSegment(value: GoalMode.massGain, label: Text('Набор')),
          ],
          selected: {widget.goalMode},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              widget.onGoalModeChanged(selection.first);
            }
          },
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
              initialDate: widget.goalPeriodEndDate ?? now.add(const Duration(days: 30)),
            );
            if (picked != null) {
              widget.onPickGoalEndDate(picked);
            }
          },
          icon: const Icon(Icons.event),
          label: Text(widget.goalPeriodEndDate == null
              ? 'Выбрать последний день периода'
              : 'Период до: ${widget.goalPeriodEndDate!.day}.${widget.goalPeriodEndDate!.month}.${widget.goalPeriodEndDate!.year}'),
        ),
        const SizedBox(height: 18),
        Text('Расчет КБЖУ', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildNaturalField(_weightController, 'Вес (кг)', maxValue: 400),
              const SizedBox(height: 8),
              _buildNaturalField(_heightController, 'Рост (см)', maxValue: 260),
              const SizedBox(height: 8),
              _buildNaturalField(_ageController, 'Возраст', maxValue: 100),
              const SizedBox(height: 8),
              DropdownButtonFormField<double>(
                initialValue: _activityMultiplier,
                decoration: const InputDecoration(labelText: 'Активность'),
                items: _activityOptions
                    .map((v) => DropdownMenuItem(value: v, child: Text(_activityLabel(v))))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _activityMultiplier = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }

                  widget.onApplyForm(
                    weight: int.parse(_weightController.text),
                    height: int.parse(_heightController.text),
                    age: int.parse(_ageController.text),
                    activityMultiplier: _activityMultiplier,
                  );
                },
                icon: const Icon(Icons.calculate),
                label: const Text('Рассчитать КБЖУ'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (widget.targets != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Целевые показатели', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _line('Калории', '${widget.targets!.calories.toStringAsFixed(0)} ккал'),
                  _line('Белки', '${widget.targets!.proteins.toStringAsFixed(0)} г'),
                  _line('Жиры', '${widget.targets!.fats.toStringAsFixed(0)} г'),
                  _line('Углеводы', '${widget.targets!.carbs.toStringAsFixed(0)} г'),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text('Прогресс-календарь', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        TableCalendar<DayNutritionProgress>(
          firstDay: firstDay,
          lastDay: lastDay,
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(day, selectedDate),
          onDaySelected: (day, focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
            widget.onSelectProgressDate(day);
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          availableCalendarFormats: {
            CalendarFormat.week: 'Неделя',
            CalendarFormat.month: 'Месяц',
          },
          eventLoader: (day) {
            return widget.progress.where((item) => isSameDay(item.date, day)).toList();
          },
          headerStyle: const HeaderStyle(titleCentered: true),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Недельный прогресс', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...weeklyGroups.map((week) {
          final avgCalories = week.fold<double>(0, (sum, d) => sum + d.calories) / week.length;
          final ratio = widget.targets == null ? 0.0 : (avgCalories / widget.targets!.calories).clamp(0.0, 1.2);
          final from = week.first.date;
          final to = week.last.date;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Неделя ${from.day}.${from.month} - ${to.day}.${to.month}'),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: (ratio / 1.2).clamp(0.0, 1.0)),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        Text('Подробности за ${selectedDay.date.day}.${selectedDay.date.month}',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _macroProgress('Калории', selectedDay.calories, widget.targets?.calories ?? 1),
        _macroProgress('Белки', selectedDay.proteins, widget.targets?.proteins ?? 1),
        _macroProgress('Жиры', selectedDay.fats, widget.targets?.fats ?? 1),
        _macroProgress('Углеводы', selectedDay.carbs, widget.targets?.carbs ?? 1),
      ],
    );
  }

  List<List<DayNutritionProgress>> _chunkByWeek(List<DayNutritionProgress> source) {
    final out = <List<DayNutritionProgress>>[];
    for (var i = 0; i < source.length; i += 7) {
      final end = (i + 7 > source.length) ? source.length : i + 7;
      out.add(source.sublist(i, end));
    }
    if (out.length <= 4) {
      return out;
    }
    return out.sublist(out.length - 4);
  }

  Widget _macroProgress(String label, double actual, double target) {
    final ratio = (actual / target).clamp(0.0, 1.3);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${actual.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}'),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: (ratio / 1.3).clamp(0.0, 1.0)),
        ],
      ),
    );
  }

  Widget _line(String left, String right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(left)),
          Text(right, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNaturalField(TextEditingController controller, String label, {required int maxValue}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Введите значение';
        }

        final parsed = int.tryParse(value);
        if (parsed == null || parsed <= 0) {
          return 'Только натуральные числа';
        }

        if (parsed > maxValue) {
          return 'Максимум: $maxValue';
        }

        return null;
      },
    );
  }

  String _activityLabel(double value) {
    return switch (value) {
      1.2 => 'Низкая',
      1.4 => 'Умеренная',
      1.6 => 'Высокая',
      1.8 => 'Очень высокая',
      _ => 'Пользовательская',
    };
  }
}
