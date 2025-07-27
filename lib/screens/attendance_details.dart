import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart'; // Adjust import path

class AttendanceDetailsScreen extends StatelessWidget {
  final String subject;

  const AttendanceDetailsScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    // Dummy data for demonstration
    final List<Map<String, dynamic>> attendanceRecords = [
      {'date': '2024-07-01', 'status': 'Present', 'notes': ''},
      {'date': '2024-07-03', 'status': 'Absent', 'notes': 'Sick leave'},
      {'date': '2024-07-05', 'status': 'Present', 'notes': ''},
      {'date': '2024-07-08', 'status': 'Late', 'notes': 'Traffic delay'},
      {'date': '2024-07-10', 'status': 'Present', 'notes': ''},
      {'date': '2024-07-12', 'status': 'Present', 'notes': ''},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryBlack),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          '$subject Attendance',
          style: AppTextStyles.heading2,
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Attendance Records for $subject',
              style: AppTextStyles.heading1,
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: attendanceRecords.length,
                itemBuilder: (context, index) {
                  final record = attendanceRecords[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date: ${record['date']}',
                            style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Status: ${record['status']}',
                                style: AppTextStyles.bodyText.copyWith(
                                  color: record['status'] == 'Present'
                                      ? AppColors.greenSuccess
                                      : (record['status'] == 'Absent' ? AppColors.primaryYello : Colors.orange),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (record['notes'].isNotEmpty)
                                Text(
                                  'Notes: ${record['notes']}',
                                  style: AppTextStyles.secondaryText,
                                ),
                            ],
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
