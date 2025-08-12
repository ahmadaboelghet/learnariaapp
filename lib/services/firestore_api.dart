import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:intl/intl.dart'; // To get day of the week

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

        // --- NEW SCHEDULE LOGIC ---
        // Fetch all types of schedules for the group
        final recurringSchedulesSnap = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('recurringSchedules').get();
        final exceptionsSnap = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('scheduleExceptions').get();
        
        final today = DateTime.now();
        final todayString = DateFormat('yyyy-MM-dd').format(today);
        final currentDayName = DateFormat('EEEE').format(today); // e.g., "Sunday"

        List<ScheduleEntry> finalScheduleForToday = [];

        // 1. Process recurring schedules for today
        for (var doc in recurringSchedulesSnap.docs) {
          final scheduleData = doc.data();
          final days = List<String>.from(scheduleData['days'] ?? []);
          if (days.contains(currentDayName)) {
            finalScheduleForToday.add(ScheduleEntry.fromFirestore({
              ...scheduleData,
              'date': todayString, // Assign today's date
            }));
          }
        }
        
        // 2. Process exceptions for today
        for (var doc in exceptionsSnap.docs) {
          final exceptionData = doc.data();
          if (exceptionData['date'] == todayString) {
            final status = exceptionData['status'];
            if (status == 'cancelled') {
              // Remove the class that was supposed to happen today
              finalScheduleForToday.removeWhere((entry) => entry.subject == reportsMap[teacherId]!.subject);
            } else if (status == 'rescheduled') {
              // Find the recurring schedule and update its time
              final index = finalScheduleForToday.indexWhere((entry) => entry.subject == reportsMap[teacherId]!.subject);
              if (index != -1) {
                finalScheduleForToday[index] = finalScheduleForToday[index].copyWith(time: exceptionData['newTime']);
              }
            }
          }
        }

        // Add the processed schedule to the report
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
      print('FATAL API Error: $e');
      throw Exception('Failed to load dashboard data. A server error occurred.');
    }
  }
}