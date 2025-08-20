import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:intl/intl.dart'; 

class FirestoreApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DashboardData> fetchDashboardData({required String parentPhoneNumber}) async {
    String studentNameForDashboard = "Student";
    try {
      final studentsSnapshot = await _firestore
          .collectionGroup('students')
          .where('parentPhoneNumber', isEqualTo: parentPhoneNumber)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        return DashboardData(studentName: studentNameForDashboard, reportsByTeacher: []);
      }
      
      studentNameForDashboard = studentsSnapshot.docs.first.data()['name'] ?? 'Student';
      Map<String, TeacherReport> reportsMap = {};

      for (var studentDoc in studentsSnapshot.docs) {
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

        // ====================================================================
        // ====================    بداية الحل الجذري والنهائي   ====================
        // ====================================================================
        final recurringSchedulesSnap = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('recurringSchedules').get();
        final exceptionsSnap = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('scheduleExceptions').get();
        
        final today = DateTime.now();
        final todayString = DateFormat('yyyy-MM-dd').format(today);
        
        // الخطوة 1: الحصول على رقم اليوم الحالي (الأحد=0, الاثنين=1, ..)
        // Dart's weekday: Mon=1..Sun=7. JS getDay(): Sun=0..Sat=6. We use the JS standard.
        final int currentDayJs = today.weekday % 7; 

        List<ScheduleEntry> finalScheduleForToday = [];

        // الخطوة 2: معالجة الجداول المحفوظة والتحقق من التوافق مع اليوم الحالي
        for (var doc in recurringSchedulesSnap.docs) {
          final scheduleData = doc.data();
          final days = List.from(scheduleData['days'] ?? []);

          if (days.isEmpty) continue; // تخطي الجدول إذا كان فارغًا

          bool isClassToday = false;

          // التحقق إذا كانت البيانات قديمة (أسماء) أم جديدة (أرقام)
          if (days.first is String) {
            // **منطق للتعامل مع البيانات القديمة (أسماء الأيام)**
            final currentDayNameEn = DateFormat('EEEE', 'en_US').format(today); // e.g., "Sunday"
            final currentDayNameAr = DateFormat('EEEE', 'ar_SA').format(today); // e.g., "الأحد"
            if (days.contains(currentDayNameEn) || days.contains(currentDayNameAr)) {
              isClassToday = true;
            }
          } else if (days.first is int) {
            // **المنطق الجديد للتعامل مع الأرقام**
            if (days.contains(currentDayJs)) {
              isClassToday = true;
            }
          }

          // إذا كانت الحصة مجدولة لليوم، أضفها للقائمة
          if (isClassToday) {
            finalScheduleForToday.add(ScheduleEntry.fromFirestore({
              ...scheduleData,
              'date': todayString, 
            }));
          }
        }
        
        // الخطوة 3: تطبيق الاستثناءات (إلغاء أو تعديل موعد)
        for (var doc in exceptionsSnap.docs) {
          final exceptionData = doc.data();
          if (exceptionData['date'] == todayString) {
            final status = exceptionData['status'];
            if (status == 'cancelled') {
              finalScheduleForToday.clear(); // إلغاء كل حصص اليوم
            } else if (status == 'rescheduled') {
              if (finalScheduleForToday.isNotEmpty) {
                finalScheduleForToday[0] = finalScheduleForToday[0].copyWith(time: exceptionData['newTime']);
              }
            }
          }
        }
        // =======================    نهاية الحل الجذري   =======================
        // ====================================================================

        reportsMap[teacherId]!.schedule.addAll(finalScheduleForToday);

        // Fetch Attendance
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

        // Fetch Grades
        final gradesSnapshot = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('assignments').get();
        for (var doc in gradesSnapshot.docs) {
          final scores = doc.data()['scores'] as List<dynamic>?;
          scores?.forEach((scoreRecord) {
            if (scoreRecord['studentId'] == studentId) {
              reportsMap[teacherId]!.grades.add(GradeRecord(
                studentName: studentName,
                assignmentName: doc.data()['name'],
                score: (scoreRecord['score'] as num?)?.toInt() ?? 0,
                date: doc.data()['date'] ?? 'N/A',
              ));
            }
          });
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