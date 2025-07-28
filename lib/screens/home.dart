import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/screens/assignment_details.dart';
import 'package:learnaria/screens/attendance_details.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/services/firestore_api.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NEW: Import Firebase Auth

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String _errorMessage = '';
  // Removed: final TextEditingController _parentPhoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Removed: _parentPhoneNumberController.addListener(_onParentPhoneNumberChanged);
    _fetchData(); // Initial data fetch
  }

  // Removed: _onParentPhoneNumberChanged()

  @override
  void dispose() {
    // Removed: _parentPhoneNumberController.removeListener(_onParentPhoneNumberChanged);
    // Removed: _parentPhoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _dashboardData = null; // Clear previous data
    });

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.phoneNumber == null) {
      setState(() {
        _errorMessage = 'User not logged in or phone number not available.';
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await FirestoreApi().fetchDashboardData(
        parentPhoneNumber: currentUser.phoneNumber!, // Use logged-in user's phone number
      );
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data. Please check your internet connection or Firebase setup. Error: $e';
        _isLoading = false;
        print('Error in _fetchData: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 4.0),
          child: Image.asset(
            'assets/images/learnaria_logo.png',
            height: 30,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.school, color: AppColors.primaryYello);
            },
          ),
        ),
        title: Text(
          'Home - Parent',
          style: AppTextStyles.heading2.copyWith(color: AppColors.primaryBlack),
        ),
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryBlack),
            onPressed: _fetchData,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: AppColors.primaryYello), // Logout button
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Will automatically navigate to LoginScreen via StreamBuilder in main.dart
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoSection(context),
            SizedBox(height: 20),

            // Removed: Parent Phone Number Input for Filtering
            // Text(
            //   'Enter Parent Phone Number:',
            //   style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
            // ),
            // SizedBox(height: 10),
            // CustomTextField(
            //   controller: _parentPhoneNumberController,
            //   hintText: 'e.g., +1234567890',
            //   prefixIcon: Icons.phone,
            //   keyboardType: TextInputType.phone,
            // ),
            // SizedBox(height: 20),

            _isLoading
                ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYello)))
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: AppColors.primaryYello, size: 50),
                              SizedBox(height: 10),
                              Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyText.copyWith(color: AppColors.primaryYello),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _fetchData,
                                style: primaryButtonStyle(),
                                child: Text('Retry', style: AppTextStyles.buttonText),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reports',
                            style: AppTextStyles.heading2,
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  context,
                                  title: 'Assignments',
                                  value: (_dashboardData?.grades.length ?? 0).toString(),
                                  description: '${_dashboardData?.grades.map((g) => g.subject).toSet().length ?? 0} Subjects',
                                  color: AppColors.primaryYello,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Assignments Overview Tapped')),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child: _buildSummaryCard(
                                  context,
                                  title: 'Attendance',
                                  value: '${_calculateAttendancePercentage()}%',
                                  description: '${_dashboardData?.attendance.length ?? 0} records',
                                  color: AppColors.greenSuccess,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Attendance Overview Tapped')),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Today\'s Courses',
                                style: AppTextStyles.heading2,
                              ),
                              Text(
                                'See All >',
                                style: AppTextStyles.secondaryText,
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          if ((_dashboardData?.schedule ?? []).isEmpty)
                            Center(child: Text('No schedule data available.', style: AppTextStyles.secondaryText))
                          else
                            ...(_dashboardData!.schedule.map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: _buildCourseCard(
                                    context,
                                    subject: entry.subject,
                                    time: '${entry.time} - ${entry.room}',
                                    status: 'Scheduled',
                                    statusColor: Colors.blue,
                                  ),
                                )).toList()),
                          SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Assignments by Subject',
                                style: AppTextStyles.heading2,
                              ),
                              Text(
                                'See All >',
                                style: AppTextStyles.secondaryText,
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            height: 120,
                            child: (_dashboardData?.grades ?? []).isEmpty
                                ? Center(child: Text('No assignment data available.', style: AppTextStyles.secondaryText))
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _dashboardData!.grades.length,
                                    itemBuilder: (context, index) {
                                      final grade = _dashboardData!.grades[index];
                                      return Padding(
                                        padding: EdgeInsets.only(right: 15.0),
                                        child: _buildSubjectAssignmentCell(
                                            context, grade.subject, grade.score),
                                      );
                                    },
                                  ),
                          ),
                          SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Attendance by Subject',
                                style: AppTextStyles.heading2,
                              ),
                              Text(
                                'See All >',
                                style: AppTextStyles.secondaryText,
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            height: 120,
                            child: (_dashboardData?.attendance ?? []).isEmpty
                                ? Center(child: Text('No attendance data available.', style: AppTextStyles.secondaryText))
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _dashboardData!.attendance.length,
                                    itemBuilder: (context, index) {
                                      final attendance = _dashboardData!.attendance[index];
                                      int percentage = attendance.status == 'present' ? 100 : (attendance.status == 'late' ? 80 : 0);
                                      return Padding(
                                        padding: EdgeInsets.only(right: 15.0),
                                        child: _buildSubjectAttendanceCell(
                                            context, attendance.studentName, percentage),
                                      );
                                    },
                                  ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
          ],
        ),
      ),
    );
  }

  int _calculateAttendancePercentage() {
    if (_dashboardData == null || _dashboardData!.attendance.isEmpty) {
      return 0;
    }
    final totalRecords = _dashboardData!.attendance.length;
    final presentCount = _dashboardData!.attendance.where((r) => r.status == 'present').length;
    return ((presentCount / totalRecords) * 100).toInt();
  }

  Widget _buildUserInfoSection(BuildContext context) {
    // Get current user's phone number if available
    final String? userPhoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;
    final String displayPhoneNumber = userPhoneNumber ?? 'N/A';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[200],
          child: Icon(Icons.person, color: Colors.grey[600]),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Parent!', // Generic greeting
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                displayPhoneNumber, // Display logged-in user's phone number
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Today, 18th September', // Dynamically update this if needed
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.settings_outlined, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, {
    required String title,
    required String value,
    required String description,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              value,
              style: AppTextStyles.heading1.copyWith(color: color),
            ),
            Text(
              description,
              style: AppTextStyles.secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, {
    required String subject,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  time,
                  style: AppTextStyles.secondaryText,
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: AppTextStyles.smallRedText.copyWith(color: statusColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildSubjectAssignmentCell(BuildContext context, String subject, int percentage) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AssignmentDetailsScreen(subject: subject),
          ),
        );
      },
      child: Container(
        width: 180,
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subject,
              style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Assignment Progress',
              style: AppTextStyles.secondaryText,
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$percentage%',
                  style: AppTextStyles.heading2.copyWith(color: percentage >= 70 ? AppColors.greenSuccess : AppColors.primaryYello),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectAttendanceCell(BuildContext context, String studentName, int percentage) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AttendanceDetailsScreen(subject: studentName),
          ),
        );
      },
      child: Container(
        width: 180,
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              studentName,
              style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Attendance Rate',
              style: AppTextStyles.secondaryText,
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$percentage%',
                  style: AppTextStyles.heading2.copyWith(color: percentage >= 90 ? AppColors.greenSuccess : AppColors.primaryYello),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
