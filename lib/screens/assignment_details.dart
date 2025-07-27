import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart'; // Adjust import path

class AssignmentDetailsScreen extends StatelessWidget {
  final String subject;

  const AssignmentDetailsScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    // Dummy data for demonstration
    final List<Map<String, dynamic>> assignments = [
      {'title': 'Homework 1', 'date': '2024-07-01', 'grade': 95, 'status': 'Submitted'},
      {'title': 'Quiz 1', 'date': '2024-07-10', 'grade': 88, 'status': 'Submitted'},
      {'title': 'Project Part 1', 'date': '2024-07-20', 'grade': 75, 'status': 'Submitted'},
      {'title': 'Final Exam', 'date': '2024-08-15', 'grade': null, 'status': 'Upcoming'},
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
          '$subject Assignments',
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
              'Detailed Assignment Grades for $subject',
              style: AppTextStyles.heading1,
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
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
                            assignment['title'],
                            style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Date: ${assignment['date']}',
                            style: AppTextStyles.secondaryText,
                          ),
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Status: ${assignment['status']}',
                                style: AppTextStyles.secondaryText.copyWith(
                                  color: assignment['status'] == 'Submitted' ? AppColors.greenSuccess : AppColors.primaryYello,
                                ),
                              ),
                              if (assignment['grade'] != null)
                                Text(
                                  'Grade: ${assignment['grade']}%',
                                  style: AppTextStyles.bodyText.copyWith(
                                    color: assignment['grade'] >= 70 ? AppColors.greenSuccess : AppColors.primaryYello,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else
                                Text(
                                  'Grade: N/A',
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
