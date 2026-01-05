import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/screens/assignment_details.dart';
import 'package:learnaria/screens/attendance_details.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/services/firestore_api.dart';
import 'package:intl/intl.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/widgets/glass_card.dart'; // تأكد من الاستيراد

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
      final data = await FirestoreApi().fetchDashboardData();
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

  Map<String, dynamic> _getCourseStatusDetails(
    ScheduleEntry entry,
    AppLocalizations appLocalizations,
  ) {
    // ... (نفس المنطق القديم بدون تغيير) ...
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
          'color': Colors.grey,
          'statusEnum': CourseStatus.Finished,
        };
      } else if (now.isAfter(startTime) && now.isBefore(endTime)) {
        return {
          'status': appLocalizations.ongoing,
          'color': AppColors.primary,
          'statusEnum': CourseStatus.Ongoing,
        };
      } else {
        return {
          'status': appLocalizations.upcoming,
          'color': AppColors.primary,
          'statusEnum': CourseStatus.Upcoming,
        };
      }
    } catch (e) {
      return {
        'status': appLocalizations.scheduled,
        'color': Colors.grey,
        'statusEnum': CourseStatus.Upcoming,
      };
    }
  }

  int get submittedAssignmentsCount {
    if (_dashboardData == null) return 0;
    return _dashboardData!.reportsByTeacher
        .expand((report) => report.grades)
        .where((grade) => grade.submitted == true)
        .length;
  }

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
    final appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo_bg.png'),
        ),
        title: Text(
          appLocalizations.appName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: theme.textTheme.bodyLarge!.color,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.iconTheme.color),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : _dashboardData != null &&
                _dashboardData!.reportsByTeacher.isNotEmpty
          ? RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: _buildDashboardContent(appLocalizations, theme),
              ),
            )
          : Center(child: Text(appLocalizations.noStudentDataContactTeacher)),
    );
  }

  Widget _buildDashboardContent(
    AppLocalizations appLocalizations,
    ThemeData theme,
  ) {
    final sortedTodaySchedule = todayScheduleEntries;
    sortedTodaySchedule.sort((a, b) {
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
        _buildUserInfoSection(appLocalizations, theme),
        const SizedBox(height: 20),
        Text(
          appLocalizations.reports,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildSummaryCard(
                title: appLocalizations.attendance,
                value:
                    '$overallAttendancePercentage% ${appLocalizations.present}',
                description: '$totalAttendanceDays ${appLocalizations.days}',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          appLocalizations.todaysCourses,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (sortedTodaySchedule.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(appLocalizations.noCoursesScheduled),
            ),
          )
        else
          ...sortedTodaySchedule.map((entry) {
            final statusDetails = _getCourseStatusDetails(
              entry,
              appLocalizations,
            );
            String timeAndLocation = entry.time;
            if (entry.location.isNotEmpty)
              timeAndLocation += ' - ${entry.location}';
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
        const SizedBox(height: 20),
        Text(
          appLocalizations.assignmentsBySubject,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          height: 150,
          child: reportsWithGradedAssignments.isEmpty
              ? Center(child: Text(appLocalizations.noAssignmentsFound))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: reportsWithGradedAssignments.length,
                  itemBuilder: (context, index) {
                    final report = reportsWithGradedAssignments[index];
                    final gradedAssignments = report.grades
                        .where((g) => g.score != null)
                        .toList();
                    gradedAssignments.sort((a, b) => b.date.compareTo(a.date));
                    final latestGrade = gradedAssignments.first.score;

                    return _buildSubjectAssignmentCell(
                      subject: report.subject,
                      teacher: report.teacherName,
                      percentage: latestGrade ?? 0,
                      allGrades: report.grades,
                      appLocalizations: appLocalizations,
                    );
                  },
                ),
        ),
        const SizedBox(height: 20),
        Text(
          appLocalizations.attendanceBySubject,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          height: 150,
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
    ThemeData theme,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${appLocalizations.helloParent}, ${_dashboardData?.studentName ?? "Student"}\'s parent!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  appLocalizations.latestReportGreeting,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String description,
    required Color color,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
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
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
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

  Widget _buildSubjectAssignmentCell({
    required String subject,
    required String teacher,
    required int percentage,
    required List<GradeRecord> allGrades,
    required AppLocalizations appLocalizations,
  }) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              AssignmentDetailsScreen(subject: subject, grades: allGrades),
        ),
      ),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 15),
        child: GlassCard(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                teacher,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                        '$percentage%',
                        style: TextStyle(
                          color: percentage >= 70
                              ? Colors.green
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        appLocalizations.latest,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
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
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AttendanceDetailsScreen(
            subject: subject,
            attendanceRecords: allAttendance,
          ),
        ),
      ),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 15),
        child: GlassCard(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                teacher,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                        '$percentage%',
                        style: TextStyle(
                          color: percentage >= 90
                              ? Colors.green
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        appLocalizations.present,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
