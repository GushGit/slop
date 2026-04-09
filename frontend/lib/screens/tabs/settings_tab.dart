import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Тема приложения', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('Система')),
            ButtonSegment(value: ThemeMode.light, label: Text('Светлая')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Темная')),
          ],
          selected: {themeMode},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              onThemeModeChanged(selection.first);
            }
          },
        ),
      ],
    );
  }
}
