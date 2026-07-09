import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learnaria/utils/locale_provider.dart';

void main() {
  group('LocaleProvider Tests', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    test('LocaleProvider initializes correctly', () async {
      final provider = LocaleProvider();
      await Future.delayed(const Duration(milliseconds: 200));

      expect(provider.locale, isNotNull);
    });

    test('LocaleProvider sets and saves locale correctly', () async {
      final provider = LocaleProvider();
      await Future.delayed(const Duration(milliseconds: 200));
      
      provider.setLocale(const Locale('ar'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.locale?.languageCode, 'ar');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('localeCode'), 'ar');
    });

    test('LocaleProvider toggles between languages', () async {
      SharedPreferences.setMockInitialValues({'localeCode': 'en'});
      final provider = LocaleProvider();
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      provider.toggleLocale();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.locale?.languageCode, 'ar');

      provider.toggleLocale();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.locale?.languageCode, 'en');
    });
  });
}
