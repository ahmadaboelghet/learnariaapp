import 'package:flutter/material.dart';
import 'package:learnaria/screens/notifications.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/screens/assignment_details.dart';
import 'package:learnaria/screens/attendance_details.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/services/firestore_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/widgets/glass_container.dart';
import 'package:learnaria/widgets/shimmer_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

enum CourseStatus { Upcoming, Ongoing, Finished }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DashboardData> _studentsData = [];
  int _currentStudentIndex = 0;
  bool _isLoading = true;
  String _errorMessage = '';
  DateTime _selectedDay = DateTime.now();
  DateTime _selectedPaymentMonth = DateTime.now();
  int _unreadNotificationsCount = 0;

  DashboardData? get _dashboardData =>
      _studentsData.isNotEmpty ? _studentsData[_currentStudentIndex] : null;

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final parentPhone = user?.email?.split('@').first;
      if (parentPhone == null || parentPhone.isEmpty) {
        throw Exception(
          'Could not determine your phone number from your email.',
        );
      }

      // Sync FCM Token to Firestore parents collection for push notification routing
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          List<String> getPhoneFormats(String phone) {
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

          final phoneFormats = getPhoneFormats(parentPhone);
          for (var phoneDocId in phoneFormats) {
            await FirebaseFirestore.instance
                .collection('parents')
                .doc(phoneDocId)
                .set({
                  'fcmToken': fcmToken,
                  'fcmTokens': FieldValue.arrayUnion([fcmToken]),
                }, SetOptions(merge: true));
          }
          debugPrint(
            'FCM Token successfully synced to parents collection for: $phoneFormats',
          );
        }
      } catch (fcmError) {
        debugPrint('Failed to sync FCM Token: $fcmError');
      }

      final data = await FirestoreApi().fetchMultiDashboardData(
        parentPhoneNumber: parentPhone,
      );

      // Fetch unread notifications count
      try {
        final notifications = await FirestoreApi().fetchNotifications(
          parentPhoneNumber: parentPhone,
        );
        final prefs = await SharedPreferences.getInstance();
        final readIds = prefs.getStringList('read_notification_ids') ?? [];
        final unread = notifications
            .where((item) => !readIds.contains(item.id))
            .length;

        // Update launcher icon badge count programmatically
        try {
          AppBadgePlus.updateBadge(unread);
        } catch (badgeErr) {
          debugPrint('Failed to update launcher badge count: $badgeErr');
        }

        if (mounted) {
          setState(() {
            _unreadNotificationsCount = unread;
          });
        }
      } catch (err) {
        debugPrint('Failed to load notifications unread count: $err');
      }

      if (mounted) {
        setState(() {
          _studentsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getCourseStatusDetails(
    ScheduleEntry entry,
    AppLocalizations appLocalizations,
  ) {
    final now = DateTime.now();
    try {
      final timeParts = entry.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final startTime = DateTime(now.year, now.month, now.day, hour, minute);
      final endTime = startTime.add(const Duration(hours: 2));

      if (now.isAfter(endTime)) {
        return {
          'status': appLocalizations.finished,
          'color': AppColors.mediumGrey,
          'statusEnum': CourseStatus.Finished,
        };
      } else if (now.isAfter(startTime) && now.isBefore(endTime)) {
        return {
          'status': appLocalizations.ongoing,
          'color': AppColors.greenSuccess,
          'statusEnum': CourseStatus.Ongoing,
        };
      } else {
        return {
          'status': appLocalizations.upcoming,
          'color': AppColors.primaryYello,
          'statusEnum': CourseStatus.Upcoming,
        };
      }
    } catch (e) {
      return {
        'status': appLocalizations.scheduled,
        'color': AppColors.mediumGrey,
        'statusEnum': CourseStatus.Upcoming,
      };
    }
  }

  // --- دالة لحساب الواجبات التي تم تسليمها ---
  int get submittedAssignmentsCount {
    if (_dashboardData == null) return 0;
    return _dashboardData!.reportsByTeacher
        .expand((report) => report.grades)
        .where((grade) => grade.submitted == true)
        .length;
  }

  // --- دالة لحساب الواجبات التي لم يتم تسليمها ---
  int get notSubmittedAssignmentsCount {
    if (_dashboardData == null) return 0;
    final totalAssignments = _dashboardData!.reportsByTeacher
        .expand((report) => report.grades)
        .length;
    return totalAssignments - submittedAssignmentsCount;
  }

  int get overallAttendancePercentage {
    if (_dashboardData == null) return 0;
    final all = _dashboardData!.reportsByTeacher
        .expand((r) => r.attendance)
        .toList();
    if (all.isEmpty) return 0;
    final present = all
        .where((a) => a.status.toLowerCase() == 'present')
        .length;
    return (present / all.length * 100).toInt();
  }

  int get totalAttendanceDays =>
      _dashboardData?.reportsByTeacher.expand((r) => r.attendance).length ?? 0;

  List<ScheduleEntry> get selectedDayScheduleEntries {
    if (_dashboardData == null) return [];
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDay);
    return _dashboardData!.reportsByTeacher
        .expand((report) => report.schedule)
        .where((entry) => entry.date == dateString)
        .toList();
  }

  List<DateTime> _generateWeekDays() {
    final today = DateTime.now();
    return List.generate(7, (index) => today.add(Duration(days: index - 3)));
  }

  Widget _buildCalendarStrip(Color textColor) {
    final weekDays = _generateWeekDays();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: weekDays.length,
        itemBuilder: (context, index) {
          final day = weekDays[index];
          final isSelected = DateUtils.isSameDay(day, _selectedDay);
          final isToday = DateUtils.isSameDay(day, DateTime.now());
          final dayName = DateFormat('E', locale).format(day);
          final dayNum = DateFormat('d').format(day);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = day;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryYello
                    : (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03)),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryYello
                      : (isDark
                            ? AppColors.glassBorderDark
                            : AppColors.glassBorderLight),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryYello.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white54 : Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayNum,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : textColor,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.white
                            : AppColors.primaryYello,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTo12Hour(String timeString) {
    try {
      final parts = timeString.split(' - ');
      String mainTime = parts[0];
      final timeParts = mainTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final tempDate = DateTime(2020, 1, 1, hour, minute);

      final formatted = DateFormat('h:mm a').format(tempDate);
      if (parts.length > 1) {
        return '$formatted - ${parts[1]}';
      }
      return formatted;
    } catch (e) {
      return timeString;
    }
  }

  late ScrollController _monthScrollController;

  @override
  void initState() {
    super.initState();
    _monthScrollController = ScrollController();
    _fetchData().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentMonth(animate: false);
      });
    });
  }

  @override
  void dispose() {
    _monthScrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentMonth({bool animate = true}) {
    if (!_monthScrollController.hasClients) return;
    final months = _generateMonths();
    int targetIndex = months.indexWhere(
      (m) =>
          m.month == _selectedPaymentMonth.month &&
          m.year == _selectedPaymentMonth.year,
    );
    if (targetIndex != -1) {
      const double itemWidth =
          110.0; // Dynamic width estimate for 'MMM yyyy' layout
      final double screenWidth = MediaQuery.of(context).size.width;
      final double offset =
          (targetIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      final double maxScroll = _monthScrollController.position.maxScrollExtent;
      final double finalOffset = offset.clamp(0.0, maxScroll);
      if (animate) {
        _monthScrollController.animateTo(
          finalOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _monthScrollController.jumpTo(finalOffset);
      }
    }
  }

  List<DateTime> _generateMonths() {
    final now = DateTime.now();
    // Return last 6 months, current month, and next 5 months (total 12 months)
    return List.generate(
      12,
      (index) => DateTime(now.year, now.month - 6 + index),
    );
  }

  List<Map<String, dynamic>> _getGroupPaymentsForMonth(DateTime date) {
    if (_dashboardData == null) return [];

    final monthStr = DateFormat('yyyy-MM').format(date);

    return _dashboardData!.reportsByTeacher.map((report) {
      final payment = report.payments.firstWhere(
        (p) => p.month == monthStr,
        orElse: () => PaymentRecord(
          month: monthStr,
          paid: false,
          amount: '500 EGP',
          date: '-',
          receipt: '-',
        ),
      );

      final isPaid = payment.paid;
      final statusTextEn = isPaid ? 'Paid' : 'Unpaid';
      final statusTextAr = isPaid ? 'تم الدفع' : 'لم يتم الدفع';
      final color = isPaid ? AppColors.greenSuccess : AppColors.errorRed;

      return {
        'subject': report.subject,
        'teacher': report.teacherName,
        'status': statusTextEn,
        'statusAr': statusTextAr,
        'amount': payment.amount,
        'date': payment.date,
        'receipt': payment.receipt,
        'color': color,
        'isPaid': isPaid,
      };
    }).toList();
  }

  Widget _buildMonthPicker(Color textColor) {
    final months = _generateMonths();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        controller: _monthScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        itemBuilder: (context, index) {
          final monthDate = months[index];
          final isSelected =
              monthDate.month == _selectedPaymentMonth.month &&
              monthDate.year == _selectedPaymentMonth.year;
          final monthName = DateFormat('MMM yyyy', locale).format(monthDate);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPaymentMonth = monthDate;
              });
              _scrollToCurrentMonth();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryYello
                    : (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03)),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryYello
                      : (isDark
                            ? AppColors.glassBorderDark
                            : AppColors.glassBorderLight),
                  width: 1.2,
                ),
              ),
              child: Text(
                monthName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : textColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentSection(
    AppLocalizations appLocalizations,
    Color textColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final paymentList = _getGroupPaymentsForMonth(_selectedPaymentMonth);

    final sectionTitle = locale == 'ar'
        ? 'حالة الدفع الشهري'
        : 'Monthly Payment Status';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          sectionTitle,
          style: AppTextStyles.heading2.copyWith(color: textColor),
        ),
        const SizedBox(height: 10),
        _buildMonthPicker(textColor),
        const SizedBox(height: 8),
        if (paymentList.isEmpty)
          GlassContainer(
            width: double.infinity,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  locale == 'ar'
                      ? 'لا توجد تفاصيل دفع'
                      : 'No payment details available',
                  style: AppTextStyles.secondaryText,
                ),
              ),
            ),
          )
        else
          ...paymentList.map((paymentInfo) {
            final isPaid = paymentInfo['isPaid'] as bool;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: GlassContainer(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      isPaid
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: paymentInfo['color'],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            paymentInfo['subject'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            paymentInfo['teacher'],
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Payment date removed per request
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isPaid
                              ? paymentInfo['amount']
                              : (locale == 'ar' ? 'غير مدفوع' : 'Unpaid'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? AppColors.greenSuccess
                                : AppColors.errorRed,
                          ),
                        ),
                        if (isPaid)
                          Text(
                            locale == 'ar' ? 'تم الدفع' : 'Paid',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.greenSuccess,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.asset('assets/images/logo_bg.png', fit: BoxFit.contain),
        ),
        title: Text(
          appLocalizations.home,
          style: AppTextStyles.heading2.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: LiquidBackground(
        child: _isLoading
            ? const HomeShimmer()
            : _errorMessage.isNotEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    _errorMessage,
                    style: AppTextStyles.bodyText.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : _dashboardData != null &&
                  _dashboardData!.reportsByTeacher.isNotEmpty
            ? RefreshIndicator(
                onRefresh: _fetchData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: _buildDashboardContent(appLocalizations, textColor),
                ),
              )
            : _buildEmptyState(appLocalizations, isDark),
      ),
    );
  }

  Widget _buildChildrenTabs(Color textColor) {
    if (_studentsData.length <= 1) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 15, bottom: 5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _studentsData.length,
        itemBuilder: (context, index) {
          final student = _studentsData[index];
          final isSelected = index == _currentStudentIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentStudentIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryYello
                    : (isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04)),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryYello
                      : (isDark
                            ? AppColors.glassBorderDark
                            : AppColors.glassBorderLight),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryYello.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  student.studentName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardContent(
    AppLocalizations appLocalizations,
    Color? textColor,
  ) {
    final sortedSchedule = selectedDayScheduleEntries;
    sortedSchedule.sort((a, b) {
      final statusA =
          _getCourseStatusDetails(a, appLocalizations)['statusEnum']
              as CourseStatus;
      final statusB =
          _getCourseStatusDetails(b, appLocalizations)['statusEnum']
              as CourseStatus;
      return statusA.index.compareTo(statusB.index);
    });

    final reportsWithGradedAssignments = _dashboardData!.reportsByTeacher
        .where((report) => report.grades.any((grade) => grade.score != null))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUserInfoSection(appLocalizations, textColor),
        _buildChildrenTabs(textColor ?? Colors.black87),
        const SizedBox(height: 20),
        Text(
          appLocalizations.reports,
          style: AppTextStyles.heading2.copyWith(color: textColor),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: appLocalizations.assignments,
                value:
                    '${appLocalizations.submitted}: $submittedAssignmentsCount',
                description:
                    '${appLocalizations.notSubmitted}: $notSubmittedAssignmentsCount',
                color: AppColors.primaryYello,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildSummaryCard(
                title: appLocalizations.attendance,
                value:
                    '$overallAttendancePercentage% ${appLocalizations.present}',
                description: '$totalAttendanceDays ${appLocalizations.days}',
                color: AppColors.greenSuccess,
              ),
            ),
          ],
        ),

        // --- Monthly Payment Status Section ---
        _buildPaymentSection(appLocalizations, textColor ?? Colors.black87),

        const SizedBox(height: 25),
        Text(
          appLocalizations.todaysCourses,
          style: AppTextStyles.heading2.copyWith(color: textColor),
        ),

        // --- Horizontal Week Calendar Selector Strip ---
        _buildCalendarStrip(textColor ?? Colors.black87),

        const SizedBox(height: 5),
        if (sortedSchedule.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text(
                appLocalizations.noCoursesScheduled,
                style: AppTextStyles.secondaryText,
              ),
            ),
          )
        else
          ...sortedSchedule.map((entry) {
            final statusDetails = _getCourseStatusDetails(
              entry,
              appLocalizations,
            );
            // Format 24h to 12h format
            String formattedTime = _formatTo12Hour(entry.time);
            String timeAndLocation = formattedTime;
            if (entry.location.isNotEmpty) {
              timeAndLocation += ' - ${entry.location}';
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _buildCourseCard(
                subject: entry.subject,
                time: timeAndLocation,
                status: statusDetails['status'],
                statusColor: statusDetails['color'],
              ),
            );
          }).toList(),
        SizedBox(height: 20),
        Text(
          appLocalizations.assignmentsBySubject,
          style: AppTextStyles.heading2.copyWith(color: textColor),
        ),
        SizedBox(height: 10),
        // =======================    بداية الجزء الذي تم تعديله   =======================
        // --- استخدام القائمة المفلترة الجديدة ---
        Container(
          height: 160,
          child: reportsWithGradedAssignments.isEmpty
              ? Center(
                  child: Text(
                    appLocalizations.noAssignmentsFound,
                    style: AppTextStyles.secondaryText,
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: reportsWithGradedAssignments.length,
                  itemBuilder: (context, index) {
                    final report = reportsWithGradedAssignments[index];

                    // --- منطق جديد لجلب آخر درجة مرصودة فقط ---
                    final gradedAssignments = report.grades
                        .where((g) => g.score != null)
                        .toList();
                    gradedAssignments.sort((a, b) => b.date.compareTo(a.date));
                    final latestGradeRecord = gradedAssignments.isNotEmpty
                        ? gradedAssignments.first
                        : null;
                    final latestGrade = latestGradeRecord?.score ?? 0;
                    final latestTotal = latestGradeRecord?.totalMark ?? 30;

                    return _buildSubjectAssignmentCell(
                      subject: report.subject,
                      teacher: report.teacherName,
                      latestScore: latestGrade,
                      totalMark: latestTotal,
                      allGrades: report.grades,
                      appLocalizations: appLocalizations,
                    );
                  },
                ),
        ),
        // =======================     نهاية الجزء الذي تم تعديله    =======================
        SizedBox(height: 20),
        Text(
          appLocalizations.attendanceBySubject,
          style: AppTextStyles.heading2.copyWith(color: textColor),
        ),
        SizedBox(height: 10),
        Container(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _dashboardData!.reportsByTeacher.length,
            itemBuilder: (context, index) {
              final report = _dashboardData!.reportsByTeacher[index];
              final totalDays = report.attendance.length;
              final presentDays = report.attendance
                  .where((a) => a.status.toLowerCase() == 'present')
                  .length;
              final percentage = totalDays == 0
                  ? 0
                  : (presentDays / totalDays * 100).toInt();
              return _buildSubjectAttendanceCell(
                subject: report.subject,
                teacher: report.teacherName,
                percentage: percentage,
                allAttendance: report.attendance,
                appLocalizations: appLocalizations,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoSection(
    AppLocalizations appLocalizations,
    Color? textColor,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final studentName =
        _dashboardData?.studentName ?? (locale == 'ar' ? 'الطالب' : 'Student');
    final greetingText = locale == 'ar'
        ? 'مرحباً، ولي أمر الطالب $studentName'
        : 'Hello, $studentName\'s parent!';

    final parentPhone =
        FirebaseAuth.instance.currentUser?.email?.split('@').first ?? '';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[200],
          child: Icon(Icons.person, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetingText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (parentPhone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone_android_rounded,
                      size: 13,
                      color: AppColors.primaryYello.withOpacity(0.85),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      parentPhone,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Badge(
          label: Text('$_unreadNotificationsCount'),
          isLabelVisible: _unreadNotificationsCount > 0,
          backgroundColor: AppColors.errorRed,
          textColor: Colors.white,
          alignment: const Alignment(
            0.65,
            -0.65,
          ), // Floats nicely above the bell icon
          child: IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: textColor,
              size: 28,
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
              _fetchData(); // Refresh notifications unread count when returning
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String description,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassContainer(
      fillOpacity: isDark ? 0.08 : 0.45,
      borderOpacity: 0.12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyText.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading1.copyWith(color: color, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTextStyles.secondaryText.copyWith(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard({
    required String subject,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassContainer(
      width: double.infinity,
      fillOpacity: isDark ? 0.08 : 0.45,
      borderOpacity: 0.12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: AppTextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: AppTextStyles.secondaryText.copyWith(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations appLocalizations, bool isDark) {
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale == 'ar';

    final subtitleText = isAr
        ? 'لم يتم ربط أي طالب برقم هاتفك بعد. يرجى التواصل مع المعلم لإضافتك.'
        : 'No students are linked to your phone number yet. Please contact the teacher to add you.';

    final promoTitle = isAr
        ? 'هل معلم ابنك لا يستخدم الناظر؟'
        : "Is your student's teacher not using Elnazer?";
    final promoDesc = isAr
        ? 'تطبيق الناظر يعمل بالربط المباشر مع لوحة تحكم المعلم (لوحة تحكم الناظر). شارك الرابط مع معلم ابنك الآن ليدير مجموعاته ومواعيده وتتمكن من متابعة درجات وغياب ابنك لحظة بلحظة!'
        : 'Elnazer app works by linking directly with the teacher\'s dashboard (Elnazer Dashboard). Share the link with your teacher now to manage groups, schedules, and let you track grades and attendance instantly!';

    final shareButtonText = isAr
        ? 'مشاركة الرابط مع المعلم'
        : 'Share Link with Teacher';
    final shareMessage = isAr
        ? 'يا مستر، لوحة تحكم الناظر هتوفر عليك وقت ومجهود كبير في إدارة المجموعات، الحضور، الغياب، والدرجات، وهتخليني أتابع مستوى ابني أول بأول! ده رابط لوحة التحكم: https://elnazer-edu.com/'
        : 'Hello Teacher, Elnazer Dashboard will save you a lot of time and effort in managing groups, attendance, and grades, and lets me track progress instantly! Here is the dashboard link: https://elnazer-edu.com/';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Welcome Card
          GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(20.0),
            fillOpacity: isDark ? 0.08 : 0.45,
            borderOpacity: 0.12,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo_bg.png',
                      height: 45,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isAr
                          ? 'مرحباً بك في تطبيق الناظر'
                          : 'Welcome to Elnazer App',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  subtitleText,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Promo Card with Image & Action
          GlassContainer(
            borderRadius: 28,
            padding: const EdgeInsets.all(24.0),
            fillOpacity: isDark ? 0.1 : 0.5,
            borderOpacity: 0.15,
            child: Column(
              children: [
                // Image container
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryYello.withOpacity(0.3),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      'assets/images/dashboard.jpeg',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  promoTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryYello,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  promoDesc,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),

                // Share Link Button
                Builder(
                  builder: (btnContext) => ElevatedButton.icon(
                  onPressed: () {
                    final box = btnContext.findRenderObject() as RenderBox?;
                    Share.share(
                      shareMessage,
                      sharePositionOrigin: box != null
                          ? box.localToGlobal(Offset.zero) & box.size
                          : Rect.fromLTWH(0, 0, MediaQuery.of(context).size.width, 80),
                    );
                  },
                  icon: const Icon(
                    Icons.share_rounded,
                    size: 18,
                    color: Colors.black87,
                  ),
                  label: Text(
                    shareButtonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYello,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    shadowColor: AppColors.primaryYello.withOpacity(0.3),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectAssignmentCell({
    required String subject,
    required String teacher,
    required int latestScore,
    required int totalMark,
    required List<GradeRecord> allGrades,
    required AppLocalizations appLocalizations,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Performance percentage for color and progress ring
    final int percentage = totalMark > 0
        ? ((latestScore / totalMark) * 100).toInt()
        : 0;

    // Dynamic color based on performance
    final Color primaryColor = percentage >= 85
        ? AppColors.greenSuccess
        : (percentage >= 65
              ? (isDark ? Colors.white60 : Colors.black54)
              : AppColors.errorRed);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              AssignmentDetailsScreen(subject: subject, grades: allGrades),
        ),
      ),
      child: GlassContainer(
        width: 170,
        margin: const EdgeInsets.only(right: 14, bottom: 4),
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    subject.isNotEmpty
                        ? subject.substring(0, 1).toUpperCase()
                        : 'S',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white30 : Colors.black38,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subject,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              teacher,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appLocalizations.latest,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$latestScore/$totalMark',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: percentage / 100,
                        strokeWidth: 3.5,
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.04),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: primaryColor.withOpacity(0.8),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectAttendanceCell({
    required String subject,
    required String teacher,
    required int percentage,
    required List<AttendanceRecord> allAttendance,
    required AppLocalizations appLocalizations,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamic color based on performance
    final Color primaryColor = percentage >= 85
        ? AppColors.greenSuccess
        : (percentage >= 65
              ? (isDark ? Colors.white60 : Colors.black54)
              : AppColors.errorRed);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AttendanceDetailsScreen(
            subject: subject,
            attendanceRecords: allAttendance,
          ),
        ),
      ),
      child: GlassContainer(
        width: 170,
        margin: const EdgeInsets.only(right: 14, bottom: 4),
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    subject.isNotEmpty
                        ? subject.substring(0, 1).toUpperCase()
                        : 'S',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white30 : Colors.black38,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subject,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              teacher,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appLocalizations.present,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: percentage / 100,
                        strokeWidth: 3.5,
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.04),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: primaryColor.withOpacity(0.8),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
