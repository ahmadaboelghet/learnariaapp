import 'package:flutter_test/flutter_test.dart';
import 'package:learnaria/models/dashboard_data.dart';

// A mock logic testing for overall grade calculation to ensure 30% attendance, 30% homework, 40% exams works correctly.
int calculateOverallGrade({
  required List<AttendanceRecord> attendance,
  required List<GradeRecord> grades,
}) {
  // 1. Attendance (30%)
  final totalAttendance = attendance.length;
  final presentAttendance = attendance.where((a) => a.status.toLowerCase() == 'present').length;
  final attendanceRate = totalAttendance > 0 ? (presentAttendance / totalAttendance * 100) : 0.0;

  // 2. Homework (30%)
  final totalHW = grades.length;
  final submittedHW = grades.where((g) => g.submitted).length;
  final homeworkRate = totalHW > 0 ? (submittedHW / totalHW * 100) : 0.0;

  // 3. Exams (40%)
  final graded = grades.where((g) => g.score != null).toList();
  final examAverage = graded.isNotEmpty
      ? (graded.map((g) => g.score!).reduce((a, b) => a + b) / graded.length)
      : 0.0;

  final double subjectScore = (attendanceRate * 0.3) + (homeworkRate * 0.3) + (examAverage * 0.4);
  return subjectScore.toInt();
}

void main() {
  group('Overall Grade Calculation Tests', () {
    test('Calculates 100% when everything is perfect', () {
      final attendance = [
        AttendanceRecord(studentName: 'Tarek', date: '2026-07-01', status: 'present'),
        AttendanceRecord(studentName: 'Tarek', date: '2026-07-02', status: 'present'),
      ];
      final grades = [
        GradeRecord(studentName: 'Tarek', assignmentName: 'HW 1', score: 100, date: '2026-07-01', submitted: true),
        GradeRecord(studentName: 'Tarek', assignmentName: 'Exam 1', score: 100, date: '2026-07-02', submitted: true),
      ];

      final result = calculateOverallGrade(attendance: attendance, grades: grades);
      expect(result, 100);
    });

    test('Calculates correct weighted score with mixed data', () {
      // Attendance: 1 present, 1 absent = 50% attendance rate. Weight 30% -> 15 points
      final attendance = [
        AttendanceRecord(studentName: 'Tarek', date: '2026-07-01', status: 'present'),
        AttendanceRecord(studentName: 'Tarek', date: '2026-07-02', status: 'absent'),
      ];

      // Homework: 2 total, 1 submitted = 50% homework rate. Weight 30% -> 15 points
      // Exams: 1 graded with 80 score = 80 average. Weight 40% -> 32 points
      // Total expected = 15 + 15 + 32 = 62%
      final grades = [
        GradeRecord(studentName: 'Tarek', assignmentName: 'HW 1', score: null, date: '2026-07-01', submitted: true),
        GradeRecord(studentName: 'Tarek', assignmentName: 'HW 2', score: 80, date: '2026-07-02', submitted: false),
      ];

      final result = calculateOverallGrade(attendance: attendance, grades: grades);
      expect(result, 62);
    });

    test('Returns 0 when data is empty to prevent division by zero', () {
      final result = calculateOverallGrade(attendance: [], grades: []);
      expect(result, 0);
    });
  });
}
