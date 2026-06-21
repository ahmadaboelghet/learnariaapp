class DashboardData {
  final String studentName;
  final List<TeacherReport> reportsByTeacher;

  DashboardData({required this.studentName, required this.reportsByTeacher});
}

class TeacherReport {
  final String teacherId;
  final String teacherName;
  final String subject;
  final List<AttendanceRecord> attendance;
  final List<GradeRecord> grades;
  final List<ScheduleEntry> schedule;
  final List<PaymentRecord> payments;

  TeacherReport({
    required this.teacherId,
    required this.teacherName,
    required this.subject,
    required this.attendance,
    required this.grades,
    required this.schedule,
    required this.payments,
  });
}

class PaymentRecord {
  final String month;
  final bool paid;
  final String amount;
  final String date;
  final String receipt;

  PaymentRecord({
    required this.month,
    required this.paid,
    required this.amount,
    required this.date,
    required this.receipt,
  });
}

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

class GradeRecord {
  final String studentName;
  final String assignmentName;
  final int? score; // Can be null if not graded yet
  final String date;
  final bool submitted; // To track if the assignment was handed in

  GradeRecord({
    required this.studentName,
    required this.assignmentName,
    this.score,
    required this.date,
    required this.submitted,
  });
}

class ScheduleEntry {
  final String subject;
  final String time;
  final String date;
  final String location;

  ScheduleEntry({
    required this.subject,
    required this.time,
    required this.date,
    required this.location,
  });

  factory ScheduleEntry.fromFirestore(Map<String, dynamic> data) {
    return ScheduleEntry(
      subject: data['subject'] ?? 'N/A',
      time: data['time'] ?? 'N/A',
      date: data['date'] ?? 'N/A',
      location: data['location'] ?? 'N/A',
    );
  }

  ScheduleEntry copyWith({
    String? subject,
    String? time,
    String? date,
    String? location,
  }) {
    return ScheduleEntry(
      subject: subject ?? this.subject,
      time: time ?? this.time,
      date: date ?? this.date,
      location: location ?? this.location,
    );
  }
}