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
  // ملاحظة: لا تضع try/catch هنا إلا إذا كنت متأكداً
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- !! DEBUG: سنقوم بتتبع كل خطوة !! ---
  try {
    print("MAIN: 1. Attempting Firebase.initializeApp...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("MAIN: 2. Firebase.initializeApp SUCCESSFUL.");
  } catch (e) {
    // --- !! إذا فشلت التهيئة، سيظهر الخطأ هنا !! ---
    print("!!!!!!!! MAIN: 1. ERROR during Firebase.initializeApp: $e");
  }

  // سيتم تحديدها حتى لو فشلت التهيئة، لكنها لن تعمل
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    print("MAIN: 3. Attempting to call setupFirebaseMessaging...");
    await setupFirebaseMessaging();
    print("MAIN: 4. setupFirebaseMessaging call FINISHED.");
  } catch (e) {
    // --- !! إذا فشلت الدالة نفسها، سيظهر الخطأ هنا !! ---
    print("!!!!!!!! MAIN: 3. ERROR during setupFirebaseMessaging call: $e");
  }

  print("MAIN: 5. Running app...");
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


// --- دالة مخصصة لتنظيم كود الإشعارات (النسخة المحسنة مع Try/Catch) ---
Future<void> setupFirebaseMessaging() async {
  
  // --- !! DEBUG: هذا أهم سطر !! ---
  print("SETUP: 0. ENTERED setupFirebaseMessaging function."); 

  final messaging = FirebaseMessaging.instance;
  
  try {
    print("SETUP: 1. Attempting messaging.requestPermission...");
    await messaging.requestPermission();
    print("SETUP: 2. messaging.requestPermission SUCCESSFUL.");
  } catch (e) {
    print("!!!!!!!! SETUP: 1. ERROR requesting permission: $e");
  }


  FirebaseAuth.instance.authStateChanges().listen((user) async {
    print("SETUP (Auth): Auth state changed. User is: ${user?.uid}");

    if (user != null) {
      
      String? fcmToken;
      try {
        print("SETUP (Auth): Getting token for user ${user.uid}...");
        fcmToken = await messaging.getToken();
        
        // --- !! سنعرف هنا إذا كان التوكن null أم لا !! ---
        print("SETUP (Auth): Got FCM Token: $fcmToken");

      } catch (e) {
        print("!!!!!!!! SETUP (Auth): ERROR getting FCM Token: $e");
      }


      if (fcmToken != null) {
        try {
          print("SETUP (Auth): Attempting to write token to Firestore: /users/${user.uid}");
          
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'fcmToken': fcmToken}, SetOptions(merge: true));

          print("SETUP (Auth): SUCCESS: Token written to Firestore.");

        } catch (e) {
          // --- !! إذا فشلت الكتابة (بسبب القواعد مثلاً) سيظهر الخطأ هنا !! ---
          print("!!!!!!!! SETUP (Auth): ERROR writing token to Firestore: $e");
        }
      } else {
        print("SETUP (Auth): fcmToken is null. Skipping Firestore write.");
      }

    } else {
      print("SETUP (Auth): User is logged out.");
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

// --- (باقي كود MyApp كما هو بدون تغيير) ---
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