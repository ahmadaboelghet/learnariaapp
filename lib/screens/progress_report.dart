import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/services/firestore_api.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/widgets/glass_container.dart';
import 'package:learnaria/widgets/shimmer_widgets.dart';

class ProgressReportScreen extends StatefulWidget {
  const ProgressReportScreen({super.key});

  @override
  State<ProgressReportScreen> createState() => _ProgressReportScreenState();
}

class _ProgressReportScreenState extends State<ProgressReportScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<DashboardData> _studentsData = [];
  int _currentStudentIndex = 0;

  DashboardData? get _dashboardData => _studentsData.isNotEmpty ? _studentsData[_currentStudentIndex] : null;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final parentPhone = user?.email?.split('@').first;

      if (parentPhone == null || parentPhone.isEmpty) {
        throw Exception('Could not determine your phone number from your email.');
      }

      final data = await FirestoreApi().fetchMultiDashboardData(parentPhoneNumber: parentPhone);
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



  // --- Calculate Overall Metrics ---
  int get _overallAverageGrade {
    if (_dashboardData == null || _dashboardData!.reportsByTeacher.isEmpty) return 0;
    
    double totalSubjectScores = 0.0;
    for (var report in _dashboardData!.reportsByTeacher) {
      // 1. Attendance (30%)
      final totalAttendance = report.attendance.length;
      final presentAttendance = report.attendance.where((a) => a.status.toLowerCase() == 'present').length;
      final attendanceRate = totalAttendance > 0 ? (presentAttendance / totalAttendance * 100) : 0.0;

      // 2. Homework (30%)
      final totalHW = report.grades.length;
      final submittedHW = report.grades.where((g) => g.submitted).length;
      final homeworkRate = totalHW > 0 ? (submittedHW / totalHW * 100) : 0.0;

      // 3. Exams (40%)
      final graded = report.grades.where((g) => g.score != null).toList();
      final examAverage = graded.isNotEmpty
          ? (graded.map((g) => g.score!).reduce((a, b) => a + b) / graded.length)
          : 0.0;

      final subjectScore = (attendanceRate * 0.3) + (homeworkRate * 0.3) + (examAverage * 0.4);
      totalSubjectScores += subjectScore;
    }
    return (totalSubjectScores / _dashboardData!.reportsByTeacher.length).toInt();
  }

  int get _overallAttendanceRate {
    if (_dashboardData == null || _dashboardData!.reportsByTeacher.isEmpty) return 0;
    
    double totalRates = 0.0;
    for (var report in _dashboardData!.reportsByTeacher) {
      final totalAttendance = report.attendance.length;
      final presentAttendance = report.attendance.where((a) => a.status.toLowerCase() == 'present').length;
      final attendanceRate = totalAttendance > 0 ? (presentAttendance / totalAttendance * 100) : 0.0;
      totalRates += attendanceRate;
    }
    return (totalRates / _dashboardData!.reportsByTeacher.length).toInt();
  }

  int get _overallHomeworkSubmissionRate {
    if (_dashboardData == null || _dashboardData!.reportsByTeacher.isEmpty) return 0;
    
    double totalRates = 0.0;
    for (var report in _dashboardData!.reportsByTeacher) {
      final totalHW = report.grades.length;
      final submittedHW = report.grades.where((g) => g.submitted).length;
      final homeworkRate = totalHW > 0 ? (submittedHW / totalHW * 100) : 0.0;
      totalRates += homeworkRate;
    }
    return (totalRates / _dashboardData!.reportsByTeacher.length).toInt();
  }

  Widget _buildChildrenTabs(Color textColor) {
    if (_studentsData.length <= 1) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 15),
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
                    : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryYello
                      : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryYello.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  student.studentName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: null,
        automaticallyImplyLeading: false,
        title: Text(
          appLocalizations.progressReport,
          style: AppTextStyles.heading2.copyWith(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: LiquidBackground(
        child: _isLoading
            ? const ReportsShimmer()
            : _errorMessage.isNotEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))))
                : _dashboardData != null && _dashboardData!.reportsByTeacher.isNotEmpty
                    ? RefreshIndicator(
                        onRefresh: _fetchReportData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 0. Child Tabs
                              _buildChildrenTabs(textColor),
                              
                              // 1. Premium Student Level Header Card
                              _buildStudentLevelHeaderCard(locale, isDark, textColor),
                              const SizedBox(height: 20),
                              
                              // 2. Attendance & Submission Analytics Card
                              _buildAnalyticsCard(locale, isDark, textColor, appLocalizations),
                              const SizedBox(height: 25),
 
                              // 3. Subject-wise Insights Section
                              Text(
                                locale == 'ar' ? 'تحليل المواد الدراسية' : 'Subject Analysis',
                                style: AppTextStyles.heading2.copyWith(color: textColor),
                              ),
                              const SizedBox(height: 10),
                              _buildSubjectInsightsList(locale, isDark, textColor),
                              const SizedBox(height: 25),
 
                              // 4. Performance Chart Section
                              _buildPerformanceChartSection(textColor, appLocalizations),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/logo_bg.png',
                                height: 70,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                locale == 'ar'
                                    ? 'لا توجد بيانات لعرضها حالياً'
                                    : 'No data to display yet',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }

  // --- Student Level Header Card ---
  Widget _buildStudentLevelHeaderCard(String locale, bool isDark, Color textColor) {
    final name = _dashboardData?.studentName ?? 'Student';
    final avgGrade = _overallAverageGrade;
    final progressColor = _getPerformanceColor(avgGrade.toDouble());
    
    return GlassContainer(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 2),
              Text(
                locale == 'ar' ? 'التقرير الأكاديمي الشامل' : 'Academic progress report',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$avgGrade%',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: progressColor),
              ),
              Text(
                locale == 'ar' ? 'المعدل العام' : 'Overall Grade',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Attendance & Submission Analytics Card ---
  Widget _buildAnalyticsCard(String locale, bool isDark, Color textColor, AppLocalizations appLocalizations) {
    final attendanceRate = _overallAttendanceRate;
    final submissionRate = _overallHomeworkSubmissionRate;

    return Row(
      children: [
        // Attendance Column
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appLocalizations.attendance,
                      style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.calendar_today_rounded, color: Colors.blue, size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$attendanceRate%',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: attendanceRate / 100,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 14),

        // Homework Submissions Column
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      locale == 'ar' ? 'تسليم الواجبات' : 'Homework',
                      style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.assignment_turned_in_rounded, color: AppColors.primaryYello, size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$submissionRate%',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: submissionRate / 100,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryYello),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Subject-wise List ---
  Widget _buildSubjectInsightsList(String locale, bool isDark, Color textColor) {
    final reports = _dashboardData!.reportsByTeacher;
    
    return Column(
      children: reports.map((report) {
        // 1. Attendance (30%)
        final totalAttendance = report.attendance.length;
        final presentAttendance = report.attendance.where((a) => a.status.toLowerCase() == 'present').length;
        final attendancePercent = totalAttendance > 0 ? (presentAttendance / totalAttendance * 100).toInt() : 0;

        // 2. Homework (30%)
        final totalHW = report.grades.length;
        final submittedHW = report.grades.where((g) => g.submitted).length;
        final homeworkPercent = totalHW > 0 ? (submittedHW / totalHW * 100).toInt() : 0;

        // 3. Exams (40%)
        final graded = report.grades.where((g) => g.score != null).toList();
        final examAvg = graded.isNotEmpty
            ? (graded.map((g) => g.score!).reduce((a, b) => a + b) / graded.length).toInt()
            : 0;

        final subjectScore = (attendancePercent * 0.3) + (homeworkPercent * 0.3) + (examAvg * 0.4);
        final subjectAvg = subjectScore.toInt();
        final subjectColor = _getPerformanceColor(subjectScore);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassContainer(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.subject,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        report.teacherName,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Average Grade
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$subjectAvg%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16, 
                            color: subjectColor
                          ),
                        ),
                        Text(
                          locale == 'ar' ? 'التقييم العام' : 'Overall',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Attendance
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$attendancePercent%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16, 
                            color: Colors.blue
                          ),
                        ),
                        Text(
                          locale == 'ar' ? 'نسبة الحضور' : 'Attendance',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getPerformanceColor(double score) {
    if (score >= 85.0) {
      return AppColors.greenSuccess;
    } else if (score >= 65.0) {
      return AppColors.darkGrey;
    } else {
      return AppColors.errorRed;
    }
  }

  // --- Performance Bar Chart Section ---
  Widget _buildPerformanceChartSection(Color textColor, AppLocalizations appLocalizations) {
    final List<BarChartGroupData> barGroups = [];
    final reports = _dashboardData!.reportsByTeacher;

    for (int i = 0; i < reports.length; i++) {
      final report = reports[i];
      
      // 1. Attendance (30%)
      final totalAttendance = report.attendance.length;
      final presentAttendance = report.attendance.where((a) => a.status.toLowerCase() == 'present').length;
      final attendanceRate = totalAttendance > 0 ? (presentAttendance / totalAttendance * 100) : 0.0;

      // 2. Homework (30%)
      final totalHW = report.grades.length;
      final submittedHW = report.grades.where((g) => g.submitted).length;
      final homeworkRate = totalHW > 0 ? (submittedHW / totalHW * 100) : 0.0;

      // 3. Exams (40%)
      final gradedAssignments = report.grades.where((g) => g.score != null).toList();
      final examAverage = gradedAssignments.isNotEmpty
          ? (gradedAssignments.map((g) => g.score!).reduce((a, b) => a + b) / gradedAssignments.length)
          : 0.0;

      final averageScore = (attendanceRate * 0.3) + (homeworkRate * 0.3) + (examAverage * 0.4);
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: averageScore,
              color: _getPerformanceColor(averageScore),
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            )
          ],
        )
      );
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalizations.performanceOverview,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 10),
        GlassContainer(
          width: double.infinity,
          height: 200,
          padding: const EdgeInsets.only(top: 20, right: 16, left: 16, bottom: 8),
          child: barGroups.isEmpty
              ? Center(child: Text(appLocalizations.noDataForChart, style: AppTextStyles.secondaryText))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                             final index = value.toInt();
                             if (index < reports.length) {
                               return Padding(
                                 padding: const EdgeInsets.only(top: 8.0),
                                 child: Text(
                                   reports[index].subject,
                                   style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54, fontWeight: FontWeight.bold),
                                 ),
                               );
                             }
                             return const Text('');
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (v, m) => Text(
                            v.toInt().toString(),
                            style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black45),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
        ),
      ],
    );
  }
}