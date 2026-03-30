import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _themePreference = "System Default";

  ThemeMode get themeMode => _themeMode;
  String get themePreference => _themePreference;

  void setTheme(String theme) {
    if (theme == "Light") {
      _themeMode = ThemeMode.light;
      _themePreference = "Light";
    } else if (theme == "Dark") {
      _themeMode = ThemeMode.dark;
      _themePreference = "Dark";
    } else {
      _themeMode = ThemeMode.system;
      _themePreference = "System Default";
    }
    notifyListeners();
  }

  void setThemeFromMode(ThemeMode mode) {
    _themeMode = mode;
    if (mode == ThemeMode.light) {
      _themePreference = "Light";
    } else if (mode == ThemeMode.dark) {
      _themePreference = "Dark";
    } else {
      _themePreference = "System Default";
    }
    notifyListeners();
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}