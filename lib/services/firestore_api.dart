import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/models/notification_item.dart';
import 'package:intl/intl.dart';

class FirestoreApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _getPhoneFormats(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+'), '').trim();
    String withZero = clean;
    String withPlus = clean;
    if (clean.startsWith('+20')) {
      withZero = '0${clean.substring(3)}';
    } else if (clean.startsWith('0')) {
      withPlus = '+20${clean.substring(1)}';
    } else {
      withPlus = '+20$clean';
      withZero = '0$clean';
    }
    return [withZero, withPlus].toSet().toList();
  }

  Future<DashboardData> fetchDashboardData({required String parentPhoneNumber}) async {
    String studentNameForDashboard = "Student";
    try {
      final phoneFormats = _getPhoneFormats(parentPhoneNumber);

      // Step 1: Fetch all matching student docs (single collectionGroup query)
      final studentsSnapshot = await _firestore
          .collectionGroup('students')
          .where('parentPhoneNumber', whereIn: phoneFormats)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        return DashboardData(studentName: studentNameForDashboard, reportsByTeacher: []);
      }

      studentNameForDashboard = studentsSnapshot.docs.first.data()['name'] ?? 'Student';

      // Step 2: For each student, kick off ALL sub-collection fetches in parallel
      final today = DateTime.now();

      final List<Future<void>> studentFutures = [];
      final Map<String, TeacherReport> reportsMap = {};

      for (var studentDoc in studentsSnapshot.docs) {
        studentFutures.add(() async {
          final studentId = studentDoc.id;
          final studentName = studentDoc.data()['name'] ?? 'N/A';
          final pathSegments = studentDoc.reference.path.split('/');
          final teacherId = pathSegments[1];
          final groupId = pathSegments[3];
          final groupRef = _firestore
              .collection('teachers').doc(teacherId)
              .collection('groups').doc(groupId);

          // Step 2a: Kick off all 5 sub-collection fetches in parallel for this student
          final results = await Future.wait([
            _firestore.collection('teachers').doc(teacherId).get(),              // [0] teacher doc
            groupRef.collection('recurringSchedules').get(),                     // [1] schedules
            groupRef.collection('scheduleExceptions').get(),                     // [2] exceptions
            groupRef.collection('dailyAttendance').get(),                        // [3] attendance
            groupRef.collection('assignments').get(),                            // [4] assignments
            groupRef.collection('payments').get(),                               // [5] payments
          ]);

          final teacherDoc = results[0] as DocumentSnapshot;
          final recurringSchedulesSnap = results[1] as QuerySnapshot;
          final exceptionsSnap = results[2] as QuerySnapshot;
          final attendanceSnapshot = results[3] as QuerySnapshot;
          final assignmentsSnapshot = results[4] as QuerySnapshot;
          final paymentsSnapshot = results[5] as QuerySnapshot;

          // Ensure teacher entry exists (guarded for parallel safety)
          if (!reportsMap.containsKey(teacherId)) {
            reportsMap[teacherId] = TeacherReport(
              teacherId: teacherId,
              teacherName: (teacherDoc.data() as Map<String, dynamic>?)?['name'] ?? 'Unknown Teacher',
              subject: (teacherDoc.data() as Map<String, dynamic>?)?['subject'] ?? 'General',
              attendance: [],
              grades: [],
              schedule: [],
              payments: [],
            );
          }

          // --- Build schedule (local computation, no extra network) ---
          List<ScheduleEntry> finalScheduleList = [];
          for (int i = -3; i <= 3; i++) {
            final targetDate = today.add(Duration(days: i));
            final dateString = DateFormat('yyyy-MM-dd').format(targetDate);
            final int targetDayJs = targetDate.weekday % 7;
            List<ScheduleEntry> daySchedules = [];

            for (var doc in recurringSchedulesSnap.docs) {
              final scheduleData = doc.data() as Map<String, dynamic>;
              final days = List.from(scheduleData['days'] ?? []);
              if (days.isEmpty) continue;
              bool isClassOnDay = false;
              if (days.first is String) {
                final dayNameEn = DateFormat('EEEE', 'en_US').format(targetDate);
                final dayNameAr = DateFormat('EEEE', 'ar_SA').format(targetDate);
                if (days.contains(dayNameEn) || days.contains(dayNameAr)) isClassOnDay = true;
              } else if (days.first is int) {
                if (days.contains(targetDayJs)) isClassOnDay = true;
              }
              if (isClassOnDay) {
                daySchedules.add(ScheduleEntry.fromFirestore({...scheduleData, 'date': dateString}));
              }
            }

            for (var doc in exceptionsSnap.docs) {
              final exceptionData = doc.data() as Map<String, dynamic>;
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

          // --- Attendance ---
          for (var doc in attendanceSnapshot.docs) {
            final records = (doc.data() as Map<String, dynamic>)['records'] as List<dynamic>?;
            records?.forEach((record) {
              if (record['studentId'] == studentId) {
                reportsMap[teacherId]!.attendance.add(AttendanceRecord(
                  studentName: studentName,
                  date: (doc.data() as Map<String, dynamic>)['date'],
                  status: record['status'],
                ));
              }
            });
          }

          // --- Assignments / Grades ---
          for (var doc in assignmentsSnapshot.docs) {
            final assignmentData = doc.data() as Map<String, dynamic>;
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
              final totalMarkValue = assignmentData['totalMark'];
              int finalTotalMark = 30;
              if (totalMarkValue is num) {
                finalTotalMark = totalMarkValue.toInt();
              } else if (totalMarkValue is String && totalMarkValue.isNotEmpty) {
                finalTotalMark = int.tryParse(totalMarkValue) ?? 30;
              }
              reportsMap[teacherId]!.grades.add(GradeRecord(
                studentName: studentName,
                assignmentName: assignmentData['name'] ?? 'N/A',
                score: finalScore,
                date: assignmentData['date'] ?? 'N/A',
                submitted: studentScoreData['submitted'] as bool? ?? false,
                totalMark: finalTotalMark,
              ));
            }
          }

          // --- Payments ---
          for (var doc in paymentsSnapshot.docs) {
            final paymentData = doc.data() as Map<String, dynamic>;
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
              if (amountVal != null) amountStr = '$amountVal EGP';

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
        }());
      }

      // Step 3: Wait for ALL students to finish fetching in parallel
      await Future.wait(studentFutures);

      return DashboardData(
        studentName: studentNameForDashboard,
        reportsByTeacher: reportsMap.values.toList(),
      );

    } catch (e) {
      print('FATAL API Error in fetchDashboardData: $e');
      throw Exception('Failed to load dashboard data. A server error occurred.');
    }
  }

  Future<List<DashboardData>> fetchMultiDashboardData({required String parentPhoneNumber}) async {
    try {
      final phoneFormats = _getPhoneFormats(parentPhoneNumber);

      // Step 1: Fetch all matching student docs
      final studentsSnapshot = await _firestore
          .collectionGroup('students')
          .where('parentPhoneNumber', whereIn: phoneFormats)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        return [];
      }

      final today = DateTime.now();

      // Group docs by student name so siblings are separated, but a single student in multiple subjects is combined
      final Map<String, List<QueryDocumentSnapshot>> studentsByName = {};
      for (var doc in studentsSnapshot.docs) {
        final name = doc.data()['name']?.toString().trim() ?? 'Student';
        studentsByName.putIfAbsent(name, () => []).add(doc);
      }

      final List<Future<DashboardData>> studentFutures = [];

      for (var entry in studentsByName.entries) {
        final studentName = entry.key;
        final docs = entry.value;

        studentFutures.add(() async {
          final Map<String, TeacherReport> reportsMap = {};
          final List<Future<void>> docFutures = [];

          for (var studentDoc in docs) {
            docFutures.add(() async {
              final studentId = studentDoc.id;
              final pathSegments = studentDoc.reference.path.split('/');
              final teacherId = pathSegments[1];
              final groupId = pathSegments[3];
              final groupRef = _firestore
                  .collection('teachers').doc(teacherId)
                  .collection('groups').doc(groupId);

              // Fetch all 5 sub-collections in parallel for this student in this group
              final results = await Future.wait([
                _firestore.collection('teachers').doc(teacherId).get(),              // [0] teacher doc
                groupRef.collection('recurringSchedules').get(),                     // [1] schedules
                groupRef.collection('scheduleExceptions').get(),                     // [2] exceptions
                groupRef.collection('dailyAttendance').get(),                        // [3] attendance
                groupRef.collection('assignments').get(),                            // [4] assignments
                groupRef.collection('payments').get(),                               // [5] payments
              ]);

              final teacherDoc = results[0] as DocumentSnapshot;
              final recurringSchedulesSnap = results[1] as QuerySnapshot;
              final exceptionsSnap = results[2] as QuerySnapshot;
              final attendanceSnapshot = results[3] as QuerySnapshot;
              final assignmentsSnapshot = results[4] as QuerySnapshot;
              final paymentsSnapshot = results[5] as QuerySnapshot;

              if (!reportsMap.containsKey(teacherId)) {
                reportsMap[teacherId] = TeacherReport(
                  teacherId: teacherId,
                  teacherName: (teacherDoc.data() as Map<String, dynamic>?)?['name'] ?? 'Unknown Teacher',
                  subject: (teacherDoc.data() as Map<String, dynamic>?)?['subject'] ?? 'General',
                  attendance: [],
                  grades: [],
                  schedule: [],
                  payments: [],
                );
              }

              // Build schedule
              List<ScheduleEntry> finalScheduleList = [];
              for (int i = -3; i <= 3; i++) {
                final targetDate = today.add(Duration(days: i));
                final dateString = DateFormat('yyyy-MM-dd').format(targetDate);
                final int targetDayJs = targetDate.weekday % 7;
                List<ScheduleEntry> daySchedules = [];

                for (var doc in recurringSchedulesSnap.docs) {
                  final scheduleData = doc.data() as Map<String, dynamic>;
                  final days = List.from(scheduleData['days'] ?? []);
                  if (days.isEmpty) continue;
                  bool isClassOnDay = false;
                  if (days.first is String) {
                    final dayNameEn = DateFormat('EEEE', 'en_US').format(targetDate);
                    final dayNameAr = DateFormat('EEEE', 'ar_SA').format(targetDate);
                    if (days.contains(dayNameEn) || days.contains(dayNameAr)) isClassOnDay = true;
                  } else if (days.first is int) {
                    if (days.contains(targetDayJs)) isClassOnDay = true;
                  }
                  if (isClassOnDay) {
                    daySchedules.add(ScheduleEntry.fromFirestore({...scheduleData, 'date': dateString}));
                  }
                }

                for (var doc in exceptionsSnap.docs) {
                  final exceptionData = doc.data() as Map<String, dynamic>;
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

              // Attendance
              for (var doc in attendanceSnapshot.docs) {
                final records = (doc.data() as Map<String, dynamic>)['records'] as List<dynamic>?;
                records?.forEach((record) {
                  if (record['studentId'] == studentId) {
                    reportsMap[teacherId]!.attendance.add(AttendanceRecord(
                      studentName: studentName,
                      date: (doc.data() as Map<String, dynamic>)['date'],
                      status: record['status'],
                    ));
                  }
                });
              }

              // Assignments
              for (var doc in assignmentsSnapshot.docs) {
                final assignmentData = doc.data() as Map<String, dynamic>;
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
                  final totalMarkValue = assignmentData['totalMark'];
                  int finalTotalMark = 30;
                  if (totalMarkValue is num) {
                    finalTotalMark = totalMarkValue.toInt();
                  } else if (totalMarkValue is String && totalMarkValue.isNotEmpty) {
                    finalTotalMark = int.tryParse(totalMarkValue) ?? 30;
                  }
                  reportsMap[teacherId]!.grades.add(GradeRecord(
                    studentName: studentName,
                    assignmentName: assignmentData['name'] ?? 'N/A',
                    score: finalScore,
                    date: assignmentData['date'] ?? 'N/A',
                    submitted: studentScoreData['submitted'] as bool? ?? false,
                    totalMark: finalTotalMark,
                  ));
                }
              }

              // Payments
              for (var doc in paymentsSnapshot.docs) {
                final paymentData = doc.data() as Map<String, dynamic>;
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
                  if (amountVal != null) amountStr = '$amountVal EGP';

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
            }());
          }

          await Future.wait(docFutures);

          return DashboardData(
            studentName: studentName,
            reportsByTeacher: reportsMap.values.toList(),
          );
        }());
      }

      final List<DashboardData> studentsList = await Future.wait(studentFutures);
      return studentsList;
    } catch (e) {
      print('FATAL API Error in fetchMultiDashboardData: $e');
      throw Exception('Failed to load dashboard data. A server error occurred.');
    }
  }


  Future<List<NotificationItem>> fetchNotifications({required String parentPhoneNumber}) async {
    try {
      final phoneFormats = _getPhoneFormats(parentPhoneNumber);
      final studentsSnapshot = await _firestore
          .collectionGroup('students')
          .where('parentPhoneNumber', whereIn: phoneFormats)
          .get();

      // Fetch all students' notification histories in parallel
      final nestedResults = await Future.wait(
        studentsSnapshot.docs.map((studentDoc) =>
          studentDoc.reference
              .collection('notificationHistory')
              .orderBy('sentAt', descending: true)
              .get()
        ),
      );

      List<NotificationItem> allNotifications = [];
      for (var notificationsSnap in nestedResults) {
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

      allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allNotifications;
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }
}