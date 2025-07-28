
// Model for Attendance Records
class AttendanceRecord {
  final String studentName;
  final String date;
  final String status;
  final String parentPhoneNumber;
  final String studentId; // NEW: Added studentId to link records

  AttendanceRecord({
    required this.studentName,
    required this.date,
    required this.status,
    required this.parentPhoneNumber,
    required this.studentId,
  });

  // Factory constructor to create an AttendanceRecord from a Firestore map
  factory AttendanceRecord.fromFirestore(Map<String, dynamic> data, String studentId) {
    return AttendanceRecord(
      studentName: data['name'] as String? ?? 'N/A', // Assuming 'name' field in student doc
      date: data['date'] as String? ?? 'N/A',
      status: data['status'] as String? ?? 'N/A',
      parentPhoneNumber: data['parentPhoneNumber'] as String? ?? 'N/A',
      studentId: studentId, // Use the passed studentId
    );
  }
}

// Model for Grade Records
class GradeRecord {
  final String studentName;
  final String subject;
  final String assignmentName;
  final int score;
  final String parentPhoneNumber;
  final String studentId; // NEW: Added studentId to link records

  GradeRecord({
    required this.studentName,
    required this.subject,
    required this.assignmentName,
    required this.score,
    required this.parentPhoneNumber,
    required this.studentId,
  });

  // Factory constructor to create a GradeRecord from a Firestore map
  factory GradeRecord.fromFirestore(Map<String, dynamic> data, String studentId) {
    return GradeRecord(
      studentName: data['name'] as String? ?? 'N/A', // Assuming 'name' field in student doc
      subject: data['subject'] as String? ?? 'N/A',
      assignmentName: data['assignmentName'] as String? ?? 'N/A',
      score: (data['score'] as num?)?.toInt() ?? 0,
      parentPhoneNumber: data['parentPhoneNumber'] as String? ?? 'N/A',
      studentId: studentId, // Use the passed studentId
    );
  }
}

// Model for Schedule Entries
class ScheduleEntry {
  final String subject;
  final String date;
  final String time;
  final String room;
  final String parentPhoneNumber;
  final String studentId; // NEW: Added studentId if schedule is per student

  ScheduleEntry({
    required this.subject,
    required this.date,
    required this.time,
    required this.room,
    required this.parentPhoneNumber,
    required this.studentId,
  });

  // Factory constructor to create a ScheduleEntry from a Firestore map
  factory ScheduleEntry.fromFirestore(Map<String, dynamic> data, String studentId) {
    return ScheduleEntry(
      subject: data['subject'] as String? ?? 'N/A',
      date: data['date'] as String? ?? 'N/A',
      time: data['time'] as String? ?? 'N/A',
      room: data['room'] as String? ?? 'N/A',
      parentPhoneNumber: data['parentPhoneNumber'] as String? ?? 'N/A',
      studentId: studentId, // Use the passed studentId
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

  // No fromJson here as data is constructed from multiple Firestore queries
}
