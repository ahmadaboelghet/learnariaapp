import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// --- معالج الإشعارات في الخلفية (يجب أن تكون دالة خارج أي كلاس) ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // هذا المكان لمعالجة الإشعارات إذا كان التطبيق مغلق تمامًا
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // --- طلب صلاحية عرض الإشعارات من المستخدم ---
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // --- إعداد معالجات الإشعارات ---

    // 1. عند وصول إشعار والتطبيق مفتوح في الواجهة
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
        }
      }
      // يمكنك هنا عرض إشعار محلي custom إذا أردت
    });

    // 2. عند الضغط على إشعار والتطبيق كان مغلقًا تمامًا
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('App opened from terminated state by notification: ${message.data}');
        }
        // هنا يمكنك توجيه المستخدم لشاشة معينة
      }
    });
    
    // 3. عند الضغط على إشعار والتطبيق كان في الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('App opened from background by notification: ${message.data}');
        }
        // هنا يمكنك توجيه المستخدم لشاشة معينة
    });

    // 4. تحديد دالة معالجة الإشعارات في الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // --- دالة لاشتراك المستخدم في الـ topic الخاص به ---
  Future<void> subscribeToUserTopic() async {
    final user = FirebaseAuth.instance.currentUser;
    // نتأكد من أن المستخدم سجل دخوله وأن لديه رقم هاتف
    if (user != null && user.phoneNumber != null) {
      // اسم الـ topic يجب أن لا يحتوي على رموز خاصة مثل '+'
      // لذلك سنقوم بتنظيف رقم الهاتف
      final String userTopic = user.phoneNumber!.replaceAll(RegExp(r'[+\s]'), '');
      
      await _fcm.subscribeToTopic(userTopic);
      
      if (kDebugMode) {
        print('Subscribed to topic: $userTopic');
      }
    } else {
       if (kDebugMode) {
        print('User not logged in or has no phone number, cannot subscribe to topic.');
      }
    }
  }

  // --- دالة لإلغاء الاشتراك عند تسجيل الخروج (اختياري) ---
  Future<void> unsubscribeFromUserTopic() async {
     final user = FirebaseAuth.instance.currentUser;
     if (user != null && user.phoneNumber != null) {
      final String userTopic = user.phoneNumber!.replaceAll(RegExp(r'[+\s]'), '');
      await _fcm.unsubscribeFromTopic(userTopic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $userTopic');
      }
    }
  }
}
