import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learnaria/l10n/app_localizations.dart';

// Provider لإدارة حالة اللغة في التطبيق
class LocaleProvider with ChangeNotifier {
  Locale? _locale;
  static const String _localePreferenceKey = 'localeCode';

  LocaleProvider() {
    _loadLocalePreference();
  }

  Locale? get locale => _locale;

  // دالة لتعيين اللغة الجديدة وحفظها
  void setLocale(Locale locale) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePreferenceKey, locale.languageCode);
    _locale = locale;
    notifyListeners(); // إعلام الواجهات بالتغيير لإعادة البناء
  }

  // --- تم تعديل هذه الدالة ---
  // تحميل اللغة المحفوظة، أو تحديد لغة الجهاز تلقائيًا
  void _loadLocalePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedLanguageCode = prefs.getString(_localePreferenceKey);

    if (savedLanguageCode != null) {
      // إذا وجدنا لغة محفوظة، نستخدمها
      _locale = Locale(savedLanguageCode);
    } else {
      // إذا لم نجد لغة محفوظة (أول تشغيل للتطبيق)
      // نحدد لغة الجهاز
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      
      // التحقق إذا كانت لغة الجهاز مدعومة في التطبيق
      bool isSupported = AppLocalizations.supportedLocales.any(
          (supportedLocale) => supportedLocale.languageCode == deviceLocale.languageCode
      );

      if (isSupported) {
        // إذا كانت مدعومة، نستخدمها كلغة افتراضية
        _locale = deviceLocale;
      } else {
        // إذا لم تكن مدعومة، نستخدم الإنجليزية كلغة افتراضية
        _locale = const Locale('en');
      }
    }
    notifyListeners();
  }

  // دالة لتبديل اللغة بين العربية والإنجليزية
  void toggleLocale() {
    if (_locale == null || _locale!.languageCode == 'en') {
      setLocale(const Locale('ar'));
    } else {
      setLocale(const Locale('en'));
    }
  }
}
