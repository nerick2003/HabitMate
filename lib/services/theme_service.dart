import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService instance = ThemeService._init();
  static SharedPreferences? _prefs;
  
  ThemeService._init();

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  ThemeMode getThemeMode() {
    final themeMode = _prefs?.getString('theme_mode') ?? 'system';
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs?.setString('theme_mode', mode.toString().split('.').last);
  }
}

