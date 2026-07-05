class SaveParentRequest {
  const SaveParentRequest({
    required this.teacherId,
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  final String teacherId;
  final String studentId;
  final String fullName;
  final String email;
  final String phone;

  Map<String, dynamic> toJson() {
    return {
      'teacher_id': teacherId,
      'student_id': studentId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
    };
  }
}

class ContactActionResponse {
  const ContactActionResponse({required this.message});

  final String message;

  factory ContactActionResponse.fromJson(Map<String, dynamic> json) {
    return ContactActionResponse(
      message: (json['message'] ?? '').toString(),
    );
  }
}

class ScheduleEmailRequest {
  const ScheduleEmailRequest({
    required this.subject,
    required this.recipient,
    required this.message,
    required this.scheduledTime,
    required this.teacherId,
  });

  final String subject;
  final String recipient;
  final String message;
  final String scheduledTime;
  final String teacherId;

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'recipient': recipient,
      'message': message,
      'scheduled_time': scheduledTime,
      'teacher_id': teacherId,
    };
  }
}

class SendEmailNowRequest {
  const SendEmailNowRequest({
    required this.subject,
    required this.recipient,
    required this.message,
    required this.teacherId,
  });

  final String subject;
  final String recipient;
  final String message;
  final String teacherId;

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'recipient': recipient,
      'message': message,
      'teacher_id': teacherId,
    };
  }
}

class ScheduledEmailItem {
  const ScheduledEmailItem({
    required this.id,
    required this.subject,
    required this.recipients,
    required this.message,
    required this.scheduledDate,
    required this.status,
  });

  final String id;
  final String subject;
  final String recipients;
  final String message;
  final String scheduledDate;
  final String status;

  factory ScheduledEmailItem.fromJson(Map<String, dynamic> json) {
    return ScheduledEmailItem(
      id: (json['id'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      recipients: (json['recipients'] ?? json['recipient'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      scheduledDate: (json['scheduledDate'] ?? json['scheduled_time'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class ParentItem {
  const ParentItem({
    required this.id,
    required this.parentName,
    required this.email,
    required this.phone,
    required this.studentId,
    required this.studentName,
    required this.studentClass,
    required this.studentSchool,
    required this.relationship,
    required this.teacherId,
    required this.createdAt,
  });

  final String id;
  final String parentName;
  final String email;
  final String phone;
  final String studentId;
  final String studentName;
  final String studentClass;
  final String studentSchool;
  final String relationship;
  final String teacherId;
  final String createdAt;

  factory ParentItem.fromJson(Map<String, dynamic> json) {
    return ParentItem(
      id: (json['id'] ?? '').toString(),
      parentName: (json['parentName'] ?? json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      studentId: (json['studentId'] ?? json['student_id'] ?? '').toString(),
      studentName: (json['studentName'] ?? '').toString(),
      studentClass: (json['studentClass'] ?? '').toString(),
        studentSchool: (json['studentSchool'] ?? json['school'] ?? json['school_name'] ?? '')
          .toString(),
      relationship: (json['relationship'] ?? '').toString(),
      teacherId: (json['teacherId'] ?? json['teacher_id'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}
