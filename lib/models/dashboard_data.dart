class DashboardData {
  final String studentName;
  final List<TeacherReport> reportsByTeacher;

  DashboardData({required this.studentName, required this.reportsByTeacher});

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    var reportsList = (json['reportsByTeacher'] as List? ?? [])
        .map(
          (reportJson) =>
              TeacherReport.fromJson(reportJson as Map<String, dynamic>),
        )
        .toList();
    return DashboardData(
      studentName: json['studentName'] as String,
      reportsByTeacher: reportsList,
    );
  }
}

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

  // --- [جديد] ---
  factory TeacherReport.fromJson(Map<String, dynamic> json) {
    return TeacherReport(
      teacherId: json['teacherId'] as String,
      teacherName: json['teacherName'] as String,
      subject: json['subject'] as String,
      attendance: (json['attendance'] as List? ?? [])
          .map((att) => AttendanceRecord.fromJson(att as Map<String, dynamic>))
          .toList(),
      grades: (json['grades'] as List? ?? [])
          .map((g) => GradeRecord.fromJson(g as Map<String, dynamic>))
          .toList(),
      schedule: (json['schedule'] as List? ?? [])
          .map((s) => ScheduleEntry.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
  // --- [نهاية الجديد] ---
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

  // --- [جديد] ---
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      studentName: json['studentName'] as String,
      date: json['date'] as String,
      status: json['status'] as String,
    );
  }
  // --- [نهاية الجديد] ---
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

  // --- [جديد] ---
  factory GradeRecord.fromJson(Map<String, dynamic> json) {
    // لوجيك احتياطي عشان الدرجة ممكن تيجي رقم أو سترنج أو null من السيرفر
    final scoreValue = json['score'];
    int? finalScore;
    if (scoreValue is num) {
      finalScore = scoreValue.toInt();
    } else if (scoreValue is String && scoreValue.isNotEmpty) {
      finalScore = int.tryParse(scoreValue);
    }

    return GradeRecord(
      studentName: json['studentName'] as String,
      assignmentName: json['assignmentName'] as String,
      score: finalScore,
      date: json['date'] as String,
      submitted: json['submitted'] as bool? ?? false,
    );
  }
  // --- [نهاية الجديد] ---
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

  // --- [تم التعديل] ---
  // غيرنا اسم الفاكتوري بتاعك من fromFirestore لـ fromJson
  // عشان الكود الجديد يقدر يستدعيه
  factory ScheduleEntry.fromJson(Map<String, dynamic> data) {
    return ScheduleEntry(
      subject: data['subject'] ?? 'N/A',
      time: data['time'] ?? 'N/A',
      date: data['date'] ?? 'N/A',
      location: data['location'] ?? 'N/A',
    );
  }
  // --- [نهاية التعديل] ---

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
