import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/screens/assignment_details.dart';
import 'package:learnaria/screens/attendance_details.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/services/firestore_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

enum CourseStatus { Upcoming, Ongoing, Finished }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
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

  Map<String, dynamic> _getCourseStatusDetails(ScheduleEntry entry) {
    final now = DateTime.now();
    try {
      final timeParts = entry.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      final startTime = DateTime(now.year, now.month, now.day, hour, minute);
      final endTime = startTime.add(const Duration(hours: 2));

      if (now.isAfter(endTime)) {
        return {'status': 'Finished', 'color': AppColors.mediumGrey, 'statusEnum': CourseStatus.Finished};
      } else if (now.isAfter(startTime) && now.isBefore(endTime)) {
        return {'status': 'Ongoing', 'color': AppColors.greenSuccess, 'statusEnum': CourseStatus.Ongoing};
      } else {
        return {'status': 'Upcoming', 'color': Colors.red, 'statusEnum': CourseStatus.Upcoming};
      }
    } catch (e) {
      return {'status': 'Scheduled', 'color': AppColors.mediumGrey, 'statusEnum': CourseStatus.Upcoming};
    }
  }

  int get totalAssignmentsCount {
    if (_dashboardData == null) return 0;
    return _dashboardData!.reportsByTeacher.fold(0, (sum, report) => sum + report.grades.length);
  }

  int get totalSubjectsWithAssignments {
     if (_dashboardData == null) return 0;
     return _dashboardData!.reportsByTeacher.where((r) => r.grades.isNotEmpty).map((r) => r.subject).toSet().length;
  }
  int get overallAttendancePercentage {
    if (_dashboardData == null) return 0;
    final all = _dashboardData!.reportsByTeacher.expand((r) => r.attendance).toList();
    if (all.isEmpty) return 0;
    final present = all.where((a) => a.status.toLowerCase() == 'present').length;
    return (present / all.length * 100).toInt();
  }
  int get totalAttendanceDays => _dashboardData?.reportsByTeacher.expand((r) => r.attendance).length ?? 0;
  
  List<ScheduleEntry> get todayScheduleEntries {
    if (_dashboardData == null) return [];
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _dashboardData!.reportsByTeacher
        .expand((report) => report.schedule)
        .where((entry) => entry.date == todayString)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: Text('Learnaria', style: AppTextStyles.heading2),
        centerTitle: false,
        titleSpacing: 0,
        actions: [IconButton(icon: Icon(Icons.refresh, color: AppColors.primaryBlack), onPressed: _fetchData)],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYello)))
          : _errorMessage.isNotEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text(_errorMessage, style: AppTextStyles.bodyText.copyWith(color: Colors.red), textAlign: TextAlign.center)))
              : _dashboardData != null && _dashboardData!.reportsByTeacher.isNotEmpty
                  ? RefreshIndicator(
                      onRefresh: _fetchData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: _buildDashboardContent(),
                      ),
                    )
                  : Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("No student data found. Please contact the teacher.", style: AppTextStyles.secondaryText, textAlign: TextAlign.center))),
    );
  }

  Widget _buildDashboardContent() {
    final sortedTodaySchedule = todayScheduleEntries;
    sortedTodaySchedule.sort((a, b) {
        final statusA = _getCourseStatusDetails(a)['statusEnum'] as CourseStatus;
        final statusB = _getCourseStatusDetails(b)['statusEnum'] as CourseStatus;
        return statusA.index.compareTo(statusB.index);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUserInfoSection(),
        SizedBox(height: 20),
        Text('Reports', style: AppTextStyles.heading2),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildSummaryCard(title: 'Assignments', value: '$totalAssignmentsCount Done', description: '$totalSubjectsWithAssignments Subjects', color: AppColors.primaryYello)),
            SizedBox(width: 15),
            Expanded(child: _buildSummaryCard(title: 'Attendance', value: '$overallAttendancePercentage% Present', description: '$totalAttendanceDays days', color: AppColors.greenSuccess)),
          ],
        ),
        SizedBox(height: 20),
        Text("Today's Courses", style: AppTextStyles.heading2),
        SizedBox(height: 10),
        if (sortedTodaySchedule.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Center(child: Text('No courses scheduled for today.', style: AppTextStyles.secondaryText)))
        else
          ...sortedTodaySchedule.map((entry) {
            final statusDetails = _getCourseStatusDetails(entry);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _buildCourseCard(
                subject: entry.subject,
                time: '${entry.time} - ${entry.room}',
                status: statusDetails['status'],
                statusColor: statusDetails['color'],
              ),
            );
          }).toList(),
        SizedBox(height: 20),
        Text('Assignments by Subject', style: AppTextStyles.heading2),
        SizedBox(height: 10),
        Container(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _dashboardData!.reportsByTeacher.length,
            itemBuilder: (context, index) {
              final report = _dashboardData!.reportsByTeacher[index];
              int latestGrade = 0;
              if (report.grades.isNotEmpty) {
                report.grades.sort((a, b) => b.date.compareTo(a.date));
                latestGrade = report.grades.first.score;
              }
              return _buildSubjectAssignmentCell(subject: report.subject, teacher: report.teacherName, percentage: latestGrade, allGrades: report.grades);
            },
          ),
        ),
        SizedBox(height: 20),
        Text('Attendance by Subject', style: AppTextStyles.heading2),
        SizedBox(height: 10),
        Container(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _dashboardData!.reportsByTeacher.length,
            itemBuilder: (context, index) {
              final report = _dashboardData!.reportsByTeacher[index];
              final totalDays = report.attendance.length;
              final presentDays = report.attendance.where((a) => a.status.toLowerCase() == 'present').length;
              final percentage = totalDays == 0 ? 0 : (presentDays / totalDays * 100).toInt();
              return _buildSubjectAttendanceCell(subject: report.subject, teacher: report.teacherName, percentage: percentage, allAttendance: report.attendance);
            },
          ),
        ),
      ],
    );
  }
  
  // --- WIDGET MODIFIED ---
  Widget _buildUserInfoSection() {
     return Row(
      children: [
        // Re-added the CircleAvatar
        CircleAvatar(radius: 24, backgroundColor: Colors.grey[200], child: Icon(Icons.person, color: Colors.grey[600])), 
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Changed the welcome message
              Text('Hello, ${_dashboardData?.studentName ?? "Student"}\'s parent!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Here is your latest report.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({required String title, required String value, required String description, required Color color}) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          Text(value, style: AppTextStyles.heading1.copyWith(color: color, fontSize: 20)),
          SizedBox(height: 4),
          Text(description, style: AppTextStyles.secondaryText.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCourseCard({required String subject, required String time, required String status, required Color statusColor}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: Offset(0, 3))]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(time, style: AppTextStyles.secondaryText),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectAssignmentCell({required String subject, required String teacher, required int percentage, required List<GradeRecord> allGrades}) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => AssignmentDetailsScreen(subject: subject, grades: allGrades))),
      child: Container(
        width: 180,
        margin: EdgeInsets.only(right: 15),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), spreadRadius: 1, blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 4),
            Text(teacher, style: AppTextStyles.secondaryText.copyWith(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$percentage%', style: AppTextStyles.heading2.copyWith(color: percentage >= 70 ? AppColors.greenSuccess : AppColors.primaryYello)),
                    Text('Latest', style: AppTextStyles.secondaryText.copyWith(fontSize: 10)),
                  ],
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectAttendanceCell({required String subject, required String teacher, required int percentage, required List<AttendanceRecord> allAttendance}) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => AttendanceDetailsScreen(subject: subject, attendanceRecords: allAttendance))),
      child: Container(
        width: 180,
        margin: EdgeInsets.only(right: 15),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), spreadRadius: 1, blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 4),
            Text(teacher, style: AppTextStyles.secondaryText.copyWith(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$percentage%', style: AppTextStyles.heading2.copyWith(color: percentage >= 90 ? AppColors.greenSuccess : AppColors.primaryYello)),
                    Text('Present', style: AppTextStyles.secondaryText.copyWith(fontSize: 10)),
                  ],
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}