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
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:url_launcher/url_launcher.dart';

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
  DateTime _selectedPaymentMonth = _getInitialPaymentMonth();

  static DateTime _getInitialPaymentMonth() {
    final now = DateTime.now();
    if (now.month == 6 || now.month == 7) {
      return DateTime(now.year, 8);
    }
    return DateTime(now.year, now.month);
  }
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
    _checkForUpdate();
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
    // Return candidate surrounding months, excluding summer vacation months (June: 6, July: 7)
    final allMonths = List.generate(
      14,
      (index) => DateTime(now.year, now.month - 7 + index),
    );
    return allMonths.where((m) => m.month != 6 && m.month != 7).toList();
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

  Widget _buildHeroDashboardCard(AppLocalizations appLocalizations, Color textColor) {
    if (_dashboardData == null || _dashboardData!.reportsByTeacher.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    
    return SizedBox(
      height: 190,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.93),
        itemCount: _dashboardData!.reportsByTeacher.length,
        itemBuilder: (context, index) {
          final report = _dashboardData!.reportsByTeacher[index];
          
          final allAttendance = report.attendance;
          int present = 0;
          if (allAttendance.isNotEmpty) {
            present = allAttendance.where((a) => a.status.toLowerCase() == 'present').length;
          }
          final attendancePercent = allAttendance.isEmpty ? 0 : (present / allAttendance.length * 100).toInt();
          
          // According to original logic, total assignments = grades.length
          final totalHw = report.grades.length;
          final submittedHw = report.grades.where((g) => g.submitted == true).length;
          final notSubmitted = totalHw - submittedHw;
          
          final paymentList = _getGroupPaymentsForMonth(_selectedPaymentMonth);
          Map<String, dynamic>? paymentInfo;
          for (var p in paymentList) {
            if (p['subject'] == report.subject) {
              paymentInfo = p;
              break;
            }
          }
          
          bool isPaid = false;
          bool isEmpty = true;
          if (paymentInfo != null) {
             isEmpty = false;
             isPaid = paymentInfo['isPaid'] as bool;
          }

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              borderRadius: 24,
              fillOpacity: isDark ? 0.08 : 0.45,
              borderOpacity: 0.12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${locale == 'ar' ? "نظرة سريعة" : "At a Glance"} - ${report.subject}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.insights_rounded, color: AppColors.primaryYello, size: 20),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniCircularProgress(
                        label: appLocalizations.attendance,
                        percentage: attendancePercent,
                        color: attendancePercent > 75 ? AppColors.greenSuccess : (attendancePercent > 50 ? AppColors.primaryYello : AppColors.errorRed),
                        isDark: isDark,
                      ),
                      Container(width: 1, height: 60, color: Colors.grey.withOpacity(0.3)),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            notSubmitted > 0 ? notSubmitted.toString() : '0',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: notSubmitted > 0 ? AppColors.errorRed : AppColors.greenSuccess,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            locale == 'ar' ? 'واجبات لم تسلم' : 'Pending HW',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 60, color: Colors.grey.withOpacity(0.3)),
                      _buildMonthlyPaymentBadge(locale, isDark, isPaid: isPaid, isEmpty: isEmpty),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniCircularProgress({required String label, required int percentage, required Color color, required bool isDark}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 55,
          height: 55,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 5,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  '$percentage%',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
        ),
      ],
    );
  }

  Widget _buildMonthlyPaymentBadge(String locale, bool isDark, {bool isPaid = false, bool isEmpty = false}) {
    IconData icon = Icons.info_outline;
    Color color = Colors.grey;
    String text = '-';
    
    if (isEmpty) {
      icon = Icons.more_horiz_rounded;
      text = locale == 'ar' ? 'لا يوجد' : 'None';
    } else if (isPaid) {
      icon = Icons.check_circle_rounded;
      color = AppColors.greenSuccess;
      text = locale == 'ar' ? 'تم الدفع' : 'Paid';
    } else {
      icon = Icons.warning_amber_rounded;
      color = AppColors.errorRed;
      text = locale == 'ar' ? 'مطلوب الدفع' : 'Due';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 12),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildUnpaidAlertBanner(AppLocalizations appLocalizations, Color textColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final paymentList = _getGroupPaymentsForMonth(_selectedPaymentMonth);
    
    if (paymentList.isEmpty) return const SizedBox.shrink(); // No items for this month

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              locale == 'ar' ? 'حالة الدفع' : 'Payment Status',
              style: AppTextStyles.heading2.copyWith(color: textColor),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildMonthPicker(textColor)),
          ],
        ),
        const SizedBox(height: 12),
        ...paymentList.map((paymentInfo) {
          final isPaid = paymentInfo['isPaid'] as bool;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: GlassContainer(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isPaid ? AppColors.greenSuccess : AppColors.errorRed).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPaid ? Icons.check_circle_rounded : Icons.payment_rounded, 
                      color: isPaid ? AppColors.greenSuccess : AppColors.errorRed, 
                      size: 22
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paymentInfo['subject'],
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isPaid 
                            ? (locale == 'ar' ? 'تم الدفع بنجاح' : 'Paid Successfully')
                            : (locale == 'ar' ? 'يرجى تسديد الاشتراك الشهري' : 'Please settle the monthly fee'),
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPaid
                      ? (locale == 'ar' ? 'تم الدفع' : 'Paid')
                      : (locale == 'ar' ? 'غير مدفوع' : 'Unpaid'),
                    style: TextStyle(
                      fontSize: 13, 
                      fontWeight: FontWeight.bold, 
                      color: isPaid ? AppColors.greenSuccess : AppColors.errorRed
                    ),
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
      height: 50,
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
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryYello
                    : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark ? Colors.white12 : Colors.black12),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryYello.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    student.studentName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
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
        _buildHeroDashboardCard(appLocalizations, textColor ?? Colors.black87),
        const SizedBox(height: 25),
        _buildUnpaidAlertBanner(appLocalizations, textColor ?? Colors.black87),

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
          ...sortedSchedule.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
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
            final isLast = index == sortedSchedule.length - 1;
            return _buildTimelineCourseCard(
              subject: entry.subject,
              time: timeAndLocation,
              status: statusDetails['status'],
              statusColor: statusDetails['color'],
              isLast: isLast,
              textColor: textColor ?? Colors.black87,
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

  Widget _buildTimelineCourseCard({
    required String subject,
    required String time,
    required String status,
    required Color statusColor,
    required bool isLast,
    required Color textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? Colors.black : Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(color: statusColor.withOpacity(0.4), blurRadius: 4, spreadRadius: 1)
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  )
                else
                  const SizedBox(height: 20), // Bottom padding for last item
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: GlassContainer(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                borderRadius: 20,
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
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: isDark ? Colors.white54 : Colors.black54),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  time, 
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
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
    final int percentage = totalMark > 0 ? ((latestScore / totalMark) * 100).toInt() : 0;
    
    final Color primaryColor = percentage >= 85
        ? AppColors.greenSuccess
        : (percentage >= 65 ? AppColors.primaryYello : AppColors.errorRed);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => AssignmentDetailsScreen(subject: subject, grades: allGrades)),
      ),
      child: GlassContainer(
        width: 200,
        margin: const EdgeInsets.only(right: 14, bottom: 4),
        padding: const EdgeInsets.all(16.0),
        borderRadius: 20,
        fillOpacity: isDark ? 0.08 : 0.45,
        borderOpacity: 0.12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.analytics_rounded, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        teacher,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    appLocalizations.latest,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                  ),
                  Text(
                    '$latestScore/$totalMark',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ],
              ),
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
    
    final Color primaryColor = percentage >= 85
        ? AppColors.greenSuccess
        : (percentage >= 65 ? AppColors.primaryYello : AppColors.errorRed);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => AttendanceDetailsScreen(subject: subject, attendanceRecords: allAttendance)),
      ),
      child: GlassContainer(
        width: 200,
        margin: const EdgeInsets.only(right: 14, bottom: 4),
        padding: const EdgeInsets.all(16.0),
        borderRadius: 20,
        fillOpacity: isDark ? 0.08 : 0.45,
        borderOpacity: 0.12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.date_range_rounded, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        teacher,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    appLocalizations.present,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkForUpdate() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(seconds: 0), // Fetch instantly for testing
      ));
      await remoteConfig.fetchAndActivate();

      final latestVersion = remoteConfig.getString('latest_version'); // e.g. "1.0.3"
      final androidUrl = remoteConfig.getString('android_update_url');
      final iosUrl = remoteConfig.getString('ios_update_url');
      final updateUrlStr = remoteConfig.getString('update_url'); // Fallback generic URL
      final forceUpdate = remoteConfig.getBool('force_update');

      if (latestVersion.isEmpty) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isUpdateAvailable(currentVersion, latestVersion)) {
        if (mounted) {
          _showUpdateDialog(
            androidUrl.isNotEmpty ? androidUrl : updateUrlStr,
            iosUrl.isNotEmpty ? iosUrl : updateUrlStr,
            forceUpdate,
          );
        }
      }
    } catch (e) {
      debugPrint("Failed to check for updates: $e");
    }
  }

  bool _isUpdateAvailable(String current, String latest) {
    // Basic semver check ignoring build numbers
    final currParts = current.split('+').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latParts = latest.split('+').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      int c = i < currParts.length ? currParts[i] : 0;
      int l = i < latParts.length ? latParts[i] : 0;
      if (l > c) return true;
      if (c > l) return false;
    }
    return false;
  }

  void _showUpdateDialog(String androidUrl, String iosUrl, bool forceUpdate) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final updateUrl = isIOS ? iosUrl : androidUrl;
    final locale = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) => WillPopScope(
        onWillPop: () async => !forceUpdate,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYello.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.system_update_rounded, size: 48, color: AppColors.primaryYello),
                ),
                const SizedBox(height: 20),
                Text(
                  locale == 'ar' ? 'تحديث جديد متاح' : 'New Update Available',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  locale == 'ar'
                      ? 'لقد أطلقنا نسخة جديدة من التطبيق بميزات أفضل وتحسينات في الأداء. نرجو التحديث الآن!'
                      : 'A new version of the app is available with better features and performance improvements. Please update now!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (updateUrl.isNotEmpty) {
                        final uri = Uri.parse(updateUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYello,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      locale == 'ar' ? 'تحديث الآن' : 'Update Now',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                if (!forceUpdate) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      locale == 'ar' ? 'تخطي الآن' : 'Skip for now',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
