// (ملف: lib/main.dart - نسخة محدثة مع طباعة الأخطاء وتهيئة التاريخ)
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

// --- [جديد] إضافة حزمة الإشعارات المحلية ---
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// ------------------------------------------

// --- دالة للتعامل مع الإشعارات عندما يكون التطبيق في الخلفية ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

// --- [جديد] تعريف القناة والإشعارات المحلية ---
/// تعريف قناة الإشعارات لأندرويد (ضروري لـ Android 8.0+)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description:
      'This channel is used for important notifications.', // description
  importance: Importance.max,
  playSound: true,
);

/// إنشاء instance من حزمة الإشعارات المحلية
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
// --------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- [جديد] تهيئة الإشعارات المحلية قبل استدعاء setupFirebaseMessaging ---
  // 1. إعدادات الأندرويد (استخدام أيقونة التطبيق الافتراضية)
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // 2. التهيئة الكاملة
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    // (يمكنك إضافة إعدادات iOS هنا إذا احتجت)
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  print("MAIN: Local notifications initialized.");

  // 3. [جديد] إنشاء القناة على أجهزة الأندرويد
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
  print("MAIN: Android Notification Channel created.");
  // --- نهاية تهيئة الإشعارات المحلية ---

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await setupFirebaseMessaging(); // الآن نستدعيها بعد التهيئة

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

// --- دالة مخصصة لتنظيم كود الإشعارات (النسخة المحسنة) ---
// --- دالة مخصصة لتنظيم كود الإشعارات (النسخة المحسنة) ---
Future<void> setupFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;

  // ... (كود طلب الإذن زي ما هو) ...
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );
  print("User notification permission status: ${settings.authorizationStatus}");

  // نستمع لتغيرات حالة الدخول أولاً
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    // إذا كان هناك مستخدم مسجل الدخول
    if (user != null) {
      // نقوم بالحصول على التوكن "بعد" التأكد من وجود مستخدم
      final fcmToken = await messaging.getToken();

      // --- [التعديل الجوهري هنا] ---
      // المستخدم اللي جاي من (OTP) بيكون معاه رقم تليفونه
      if (fcmToken != null && user.phoneNumber != null) {
        print(
          "Saving token and PHONE NUMBER for user ${user.uid}: ${user.phoneNumber}: ${fcmToken}",
        );

        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': fcmToken,
          'phoneNumber': user.phoneNumber, // <-- [مهم جداً] حفظ رقم التليفون
        }, SetOptions(merge: true));
      } else {
        print("User is logged in but has no phone number (maybe old account?)");
      }
    }
  });

  // --- [تم التعديل] التعامل مع الإشعارات عند وصولها والتطبيق في المقدمة ---
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // التأكد من وجود إشعار ومن أننا على نظام أندرويد لعرضه
    if (notification != null && android != null) {
      print(
        'Foreground Notification: ${notification.title} / ${notification.body}',
      );

      // [جديد] استخدام الإشعارات المحلية لإظهار الإشعار في شريط الحالة
      flutterLocalNotificationsPlugin.show(
        notification.hashCode, // id فريد للإشعار
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id, // استخدام نفس ID القناة
            channel.name,
            channelDescription: channel.description,
            playSound: true,
            icon: '@drawable/ic_notification',
            color: Colors.amber,
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
            priority: Priority.high,
          ),
        ),
        // يمكنك تحديد payload إذا أردت التعامل مع الضغط على الإشعار المحلي
        // payload: message.data.toString(),
      );
    }
  });

  // (يمكنك إضافة onMessageOpenedApp و getInitialMessage هنا لاحقاً لمعالجة التوجيه)

  // 5. التعامل مع فتح التطبيق من إشعار (عندما يكون مغلقاً)
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print(
        'App opened from terminated state by message. Data: ${message.data}',
      );
      // _handleMessageNavigation(message.data); // دالة لمعالجة التوجيه
    }
  });

  // 6. التعامل مع فتح التطبيق من إشعار (عندما يكون في الخلفية)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('App opened from background state by message. Data: ${message.data}');
    // _handleMessageNavigation(message.data); // دالة لمعالجة التوجيه
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // قراءة الـ Providers هنا
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      // navigatorKey: navigatorKey, // لتمكين التنقل من handleMessageNavigation
      debugShowCheckedModeBanner: false,
      // استخدام AppLocalizations لجلب العنوان المترجم
      onGenerateTitle: (context) {
        // التأكد من أن Localizations جاهزة قبل استخدامها
        final localizations = AppLocalizations.of(context);
        return localizations?.appName ?? 'Learnaria'; // عنوان افتراضي
      },
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations
          .supportedLocales, // استخدام القائمة من AppLocalizations
      // --- إعدادات المظهر (تم تصحيحها) ---
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      home: const SplashScreen(),
    );
  }
}
