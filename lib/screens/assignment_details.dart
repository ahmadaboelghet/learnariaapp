import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/widgets/glass_container.dart';

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
    final appLocalizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final locale = Localizations.localeOf(context).languageCode;

    grades.sort((a, b) => b.date.compareTo(a.date));

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            appLocalizations.assignmentsForSubject(subject),
            style: AppTextStyles.heading2.copyWith(color: textColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 16.0),
                child: Text(
                  appLocalizations.detailedGradesForSubject(subject),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              Expanded(
                child: grades.isEmpty
                    ? Center(
                        child: Text(
                          appLocalizations.noAssignmentsFound,
                          style: AppTextStyles.secondaryText,
                        ),
                      )
                    : ListView.builder(
                        itemCount: grades.length,
                        itemBuilder: (context, index) {
                          final assignment = grades[index];
                          final isGraded = assignment.score != null;
                          final score = assignment.score ?? 0;
    
                          // Dynamic badge color for grade
                          final Color gradeColor = score >= 85
                              ? AppColors.greenSuccess
                              : (score >= 65 ? AppColors.darkGrey : AppColors.errorRed);
    
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Leading assignment icon with subtle background
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: gradeColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.assignment_outlined,
                                      color: gradeColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  
                                  // Assignment info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          assignment.assignmentName,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 12,
                                              color: isDark ? Colors.white38 : Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              assignment.date,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? Colors.white38 : Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Submission badge (only for homework)
                                            if (assignment.assignmentName.contains("واجب"))
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: assignment.submitted
                                                      ? AppColors.greenSuccess.withOpacity(0.08)
                                                      : Colors.orange.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  assignment.submitted
                                                      ? (locale == 'ar' ? 'تم التسليم' : 'Submitted')
                                                      : (locale == 'ar' ? 'لم يسلم' : 'Pending'),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: assignment.submitted ? AppColors.greenSuccess : Colors.orange,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  
                                  // Grade display
                                  if (isGraded || !assignment.assignmentName.contains("واجب"))
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isGraded ? gradeColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isGraded ? '$score/${assignment.totalMark}' : (locale == 'ar' ? 'لم ترصد' : 'Not graded'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isGraded ? gradeColor : Colors.grey,
                                        ),
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
      ),
    );
  }
}