import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/models/dashboard_data.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/widgets/glass_container.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    // Sort records from newest to oldest
    attendanceRecords.sort((a, b) => b.date.compareTo(a.date));

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
            appLocalizations.attendanceForSubject(subject),
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
                  appLocalizations.detailedAttendanceForSubject(subject),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              Expanded(
                child: attendanceRecords.isEmpty
                    ? Center(
                        child: Text(
                          appLocalizations.noAttendanceFound,
                          style: AppTextStyles.secondaryText,
                        ),
                      )
                    : ListView.builder(
                        itemCount: attendanceRecords.length,
                        itemBuilder: (context, index) {
                          final record = attendanceRecords[index];
                          final isPresent = record.status.toLowerCase() == 'present';
                          final Color statusColor = isPresent ? AppColors.greenSuccess : AppColors.errorRed;
    
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Leading status icon with soft circular background
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPresent ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                                      color: statusColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  
                                  // Date info
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 14,
                                          color: isDark ? Colors.white38 : Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          record.date,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isPresent ? appLocalizations.presentStatus : appLocalizations.absentStatus,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
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
