import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnaria/models/dashboard_data.dart';

class FirestoreApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize Firebase (call this once, e.g., in main.dart)
  static Future<void> initializeFirebase() async {
    // This is now handled in main.dart directly
  }

  // Fetches all relevant dashboard data for the logged-in parent
  Future<DashboardData> fetchDashboardData({required String parentPhoneNumber}) async {
    // Get the current logged-in user's phone number if not provided
    final String? actualParentPhoneNumber = parentPhoneNumber; // Now parentPhoneNumber is always passed from HomeScreen

    if (actualParentPhoneNumber == null || actualParentPhoneNumber.isEmpty) {
      throw Exception('Parent phone number is required to fetch data.');
    }

    List<AttendanceRecord> attendanceRecords = [];
    List<GradeRecord> gradeRecords = [];
    List<ScheduleEntry> scheduleEntries = [];

    // --- Fetch Students associated with this parent phone number ---
    try {
      // Find all students belonging to this teacher (teacher_001) with the given parentPhoneNumber
      // This assumes parentPhoneNumber is indexed in Firestore for efficient querying.
      // You might need to create a composite index in Firebase Console if you query by teacherId and parentPhoneNumber.
      final studentsSnapshot = await _firestore
          .collection('teachers')
          .doc('teacher_001') // IMPORTANT: Replace with dynamic teacher ID if authentication is implemented for teachers
          .collection('students')
          .where('parentPhoneNumber', isEqualTo: actualParentPhoneNumber)
          .get();

      final List<Map<String, dynamic>> studentsData = studentsSnapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['name'],
        'parentPhoneNumber': doc['parentPhoneNumber'],
      }).toList();

      if (studentsData.isEmpty) {
        print('No students found for parent: $actualParentPhoneNumber');
        return DashboardData(attendance: [], grades: [], schedule: []);
      }

      // Collect all student IDs found for this parent
      final List<String> studentIds = studentsData.map((s) => s['id'] as String).toList();
      final Map<String, String> studentNames = {for (var s in studentsData) s['id'] as String: s['name'] as String};


      // --- Fetch Attendance Records for these students ---
      // This query can be complex if attendance records are stored per day and contain multiple students.
      // Option 1: Fetch all attendance for the teacher and filter in app (less efficient for large data)
      // Option 2: Restructure Firestore (e.g., attendance per student) or use Cloud Functions for aggregation.
      // For now, we'll fetch daily records and filter by studentId.
      final attendanceSnapshot = await _firestore
          .collection('teachers')
          .doc('teacher_001') // IMPORTANT: Replace with dynamic teacher ID
          .collection('dailyAttendance')
          .get();

      for (var doc in attendanceSnapshot.docs) {
        final date = doc['date'] as String;
        final records = doc['records'] as List<dynamic>?;
        if (records != null) {
          for (var record in records) {
            // Check if this attendance record belongs to one of the parent's students
            if (studentIds.contains(record['studentId'])) {
              attendanceRecords.add(AttendanceRecord(
                studentName: studentNames[record['studentId']] ?? 'N/A',
                date: date,
                status: record['status'] as String? ?? 'N/A',
                parentPhoneNumber: actualParentPhoneNumber,
                studentId: record['studentId'] as String,
              ));
            }
          }
        }
      }

      // --- Fetch Grade Records for these students ---
      final gradesSnapshot = await _firestore
          .collection('teachers')
          .doc('teacher_001') // IMPORTANT: Replace with dynamic teacher ID
          .collection('assignments')
          .get();

      for (var doc in gradesSnapshot.docs) {
        final assignmentName = doc['name'] as String;
        final assignmentDate = doc['date'] as String;
        final scores = doc['scores'] as List<dynamic>?;
        if (scores != null) {
          for (var scoreRecord in scores) {
            // Check if this grade record belongs to one of the parent's students
            if (studentIds.contains(scoreRecord['studentId'])) {
              gradeRecords.add(GradeRecord(
                studentName: studentNames[scoreRecord['studentId']] ?? 'N/A',
                subject: assignmentName,
                assignmentName: assignmentName,
                score: (scoreRecord['score'] as num?)?.toInt() ?? 0,
                parentPhoneNumber: actualParentPhoneNumber,
                studentId: scoreRecord['studentId'] as String,
              ));
            }
          }
        }
      }

      // --- Fetch Schedule Entries for these students/parent ---
      // Assuming schedule entries might be linked directly by parentPhoneNumber or studentId
      final scheduleSnapshot = await _firestore
          .collection('teachers')
          .doc('teacher_001') // IMPORTANT: Replace with dynamic teacher ID
          .collection('classSchedule')
          .where('parentPhoneNumber', isEqualTo: actualParentPhoneNumber)
          .get();

      scheduleEntries = scheduleSnapshot.docs.map((doc) {
        return ScheduleEntry(
          subject: doc['subject'] as String? ?? 'N/A',
          date: doc['date'] as String? ?? 'N/A',
          time: doc['time'] as String? ?? 'N/A',
          room: doc['room'] as String? ?? 'N/A',
          parentPhoneNumber: doc['parentPhoneNumber'] as String? ?? 'N/A',
          studentId: '', // Schedule might not always have studentId directly
        );
      }).toList();

    } catch (e) {
      print('Error fetching dashboard data from Firestore: $e');
      throw Exception('Failed to load dashboard data from Firestore: $e');
    }

    return DashboardData(
      attendance: attendanceRecords,
      grades: gradeRecords,
      schedule: scheduleEntries,
    );
  }
}
