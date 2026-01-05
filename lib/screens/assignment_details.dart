import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/widgets/glass_card.dart';

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
    grades.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          appLocalizations.assignmentsForSubject(subject),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: grades.isEmpty
                  ? Center(child: Text(appLocalizations.noAssignmentsFound))
                  : ListView.builder(
                      itemCount: grades.length,
                      itemBuilder: (context, index) {
                        final assignment = grades[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        assignment.assignmentName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${appLocalizations.dateLabel} ${assignment.date}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
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
                                      style: TextStyle(
                                        color: (assignment.score ?? 0) >= 70
                                            ? Colors.green
                                            : AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      assignment.submitted
                                          ? 'تم التسليم'
                                          : 'لم يسلم',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: assignment.submitted
                                            ? Colors.green
                                            : Colors.orange,
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
