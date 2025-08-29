// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Learnaria';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get signup => 'إنشاء حساب';

  @override
  String get home => 'الرئيسية';

  @override
  String get reports => 'التقارير';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get welcome => 'أهلاً بك';

  @override
  String get assignments => 'الواجبات';

  @override
  String get attendance => 'الحضور';

  @override
  String get schedule => 'جدول اليوم';

  @override
  String get progressReport => 'تقرير التقدم';

  @override
  String get darkMode => 'الوضع المظلم';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get yourProfile => 'ملفك الشخصي';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get security => 'الأمان';

  @override
  String get language => 'اللغة';

  @override
  String get confirmSignOut => 'تأكيد تسجيل الخروج';

  @override
  String get areYouSureSignOut => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get studentParent => 'ولي أمر الطالب';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get paymentOption => 'خيارات الدفع';

  @override
  String get helloParent => 'أهلاً';

  @override
  String get todayDate => 'اليوم،';

  @override
  String get days => 'أيام';

  @override
  String get outOfDays => 'من أصل';

  @override
  String get daysMissed => 'أيام غياب';

  @override
  String get feedback => 'التقييمات';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get excellent => 'ممتاز';

  @override
  String get needsImprovement => 'يحتاج لتحسين';

  @override
  String get monthView => 'عرض شهري';

  @override
  String get noFeedback => 'لا توجد تقييمات متاحة.';

  @override
  String get noAttendanceData => 'لا توجد بيانات حضور لعرضها.';

  @override
  String get noStudentData => 'لا توجد بيانات طالب مسجلة لحسابك.';

  @override
  String get done => 'مكتمل';

  @override
  String get subjects => 'مواد';

  @override
  String get present => 'حاضر';

  @override
  String get todaysCourses => 'حصص اليوم';

  @override
  String get noCoursesScheduled => 'لا توجد حصص مجدولة لليوم.';

  @override
  String get finished => 'منتهية';

  @override
  String get ongoing => 'جارية';

  @override
  String get upcoming => 'قادمة';

  @override
  String get scheduled => 'مجدولة';

  @override
  String get assignmentsBySubject => 'الواجبات حسب المادة';

  @override
  String get attendanceBySubject => 'الحضور حسب المادة';

  @override
  String get latest => 'الأحدث';

  @override
  String get noStudentDataContactTeacher => 'لا توجد بيانات طالب. يرجى التواصل مع المعلم.';

  @override
  String get latestReportGreeting => 'هذا هو تقريرك الأخير.';

  @override
  String get loginWelcome => 'أهلاً بعودتك!';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get enterValidEmail => 'الرجاء إدخال بريد إلكتروني صالح';

  @override
  String get enterYourPassword => 'الرجاء إدخال كلمة المرور';

  @override
  String get signupWelcome => 'إنشاء حساب جديد';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get alreadyHaveAccount => 'هل لديك حساب بالفعل؟';

  @override
  String get passwordTooShort => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get more => 'المزيد';

  @override
  String assignmentsForSubject(String subject) {
    return 'واجبات مادة $subject';
  }

  @override
  String detailedGradesForSubject(String subject) {
    return 'تفاصيل درجات واجبات مادة $subject';
  }

  @override
  String get noAssignmentsFound => 'لا توجد واجبات لهذه المادة.';

  @override
  String get dateLabel => 'التاريخ:';

  @override
  String get gradeLabel => 'الدرجة:';

  @override
  String attendanceForSubject(String subject) {
    return 'حضور مادة $subject';
  }

  @override
  String detailedAttendanceForSubject(String subject) {
    return 'سجلات الحضور التفصيلية لمادة $subject';
  }

  @override
  String get noAttendanceFound => 'لا توجد سجلات حضور لهذه المادة.';

  @override
  String get presentStatus => 'حاضر';

  @override
  String get absentStatus => 'غائب';

  @override
  String get noNotificationsYet => 'لا توجد إشعارات حتى الآن.';

  @override
  String helloStudentParent(String studentName) {
    return 'أهلاً، ولي أمر $studentName!';
  }

  @override
  String get introTitle1 => 'تابع تقدمهم الدراسي';

  @override
  String get introDesc1 => 'اطلع على الواجبات، درجات الاختبارات، وسجلات الحضور بسهولة وفي مكان واحد.';

  @override
  String get introTitle2 => 'لا تفوت أي تحديث';

  @override
  String get introDesc2 => 'احصل على إشعارات فورية بالجداول اليومية، والتقييمات الجديدة، والرسائل الهامة.';

  @override
  String get introTitle3 => 'كل ما تحتاجه في تطبيق واحد';

  @override
  String get introDesc3 => 'ليناريا يجمع كل المعلومات الهامة لمتابعة رحلة أبنائك التعليمية بفاعلية.';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get next => 'التالي';

  @override
  String get skip => 'تخطي';

  @override
  String get loginWelcomeMessage => 'أهلاً بعودتك!';

  @override
  String get loginSubMessage => 'سجل الدخول برقم هاتفك وكلمة المرور.';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get forgetPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get signupCreateAccount => 'إنشاء حساب';

  @override
  String get signupStartJourney => 'ابدأ رحلتك مع ليناريا!';

  @override
  String get agreeToTerms => 'أوافق على الشروط والأحكام';

  @override
  String get mustAgreeToTermsError => 'يجب عليك الموافقة على الشروط والأحكام.';

  @override
  String get submitted => 'تم التسليم';

  @override
  String get notSubmitted => 'لم يتم التسليم';

  @override
  String get performanceOverview => 'نظرة عامة على الأداء';

  @override
  String get noDataForChart => 'لا توجد بيانات متاحة للرسم البياني.';
}
