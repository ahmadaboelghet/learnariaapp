import 'package:flutter_test/flutter_test.dart';
import 'package:learnaria/models/dashboard_data.dart';

void main() {
  group('Dashboard Data Models Tests', () {
    test('ScheduleEntry.fromFirestore parses map correctly', () {
      final mapData = {
        'subject': 'Math',
        'time': '10:00 AM',
        'date': '2026-07-09',
        'location': 'Room 101'
      };

      final entry = ScheduleEntry.fromFirestore(mapData);

      expect(entry.subject, 'Math');
      expect(entry.time, '10:00 AM');
      expect(entry.date, '2026-07-09');
      expect(entry.location, 'Room 101');
    });

    test('ScheduleEntry.fromFirestore handles missing data with defaults', () {
      final mapData = <String, dynamic>{};

      final entry = ScheduleEntry.fromFirestore(mapData);

      expect(entry.subject, 'N/A');
      expect(entry.time, 'N/A');
      expect(entry.date, 'N/A');
      expect(entry.location, 'N/A');
    });

    test('ScheduleEntry.copyWith modifies specified fields only', () {
      final entry = ScheduleEntry(
        subject: 'Math',
        time: '10:00 AM',
        date: '2026-07-09',
        location: 'Room 101'
      );

      final updatedEntry = entry.copyWith(time: '11:00 AM', location: 'Room 102');

      expect(updatedEntry.subject, 'Math');
      expect(updatedEntry.time, '11:00 AM');
      expect(updatedEntry.date, '2026-07-09');
      expect(updatedEntry.location, 'Room 102');
    });
  });
}
