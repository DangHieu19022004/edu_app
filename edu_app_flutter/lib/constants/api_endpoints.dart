class ApiEndpoints {
  ApiEndpoints._();
  static const String usersFormRegister = '/users/formregister/';
  static const String usersFormLogin = '/users/formlogin/';
  static const String usersGoogleLogin = '/users/googlelogin/';
  static const String usersFacebookLogin = '/users/facebooklogin/';
  static const String usersVerifyToken = '/users/verify-token/';
  static const String usersRefreshToken = '/users/refresh-token/';
  static const String classroomSaveClassroom = '/classroom/save_classroom/';
  static const String classroomGetClassrooms = '/classroom/get_classrooms/';
  static const String classroomGetStudentsByClass = '/classroom/get_students_by_class/';
  static const String classroomDeleteClassroom = '/classroom/delete_classroom/';
  static const String contactSaveParent = '/contact/save_parent/';
  static const String contactGetParents = '/contact/get_parents/';
  static const String contactScheduleEmail = '/contact/schedule_email/';
  static const String contactSendEmailNow = '/contact/send_email_now/';
  static const String contactGetScheduledEmails = '/contact/get_scheduled_emails/';
  static const String contactDeleteEmailSchedule = '/contact/delete_email_schedule/';
  static const String ocrDetect = '/ocr/detect/';
  static const String ocrSaveFullReportCard = '/ocr/save_full_report_card/';
  static const String ocrGetFullReportCard = '/ocr/get_full_report_card/';
  static const String ocrUpdateReportCard = '/ocr/update_report_card/';
  static const String ocrDeleteFullReportCard = '/ocr/delete_full_report_card/';
}
