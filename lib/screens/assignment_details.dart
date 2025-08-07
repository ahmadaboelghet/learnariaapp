import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/models/dashboard_data.dart';

class AssignmentDetailsScreen extends StatelessWidget {
  final String subject;
  final List<GradeRecord> grades;

  const AssignmentDetailsScreen({
    super.key,
    required this.subject,
    required this.grades,
  });

  @override
  Widget build(BuildContext context) {
    // ترتيب الواجبات من الأحدث للأقدم
    grades.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8), // لون خلفية فاتح جدًا لإبراز البطاقات
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('$subject Assignments', style: AppTextStyles.heading2),
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
                'Detailed Assignment Grades for $subject',
                style: AppTextStyles.heading1,
              ),
            ),
            Expanded(
              child: grades.isEmpty
                  ? Center(child: Text('No assignments found for this subject.', style: AppTextStyles.secondaryText))
                  : ListView.builder(
                      itemCount: grades.length,
                      itemBuilder: (context, index) {
                        final assignment = grades[index];
                        // استخدام تصميم البطاقة الجديد هنا
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 3,
                          shadowColor: Colors.grey.withOpacity(0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          color: Colors.white, // --- تم إضافة هذا السطر لضمان اللون الأبيض ---
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  assignment.assignmentName,
                                  style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Date: ${assignment.date}',
                                      style: AppTextStyles.secondaryText,
                                    ),
                                    Text(
                                      'Grade: ${assignment.score}%',
                                      style: AppTextStyles.bodyText.copyWith(
                                        color: assignment.score >= 70 ? AppColors.greenSuccess : AppColors.primaryYello,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16
                                      ),
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