import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/screens/notifications.dart';
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

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: null,
        automaticallyImplyLeading: false,
        title: Text(
          appLocalizations.progressReport,
          style: AppTextStyles.heading2.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
        ),
        centerTitle: false,
      ),
      body: LiquidBackground(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYello)))
            : _errorMessage.isNotEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.red))))
                : _dashboardData != null && _dashboardData!.reportsByTeacher.isNotEmpty
                    ? RefreshIndicator(
                        onRefresh: _fetchReportData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildUserInfoSection(),
                                SizedBox(height: 20),
                                _buildAttendanceSection(),
                                SizedBox(height: 20),
                                _buildFeedbackSection(),
                                SizedBox(height: 20),
                                _buildPerformanceChartSection(),
                                SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text(appLocalizations.noStudentData, style: AppTextStyles.secondaryText, textAlign: TextAlign.center))),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    final appLocalizations = AppLocalizations.of(context)!;
    return Row(
      children: [
        CircleAvatar(radius: 24, backgroundColor: Colors.grey[200], child: Icon(Icons.person, color: Colors.grey[600])),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appLocalizations.helloStudentParent(_dashboardData?.studentName ?? "Student"),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge!.color),
              ),
              Text(
                '${appLocalizations.todayDate} ${DateFormat.yMMMMd().format(DateTime.now())}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationsScreen()));
          },
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
            child: Image(image: AssetImage('assets/images/notification-bell.png'), height: 24, width: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceSection() {
    final appLocalizations = AppLocalizations.of(context)!;
    final allAttendance = _dashboardData!.reportsByTeacher.expand((report) => report.attendance).toList();
    final totalDays = allAttendance.length;
    final presentDays = allAttendance.where((record) => record.status.toLowerCase() == 'present').length;
    final missedDays = totalDays - presentDays;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(appLocalizations.attendance, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 10),
        GlassContainer(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$presentDays ${appLocalizations.days}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text('(${appLocalizations.outOfDays} $totalDays ${appLocalizations.days})', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryYello, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('$missedDays ${appLocalizations.daysMissed}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    final appLocalizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(appLocalizations.feedback, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
        const SizedBox(height: 10),
        if (_dashboardData!.reportsByTeacher.isEmpty)
          Center(child: Text(appLocalizations.noFeedback))
        else
          Row(
            children: _dashboardData!.reportsByTeacher.take(2).map((report) {
              final totalAttendance = report.attendance.length;
              final presentAttendance = report.attendance.where((a) => a.status.toLowerCase() == 'present').length;
              final attendancePercent = totalAttendance > 0 ? (presentAttendance / totalAttendance) : 0.0;

              final totalAssignments = report.grades.length;
              final submittedAssignments = report.grades.where((g) => g.submitted).length;
              final submissionPercent = totalAssignments > 0 ? (submittedAssignments / totalAssignments) : 0.0;
              
              final gradedAssignments = report.grades.where((g) => g.score != null).toList();
              final averageScore = gradedAssignments.isNotEmpty
                  ? gradedAssignments.map((g) => g.score!).reduce((a, b) => a + b) / gradedAssignments.length
                  : 0.0;
              
              final finalFeedbackScore = (attendancePercent * 30) + (submissionPercent * 40) + (averageScore * 0.30);
              
              final status = finalFeedbackScore >= 85 ? appLocalizations.excellent : appLocalizations.needsImprovement;
              final statusColor = finalFeedbackScore >= 85 ? AppColors.greenSuccess : AppColors.primaryYello;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _buildFeedbackCard(report.subject, status, statusColor, finalFeedbackScore.toInt()),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildFeedbackCard(String subject, String status, Color statusColor, int percentage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassContainer(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subject, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 5),
          Text(status, style: TextStyle(fontSize: 14, color: statusColor)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$percentage%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  // =======================    بداية الجزء الذي تم تعديله   =======================
  // --- دالة جديدة لتحديد لون العمود بناءً على النسبة ---
  Color _getPerformanceColor(double score) {
    if (score < 50) {
      return Colors.red;
    } else if (score >= 50 && score < 70) {
      return Colors.grey;
    } else if (score >= 70 && score < 90) {
      return AppColors.primaryYello;
    } else { // score >= 90
      return AppColors.greenSuccess;
    }
  }

  Widget _buildPerformanceChartSection() {
    final appLocalizations = AppLocalizations.of(context)!;
    final List<BarChartGroupData> barGroups = [];
    final reports = _dashboardData!.reportsByTeacher;

    for (int i = 0; i < reports.length; i++) {
      final report = reports[i];
      
      final totalAttendance = report.attendance.length;
      final presentAttendance = report.attendance.where((a) => a.status.toLowerCase() == 'present').length;
      final attendancePercent = totalAttendance > 0 ? (presentAttendance / totalAttendance) : 0.0;

      final totalAssignments = report.grades.length;
      final submittedAssignments = report.grades.where((g) => g.submitted).length;
      final submissionPercent = totalAssignments > 0 ? (submittedAssignments / totalAssignments) : 0.0;
      
      final gradedAssignments = report.grades.where((g) => g.score != null).toList();
      final averageScore = gradedAssignments.isNotEmpty
          ? gradedAssignments.map((g) => g.score!).reduce((a, b) => a + b) / gradedAssignments.length
          : 0.0;
      
      final finalFeedbackScore = (attendancePercent * 30) + (submissionPercent * 40) + (averageScore * 0.30);

      // --- استخدام الدالة الجديدة لتحديد اللون ---
      final barColor = _getPerformanceColor(finalFeedbackScore);

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: finalFeedbackScore,
              color: barColor, // <-- تم تطبيق اللون هنا
              width: 16,
              borderRadius: BorderRadius.circular(4)
            )
          ],
        )
      );
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(appLocalizations.performanceOverview, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 10),
        GlassContainer(
          width: double.infinity,
          height: 220,
          padding: const EdgeInsets.only(top: 16, right: 16),
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
                                child: Text(reports[index].subject, style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall!.color)),
                              );
                             }
                             return Text('');
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall!.color)))),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
        ),
      ],
    );
  }
  // =======================     نهاية الجزء الذي تم تعديله    =======================
}