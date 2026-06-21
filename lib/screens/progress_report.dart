import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/services/firestore_api.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/widgets/glass_container.dart';

class ProgressReportScreen extends StatefulWidget {
  const ProgressReportScreen({super.key});

  @override
  State<ProgressReportScreen> createState() => _ProgressReportScreenState();
}

class _ProgressReportScreenState extends State<ProgressReportScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  DashboardData? _dashboardData;

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

      final data = await FirestoreApi().fetchDashboardData(parentPhoneNumber: parentPhone);
      if (mounted) {
        setState(() {
          _dashboardData = data;
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
    
    double totalWeighted = 0;
    int count = 0;
    for (var report in _dashboardData!.reportsByTeacher) {
      final graded = report.grades.where((g) => g.score != null).toList();
      if (graded.isNotEmpty) {
        final avg = graded.map((g) => g.score!).reduce((a, b) => a + b) / graded.length;
        totalWeighted += avg;
        count++;
      }
    }
    return count > 0 ? (totalWeighted / count).toInt() : 0;
  }

  int get _overallAttendanceRate {
    if (_dashboardData == null || _dashboardData!.reportsByTeacher.isEmpty) return 0;
    final all = _dashboardData!.reportsByTeacher.expand((r) => r.attendance).toList();
    if (all.isEmpty) return 0;
    final present = all.where((a) => a.status.toLowerCase() == 'present').length;
    return (present / all.length * 100).toInt();
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
            ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYello)))
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
                    : Center(child: Text(appLocalizations.noStudentData)),
      ),
    );
  }

  // --- Student Level Header Card ---
  Widget _buildStudentLevelHeaderCard(String locale, bool isDark, Color textColor) {
    final name = _dashboardData?.studentName ?? 'Student';
    final avgGrade = _overallAverageGrade;
    
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
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryYello),
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
    
    // Calculate total homework submission rate
    int totalHW = 0;
    int submittedHW = 0;
    if (_dashboardData != null) {
      totalHW = _dashboardData!.reportsByTeacher.expand((r) => r.grades).length;
      submittedHW = _dashboardData!.reportsByTeacher.expand((r) => r.grades).where((g) => g.submitted).length;
    }
    final submissionRate = totalHW > 0 ? (submittedHW / totalHW * 100).toInt() : 0;

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
        final graded = report.grades.where((g) => g.score != null).toList();
        final subjectAvg = graded.isNotEmpty
            ? (graded.map((g) => g.score!).reduce((a, b) => a + b) / graded.length).toInt()
            : 0;
            
        final totalAttendance = report.attendance.length;
        final presentAttendance = report.attendance.where((a) => a.status.toLowerCase() == 'present').length;
        final attendancePercent = totalAttendance > 0 ? (presentAttendance / totalAttendance * 100).toInt() : 0;

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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16, 
                            color: AppColors.primaryYello
                          ),
                        ),
                        Text(
                          locale == 'ar' ? 'متوسط الدرجات' : 'Avg Grade',
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
      return AppColors.primaryYello;
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
      
      final gradedAssignments = report.grades.where((g) => g.score != null).toList();
      final averageScore = gradedAssignments.isNotEmpty
          ? (gradedAssignments.map((g) => g.score!).reduce((a, b) => a + b) / gradedAssignments.length)
          : 0.0;
      
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