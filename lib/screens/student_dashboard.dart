// //
//    // ملف: lib/screens/student_dashboard.dart
//    // (النسخة النهائية: StatefulWidget تستدعي الـ API الصحيح وتعرض البيانات)
//    //

//    import 'package:flutter/material.dart';
//    import 'package:learnaria/models/dashboard_data.dart'; // تأكد من المسار
//    import 'package:learnaria/services/firestore_api.dart';
//    import 'package:intl/intl.dart'; // لجلب التاريخ
//    // يمكنك إضافة imports أخرى تحتاجها هنا (مثل Provider)

//    class StudentDashboard extends StatefulWidget {
//      const StudentDashboard({super.key});

//      @override
//      State<StudentDashboard> createState() => _StudentDashboardState();
//    }

//    class _StudentDashboardState extends State<StudentDashboard> {

//      late Future<DashboardData> _dashboardDataFuture;
//      final FirestoreApi _api = FirestoreApi();

//      @override
//      void initState() {
//        super.initState();
//        // استدعاء الدالة لجلب البيانات عند فتح الشاشة لأول مرة
//        _loadDashboardData();
//      }

//      // دالة منفصلة لجلب البيانات لتسهيل عملية التحديث
//      void _loadDashboardData() {
//         print("StudentDashboard (DEBUG): جاري استدعاء fetchDashboardData...");
//         setState(() { // تحديث الواجهة لتعرض مؤشر التحميل عند التحديث
//             _dashboardDataFuture = _api.fetchDashboardData();
//         });
//      }

//      @override
//      Widget build(BuildContext context) {
//        // يمكنك الوصول للـ Theme هنا
//        // final theme = Theme.of(context);

//        return Scaffold(
//          backgroundColor: Colors.grey[100], // لون خلفية أفتح قليلاً
//          appBar: AppBar(
//            backgroundColor: Colors.white, // AppBar أبيض
//            surfaceTintColor: Colors.transparent, // منع تغيير اللون عند السحب للأسفل
//            leading: Padding(
//              padding: const EdgeInsets.all(10.0), // زيادة الـ padding
//              child: Image.asset('assets/images/logo.png'), // تأكد من المسار
//            ),
//            title: const Text(
//                 "Learnaria", // إضافة عنوان للـ AppBar
//                 style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)
//             ),
//            centerTitle: false, // محاذاة لليسار/اليمين
//            actions: [
//              IconButton(
//                icon: Icon(Icons.settings_outlined, color: Colors.grey[700]), // أيقونة الإعدادات
//                onPressed: () {
//                  Navigator.pushNamed(context, '/settings'); // افترض وجود صفحة إعدادات
//                },
//              ),
//            ],
//            elevation: 1, // ظل خفيف جداً
//          ),
//          body: FutureBuilder<DashboardData>(
//            future: _dashboardDataFuture,
//            builder: (context, snapshot) {

//              // --- حالة التحميل ---
//              if (snapshot.connectionState == ConnectionState.waiting) {
//                print("StudentDashboard (DEBUG): جاري التحميل... (Waiting for Future)");
//                return const Center(child: CircularProgressIndicator());
//              }

//              // --- حالة الخطأ ---
//              if (snapshot.hasError || snapshot.data == null) { // التعامل مع null data كخطأ أيضاً
//                print("StudentDashboard (خطأ ❌): حدث خطأ أثناء جلب البيانات: ${snapshot.error}");
//                return _buildErrorWidget(snapshot.error); // واجهة منفصلة للخطأ
//              }

//              // --- حالة النجاح ولكن لا توجد بيانات (لم يتم العثور على طالب) ---
//              final dashboardData = snapshot.data!;
//              if (dashboardData.reportsByTeacher.isEmpty) {
//                print("StudentDashboard (تحذير ⚠️): نجح الجلب ولكن لا توجد بيانات طالب.");
//                return _buildEmptyStateWidget(); // واجهة منفصلة للحالة الفارغة
//              }

//              // --- حالة النجاح وتوجد بيانات ---
//              print("StudentDashboard (نجاح ✅): تم جلب البيانات بنجاح.");
//              final studentName = dashboardData.studentName;
//              final reports = dashboardData.reportsByTeacher;

//              // حساب الإحصائيات (يمكن نقل هذا لمنطق منفصل لاحقاً)
//              int totalAssignments = 0;
//              int submittedAssignments = 0;
//              int presentDays = 0;
//              int absentDays = 0;
//              reports.forEach((report) {
//                totalAssignments += report.grades.length;
//                submittedAssignments += report.grades.where((g) => g.submitted).length;
//                presentDays += report.attendance.where((a) => a.status == 'present').length;
//                absentDays += report.attendance.where((a) => a.status == 'absent').length;
//              });
//              int totalAttendanceDays = presentDays + absentDays;
//              double attendancePercentage = totalAttendanceDays == 0 ? 100 : (presentDays / totalAttendanceDays) * 100; // اعتبر 100% إذا لا يوجد سجلات


//              return RefreshIndicator(
//                 onRefresh: () async => _loadDashboardData(), // استدعاء دالة التحديث
//                 child: ListView( // استخدام ListView بدلاً من SingleChildScrollView للسماح بالسحب للتحديث دائماً
//                  physics: const AlwaysScrollableScrollPhysics(),
//                  children: [
//                    Padding(
//                      padding: const EdgeInsets.all(16.0),
//                      child: Column(
//                        crossAxisAlignment: CrossAxisAlignment.start,
//                        children: [
//                          _buildUserInfo(studentName),
//                          const SizedBox(height: 24),
//                          _buildSectionHeader('Reports'),
//                          const SizedBox(height: 12),
//                          _buildReportsSection(
//                            assignmentsCount: submittedAssignments,
//                            totalAssignments: totalAssignments,
//                            attendancePercentage: attendancePercentage,
//                            totalAttendanceDays: totalAttendanceDays,
//                          ),
//                          const SizedBox(height: 24),
//                          _buildSectionHeader('Today\'s Courses'),
//                          const SizedBox(height: 12),
//                          _buildTodaysCourses(reports),
//                          const SizedBox(height: 24),
//                          _buildSectionHeader('Teachers'),
//                          const SizedBox(height: 12),
//                          _buildTeachersSection(reports),
//                          const SizedBox(height: 24), // مسافة إضافية في الأسفل
//                        ],
//                      ),
//                    ),
//                  ],
//                ),
//              );
//            },
//          ),
//          // يمكنك إزالة الـ BottomNavigationBar إذا كنت تستخدم MainLayout
//           bottomNavigationBar: _buildBottomNavigationBar(),
//        );
//      }

//     // --- Widgets ---

//      // واجهة عرض الخطأ مع زر إعادة المحاولة
//      Widget _buildErrorWidget(Object? error) {
//        return Center(
//          child: Padding(
//            padding: const EdgeInsets.all(20.0),
//            child: Column(
//              mainAxisAlignment: MainAxisAlignment.center,
//              children: [
//                Icon(Icons.error_outline, color: Colors.red[700], size: 60),
//                const SizedBox(height: 16),
//                Text(
//                  'عذراً، حدث خطأ أثناء تحميل البيانات.',
//                  textAlign: TextAlign.center,
//                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                ),
//                const SizedBox(height: 8),
//                Text(
//                  error.toString(), // عرض تفاصيل الخطأ للمساعدة في الـ debugging
//                  textAlign: TextAlign.center,
//                  style: TextStyle(color: Colors.grey[600]),
//                ),
//                const SizedBox(height: 24),
//                ElevatedButton.icon(
//                  icon: const Icon(Icons.refresh),
//                  label: const Text('إعادة المحاولة'),
//                  onPressed: _loadDashboardData, // استدعاء دالة التحديث
//                  style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.amber[700],
//                     foregroundColor: Colors.black87,
//                  ),
//                )
//              ],
//            ),
//          ),
//        );
//      }

//      // واجهة عرض الحالة الفارغة
//      Widget _buildEmptyStateWidget() {
//         return Center(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.sentiment_dissatisfied_outlined, color: Colors.grey[500], size: 60),
//                   const SizedBox(height: 16),
//                   const Text(
//                     'لم يتم العثور على بيانات طالب مرتبط بهذا الحساب.',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                   ),
//                    const SizedBox(height: 8),
//                    Text(
//                      'تأكد من أن المعلم قام بإضافتك باستخدام رقم الهاتف الصحيح.',
//                      textAlign: TextAlign.center,
//                      style: TextStyle(color: Colors.grey[600]),
//                    ),
//                    const SizedBox(height: 24),
//                    ElevatedButton.icon(
//                      icon: const Icon(Icons.refresh),
//                      label: const Text('تحديث'),
//                      onPressed: _loadDashboardData,
//                      style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.amber[700],
//                         foregroundColor: Colors.black87,
//                      ),
//                     )
//                 ],
//             ),
//           ),
//         );
//      }


//      Widget _buildUserInfo(String studentName) {
//        final String todayDate = DateFormat('EEEE, d MMMM', 'ar').format(DateTime.now());

//        return Row(
//          mainAxisAlignment: MainAxisAlignment.spaceBetween,
//          crossAxisAlignment: CrossAxisAlignment.center, // محاذاة رأسية أفضل
//          children: [
//            Flexible(
//              child: Row(
//                children: [
//                  // يمكنك استبدالها بصورة ولي الأمر إذا كانت متاحة
//                  const CircleAvatar(radius: 28, backgroundColor: Colors.amber, child: Icon(Icons.person, color: Colors.white, size: 30)),
//                  const SizedBox(width: 12),
//                  Flexible(
//                    child: Column(
//                      crossAxisAlignment: CrossAxisAlignment.start,
//                      children: [
//                        Text(
//                          // عرض اسم الطالب بدلاً من اسم ولي الأمر هنا قد يكون أوضح
//                          'متابعة الطالب: $studentName',
//                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
//                          overflow: TextOverflow.ellipsis,
//                        ),
//                        const SizedBox(height: 2), // تقليل المسافة
//                        Text(
//                          todayDate,
//                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//                        ),
//                      ],
//                    ),
//                  ),
//                ],
//              ),
//            ),
//            // زر الإشعارات (يفضل أن يكون له خلفية مميزة إذا كان هناك إشعارات جديدة)
//            InkWell(
//                 onTap: () {
//                     // TODO: Navigate to Notifications Screen
//                     print("زر الإشعارات تم الضغط عليه");
//                 },
//                 borderRadius: BorderRadius.circular(25),
//                 child: Container(
//                   padding: const EdgeInsets.all(10), // تكبير قليلًا
//                   decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey[300]!)),
//                   child: Icon(Icons.notifications_none, color: Colors.grey[800]),
//                 ),
//             ),
//          ],
//        );
//      }

//      Widget _buildSectionHeader(String title) {
//         return Padding(
//           padding: const EdgeInsets.only(bottom: 4.0), // إضافة مسافة سفلية فقط
//           child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
//         );
//       }

//     Widget _buildReportsSection({ required int assignmentsCount, required int totalAssignments, required double attendancePercentage, required int totalAttendanceDays }) {
//       String assignmentStatusText = totalAssignments > 0
//           ? (assignmentsCount == totalAssignments ? 'مكتمل' : '$assignmentsCount مُسلّم')
//           : 'لا يوجد واجبات';
//       Color assignmentColor = (totalAssignments > 0 && assignmentsCount < totalAssignments) ? Colors.orange : Colors.teal; // تغيير اللون

//       String attendanceStatusText = attendancePercentage >= 85 ? 'جيد جداً' : (attendancePercentage >= 65 ? 'مقبول' : 'ضعيف');
//       Color attendanceColor = attendancePercentage >= 85 ? Colors.teal : (attendancePercentage >= 65 ? Colors.orange : Colors.redAccent);

//       return Row(
//         children: [
//           Expanded(child: _buildReportCard(
//               title: 'الواجبات',
//               count: totalAssignments > 0 ? '$assignmentsCount/$totalAssignments' : '-',
//               status: assignmentStatusText,
//               subjects: '',
//               statusColor: assignmentColor,
//               iconColor: assignmentColor,
//               icon: Icons.assignment_turned_in_outlined, // أيقونة مناسبة
//               onTap: () {
//                 // TODO: Navigate to assignments details screen
//                  print("الضغط على بطاقة الواجبات");
//               }
//               )),
//           const SizedBox(width: 16),
//           Expanded(child: _buildReportCard(
//               title: 'الحضور',
//               count: '${attendancePercentage.toStringAsFixed(0)}%',
//               status: attendanceStatusText,
//               subjects: '$totalAttendanceDays يوم',
//               statusColor: attendanceColor,
//               iconColor: attendanceColor,
//               icon: Icons.event_available_outlined, // أيقونة مناسبة
//               onTap: () {
//                 // TODO: Navigate to attendance details screen
//                 print("الضغط على بطاقة الحضور");
//               }
//               )),
//         ],
//       );
//     }

//     Widget _buildReportCard({ required String title, required String count, required String status, required String subjects, required Color statusColor, required Color iconColor, required IconData icon, VoidCallback? onTap }) {
//        return Material( // استخدام Material لـ InkWell ripple effect
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(15),
//           elevation: 1.5, // تقليل الـ elevation
//           shadowColor: Colors.grey.withOpacity(0.2),
//           child: InkWell(
//             onTap: onTap,
//             borderRadius: BorderRadius.circular(15),
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                     Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                             Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)), // خط أغمق
//                             Icon(icon, color: iconColor, size: 20), // إضافة أيقونة
//                         ],
//                     ),
//                   const SizedBox(height: 15), // زيادة المسافة
//                   Text(count, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: statusColor)),
//                   const SizedBox(height: 4),
//                   Text(status, style: TextStyle(fontSize: 12, color: statusColor.withOpacity(0.9), fontWeight: FontWeight.w500)),
//                    if (subjects.isNotEmpty) ...[
//                        const SizedBox(height: 8),
//                        Text(subjects, style: const TextStyle(fontSize: 11, color: Colors.grey)),
//                     ],

//                 ],
//               ),
//             ),
//           ),
//         );
//      }

//     // بناء قسم جدول اليوم
//     Widget _buildTodaysCourses(List<TeacherReport> reports) {
//       List<ScheduleEntry> todaysSchedule = [];
//       reports.forEach((report) {
//          // التأكد من أن schedule ليس null قبل إضافته
//          if (report.schedule != null) {
//             todaysSchedule.addAll(report.schedule!);
//          }
//       });
//       // فرز الجدول حسب الوقت (افترض أن الوقت بصيغة HH:mm)
//       try {
//           todaysSchedule.sort((a, b) => a.time.compareTo(b.time));
//       } catch (e) {
//           print("Error sorting schedule: $e"); // معالجة خطأ المقارنة إذا كان الوقت غير صالح
//       }


//       if (todaysSchedule.isEmpty) {
//         return Container(
//            height: 100, // ارتفاع ثابت حتى لو فارغ
//            padding: const EdgeInsets.symmetric(vertical: 20),
//            alignment: Alignment.center,
//            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
//            child: Text("لا توجد حصص مجدولة لهذا اليوم.", style: TextStyle(color: Colors.grey[600])),
//         );
//       }

//        return SizedBox(
//           height: 110, // تقليل الارتفاع قليلاً
//           child: ListView.separated(
//             clipBehavior: Clip.none, // السماح للظل بالظهور خارج الحدود
//             scrollDirection: Axis.horizontal,
//             itemCount: todaysSchedule.length,
//             separatorBuilder: (context, index) => const SizedBox(width: 12), // تقليل الفاصل
//             itemBuilder: (context, index) {
//                final entry = todaysSchedule[index];
//                final teacherReport = reports.firstWhere((r) => r.schedule?.contains(entry) ?? false, orElse: () => reports.first);
//                final subject = teacherReport.subject ?? 'مادة'; // قيمة افتراضية
//                // تحديد الحالة
//                TimeOfDay startTime = TimeOfDay(hour: 12, minute: 0); // قيمة افتراضية
//                 try {
//                    startTime = TimeOfDay(hour: int.parse(entry.time.split(':')[0]), minute: int.parse(entry.time.split(':')[1]));
//                 } catch(e) { print("Error parsing time: ${entry.time}"); }

//                final now = TimeOfDay.now();
//                // تقدير وقت الانتهاء (افترض مدة 90 دقيقة)
//                final endTime = startTime.replacing(hour: (startTime.hour + 1) % 24, minute: (startTime.minute + 30) % 60); // منطق مبسط جداً
//                String status = 'Upcoming';
//                Color statusColor = Colors.blueAccent;
//                Color borderColor = Colors.blueAccent.withOpacity(0.5);

//                 double nowMinutes = now.hour * 60.0 + now.minute;
//                 double startMinutes = startTime.hour * 60.0 + startTime.minute;
//                 double endMinutes = endTime.hour * 60.0 + endTime.minute;
//                  // التعامل مع الحصص التي تنتهي في اليوم التالي (غير محتمل هنا)
//                  if (endMinutes < startMinutes) endMinutes += 24 * 60;

//                 if (nowMinutes >= startMinutes && nowMinutes < endMinutes) {
//                    status = 'Ongoing';
//                    statusColor = Colors.green;
//                    borderColor = Colors.green.withOpacity(0.5);
//                 } else if (nowMinutes >= endMinutes) {
//                    status = 'Finished';
//                    statusColor = Colors.grey;
//                    borderColor = Colors.grey.withOpacity(0.3);
//                 }


//                return _buildCourseCard(
//                     title: subject,
//                     time: entry.time,
//                     status: status,
//                     borderColor: borderColor,
//                     statusColor: statusColor,
//                     onTap: () { print("Pressed course: $subject at ${entry.time}"); }
//                 );
//             },
//           ),
//         );
//      }

//     Widget _buildCourseCard({ required String title, required String time, required String status, required Color borderColor, required Color statusColor, VoidCallback? onTap}) {
//        return Material( // استخدام Material لـ InkWell ripple effect
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(15),
//           elevation: 1,
//           shadowColor: Colors.grey.withOpacity(0.15),
//           child: InkWell(
//             onTap: onTap,
//             borderRadius: BorderRadius.circular(15),
//             child: Container(
//               width: 150, // تقليل العرض قليلاً
//               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), // تعديل الـ padding
//               decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(15),
//                   border: Border.all(color: borderColor, width: 1), // تقليل سمك الحدود
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: CrossAxisAlignment.start, // لمحاذاة الحالة للأعلى
//                     children: [
//                       Flexible(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis)),
//                       Container( // خلفية للحالة
//                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                         decoration: BoxDecoration(
//                             color: statusColor.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min, // لجعل الـ Row يأخذ أقل مساحة
//                           children: [
//                             Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
//                             const SizedBox(width: 4),
//                             Text(status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w500)),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   Text(time, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
//                 ],
//               ),
//             ),
//           ),
//         );
//      }

//     // بناء قسم المعلمين
//     Widget _buildTeachersSection(List<TeacherReport> reports) {
//        if (reports.isEmpty) {
//          return Container();
//        }
//        return SizedBox(
//           height: 180, // تعديل الارتفاع
//           child: ListView.separated(
//             clipBehavior: Clip.none,
//             scrollDirection: Axis.horizontal,
//             itemCount: reports.length,
//             separatorBuilder: (context, index) => const SizedBox(width: 12),
//             itemBuilder: (context, index) {
//                final report = reports[index];
//                return _buildTeacherCard(
//                    name: report.teacherName,
//                    subject: report.subject,
//                    // imageUrl: report.teacherImageUrl ?? 'https://avatar.iran.liara.run/public', // استخدام API للأفاتارات
//                    imageUrl: 'https://avatar.iran.liara.run/username?username=${report.teacherName.replaceAll(' ', '+')}', // بناء URL ديناميكي
//                    onTap: () { print("Pressed teacher: ${report.teacherName}"); }
//                );
//             },
//           ),
//         );
//      }

//     Widget _buildTeacherCard({ required String name, required String subject, required String imageUrl, VoidCallback? onTap }) {
//       return Material(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(15),
//           elevation: 1,
//           shadowColor: Colors.grey.withOpacity(0.15),
//           child: InkWell(
//             onTap: onTap,
//             borderRadius: BorderRadius.circular(15),
//             child: Container(
//               width: 130, // تقليل العرض
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   ClipRRect(
//                     borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
//                     child: Image.network(
//                       imageUrl, height: 90, // تقليل ارتفاع الصورة
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) => Container(height: 90, color: Colors.grey[200], child: const Icon(Icons.person, color: Colors.grey, size: 40)),
//                       loadingBuilder: (context, child, loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return Container(height: 90, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
//                       },
//                     ),
//                   ),
//                   Expanded( // لجعل الـ Padding يأخذ باقي المساحة
//                       child: Padding(
//                       padding: const EdgeInsets.all(10.0), // زيادة الـ padding قليلاً
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween, // لتوزيع العناصر
//                         children: [
//                           Column( // تجميع الاسم والمادة
//                              crossAxisAlignment: CrossAxisAlignment.start,
//                              children: [
//                                 Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis),
//                                 const SizedBox(height: 2),
//                                 Text(subject, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
//                              ],
//                           ),
//                           Align( // محاذاة أيقونة الشات للأسفل واليمين
//                             alignment: Alignment.bottomRight,
//                             child: Container(
//                               padding: const EdgeInsets.all(6),
//                               decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
//                               child: Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[800]),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//      }

//      // شريط التنقل السفلي
//      Widget _buildBottomNavigationBar() {
//        // TODO: ربط هذا بمزود حالة (State Provider) أو MainLayout للتحكم في الصفحة النشطة
//        int _currentIndex = 0; // مثال

//        return BottomNavigationBar(
//           type: BottomNavigationBarType.fixed, // يظهر كل العناوين دائماً
//           backgroundColor: Colors.white, // خلفية بيضاء
//           selectedItemColor: Colors.amber[800], // لون العنصر النشط
//           unselectedItemColor: Colors.grey[500], // لون العناصر غير النشطة
//           selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), // تصغير الخط
//           unselectedLabelStyle: const TextStyle(fontSize: 11),
//           elevation: 5, // ظل خفيف
//           items: const [
//             BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'الرئيسية'),
//             BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'التقدم'),
//             BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: 'الرسائل'),
//             BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'الملف الشخصي'),
//           ],
//           currentIndex: _currentIndex,
//           onTap: (index) {
//              // TODO: إضافة منطق التنقل بين الصفحات
//              print("Bottom Nav tapped: index $index");
//              // setState(() => _currentIndex = index); // تحديث الصفحة النشطة (إذا كان الـ state هنا)
//           },
//         );
//      }
//    }