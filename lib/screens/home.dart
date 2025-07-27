import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart'; // Adjust import path
import 'package:learnaria/screens/assignment_details.dart'; // Import assignment details screen
import 'package:learnaria/screens/attendance_details.dart'; // Import attendance details screen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Adjust padding to move the logo slightly to the right from the edge
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 4.0), // Increased left padding
          child: Image.asset(
            'assets/images/logo.png', // Replace with your actual logo path
            height: 30, // Keep original height or adjust as needed
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.school, color: AppColors.primaryYello);
            },
          ),
        ),
        title: Text(
          '  Learnaria', // Or 'Home - Student' based on context
          style: AppTextStyles.heading2.copyWith(color: AppColors.primaryBlack),
        ),
        centerTitle: false, // Ensures the title is aligned to the left
        titleSpacing: 0, // Reduces the default spacing between leading and title
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Section - Same as in the image
            _buildUserInfoSection(context),
            SizedBox(height: 20),

            // Reports Section (Assignments & Attendance Summary)
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
                    value: '5',
                    description: '7 Subjects',
                    color: AppColors.primaryYello,
                    onTap: () {
                      // Navigate to a general assignments overview or first subject's assignments
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
                    value: '95%',
                    description: '24 days',
                    color: AppColors.greenSuccess,
                    onTap: () {
                      // Navigate to a general attendance overview
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Attendance Overview Tapped')),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Feature 1: Upcoming Classes (Today's Courses)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Courses',
                  style: AppTextStyles.heading2,
                ),
              ],
            ),
            SizedBox(height: 10),
            _buildCourseCard(
              context,
              subject: 'Arabic',
              time: '10:00 - 12:00',
              status: 'Ongoing',
              statusColor: Colors.green,
            ),
            SizedBox(height: 10),
            _buildCourseCard(
              context,
              subject: 'Math',
              time: '12:30 - 2:00',
              status: 'Upcoming',
              statusColor: AppColors.primaryYello,
            ),
            SizedBox(height: 20),

            // Feature 2: Assignments per Subject (Horizontal Scroll)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assignments by Subject',
                  style: AppTextStyles.heading2,
                ),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 120, // Give a fixed height for horizontal ListView
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildSubjectAssignmentCell(context, 'Arabic', 95),
                  SizedBox(width: 15),
                  _buildSubjectAssignmentCell(context, 'English', 74),
                  SizedBox(width: 15),
                  _buildSubjectAssignmentCell(context, 'Science', 88),
                  SizedBox(width: 15),
                  _buildSubjectAssignmentCell(context, 'History', 65), // Added more for scroll
                  SizedBox(width: 15),
                  _buildSubjectAssignmentCell(context, 'Art', 90),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Feature 3: Attendance per Subject (Horizontal Scroll)
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
              height: 120, // Give a fixed height for horizontal ListView
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildSubjectAttendanceCell(context, 'Arabic', 98),
                  SizedBox(width: 15),
                  _buildSubjectAttendanceCell(context, 'English', 90),
                  SizedBox(width: 15),
                  _buildSubjectAttendanceCell(context, 'Science', 92),
                  SizedBox(width: 15),
                  _buildSubjectAttendanceCell(context, 'History', 85), // Added more for scroll
                  SizedBox(width: 15),
                  _buildSubjectAttendanceCell(context, 'Art', 99),
                ],
              ),
            ),
            SizedBox(height: 20), // Reduced space as bottom nav is external
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context) {
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
                'Hello, Mr. Mohamed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'Today, 18th September',
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
          child: Image.asset('assets/images/notification-bell.png', height: 24, width: 24, errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.notifications, color: Colors.grey[600]);
          }),
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
        width: 180, // Fixed width for horizontal cells
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
        child: Column( // Changed to Column for internal layout
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
          children: [
            Text(
              subject,
              style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Assignment Progress',
              style: AppTextStyles.secondaryText,
            ),
            Spacer(), // Pushes percentage and arrow to bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$percentage%',
                  style: AppTextStyles.heading2.copyWith(color: percentage >= 70 ? AppColors.greenSuccess : AppColors.primaryYello),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mediumGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectAttendanceCell(BuildContext context, String subject, int percentage) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AttendanceDetailsScreen(subject: subject),
          ),
        );
      },
      child: Container(
        width: 180, // Fixed width for horizontal cells
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
        child: Column( // Changed to Column for internal layout
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
          children: [
            Text(
              subject,
              style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Attendance Rate',
              style: AppTextStyles.secondaryText,
            ),
            Spacer(), // Pushes percentage and arrow to bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$percentage%',
                  style: AppTextStyles.heading2.copyWith(color: percentage >= 90 ? AppColors.greenSuccess : AppColors.primaryYello),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mediumGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
