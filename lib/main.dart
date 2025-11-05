// (ملف: lib/main.dart - نسخة محدثة مع طباعة الأخطاء وتهيئة التاريخ)
   import 'package:flutter/material.dart';
   import 'package:firebase_core/firebase_core.dart';
   import 'package:learnaria/firebase_options.dart';
   import 'package:learnaria/screens/auth_check.dart'; // <-- تأكد من وجود هذا الملف
import 'package:learnaria/screens/splash.dart';
   import 'package:learnaria/utils/app_styles.dart';
   import 'package:provider/provider.dart';
   import 'package:learnaria/utils/theme_provider.dart';
   import 'package:learnaria/utils/locale_provider.dart';
   import 'package:flutter_localizations/flutter_localizations.dart';
   import 'package:learnaria/l10n/app_localizations.dart';
   import 'package:firebase_messaging/firebase_messaging.dart';
   import 'package:cloud_firestore/cloud_firestore.dart';
   import 'package:firebase_auth/firebase_auth.dart';
   import 'package:intl/date_symbol_data_local.dart'; // <-- لإعداد التاريخ بالعربي

   @pragma('vm:entry-point')
   Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
     // تأكد من تهيئة Firebase هنا أيضًا إذا كنت ستقوم بعمليات تتطلبها
     try {
       await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
       print("Handling a background message: ${message.messageId}");
       // يمكنك إضافة المزيد من المنطق هنا
     } catch (e) {
       print("!!!!!!!! BACKGROUND HANDLER ERROR initializing Firebase: $e");
     }
   }

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();

     // تهيئة التاريخ للغة العربية (أو لغات أخرى)
     try {
        // تهيئة لجميع اللغات المدعومة بدلاً من لغة واحدة فقط
        await initializeDateFormatting();
        print("MAIN: Date formatting initialized successfully.");
     } catch (e) {
        print("!!!!!!!! Warning: Could not initialize date formatting: $e");
     }

     // تهيئة Firebase وإعداد الإشعارات
     try {
       print("MAIN: 1. Attempting Firebase.initializeApp...");
       await Firebase.initializeApp(
         options: DefaultFirebaseOptions.currentPlatform,
       );
       print("MAIN: 2. Firebase.initializeApp SUCCESSFUL.");

       // إعداد معالج الخلفية *بعد* التهيئة الناجحة
       FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
       print("MAIN: Background message handler set.");


       // إعداد باقي الإشعارات وحفظ التوكن
       print("MAIN: 3. Attempting to call setupFirebaseMessaging...");
       await setupFirebaseMessaging(); // لا حاجة لـ await هنا لأنها تحتوي على listen
       print("MAIN: 4. setupFirebaseMessaging call initiated (listener attached).");

     } catch (e) {
       print("!!!!!!!! MAIN: ERROR during Firebase initialization or setup: $e");
       // من المهم معالجة هذا الخطأ، ربما بعرض رسالة للمستخدم
       // runApp(ErrorApp(error: e.toString())); // مثال
       // return; // إيقاف التطبيق إذا فشلت التهيئة الأساسية
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

   // --- دالة إعداد الإشعارات وحفظ التوكن ---
   Future<void> setupFirebaseMessaging() async {
     print("SETUP: 0. ENTERED setupFirebaseMessaging function.");
     final messaging = FirebaseMessaging.instance;

     // 1. طلب الإذن (مهم لـ iOS وأندرويد 13+)
     try {
       print("SETUP: 1. Attempting messaging.requestPermission...");
       NotificationSettings settings = await messaging.requestPermission(
         alert: true,
         badge: true,
         sound: true,
         provisional: false, // اطلب إذناً كاملاً وليس مؤقتاً
       );
       print("SETUP: 2. Notification permission status: ${settings.authorizationStatus}");
       if (settings.authorizationStatus != AuthorizationStatus.authorized &&
           settings.authorizationStatus != AuthorizationStatus.provisional) {
         print("!!!!!!!! SETUP: User declined or has not accepted permission");
         // يمكنك هنا إظهار رسالة للمستخدم توضح أهمية الإشعارات
       }
     } catch (e) {
       print("!!!!!!!! SETUP: 1. ERROR requesting notification permission: $e");
     }

     // 2. الاستماع لتغيرات حالة المصادقة لحفظ/حذف التوكن
     FirebaseAuth.instance.authStateChanges().listen((user) async {
       print("SETUP (Auth): Auth state changed. User is: ${user?.uid ?? 'null'}");

       if (user != null) {
         // المستخدم سجل الدخول -> حاول الحصول على التوكن وحفظه
         String? fcmToken;
         try {
           print("SETUP (Auth): Getting FCM token for user ${user.uid}...");
           // الحصول على التوكن
           fcmToken = await messaging.getToken();
           print("SETUP (Auth): Got FCM Token: $fcmToken");

           if (fcmToken != null) {
             // حفظ التوكن في Firestore
             print("SETUP (Auth): Attempting to write token to Firestore: /users/${user.uid}");
             await FirebaseFirestore.instance
                 .collection('users')
                 .doc(user.uid)
                 .set({'fcmToken': fcmToken}, SetOptions(merge: true));
             print("SETUP (Auth): SUCCESS: Token written to Firestore.");
           } else {
             // هذا قد يحدث إذا كانت خدمات جوجل غير متاحة مؤقتاً
             print("!!!!!!!! SETUP (Auth): ERROR getting FCM Token: Token is null.");
           }
         } catch (e) {
           // التعامل مع الأخطاء أثناء الحصول على التوكن أو الكتابة
           print("!!!!!!!! SETUP (Auth): ERROR getting or writing FCM Token: $e");
         }
       } else {
         // المستخدم سجل الخروج -> يمكنك حذف التوكن إذا أردت
         print("SETUP (Auth): User is logged out.");
         try {
           // حاول حذف التوكن لمنع إرسال إشعارات لجهاز غير مستخدم
           // await messaging.deleteToken();
           // print("SETUP (Auth): Token potentially deleted on logout.");
           // ملاحظة: deleteToken قد يسبب مشاكل إذا تم استدعاؤه كثيراً
           // قد يكون الأفضل هو فقط عدم إرسال إشعار من الخادم إذا كان المستخدم غير نشط
         } catch (e) {
           print("!!!!!!!! SETUP (Auth): ERROR deleting token on logout: $e");
         }
       }
     });

     // 3. الاستماع للتوكن الجديد (إذا تغير)
     messaging.onTokenRefresh.listen((newToken) async {
        print("SETUP (Token Refresh): FCM Token refreshed: $newToken");
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && newToken != null) {
          try {
            print("SETUP (Token Refresh): Attempting to update token in Firestore for user ${user.uid}");
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({'fcmToken': newToken}, SetOptions(merge: true));
            print("SETUP (Token Refresh): SUCCESS: Token updated in Firestore.");
          } catch (e) {
             print("!!!!!!!! SETUP (Token Refresh): ERROR updating refreshed token: $e");
          }
        }
     }).onError((error) {
         print("!!!!!!!! SETUP (Token Refresh): Error listening to token refresh: $error");
     });


     // 4. التعامل مع الإشعارات عند وصولها والتطبيق في المقدمة
     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
       print('Foreground Message data: ${message.data}');
       if (message.notification != null) {
         print('Foreground Notification: ${message.notification!.title} / ${message.notification!.body}');
         // TODO: عرض إشعار داخل التطبيق أو تحديث الواجهة
         // مثال: استخدام Get.snackbar أو OverlayNotification
         // أو عرض إشعار محلي باستخدام flutter_local_notifications إذا أردت ظهوره في شريط الحالة
       }
     });

      // 5. التعامل مع فتح التطبيق من إشعار (عندما يكون مغلقاً)
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          print('App opened from terminated state by message. Data: ${message.data}');
          _handleMessageNavigation(message.data); // دالة لمعالجة التوجيه
        }
      });

      // 6. التعامل مع فتح التطبيق من إشعار (عندما يكون في الخلفية)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from background state by message. Data: ${message.data}');
        _handleMessageNavigation(message.data); // دالة لمعالجة التوجيه
      });

     print("SETUP: Firebase Messaging setup complete (listeners attached).");
   }

   // دالة مساعدة لمعالجة التوجيه بناءً على بيانات الإشعار
   void _handleMessageNavigation(Map<String, dynamic> data) {
      final screen = data['screen']; // افترض أنك ترسل 'screen' في data
      if (screen == 'attendance') {
         // TODO: انتقل لشاشة الحضور
         print("Navigation: Should navigate to Attendance screen.");
         // مثال: navigatorKey.currentState?.pushNamed('/attendance', arguments: data['studentId']);
      } else if (screen == 'grades') {
         // TODO: انتقل لشاشة الدرجات
         print("Navigation: Should navigate to Grades screen.");
         // مثال: navigatorKey.currentState?.pushNamed('/grades', arguments: data['assignmentId']);
      }
      // أضف المزيد من الشروط حسب الحاجة
   }

   // --- MyApp Widget ---
   class MyApp extends StatelessWidget {
     const MyApp({super.key});

     // يمكنك إضافة GlobalKey<NavigatorState> هنا إذا أردت التنقل من خارج الـ BuildContext
     // static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
         supportedLocales: AppLocalizations.supportedLocales, // استخدام القائمة من AppLocalizations

         themeMode: themeProvider.currentTheme,
         // تعريف الثيمات بشكل أفضل
         theme: ThemeData(
             brightness: Brightness.light,
             primarySwatch: Colors.amber, // استخدام primarySwatch لإنشاء تدرجات لونية متناسقة
             scaffoldBackgroundColor: const Color(0xFFF8F8F8), // لون خلفية فاتح قليلاً
             primaryColor: AppColors.primaryYello, // تأكد من تعريفه
             appBarTheme: const AppBarTheme(
                 backgroundColor: Colors.white,
                 elevation: 0.5, // ظل خفيف جداً
                 iconTheme: IconThemeData(color: AppColors.primaryBlack),
                 titleTextStyle: TextStyle(color: AppColors.primaryBlack, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter'), // تحديد الخط
                 centerTitle: false, // محاذاة العنوان لليسار/اليمين حسب اللغة
             ),
             fontFamily: 'Inter', // تحديد الخط الافتراضي للتطبيق
             // يمكنك تخصيص ألوان وعناصر أخرى للثيم الفاتح
             colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.amber).copyWith(secondary: Colors.redAccent), // تحديد لون ثانوي
          ),
          
          home: const SplashScreen(),
        );
      }
  }

