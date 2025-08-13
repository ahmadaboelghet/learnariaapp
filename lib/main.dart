import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:learnaria/firebase_options.dart';
import 'package:learnaria/screens/splash.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:provider/provider.dart';
import 'package:learnaria/utils/theme_provider.dart';
import 'package:learnaria/utils/locale_provider.dart'; // <-- استيراد ملف اللغة

// --- حزم الترجمة ---
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:learnaria/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- استخدام MultiProvider لتوفير أكثر من حالة ---
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- استخدام Consumer2 للاستماع لحالة المظهر واللغة ---
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,

          // --- إعدادات الترجمة ---
          locale: localeProvider.locale, // <-- تحديد اللغة من الـ Provider
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('ar', ''), // Arabic
          ],

          // --- إعدادات المظهر ---
          themeMode: themeProvider.currentTheme,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            primaryColor: AppColors.primaryYello,
            // ... باقي إعدادات المظهر الفاتح من الكود الأصلي
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.primaryBlack),
              titleTextStyle: TextStyle(color: AppColors.primaryBlack, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            primaryColor: AppColors.primaryYello,
            // ... يمكنك تخصيص باقي إعدادات المظهر الداكن
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
