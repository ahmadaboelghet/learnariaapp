//
   // ملف: lib/services/firestore_api.dart
   // (النسخة النهائية: الدالة تجلب بيانات المستخدم بنفسها وتقوم بالربط)
   //

   import 'package:cloud_firestore/cloud_firestore.dart';
   import 'package:learnaria/models/dashboard_data.dart'; // تأكد من المسار
   import 'package:intl/intl.dart';
   import 'package:firebase_auth/firebase_auth.dart';

   class FirestoreApi {
     final FirebaseFirestore _firestore = FirebaseFirestore.instance;

     // الدالة تجلب بيانات ولي الأمر بنفسها
     Future<DashboardData> fetchDashboardData() async {
       String studentNameForDashboard = "Student"; // قيمة افتراضية
       try {
         // 1. جلب بيانات ولي الأمر المسجل حالياً
         final User? currentUser = FirebaseAuth.instance.currentUser;

         // إذا لم يكن المستخدم مسجلاً أو لا يملك رقم هاتف، أرجع بيانات فارغة
         // تحقق أيضاً أن رقم الهاتف ليس فارغاً
         if (currentUser == null || currentUser.phoneNumber == null || currentUser.phoneNumber!.isEmpty) {
           print('FirestoreAPI (خطأ ❌): لا يمكن جلب البيانات. المستخدم null أو لا يملك رقم هاتف.');
           // أرجع بيانات فارغة بدلاً من رمي خطأ لتجنب تعطل الواجهة
           return DashboardData(studentName: studentNameForDashboard, reportsByTeacher: []);
         }

         final String parentUid = currentUser.uid;
         final String parentPhoneNumber = currentUser.phoneNumber!;

         print('FirestoreAPI (DEBUG): جاري البحث عن طالب برقم هاتف ولي الأمر: $parentPhoneNumber (UID: $parentUid)');

         // 2. البحث عن الطالب (أو الطلاب) باستخدام رقم هاتف ولي الأمر
         final studentsSnapshot = await _firestore
             .collectionGroup('students')
             .where('parentPhoneNumber', isEqualTo: parentPhoneNumber)
             // يمكنك إضافة .limit(1) إذا كنت متأكداً أن لكل ولي أمر طالب واحد فقط
             .get();

         if (studentsSnapshot.docs.isEmpty) {
           print('FirestoreAPI (DEBUG): لم يتم العثور على طالب برقم الهاتف: $parentPhoneNumber.');
           return DashboardData(studentName: studentNameForDashboard, reportsByTeacher: []);
         }

         print('FirestoreAPI (DEBUG): تم العثور على ${studentsSnapshot.docs.length} طالب مرتبط بالرقم: $parentPhoneNumber.');
         // استخدام اسم أول طالب تم العثور عليه كاسم رئيسي
         studentNameForDashboard = studentsSnapshot.docs.first.data()['name'] ?? studentNameForDashboard;
         Map<String, TeacherReport> reportsMap = {};

         // 3. المرور على كل طالب مرتبط بهذا الرقم وإنشاء حلقة الوصل وتجميع التقارير
         for (var studentDoc in studentsSnapshot.docs) {
            final studentId = studentDoc.id;
            // تأكد من أن studentId ليس فارغاً
            if(studentId == null || studentId.isEmpty) {
                print('FirestoreAPI (خطأ ❌): تم العثور على مستند طالب بدون ID.');
                continue; // تخطى هذا المستند
            }
            print('FirestoreAPI (DEBUG): معالجة الطالب ID: $studentId');

           // --- !! ربط الطالب بولي الأمر (حلقة الوصل) !! ---
           try {
             // قراءة البيانات الحالية مرة واحدة
             final studentDataMap = studentDoc.data();
             final currentData = studentDataMap as Map<String, dynamic>?; // Cast آمن

             // التحقق إذا كان الحقل موجوداً بالفعل وبنفس القيمة لتجنب الكتابة غير الضرورية
             if (currentData == null || currentData['parentUserId'] != parentUid) {
                print('FirestoreAPI (محاولة الربط): جاري ربط UID ${parentUid} بالطالب ${studentId}');
                await studentDoc.reference.set(
                  {'parentUserId': parentUid},
                  SetOptions(merge: true), // استخدم merge لتجنب مسح الحقول الأخرى
                );
                print('FirestoreAPI (نجاح ✅): تم ربط الطالب ${studentId} بولي الأمر ${parentUid}.');
             } else {
                 // print('FirestoreAPI (معلومة): الطالب ${studentId} مربوط بالفعل بولي الأمر ${parentUid}.');
             }
           } catch (e) {
             // سجل الخطأ ولكن استمر في معالجة الطلاب الآخرين
             print('FirestoreAPI (خطأ ❌): فشل ربط الطالب ${studentId}. خطأ: $e');
             // لا تتوقف هنا، أكمل لباقي الطلاب والتقارير
           }
           // --- !! نهاية الربط !! ---

           // --- (كود جلب التقارير للطالب الحالي) ---
           // تأكد من أن studentDoc.data() ليس null قبل استخدامه
           final studentData = studentDoc.data() as Map<String, dynamic>?;
           if (studentData == null) {
              print('FirestoreAPI (خطأ ❌): بيانات الطالب ${studentId} هي null.');
              continue;
           }

           final studentName = studentData['name'] ?? 'N/A';
           final pathSegments = studentDoc.reference.path.split('/');
           // التحقق من طول المسار قبل الوصول للعناصر
           if (pathSegments.length < 4) {
              print('FirestoreAPI (خطأ ❌): مسار الطالب غير متوقع: ${studentDoc.reference.path} للطالب ${studentId}');
              continue; // انتقل للطالب التالي
           }
           final teacherId = pathSegments[1];
           final groupId = pathSegments[3];

           // التأكد من أن teacherId و groupId ليسا فارغين
           if (teacherId.isEmpty || groupId.isEmpty) {
               print('FirestoreAPI (خطأ ❌): TeacherId أو GroupId فارغ في المسار: ${studentDoc.reference.path}');
               continue;
           }

            print('FirestoreAPI (DEBUG): جلب تقارير الطالب ${studentId} من المعلم ${teacherId} والمجموعة ${groupId}');

           // جلب بيانات المعلم إذا لم تكن موجودة في reportsMap
           if (!reportsMap.containsKey(teacherId)) {
             try {
               final teacherDoc = await _firestore.collection('teachers').doc(teacherId).get();
               // التأكد من أن بيانات المعلم ليست null
               final teacherData = teacherDoc.data() as Map<String, dynamic>?;
               reportsMap[teacherId] = TeacherReport(
                 teacherId: teacherId,
                 teacherName: teacherData?['name'] ?? 'Unknown Teacher',
                 subject: teacherData?['subject'] ?? 'General',
                 attendance: [],
                 grades: [],
                 schedule: [],
               );
             } catch (e) {
                print('FirestoreAPI (خطأ ❌): فشل جلب بيانات المعلم ${teacherId}: $e');
                reportsMap[teacherId] = TeacherReport(
                   teacherId: teacherId, teacherName: 'Unknown Teacher', subject: 'General',
                   attendance: [], grades: [], schedule: []
                 );
             }
           }

            // جلب الجدول الزمني + الحضور + الدرجات (داخل try-catch لكل عملية)
            // --- الجدول الزمني ---
            try {
                final recurringSchedulesSnap = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('recurringSchedules').get();
                final exceptionsSnap = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('scheduleExceptions').get();
                final today = DateTime.now();
                final todayString = DateFormat('yyyy-MM-dd').format(today);
                final int currentDayDart = today.weekday; // الاثنين = 1 ... الأحد = 7

                List<ScheduleEntry> finalScheduleForToday = [];

                for (var doc in recurringSchedulesSnap.docs) {
                    final scheduleDataMap = doc.data();
                    final scheduleData = scheduleDataMap as Map<String, dynamic>?;
                    if (scheduleData == null) continue;

                    final daysRaw = scheduleData['days'];
                    if (daysRaw is! List || daysRaw.isEmpty) continue;
                    final days = List.from(daysRaw);

                    bool isClassToday = false;
                    if (days.first is String) {
                        final currentDayNameEn = DateFormat('EEEE', 'en_US').format(today).toLowerCase();
                        final currentDayNameAr = DateFormat('EEEE', 'ar_SA').format(today).toLowerCase();
                        final daysLower = days.map((d) => d.toString().toLowerCase()).toList();
                        if (daysLower.contains(currentDayNameEn) || daysLower.contains(currentDayNameAr)) {
                          isClassToday = true;
                        }
                    } else if (days.first is int) {
                        if (days.contains(currentDayDart)) {
                          isClassToday = true;
                        }
                    }

                    if (isClassToday) {
                        // تأكد من وجود time قبل إضافته
                        if (scheduleData['time'] is String) {
                           finalScheduleForToday.add(ScheduleEntry.fromFirestore({...scheduleData, 'date': todayString}));
                        } else {
                           print('FirestoreAPI (تحذير ⚠️): بيانات الجدول ${doc.id} لا تحتوي على حقل time صحيح.');
                        }
                    }
                }
                 // تطبيق الاستثناءات
                for (var doc in exceptionsSnap.docs) {
                  final exceptionDataMap = doc.data();
                  final exceptionData = exceptionDataMap as Map<String, dynamic>?;
                  if (exceptionData == null) continue;

                  if (exceptionData['date'] == todayString) {
                    final status = exceptionData['status'];
                    if (status == 'cancelled') {
                        finalScheduleForToday.clear();
                        break; // لا داعي لإكمال باقي الاستثناءات إذا تم الإلغاء
                    } else if (status == 'rescheduled' && finalScheduleForToday.isNotEmpty) {
                      final newTime = exceptionData['newTime'];
                      if (newTime is String) {
                         finalScheduleForToday[0] = finalScheduleForToday[0].copyWith(time: newTime);
                      }
                    }
                  }
                }
                // إضافة الجدول النهائي (قد يكون فارغاً) إلى تقرير المعلم
                 reportsMap[teacherId]?.schedule.addAll(finalScheduleForToday);

             } catch (e, st) { print('FirestoreAPI (خطأ ❌): فشل جلب الجدول الزمني للمعلم ${teacherId}: $e \n $st'); }

            // --- الحضور ---
            try {
                final attendanceSnapshot = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('dailyAttendance').get();
                for (var doc in attendanceSnapshot.docs) {
                   final attendanceData = doc.data();
                   final recordsRaw = attendanceData['records'];
                   final date = attendanceData['date'] ?? 'N/A'; // تاريخ افتراضي

                   if (recordsRaw is List) {
                      final records = List<Map<String, dynamic>>.from(recordsRaw.whereType<Map<String, dynamic>>());
                      records.forEach((record) {
                        if (record['studentId'] == studentId) {
                           // إضافة سجل الحضور لتقرير المعلم
                           reportsMap[teacherId]?.attendance.add(AttendanceRecord(
                            studentName: studentName,
                            date: date,
                            status: record['status'] ?? 'unknown',
                          ));
                        }
                      });
                   }
                }
            } catch (e, st) { print('FirestoreAPI (خطأ ❌): فشل جلب الحضور للمعلم ${teacherId}: $e \n $st'); }

            // --- الدرجات ---
             try {
                final assignmentsSnapshot = await _firestore.collection('teachers').doc(teacherId).collection('groups').doc(groupId).collection('assignments').get();
                for (var doc in assignmentsSnapshot.docs) {
                  final assignmentData = doc.data();
                  final assignmentName = assignmentData['name'] ?? 'N/A';
                  final assignmentDate = assignmentData['date'] ?? 'N/A';
                  final scoresMapRaw = assignmentData['scores'];

                  if (scoresMapRaw is Map<String, dynamic>) {
                      final scoresMap = Map<String, dynamic>.from(scoresMapRaw);
                      final studentScoreDataRaw = scoresMap[studentId];

                      if (studentScoreDataRaw is Map<String, dynamic>) {
                          final studentScoreData = Map<String, dynamic>.from(studentScoreDataRaw);
                          final scoreValue = studentScoreData['score'];
                          int? finalScore;
                          if (scoreValue is num) finalScore = scoreValue.toInt();
                          else if (scoreValue is String && scoreValue.isNotEmpty) finalScore = int.tryParse(scoreValue);

                          // إضافة سجل الدرجة لتقرير المعلم
                          reportsMap[teacherId]?.grades.add(GradeRecord(
                              studentName: studentName,
                              assignmentName: assignmentName,
                              score: finalScore,
                              date: assignmentDate,
                              submitted: studentScoreData['submitted'] as bool? ?? false,
                          ));
                      }
                  }
                }
             } catch (e, st) { print('FirestoreAPI (خطأ ❌): فشل جلب الدرجات للمعلم ${teacherId}: $e \n $st'); }

           // --- نهاية كود جلب التقارير ---

         } // نهاية الـ for loop الخاص بالطلاب

         print('FirestoreAPI (DEBUG): اكتمل جلب البيانات لـ ${reportsMap.length} معلم.');
         // إرجاع البيانات المجمعة
         return DashboardData(
           studentName: studentNameForDashboard,
           reportsByTeacher: reportsMap.values.toList(),
         );

       } catch (e, stackTrace) { // التعامل مع الأخطاء العامة في الدالة
         print('FATAL API Error in fetchDashboardData: $e');
         print('Stack trace: $stackTrace');
         // أرجع بيانات فارغة لتجنب تعطل الواجهة
         return DashboardData(studentName: studentNameForDashboard, reportsByTeacher: []);
       }
     }
   }