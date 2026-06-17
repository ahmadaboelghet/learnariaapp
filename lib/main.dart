import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnaria/firebase_options.dart';
import 'package:learnaria/screens/splash.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:provider/provider.dart';
import 'package:learnaria/utils/theme_provider.dart';
import 'package:learnaria/utils/locale_provider.dart'; 

// --- حزم الترجمة ---
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:learnaria/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request push notification permissions and extract FCM Token
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    // Set foreground notification options to show banners when app is open
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Extract and inspect the FCM Token
    String? token = await messaging.getToken();
    debugPrint('================= FCM TOKEN =================');
    debugPrint(token ?? 'FCM Token is null');
    debugPrint('=============================================');
  } catch (e) {
    debugPrint('Error requesting notification permission or getting FCM token: $e');
  }

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

          // --- إعدادات المظهر الفاخر ---
          themeMode: themeProvider.currentTheme,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF9FAFC),
            primaryColor: AppColors.primaryYello,
            fontFamily: GoogleFonts.cairo().fontFamily,
            textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme).copyWith(
              bodyLarge: GoogleFonts.cairo(color: Colors.black87),
              bodyMedium: GoogleFonts.cairo(color: Colors.black87),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black87),
              titleTextStyle: GoogleFonts.cairo(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0D0E12),
            primaryColor: AppColors.primaryYello,
            fontFamily: GoogleFonts.cairo().fontFamily,
            textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).copyWith(
              bodyLarge: GoogleFonts.cairo(color: Colors.white),
              bodyMedium: GoogleFonts.cairo(color: Colors.white70),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
