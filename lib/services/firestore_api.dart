import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // تأكد من وجود هذا السطر

class FirestoreApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- !! تم تعديل الدالة !! ---
  // لم نعد بحاجة لاستقبال parentPhoneNumber
  Future<DashboardData> fetchDashboardData() async {
    String studentNameForDashboard = "Student";
    try {
      
      // --- !! 1. جلب بيانات ولي الأمر المسجل حالياً !! ---
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      // إذا لم يكن هناك مستخدم مسجل، أرجع بيانات فارغة
      if (currentUser == null || currentUser.phoneNumber == null) {
        print('FirestoreAPI (خطأ ❌): لا يمكن جلب البيانات. المستخدم null أو لا يملك رقم هاتف.');
        return DashboardData(studentName: studentNameForDashboard, reportsByTeacher: []);
      }

      final String parentUid = currentUser.uid;
      final String parentPhoneNumber = currentUser.phoneNumber!;

      print('FirestoreAPI (DEBUG): جاري البحث عن طالب برقم هاتف ولي الأمر: $parentPhoneNumber');
      // --- !! نهاية التعديل !! ---
      

      final studentsSnapshot = await _firestore
          .collectionGroup('students')
          .where('parentPhoneNumber', isEqualTo: parentPhoneNumber)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        print('FirestoreAPI (DEBUG): لم يتم العثور على طالب برقم الهاتف هذا.');
        return DashboardData(studentName: studentNameForDashboard, reportsByTeacher: []);
      }
      
      studentNameForDashboard = studentsSnapshot.docs.first.data()['name'] ?? 'Student';
      Map<String, TeacherReport> reportsMap = {};

      for (var studentDoc in studentsSnapshot.docs) {

        // --- !! 2. ربط الطالب بولي الأمر (حلقة الوصل) !! ---
        // (هذا الكود سيعمل الآن لأننا متأكدون من وجود parentUid)
        try {
          print('FirestoreAPI (محاولة الربط): جاري ربط UID ${parentUid} بالطالب ${studentDoc.id}');
          
          await studentDoc.reference.set(
            {'parentUserId': parentUid},
            SetOptions(merge: true), // merge:true ليتم الإضافة/التحديث بدون مسح بيانات
          );
          
          print('FirestoreAPI (نجاح ✅): تم ربط الطالب بنجاح.');
        
        } catch (e) {
          print('FirestoreAPI (خطأ ❌): فشل ربط الطالب ${studentDoc.id}. خطأ: $e');
        }
        // --- !! نهاية التعديل !! ---


        // --- (باقي الكود الخاص بك كما هو) ---
        final studentId = studentDoc.id;
        final studentName = studentDoc.data()['name'] ?? 'N/A';
        final pathSegments = studentDoc.reference.path.split('/');
        final teacherId = pathSegments[1];
        final groupId = pathSegments[3];

        if (!reportsMap.containsKey(teacherId)) {
          final teacherDoc = await _firestore.collection('teachers').doc(teacherId).get();
          reportsMap[teacherId] = TeacherReport(
            teacherId: teacherId,
            teacherName: teacherDoc.data()?['name'] ?? 'Unknown Teacher',
            subject: teacherDoc.data()?['subject'] ?? 'General',
            attendance: [],
            grades: [],
            schedule: [],
          );
        }
        
        // ... (باقي الكود بدون تغيير) ...
        
        final recurringSchedulesSnap = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('recurringSchedules').get();
        final exceptionsSnap = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('scheduleExceptions').get();
        
        final today = DateTime.now();
        final todayString = DateFormat('yyyy-MM-dd').format(today);
        
        final int currentDayJs = today.weekday % 7; 

        List<ScheduleEntry> finalScheduleForToday = [];

        for (var doc in recurringSchedulesSnap.docs) {
          final scheduleData = doc.data();
          final days = List.from(scheduleData['days'] ?? []);

          if (days.isEmpty) continue;

          bool isClassToday = false;

          if (days.first is String) {
            final currentDayNameEn = DateFormat('EEEE', 'en_US').format(today);
            final currentDayNameAr = DateFormat('EEEE', 'ar_SA').format(today);
            if (days.contains(currentDayNameEn) || days.contains(currentDayNameAr)) {
              isClassToday = true;
            }
          } else if (days.first is int) {
            if (days.contains(currentDayJs)) {
              isClassToday = true;
            }
          }

          if (isClassToday) {
            finalScheduleForToday.add(ScheduleEntry.fromFirestore({
              ...scheduleData,
              'date': todayString, 
            }));
          }
        }
        
        for (var doc in exceptionsSnap.docs) {
          final exceptionData = doc.data();
          if (exceptionData['date'] == todayString) {
            final status = exceptionData['status'];
            if (status == 'cancelled') {
              finalScheduleForToday.clear();
            } else if (status == 'rescheduled') {
              if (finalScheduleForToday.isNotEmpty) {
                finalScheduleForToday[0] = finalScheduleForToday[0].copyWith(time: exceptionData['newTime']);
              }
            }
          }
        }

        reportsMap[teacherId]!.schedule.addAll(finalScheduleForToday);

        final attendanceSnapshot = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('dailyAttendance').get();
        for (var doc in attendanceSnapshot.docs) {
          final records = doc.data()['records'] as List<dynamic>?;
          records?.forEach((record) {
            if (record['studentId'] == studentId) {
              reportsMap[teacherId]!.attendance.add(AttendanceRecord(
                studentName: studentName,
                date: doc.data()['date'],
                status: record['status'],
              ));
            }
          });
        }

        final assignmentsSnapshot = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('assignments').get();
        for (var doc in assignmentsSnapshot.docs) {
          final assignmentData = doc.data();
          final scoresMap = assignmentData['scores'] as Map<String, dynamic>? ?? {};
          final studentScoreData = scoresMap[studentId] as Map<String, dynamic>?;

          if (studentScoreData != null) {
              final scoreValue = studentScoreData['score'];
              int? finalScore;
              if (scoreValue is num) {
                  finalScore = scoreValue.toInt();
              } else if (scoreValue is String && scoreValue.isNotEmpty) {
                  finalScore = int.tryParse(scoreValue);
              }

              reportsMap[teacherId]!.grades.add(GradeRecord(
                  studentName: studentName,
                  assignmentName: assignmentData['name'] ?? 'N/A',
                  score: finalScore,
                  date: assignmentData['date'] ?? 'N/A',
                  submitted: studentScoreData['submitted'] as bool? ?? false,
              ));
          }
        }
      }

      return DashboardData(
        studentName: studentNameForDashboard,
        reportsByTeacher: reportsMap.values.toList(),
      );

    } catch (e) {
      print('FATAL API Error in fetchDashboardData: $e');
      throw Exception('Failed to load dashboard data. A server error occurred.');
    }
  }
}