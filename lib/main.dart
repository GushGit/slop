import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ReciperApp());
}

class ReciperApp extends StatefulWidget {
  const ReciperApp({super.key});

  @override
  State<ReciperApp> createState() => _ReciperAppState();
}

class _ReciperAppState extends State<ReciperApp> {
  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _appLanguage = AppLanguage.russian;

  void _updateThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void _updateLanguage(AppLanguage language) {
    setState(() {
      _appLanguage = language;
    });
  }

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0E8C6E),
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.primaryContainer,
        contentTextStyle: TextStyle(color: scheme.onPrimaryContainer),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reciper AI',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _themeMode,
      home: HomeScreen(
        themeMode: _themeMode,
        appLanguage: _appLanguage,
        onThemeModeChanged: _updateThemeMode,
        onLanguageChanged: _updateLanguage,
      ),
    );
  }
}