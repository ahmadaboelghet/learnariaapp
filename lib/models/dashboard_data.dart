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

  List<GradeRecord> get homeworks => grades.where((g) => g.isHomework).toList();
  List<GradeRecord> get exams => grades.where((g) => g.isExam).toList();

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
  final num? score; // Can be decimal like 19.5 or integer
  final String date;
  final bool submitted; // To track if the assignment was handed in
  final num totalMark;
  final String? type; // 'exam' or 'homework'

  GradeRecord({
    required this.studentName,
    required this.assignmentName,
    this.score,
    required this.date,
    required this.submitted,
    this.totalMark = 30, // Default to 30 as configured in the system
    this.type,
  });

  String get scoreFormatted {
    if (score == null) return '';
    return score! % 1 == 0 ? score!.toInt().toString() : score!.toString();
  }

  String get totalMarkFormatted {
    return totalMark % 1 == 0 ? totalMark.toInt().toString() : totalMark.toString();
  }

  bool get isHomework {
    if (type == 'homework') return true;
    if (type == 'exam') return false;
    final name = assignmentName.toLowerCase();
    if (name.contains('واجب') || name.contains('hw') || name.contains('homework')) return true;
    return false;
  }

  bool get isExam {
    if (type == 'exam') return true;
    if (type == 'homework') return false;
    final name = assignmentName.toLowerCase();
    if (name.contains('امتحان') ||
        name.contains('اختبار') ||
        name.contains('شامل') ||
        name.contains('quiz') ||
        name.contains('exam') ||
        name.contains('test')) {
      return true;
    }
    return !isHomework;
  }
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