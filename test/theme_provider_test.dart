import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learnaria/utils/theme_provider.dart';

void main() {
  group('ThemeProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ThemeProvider initializes with light theme by default', () async {
      final provider = ThemeProvider();
      await provider.getTheme(); 

      expect(provider.isDarkMode, false);
      expect(provider.currentTheme, ThemeMode.light);
    });

    test('ThemeProvider toggles theme and saves to SharedPreferences', () async {
      final provider = ThemeProvider();
      await provider.getTheme(); 

      provider.toggleTheme(true);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.isDarkMode, true);
      expect(provider.currentTheme, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(ThemeProvider.THEME_STATUS), true);

      provider.toggleTheme(false);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.isDarkMode, false);
      expect(provider.currentTheme, ThemeMode.light);
      expect(prefs.getBool(ThemeProvider.THEME_STATUS), false);
    });
  });
}
