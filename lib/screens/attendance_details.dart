import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/l10n/app_localizations.dart'; // استيراد الترجمة

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
    final appLocalizations = AppLocalizations.of(context)!;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    // ترتيب السجلات من الأحدث للأقدم
    attendanceRecords.sort((a, b) => b.date.compareTo(a.date));

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
          appLocalizations.attendanceForSubject(subject),
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
                appLocalizations.detailedAttendanceForSubject(subject),
                style: AppTextStyles.heading1.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
              ),
            ),
            Expanded(
              child: attendanceRecords.isEmpty
                  ? Center(child: Text(appLocalizations.noAttendanceFound, style: AppTextStyles.secondaryText))
                  : ListView.builder(
                      itemCount: attendanceRecords.length,
                      itemBuilder: (context, index) {
                        final record = attendanceRecords[index];
                        final isPresent = record.status.toLowerCase() == 'present';
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
                                Text(
                                  '${appLocalizations.dateLabel} ${record.date}',
                                  style: AppTextStyles.bodyText.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Theme.of(context).textTheme.bodyLarge!.color,
                                  ),
                                ),
                                Text(
                                  isPresent ? appLocalizations.presentStatus : appLocalizations.absentStatus,
                                  style: AppTextStyles.bodyText.copyWith(
                                    color: isPresent ? AppColors.greenSuccess : AppColors.primaryYello,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
