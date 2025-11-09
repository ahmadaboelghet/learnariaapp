//
// ملف: lib/services/firestore_api.dart
// (النسخة النهائية: تستدعي الـ Cloud Function وتعمل Cast صح)
//

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert'; // <-- [جديد] هنحتاج دي عشان الـ Cast

class FirestoreApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- [تم التعديل بالكامل] ---
  // الدالة الآن تستدعي الـ Cloud Function
  Future<DashboardData> fetchDashboardData() async {
    try {
      // 1. نتأكد أن المستخدم مسجل دخوله
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      print('FirestoreAPI: Calling "getDashboardData" Cloud Function...');

      // 2. استدعاء الـ Function
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('getDashboardData');
      final result = await callable.call();

      print('FirestoreAPI: Cloud Function returned successfully.');
      
      // --- [هذا هو الإصلاح] ---
      // الداتا اللي راجعة (result.data) نوعها Map<Object?, Object?>
      // إحنا محتاجين نحولها لـ Map<String, dynamic>
      
      final dynamic rawData = result.data;
      if (rawData == null) {
        throw Exception('Cloud Function returned null data.');
      }
      
      // 3. بنحول الداتا لـ String
      final String jsonString = jsonEncode(rawData);
      
      // 4. بنرجع الداتا من String لـ Map (المرة دي Dart هيفهمها صح)
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);

      // 5. دلوقتي الـ fromJson هتشتغل 100%
      return DashboardData.fromJson(jsonData);
      // --- [نهاية الإصلاح] ---

    } on FirebaseFunctionsException catch (e) {
      print('Cloud Function Error: ${e.code} - ${e.message}');
      throw Exception('Failed to load data from server: ${e.message}');
    } catch (e) {
      print('Fatal API Error in fetchDashboardData (Cast Error?): $e');
      throw Exception('Failed to load dashboard data: $e');
    }
  }
}