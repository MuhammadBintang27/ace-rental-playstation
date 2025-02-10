import 'package:flutter/material.dart';
import 'dark_mode.dart';
import 'light_mode.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = lightMode;

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == darkMode;

  set setThemeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme() {
    setThemeData = _themeData == lightMode ? darkMode : lightMode;
  }
}
