import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Learnaria'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @assignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignments;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get schedule;

  /// No description provided for @progressReport.
  ///
  /// In en, this message translates to:
  /// **'Progress Report'**
  String get progressReport;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get yourProfile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @confirmSignOut.
  ///
  /// In en, this message translates to:
  /// **'Confirm Sign Out'**
  String get confirmSignOut;

  /// No description provided for @areYouSureSignOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get areYouSureSignOut;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @studentParent.
  ///
  /// In en, this message translates to:
  /// **'Student\'s parent'**
  String get studentParent;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @paymentOption.
  ///
  /// In en, this message translates to:
  /// **'Payment option'**
  String get paymentOption;

  /// No description provided for @helloParent.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get helloParent;

  /// No description provided for @todayDate.
  ///
  /// In en, this message translates to:
  /// **'Today,'**
  String get todayDate;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @outOfDays.
  ///
  /// In en, this message translates to:
  /// **'out of'**
  String get outOfDays;

  /// No description provided for @daysMissed.
  ///
  /// In en, this message translates to:
  /// **'days missed'**
  String get daysMissed;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @needsImprovement.
  ///
  /// In en, this message translates to:
  /// **'Needs Improvement'**
  String get needsImprovement;

  /// No description provided for @monthView.
  ///
  /// In en, this message translates to:
  /// **'Month View'**
  String get monthView;

  /// No description provided for @noFeedback.
  ///
  /// In en, this message translates to:
  /// **'No feedback available.'**
  String get noFeedback;

  /// No description provided for @noAttendanceData.
  ///
  /// In en, this message translates to:
  /// **'No attendance data to display.'**
  String get noAttendanceData;

  /// No description provided for @noStudentData.
  ///
  /// In en, this message translates to:
  /// **'No student data found for your account.'**
  String get noStudentData;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @subjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjects;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @todaysCourses.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Courses'**
  String get todaysCourses;

  /// No description provided for @noCoursesScheduled.
  ///
  /// In en, this message translates to:
  /// **'No courses scheduled for today.'**
  String get noCoursesScheduled;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @assignmentsBySubject.
  ///
  /// In en, this message translates to:
  /// **'Assignments by Subject'**
  String get assignmentsBySubject;

  /// No description provided for @attendanceBySubject.
  ///
  /// In en, this message translates to:
  /// **'Attendance by Subject'**
  String get attendanceBySubject;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @noStudentDataContactTeacher.
  ///
  /// In en, this message translates to:
  /// **'No student data found. Please contact the teacher.'**
  String get noStudentDataContactTeacher;

  /// No description provided for @latestReportGreeting.
  ///
  /// In en, this message translates to:
  /// **'Here is your latest report.'**
  String get latestReportGreeting;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get loginWelcome;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterYourPassword;

  /// No description provided for @signupWelcome.
  ///
  /// In en, this message translates to:
  /// **'Create an Account'**
  String get signupWelcome;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @assignmentsForSubject.
  ///
  /// In en, this message translates to:
  /// **'{subject} Assignments'**
  String assignmentsForSubject(String subject);

  /// No description provided for @detailedGradesForSubject.
  ///
  /// In en, this message translates to:
  /// **'Detailed Assignment Grades for {subject}'**
  String detailedGradesForSubject(String subject);

  /// No description provided for @noAssignmentsFound.
  ///
  /// In en, this message translates to:
  /// **'No assignments found for this subject.'**
  String get noAssignmentsFound;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get dateLabel;

  /// No description provided for @gradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Grade:'**
  String get gradeLabel;

  /// No description provided for @attendanceForSubject.
  ///
  /// In en, this message translates to:
  /// **'{subject} Attendance'**
  String attendanceForSubject(String subject);

  /// No description provided for @detailedAttendanceForSubject.
  ///
  /// In en, this message translates to:
  /// **'Detailed Attendance Records for {subject}'**
  String detailedAttendanceForSubject(String subject);

  /// No description provided for @noAttendanceFound.
  ///
  /// In en, this message translates to:
  /// **'No attendance records found for this subject.'**
  String get noAttendanceFound;

  /// No description provided for @presentStatus.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get presentStatus;

  /// No description provided for @absentStatus.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absentStatus;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get noNotificationsYet;

  /// No description provided for @helloStudentParent.
  ///
  /// In en, this message translates to:
  /// **'Hello, {studentName}\'s parent!'**
  String helloStudentParent(String studentName);

  /// No description provided for @introTitle1.
  ///
  /// In en, this message translates to:
  /// **'Track Their Academic Progress'**
  String get introTitle1;

  /// No description provided for @introDesc1.
  ///
  /// In en, this message translates to:
  /// **'View assignments, test scores, and attendance records easily in one place.'**
  String get introDesc1;

  /// No description provided for @introTitle2.
  ///
  /// In en, this message translates to:
  /// **'Never Miss an Update'**
  String get introTitle2;

  /// No description provided for @introDesc2.
  ///
  /// In en, this message translates to:
  /// **'Get instant notifications for daily schedules, new grades, and important messages.'**
  String get introDesc2;

  /// No description provided for @introTitle3.
  ///
  /// In en, this message translates to:
  /// **'Everything in One App'**
  String get introTitle3;

  /// No description provided for @introDesc3.
  ///
  /// In en, this message translates to:
  /// **'Learnaria brings together all the important information to follow your children\'s educational journey.'**
  String get introDesc3;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @loginWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get loginWelcomeMessage;

  /// No description provided for @loginSubMessage.
  ///
  /// In en, this message translates to:
  /// **'Login with your phone number and password.'**
  String get loginSubMessage;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @forgetPassword.
  ///
  /// In en, this message translates to:
  /// **'Forget Password?'**
  String get forgetPassword;

  /// No description provided for @signupCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupCreateAccount;

  /// No description provided for @signupStartJourney.
  ///
  /// In en, this message translates to:
  /// **'Start your journey with Learnaria!'**
  String get signupStartJourney;

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Conditions'**
  String get agreeToTerms;

  /// No description provided for @mustAgreeToTermsError.
  ///
  /// In en, this message translates to:
  /// **'You must agree to the terms and conditions.'**
  String get mustAgreeToTermsError;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @notSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Not Submitted'**
  String get notSubmitted;

  /// No description provided for @performanceOverview.
  ///
  /// In en, this message translates to:
  /// **'Performance Overview'**
  String get performanceOverview;

  /// No description provided for @noDataForChart.
  ///
  /// In en, this message translates to:
  /// **'No data available for chart.'**
  String get noDataForChart;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLogin;

  /// No description provided for @authSignup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignup;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We will send you an OTP code'**
  String get authSubtitle;

  /// No description provided for @authPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get authPhoneLabel;

  /// No description provided for @authSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get authSendCode;

  /// No description provided for @authPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get authPhoneHint;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred, please try again'**
  String get authErrorGeneric;

  /// No description provided for @authErrorInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get authErrorInvalidPhone;

  /// No description provided for @authErrorSendingCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to send code: {message}'**
  String authErrorSendingCode(Object message);

  /// No description provided for @otpVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get otpVerifyTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'A 6-digit code was sent to'**
  String get otpSentTo;

  /// No description provided for @otpVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerifyButton;

  /// No description provided for @otpErrorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Verification failed: Invalid code'**
  String get otpErrorInvalidCode;

  /// No description provided for @otpChangePhone.
  ///
  /// In en, this message translates to:
  /// **'Change phone number?'**
  String get otpChangePhone;

  /// No description provided for @otpEnter6Digits.
  ///
  /// In en, this message translates to:
  /// **'Please enter 6 digits'**
  String get otpEnter6Digits;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhone;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Learnaria'**
  String get authTitle;

  /// No description provided for @authSlogan.
  ///
  /// In en, this message translates to:
  /// **'Learn more, learn smarter'**
  String get authSlogan;

  /// No description provided for @authContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authContinue;

  /// No description provided for @authTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By clicking continue, you accept our'**
  String get authTermsPrefix;

  /// No description provided for @authTermsLink.
  ///
  /// In en, this message translates to:
  /// **'terms and conditions'**
  String get authTermsLink;

  /// No description provided for @authParentNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'There is no data for this parent. Please tell your son\'s teacher about Learnaria.'**
  String get authParentNotFoundError;

  /// No description provided for @authChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get authChecking;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
