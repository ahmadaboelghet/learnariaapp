import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/widgets/glass_card.dart';

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
    attendanceRecords.sort((a, b) => b.date.compareTo(a.date));

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
          appLocalizations.attendanceForSubject(subject),
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
                appLocalizations.detailedAttendanceForSubject(subject),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: attendanceRecords.isEmpty
                  ? Center(child: Text(appLocalizations.noAttendanceFound))
                  : ListView.builder(
                      itemCount: attendanceRecords.length,
                      itemBuilder: (context, index) {
                        final record = attendanceRecords[index];
                        final isPresent =
                            record.status.toLowerCase() == 'present';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${appLocalizations.dateLabel} ${record.date}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  isPresent
                                      ? appLocalizations.presentStatus
                                      : appLocalizations.absentStatus,
                                  style: TextStyle(
                                    color: isPresent
                                        ? Colors.green
                                        : AppColors.primary,
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
