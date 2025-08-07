import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnaria/models/dashboard_data.dart';

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
      Set<String> processedGroupSchedules = {};

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

        // Fetch Grades and include the date
        final gradesSnapshot = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('assignments').get();
        for (var doc in gradesSnapshot.docs) {
          final scores = doc.data()['scores'] as List<dynamic>?;
          scores?.forEach((scoreRecord) {
            if (scoreRecord['studentId'] == studentId) {
              reportsMap[teacherId]!.grades.add(GradeRecord(
                studentName: studentName,
                assignmentName: doc.data()['name'],
                score: (scoreRecord['score'] as num?)?.toInt() ?? 0,
                date: doc.data()['date'] ?? 'N/A', // تم إضافة التاريخ هنا
              ));
            }
          });
        }

        // Fetch Schedule
        if (!processedGroupSchedules.contains(groupId)) {
          final scheduleSnapshot = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('classSchedule').get();
          for (var doc in scheduleSnapshot.docs) {
              reportsMap[teacherId]!.schedule.add(ScheduleEntry.fromFirestore(doc.data()));
          }
          processedGroupSchedules.add(groupId);
        }
      }

      return DashboardData(
        studentName: studentNameForDashboard,
        reportsByTeacher: reportsMap.values.toList(),
      );

    } catch (e) {
      print('FATAL API Error: $e');
      throw Exception('Failed to load dashboard data. A server error occurred.');
    }
  }
}