
// Model for Attendance Records
class AttendanceRecord {
  final String studentName;
  final String date;
  final String status;
  final String parentPhoneNumber; // NEW: Added parent phone number

  AttendanceRecord({
    required this.studentName,
    required this.date,
    required this.status,
    required this.parentPhoneNumber,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      studentName: json['studentName'] as String? ?? 'N/A',
      date: json['date'] as String? ?? 'N/A',
      status: json['status'] as String? ?? 'N/A',
      parentPhoneNumber: json['parentPhoneNumber'] as String? ?? 'N/A', // Parse parentPhoneNumber
    );
  }
}

// Model for Grade Records
class GradeRecord {
  final String studentName;
  final String subject;
  final String assignmentName;
  final int score; // Changed to int
  final String parentPhoneNumber; // NEW: Added parent phone number

  GradeRecord({
    required this.studentName,
    required this.subject,
    required this.assignmentName,
    required this.score,
    required this.parentPhoneNumber,
  });

  factory GradeRecord.fromJson(Map<String, dynamic> json) {
    return GradeRecord(
      studentName: json['studentName'] as String? ?? 'N/A',
      subject: json['subject'] as String? ?? 'N/A',
      assignmentName: json['assignmentName'] as String? ?? 'N/A',
      score: (json['score'] as num?)?.toInt() ?? 0, // Handle int or double from JSON
      parentPhoneNumber: json['parentPhoneNumber'] as String? ?? 'N/A', // Parse parentPhoneNumber
    );
  }
}

// Model for Schedule Entries
class ScheduleEntry {
  final String subject;
  final String date;
  final String time;
  final String room;
  final String parentPhoneNumber; // NEW: Added parent phone number

  ScheduleEntry({
    required this.subject,
    required this.date,
    required this.time,
    required this.room,
    required this.parentPhoneNumber,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      subject: json['subject'] as String? ?? 'N/A',
      date: json['date'] as String? ?? 'N/A',
      time: json['time'] as String? ?? 'N/A',
      room: json['room'] as String? ?? 'N/A',
      parentPhoneNumber: json['parentPhoneNumber'] as String? ?? 'N/A', // Parse parentPhoneNumber
    );
  }
}

// Main Dashboard Data Model to hold all types of records
class DashboardData {
  final List<AttendanceRecord> attendance;
  final List<GradeRecord> grades;
  final List<ScheduleEntry> schedule;

  DashboardData({
    required this.attendance,
    required this.grades,
    required this.schedule,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      attendance: (json['attendance'] as List<dynamic>?)
              ?.map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      grades: (json['grades'] as List<dynamic>?)
              ?.map((item) => GradeRecord.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      schedule: (json['schedule'] as List<dynamic>?)
              ?.map((item) => ScheduleEntry.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
