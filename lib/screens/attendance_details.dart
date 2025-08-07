import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/models/dashboard_data.dart';

class AttendanceDetailsScreen extends StatelessWidget {
  final String subject;
  final List<AttendanceRecord> attendanceRecords;

  const AttendanceDetailsScreen({
    super.key,
    required this.subject,
    required this.attendanceRecords,
  });

  @override
  Widget build(BuildContext context) {
    // ترتيب السجلات من الأحدث للأقدم
    attendanceRecords.sort((a, b) => b.date.compareTo(a.date));

    // دالة لتحديد اللون بناءً على الحالة
    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'present':
          return AppColors.greenSuccess;
        case 'late':
          return Colors.orange;
        case 'absent':
          return AppColors.primaryYello;
        default:
          return AppColors.darkGrey;
      }
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('$subject Attendance', style: AppTextStyles.heading2),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
              child: Text(
                'Detailed Attendance Records for $subject',
                style: AppTextStyles.heading1,
              ),
            ),
            Expanded(
              child: attendanceRecords.isEmpty
                  ? Center(child: Text('No attendance records found for this subject.', style: AppTextStyles.secondaryText))
                  : ListView.builder(
                      itemCount: attendanceRecords.length,
                      itemBuilder: (context, index) {
                        final record = attendanceRecords[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 3,
                          shadowColor: Colors.grey.withOpacity(0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Date: ${record.date}',
                                  style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  record.status.toUpperCase(),
                                  style: AppTextStyles.bodyText.copyWith(
                                    color: getStatusColor(record.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}