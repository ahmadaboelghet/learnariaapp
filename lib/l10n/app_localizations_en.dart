// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'الناظر';

  @override
  String get login => 'Login';

  @override
  String get signup => 'Sign Up';

  @override
  String get home => 'Home';

  @override
  String get reports => 'Reports';

  @override
  String get profile => 'Profile';

  @override
  String get welcome => 'Welcome';

  @override
  String get assignments => 'Assignments';

  @override
  String get attendance => 'Attendance';

  @override
  String get schedule => 'Today\'s Schedule';

  @override
  String get progressReport => 'Progress Report';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get logout => 'Logout';

  @override
  String get yourProfile => 'Your Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get security => 'Security';

  @override
  String get language => 'Language';

  @override
  String get confirmSignOut => 'Confirm Sign Out';

  @override
  String get areYouSureSignOut => 'Are you sure you want to sign out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get signOut => 'Sign Out';

  @override
  String get studentParent => 'Student\'s parent';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get paymentOption => 'Payment option';

  @override
  String get helloParent => 'Hello';

  @override
  String get todayDate => 'Today,';

  @override
  String get days => 'days';

  @override
  String get outOfDays => 'out of';

  @override
  String get daysMissed => 'days missed';

  @override
  String get feedback => 'Feedback';

  @override
  String get seeAll => 'See All';

  @override
  String get excellent => 'Excellent';

  @override
  String get needsImprovement => 'Needs Improvement';

  @override
  String get monthView => 'Month View';

  @override
  String get noFeedback => 'No feedback available.';

  @override
  String get noAttendanceData => 'No attendance data to display.';

  @override
  String get noStudentData => 'No student data found for your account.';

  @override
  String get done => 'Done';

  @override
  String get subjects => 'Subjects';

  @override
  String get present => 'Present';

  @override
  String get todaysCourses => 'Today\'s Courses';

  @override
  String get noCoursesScheduled => 'No courses scheduled for today.';

  @override
  String get finished => 'Finished';

  @override
  String get ongoing => 'Ongoing';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get scheduled => 'Scheduled';

  @override
  String get assignmentsBySubject => 'Assignments by Subject';

  @override
  String get attendanceBySubject => 'Attendance by Subject';

  @override
  String get latest => 'Latest';

  @override
  String get noStudentDataContactTeacher => 'No student data found. Please contact the teacher.';

  @override
  String get latestReportGreeting => 'Here is your latest report.';

  @override
  String get loginWelcome => 'Welcome Back!';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get enterValidEmail => 'Please enter a valid email';

  @override
  String get enterYourPassword => 'Please enter your password';

  @override
  String get signupWelcome => 'Create an Account';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get more => 'More';

  @override
  String assignmentsForSubject(String subject) {
    return '$subject Assignments';
  }

  @override
  String detailedGradesForSubject(String subject) {
    return 'Detailed Assignment Grades for $subject';
  }

  @override
  String get noAssignmentsFound => 'No assignments found for this subject.';

  @override
  String get dateLabel => 'Date:';

  @override
  String get gradeLabel => 'Grade:';

  @override
  String attendanceForSubject(String subject) {
    return '$subject Attendance';
  }

  @override
  String detailedAttendanceForSubject(String subject) {
    return 'Detailed Attendance Records for $subject';
  }

  @override
  String get noAttendanceFound => 'No attendance records found for this subject.';

  @override
  String get presentStatus => 'Present';

  @override
  String get absentStatus => 'Absent';

  @override
  String get noNotificationsYet => 'No notifications yet.';

  @override
  String helloStudentParent(String studentName) {
    return 'Hello, $studentName\'s parent!';
  }

  @override
  String get introTitle1 => 'Track Their Academic Progress';

  @override
  String get introDesc1 => 'View assignments, test scores, and attendance records easily in one place.';

  @override
  String get introTitle2 => 'Never Miss an Update';

  @override
  String get introDesc2 => 'Get instant notifications for daily schedules, new grades, and important messages.';

  @override
  String get introTitle3 => 'Everything in One App';

  @override
  String get introDesc3 => 'Al-Nazer brings together all the important information to follow your children\'s educational journey.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get loginWelcomeMessage => 'Welcome Back!';

  @override
  String get loginSubMessage => 'Login with your phone number and password.';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get forgetPassword => 'Forget Password?';

  @override
  String get signupCreateAccount => 'Create Account';

  @override
  String get signupStartJourney => 'Start your journey with Al-Nazer!';

  @override
  String get agreeToTerms => 'I agree to the Terms & Conditions';

  @override
  String get mustAgreeToTermsError => 'You must agree to the terms and conditions.';

  @override
  String get submitted => 'Submitted';

  @override
  String get notSubmitted => 'Not Submitted';

  @override
  String get performanceOverview => 'Performance Overview';

  @override
  String get noDataForChart => 'No data available for chart.';

  @override
  String get pleaseEnterPhone => 'Please enter your phone number.';

  @override
  String get verify => 'Verify Phone Number';

  @override
  String enterOtpSentTo(String phoneNumber) {
    return 'Enter the verification code sent to $phoneNumber.';
  }

  @override
  String get otpVerification => 'Verify Phone Number';

  @override
  String get pleaseEnterPassword => 'Please enter your password.';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get enterPhoneToReset => 'Enter your phone number to reset your password.';

  @override
  String get continue_ => 'Continue';

  @override
  String get createPassword => 'Create Password';
}
