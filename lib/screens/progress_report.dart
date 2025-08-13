import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/screens/notifications.dart';
import 'package:learnaria/services/firestore_api.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/l10n/app_localizations.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: null,
        automaticallyImplyLeading: false,
        title: Text(
          appLocalizations.progressReport,
          style: AppTextStyles.heading2.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
        ),
        centerTitle: false,
      ),
      body: _isLoading
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
                              _buildMonthViewSection(),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text(appLocalizations.noStudentData, style: AppTextStyles.secondaryText, textAlign: TextAlign.center))),
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
                // --- تم تعديل رسالة الترحيب هنا ---
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
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(appLocalizations.attendance, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge!.color)),
        SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isLightMode ? Colors.white : Theme.of(context).cardColor, 
            borderRadius: BorderRadius.circular(15), 
            boxShadow: isLightMode ? [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: Offset(0, 3))] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$presentDays ${appLocalizations.days}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge!.color)),
                  SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text('(${appLocalizations.outOfDays} $totalDays ${appLocalizations.days})', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.primaryYello, shape: BoxShape.circle)),
                  SizedBox(width: 8),
                  Text('$missedDays ${appLocalizations.daysMissed}', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color)),
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
    final Map<String, List<GradeRecord>> gradesBySubject = {};
    for (var report in _dashboardData!.reportsByTeacher) {
      for (var grade in report.grades) {
        gradesBySubject.putIfAbsent(report.subject, () => []).add(grade);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(appLocalizations.feedback, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge!.color)),
          ],
        ),
        SizedBox(height: 10),
        if (gradesBySubject.isEmpty)
          Center(child: Text(appLocalizations.noFeedback))
        else
          Row(
            children: gradesBySubject.entries.take(2).map((entry) {
              final subject = entry.key;
              final grades = entry.value;
              final averageScore = grades.map((g) => g.score).reduce((a, b) => a + b) / grades.length;
              final status = averageScore >= 85 ? appLocalizations.excellent : appLocalizations.needsImprovement;
              final statusColor = averageScore >= 85 ? AppColors.greenSuccess : AppColors.primaryYello;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _buildFeedbackCard(subject, status, statusColor, averageScore.toInt()),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildFeedbackCard(String subject, String status, Color statusColor, int percentage) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isLightMode ? Colors.white : Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(15), 
        boxShadow: isLightMode ? [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: Offset(0, 3))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subject, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge!.color)),
          SizedBox(height: 5),
          Text(status, style: TextStyle(fontSize: 14, color: statusColor)),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$percentage%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge!.color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthViewSection() {
    final appLocalizations = AppLocalizations.of(context)!;
    final allAttendance = _dashboardData!.reportsByTeacher.expand((report) => report.attendance).toList();
    final Map<int, int> monthlyData = {};
    for (var record in allAttendance) {
      try {
        final date = DateFormat('yyyy-MM-dd').parse(record.date);
        if (record.status.toLowerCase() == 'present') {
          monthlyData[date.month] = (monthlyData[date.month] ?? 0) + 1;
        }
      } catch (e) {/* ignore */}
    }
    
    final barGroups = monthlyData.keys.toList()..sort();
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(appLocalizations.monthView, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge!.color)),
        SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 220,
          padding: const EdgeInsets.only(top: 16, right: 16),
          decoration: BoxDecoration(
            color: isLightMode ? Colors.white : Theme.of(context).cardColor, 
            borderRadius: BorderRadius.circular(15), 
            boxShadow: isLightMode ? [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: Offset(0, 3))] : null,
          ),
          child: barGroups.isEmpty
              ? Center(child: Text(appLocalizations.noAttendanceData, style: AppTextStyles.secondaryText))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 31,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(DateFormat('MMM').format(DateTime(0, value.toInt())), style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall!.color)),
                          ),
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall!.color)))),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups.map((monthInt) => BarChartGroupData(
                      x: monthInt,
                      barRods: [BarChartRodData(toY: monthlyData[monthInt]!.toDouble(), color: AppColors.primaryYello, width: 16, borderRadius: BorderRadius.circular(4))],
                    )).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}
