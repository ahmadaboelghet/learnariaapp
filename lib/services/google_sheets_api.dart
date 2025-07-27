import 'dart:convert'; // For json.decode
import 'package:http/http.dart' as http; // Import http package
import 'package:learnaria/models/dashboard_data.dart'; // Import your data models

class GoogleSheetsApi {
  // IMPORTANT: Replace this with your actual Google Apps Script Web App URL.
  // This URL is obtained after deploying your Apps Script as a Web App (Anyone access).
  static const String APPS_SCRIPT_WEB_APP_URL = 'https://script.google.com/macros/s/AKfycbxypUgcojRTpU4i2PdgjFjU-5DVMSmzhKq9mAXdmoJUqbuNSf83rIe4KmwmUvO_R-BA/exec';

  // --- Function to fetch data from Google Sheets with optional filtering ---
  Future<DashboardData> fetchDashboardData({String? parentPhoneNumber}) async {
    String url = APPS_SCRIPT_WEB_APP_URL;
    if (parentPhoneNumber != null && parentPhoneNumber.isNotEmpty) {
      // Add parentPhoneNumber as a query parameter for filtering
      url += '?parentPhoneNumber=${Uri.encodeComponent(parentPhoneNumber)}';
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON.
        final Map<String, dynamic> jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        return DashboardData.fromJson(jsonResponse);
      } else {
        // If the server did not return a 200 OK response, throw an exception.
        print('Failed to load data: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load dashboard data from Google Sheets API');
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
      throw Exception('Error fetching dashboard data: $e');
    }
  }

  // --- Functions to save data to Google Sheets (via Apps Script doPost) ---
  // These are examples. You would call these from your UI to add new records.

  Future<bool> saveAttendanceRecord(AttendanceRecord record) async {
    final Map<String, dynamic> dataToSend = {
      'recordType': 'attendance',
      'data': {
        'studentName': record.studentName,
        'date': record.date,
        'status': record.status,
        'parentPhoneNumber': record.parentPhoneNumber,
      },
    };
    return _sendDataToAppsScript(dataToSend);
  }

  Future<bool> saveGradeRecord(GradeRecord record) async {
    final Map<String, dynamic> dataToSend = {
      'recordType': 'grade',
      'data': {
        'studentName': record.studentName,
        'subject': record.subject,
        'assignmentName': record.assignmentName,
        'score': record.score,
        'parentPhoneNumber': record.parentPhoneNumber,
      },
    };
    return _sendDataToAppsScript(dataToSend);
  }

  Future<bool> saveScheduleEntry(ScheduleEntry entry) async {
    final Map<String, dynamic> dataToSend = {
      'recordType': 'schedule',
      'data': {
        'subject': entry.subject,
        'date': entry.date,
        'time': entry.time,
        'room': entry.room,
        'parentPhoneNumber': entry.parentPhoneNumber,
      },
    };
    return _sendDataToAppsScript(dataToSend);
  }

  // Helper function to send POST requests to Apps Script
  Future<bool> _sendDataToAppsScript(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(APPS_SCRIPT_WEB_APP_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body) as Map<String, dynamic>;
        if (result['success'] == true) {
          print('Data saved successfully: ${result['message']}');
          return true;
        } else {
          print('Failed to save data: ${result['message']}');
          return false;
        }
      } else {
        print('Failed to send data: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending data to Apps Script: $e');
      return false;
    }
  }
}
