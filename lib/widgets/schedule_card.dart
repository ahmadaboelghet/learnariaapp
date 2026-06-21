import 'package:flutter/material.dart';
import 'package:learnaria/models/dashboard_data.dart';

class ScheduleCard extends StatelessWidget {
  final ScheduleEntry schedule;

  const ScheduleCard({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schedule.subject,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_filled, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  schedule.time,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ==== بداية الكود الجديد لعرض المكان ====
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  schedule.location, // عرض قيمة المكان
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            // ==== نهاية الكود الجديد ====
          ],
        ),
      ),
    );
  }
}