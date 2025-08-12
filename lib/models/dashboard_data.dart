// Model for Attendance Records
class AttendanceRecord {
  final String studentName;
  final String date;
  final String status;

  AttendanceRecord({
    required this.studentName,
    required this.date,
    required this.status,
  });
}

// Model for Grade Records
class GradeRecord {
  final String studentName;
  final String assignmentName;
  final int score;
  final String date;

  GradeRecord({
    required this.studentName,
    required this.assignmentName,
    required this.score,
    required this.date,
  });
}

// Model for Schedule Entries
class ScheduleEntry {
  final String subject;
  final String date;
  final String time;
  final String room;

  ScheduleEntry({
    required this.subject,
    required this.date,
    required this.time,
    required this.room,
  });

  factory ScheduleEntry.fromFirestore(Map<String, dynamic> data) {
    return ScheduleEntry(
      subject: data['subject'] as String? ?? 'N/A',
      date: data['date'] as String? ?? 'N/A',
      time: data['time'] as String? ?? 'N/A',
      room: data['room'] as String? ?? 'N/A',
    );
  }

  // --- NEW: copyWith method added to fix the error ---
  ScheduleEntry copyWith({
    String? subject,
    String? date,
    String? time,
    String? room,
  }) {
    return ScheduleEntry(
      subject: subject ?? this.subject,
      date: date ?? this.date,
      time: time ?? this.time,
      room: room ?? this.room,
    );
  }
}

// Model for Teacher's Report
class TeacherReport {
  final String teacherId;
  final String teacherName;
  final String subject;
  final List<AttendanceRecord> attendance;
  final List<GradeRecord> grades;
  final List<ScheduleEntry> schedule;

  TeacherReport({
    required this.teacherId,
    required this.teacherName,
    required this.subject,
    required this.attendance,
    required this.grades,
    required this.schedule,
  });
}

// Main Dashboard Data Model
class DashboardData {
  final String studentName;
  final List<TeacherReport> reportsByTeacher;

  DashboardData({
    required this.studentName,
    required this.reportsByTeacher,
  });
}