import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/cooking_result.dart';
import '../models/recipe_option.dart';

class InteractiveCookingScreen extends StatefulWidget {
  const InteractiveCookingScreen({
    super.key,
    required this.recipe,
    required this.consumption,
    required this.finalCalories,
    required this.finalProteins,
    required this.finalFats,
    required this.finalCarbs,
  });

  final RecipeOption recipe;
  final Map<String, int> consumption;
  final double finalCalories;
  final double finalProteins;
  final double finalFats;
  final double finalCarbs;

  @override
  State<InteractiveCookingScreen> createState() => _InteractiveCookingScreenState();
}

class _InteractiveCookingScreenState extends State<InteractiveCookingScreen> {
  late final FlutterTts _tts;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  Timer? _timer;
  bool _isTtsAvailable = true;

  int _stepIndex = 0;
  int _remainingSeconds = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _initTts();
    _initNotifications();
    _resetTimerForCurrentStep();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopTtsSafely();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepText = widget.recipe.steps[_stepIndex];

    return Scaffold(
      appBar: AppBar(title: Text('Готовка: ${widget.recipe.title}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Шаг ${_stepIndex + 1} из ${widget.recipe.steps.length}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(stepText, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.record_voice_over),
                    label: const Text('Озвучить шаг'),
                    onPressed: () => _speak(stepText),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.ondemand_video),
                    label: const Text('Видео'),
                    onPressed: _openVideo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Таймер шага', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_formatSeconds(_remainingSeconds), style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRunning ? 'Пауза' : 'Старт'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _resetTimerForCurrentStep,
                  icon: const Icon(Icons.replay),
                  label: const Text('Сброс'),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _stepIndex > 0 ? _previousStep : null,
                    child: const Text('Назад'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _stepIndex < widget.recipe.steps.length - 1 ? _nextStep : _finishCooking,
                    child: Text(_stepIndex < widget.recipe.steps.length - 1 ? 'Далее' : 'Завершить'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() => _isRunning = false);
        _onTimerCompleted();
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimerForCurrentStep() {
    _pauseTimer();
    final fallback = 60;
    final value = _stepIndex < widget.recipe.stepDurationsSec.length
        ? widget.recipe.stepDurationsSec[_stepIndex]
        : fallback;
    setState(() {
      _remainingSeconds = value;
    });
  }

  Future<void> _speak(String text) async {
    if (!_isTtsAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Озвучка недоступна на текущей платформе.')),
        );
      }
      return;
    }

    try {
      await _tts.stop();
      await _tts.speak(text);
    } on MissingPluginException {
      _isTtsAvailable = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Озвучка временно недоступна (плагин не подключен).')),
        );
      }
    }
  }

  Future<void> _openVideo() async {
    final uri = Uri.parse(widget.recipe.videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _nextStep() {
    if (_stepIndex >= widget.recipe.steps.length - 1) {
      return;
    }

    setState(() {
      _stepIndex += 1;
    });
    _resetTimerForCurrentStep();
  }

  void _previousStep() {
    if (_stepIndex <= 0) {
      return;
    }

    setState(() {
      _stepIndex -= 1;
    });
    _resetTimerForCurrentStep();
  }

  Future<void> _finishCooking() async {
    _pauseTimer();

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
      CookingResult(
        consumptionPercentByIngredient: widget.consumption,
        finalCalories: widget.finalCalories,
        finalProteins: widget.finalProteins,
        finalFats: widget.finalFats,
        finalCarbs: widget.finalCarbs,
      ),
    );
  }

  String _formatSeconds(int total) {
    final min = (total ~/ 60).toString().padLeft(2, '0');
    final sec = (total % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('ru-RU');
    } on MissingPluginException {
      _isTtsAvailable = false;
    }
  }

  Future<void> _stopTtsSafely() async {
    if (!_isTtsAvailable) {
      return;
    }
    try {
      await _tts.stop();
    } on MissingPluginException {
      _isTtsAvailable = false;
    }
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    try {
      await _notifications.initialize(settings);
    } on MissingPluginException {
      // Optional on unsupported platforms.
    }
  }

  Future<void> _onTimerCompleted() async {
    try {
      FlutterRingtonePlayer().playNotification();
    } on MissingPluginException {
      // Ignore audio plugin absence.
    }

    try {
      await _notifications.show(
        widget.recipe.title.hashCode + _stepIndex,
        'Таймер завершен',
        'Шаг ${_stepIndex + 1} завершен: ${widget.recipe.title}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cooking_timer_channel',
            'Cooking Timer',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } on MissingPluginException {
      // Ignore notification plugin absence.
    }
  }
}
