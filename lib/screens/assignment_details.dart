import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/l10n/app_localizations.dart';

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
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    grades.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          appLocalizations.assignmentsForSubject(subject),
          style: AppTextStyles.heading2.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
        ),
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
                appLocalizations.detailedGradesForSubject(subject),
                style: AppTextStyles.heading1.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
              ),
            ),
            Expanded(
              child: grades.isEmpty
                  ? Center(child: Text(appLocalizations.noAssignmentsFound, style: AppTextStyles.secondaryText))
                  : ListView.builder(
                      itemCount: grades.length,
                      itemBuilder: (context, index) {
                        final assignment = grades[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: isLightMode ? 3 : 1,
                          shadowColor: Colors.grey.withOpacity(0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          color: Theme.of(context).cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        assignment.assignmentName,
                                        style: AppTextStyles.bodyText.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Theme.of(context).textTheme.bodyLarge!.color,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${appLocalizations.dateLabel} ${assignment.date}',
                                        style: AppTextStyles.secondaryText,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      assignment.score != null
                                          ? '${appLocalizations.gradeLabel} ${assignment.score}'
                                          : 'لم ترصد',
                                      style: AppTextStyles.bodyText.copyWith(
                                        color: (assignment.score ?? 0) >= 70
                                            ? AppColors.greenSuccess
                                            : AppColors.primaryYello,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      assignment.submitted ? 'تم التسليم' : 'لم يسلم',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: assignment.submitted
                                            ? AppColors.greenSuccess
                                            : Colors.orange,
                                      ),
                                    ),
                                  ],
                                )
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