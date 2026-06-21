import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/models/notification_item.dart';
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
            payments: [],
          );
        }
        
        final recurringSchedulesSnap = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('recurringSchedules').get();
        final exceptionsSnap = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('scheduleExceptions').get();
        
        final today = DateTime.now();
        List<ScheduleEntry> finalScheduleList = [];

        for (int i = -3; i <= 3; i++) {
          final targetDate = today.add(Duration(days: i));
          final dateString = DateFormat('yyyy-MM-dd').format(targetDate);
          final int targetDayJs = targetDate.weekday % 7; 

          List<ScheduleEntry> daySchedules = [];

          for (var doc in recurringSchedulesSnap.docs) {
            final scheduleData = doc.data();
            final days = List.from(scheduleData['days'] ?? []);

            if (days.isEmpty) continue;

            bool isClassOnDay = false;

            if (days.first is String) {
              final dayNameEn = DateFormat('EEEE', 'en_US').format(targetDate);
              final dayNameAr = DateFormat('EEEE', 'ar_SA').format(targetDate);
              if (days.contains(dayNameEn) || days.contains(dayNameAr)) {
                isClassOnDay = true;
              }
            } else if (days.first is int) {
              if (days.contains(targetDayJs)) {
                isClassOnDay = true;
              }
            }

            if (isClassOnDay) {
              daySchedules.add(ScheduleEntry.fromFirestore({
                ...scheduleData,
                'date': dateString, 
              }));
            }
          }

          // Check exceptions for this target date
          for (var doc in exceptionsSnap.docs) {
            final exceptionData = doc.data();
            if (exceptionData['date'] == dateString) {
              final status = exceptionData['status'];
              if (status == 'cancelled') {
                daySchedules.clear();
              } else if (status == 'rescheduled') {
                for (int j = 0; j < daySchedules.length; j++) {
                  daySchedules[j] = daySchedules[j].copyWith(time: exceptionData['newTime']);
                }
              }
            }
          }

          finalScheduleList.addAll(daySchedules);
        }

        reportsMap[teacherId]!.schedule.addAll(finalScheduleList);

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

        final paymentsSnapshot = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('payments').get();
        for (var doc in paymentsSnapshot.docs) {
          final paymentData = doc.data();
          final month = paymentData['month'] as String? ?? '';
          final records = paymentData['records'] as List<dynamic>? ?? [];
          
          final record = records.firstWhere(
            (r) => r is Map && r['studentId'] == studentId,
            orElse: () => null,
          );
          
          if (record != null) {
            final isPaid = record['paid'] == true;
            final amountVal = record['amount'];
            String amountStr = '500 EGP';
            if (amountVal != null) {
              amountStr = '$amountVal EGP';
            }
            
            String dateStr = '-';
            if (isPaid) {
              if (record['date'] != null) {
                dateStr = record['date'].toString();
              } else if (record['paidAt'] != null) {
                dateStr = record['paidAt'].toString();
              } else {
                try {
                  final parsedMonth = DateFormat('yyyy-MM').parse(month);
                  final paymentDate = DateTime(parsedMonth.year, parsedMonth.month, 5);
                  dateStr = DateFormat('dd MMMM yyyy').format(paymentDate);
                } catch (_) {
                  dateStr = '05-$month';
                }
              }
            }
            
            String receiptStr = '-';
            if (isPaid) {
              if (record['receipt'] != null) {
                receiptStr = record['receipt'].toString();
              } else if (record['receiptNo'] != null) {
                receiptStr = record['receiptNo'].toString();
              } else {
                receiptStr = 'REC-${month.replaceAll('-', '')}${studentId.substring(0, 2).toUpperCase()}';
              }
            }
            
            reportsMap[teacherId]!.payments.add(PaymentRecord(
              month: month,
              paid: isPaid,
              amount: amountStr,
              date: dateStr,
              receipt: receiptStr,
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

  Future<List<NotificationItem>> fetchNotifications({required String parentPhoneNumber}) async {
    try {
      final studentsSnapshot = await _firestore
          .collectionGroup('students')
          .where('parentPhoneNumber', isEqualTo: parentPhoneNumber)
          .get();

      List<NotificationItem> allNotifications = [];

      for (var studentDoc in studentsSnapshot.docs) {
        // Query notificationHistory subcollection
        final notificationsSnap = await studentDoc.reference
            .collection('notificationHistory')
            .orderBy('sentAt', descending: true)
            .get();

        for (var doc in notificationsSnap.docs) {
          final data = doc.data();
          final id = doc.id;
          final title = data['title'] ?? 'Notification';
          final body = data['body'] ?? '';
          final titleAr = data['titleAr'] ?? title;
          final bodyAr = data['bodyAr'] ?? body;
          final contextStr = data['context'] ?? '';
          final sentAtTimestamp = data['sentAt'] as Timestamp?;
          final timestamp = sentAtTimestamp?.toDate() ?? DateTime.now();

          // Map contexts logically:
          // Presence/Absence/Attendance -> attendance category
          // Grades/Marks/Exams/Assignments -> grade category
          // Payments/Invoices/Fees -> payment category
          // Others -> system category
          String category = 'system';
          final lowerContext = contextStr.toLowerCase();
          if (lowerContext.contains('presence') || lowerContext.contains('absence') || lowerContext.contains('attendance')) {
            category = 'attendance';
          } else if (lowerContext.contains('grade') || lowerContext.contains('mark') || lowerContext.contains('exam') || lowerContext.contains('assignment')) {
            category = 'grade';
          } else if (lowerContext.contains('payment') || lowerContext.contains('invoice') || lowerContext.contains('fee')) {
            category = 'payment';
          }

          allNotifications.add(NotificationItem(
            id: id,
            title: title,
            body: body,
            titleAr: titleAr,
            bodyAr: bodyAr,
            timestamp: timestamp,
            category: category,
            isRead: false,
          ));
        }
      }

      // Sort aggregated notifications by date descending
      allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allNotifications;
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }
}