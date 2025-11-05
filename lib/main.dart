import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:learnaria/firebase_options.dart';
import 'package:learnaria/screens/splash.dart';
import 'package:learnaria/utils/app_styles.dart'; // ستحتاج AppColors من هذا الملف
import 'package:provider/provider.dart';
import 'package:learnaria/utils/theme_provider.dart';
import 'package:learnaria/utils/locale_provider.dart';

// --- حزم الترجمة ---
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:learnaria/l10n/app_localizations.dart';

// ---  Imports for Notifications ---
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


// --- دالة للتعامل مع الإشعارات عندما يكون التطبيق في الخلفية ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await setupFirebaseMessaging();

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

// --- دالة مخصصة لتنظيم كود الإشعارات ---
// --- دالة مخصصة لتنظيم كود الإشعارات (النسخة المحسنة) ---
Future<void> setupFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  // نستمع لتغيرات حالة الدخول أولاً
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    // إذا كان هناك مستخدم مسجل الدخول
    if (user != null) {
      // نقوم بالحصول على التوكن "بعد" التأكد من وجود مستخدم
      final fcmToken = await messaging.getToken();
      
      // نطبع التوكن هنا للتأكد في كل مرة يتم فيها الحفظ
      print("Saving token for user ${user.uid}: $fcmToken");

      if (fcmToken != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'fcmToken': fcmToken}, SetOptions(merge: true));
      }
    }
  });
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    if (message.notification != null) {
      print('Notification Title: ${message.notification!.title}');
      print('Notification Body: ${message.notification!.body}');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,

          // --- إعدادات الترجمة ---
          locale: localeProvider.locale,
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

          // --- إعدادات المظهر (تم تصحيحها) ---
          themeMode: themeProvider.currentTheme, // provider.themeMode هو الصحيح
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            primaryColor: AppColors.primaryYello,
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
