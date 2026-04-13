import 'package:edu_app_flutter/models/ocr_models.dart';

class ChatbotAskRequest {
  const ChatbotAskRequest({
    required this.question,
    required this.students,
    this.conversationId,
  });

  final String question;
  final List<ChatbotStudentPayload> students;
  final String? conversationId;

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'students': students.map((item) => item.toJson()).toList(),
      if ((conversationId ?? '').trim().isNotEmpty)
        'conversation_id': conversationId!.trim(),
    };
  }
}

class ChatbotStudentPayload {
  const ChatbotStudentPayload({
    required this.student,
    required this.reportCard,
    required this.subjects,
  });

  final ChatbotStudentInfo student;
  final ChatbotReportCardInfo reportCard;
  final List<ChatbotSubjectInfo> subjects;

  factory ChatbotStudentPayload.fromOcrItem(OcrAllStudentDataItem item) {
    return ChatbotStudentPayload(
      student: ChatbotStudentInfo(
        id: item.student.id,
        name: item.student.name,
        gender: item.student.gender,
        dob: item.student.dob,
        school: item.student.school,
        className: item.student.className,
        classYear: item.student.classYear,
      ),
      reportCard: ChatbotReportCardInfo(
        schoolYear: item.reportCard.schoolYear,
        teacherComment: item.reportCard.teacherComment,
        conduct: item.reportCard.conduct,
        gpa: item.reportCard.gpa,
      ),
      subjects: item.subjects
          .map(
            (subject) => ChatbotSubjectInfo(
              name: subject.name,
              year: subject.year,
              hk1: subject.hk1,
              hk2: subject.hk2,
              cn: subject.cn,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student': student.toJson(),
      'report_card': reportCard.toJson(),
      'subjects': subjects.map((item) => item.toJson()).toList(),
    };
  }
}

class ChatbotStudentInfo {
  const ChatbotStudentInfo({
    required this.id,
    required this.name,
    required this.gender,
    required this.dob,
    required this.school,
    required this.className,
    required this.classYear,
  });

  final String id;
  final String name;
  final String gender;
  final String dob;
  final String school;
  final String className;
  final String classYear;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'dob': dob,
      'school': school,
      'class': className,
      'class_year': classYear,
    };
  }
}

class ChatbotReportCardInfo {
  const ChatbotReportCardInfo({
    required this.schoolYear,
    required this.teacherComment,
    required this.conduct,
    required this.gpa,
  });

  final String schoolYear;
  final String teacherComment;
  final String conduct;
  final Map<String, double> gpa;

  Map<String, dynamic> toJson() {
    return {
      'school_year': schoolYear,
      'teacher_comment': teacherComment,
      'conduct': conduct,
      'gpa': gpa,
    };
  }
}

class ChatbotSubjectInfo {
  const ChatbotSubjectInfo({
    required this.name,
    required this.year,
    required this.hk1,
    required this.hk2,
    required this.cn,
  });

  final String name;
  final String year;
  final String hk1;
  final String hk2;
  final String cn;

  Map<String, dynamic> toJson() {
    return {'name': name, 'year': year, 'hk1': hk1, 'hk2': hk2, 'cn': cn};
  }
}

class ChatbotAskResponse {
  const ChatbotAskResponse({
    required this.answer,
    required this.conversationId,
    required this.metadata,
  });

  final String answer;
  final String conversationId;
  final Map<String, dynamic> metadata;

  factory ChatbotAskResponse.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    return ChatbotAskResponse(
      answer: (json['answer'] ?? '').toString(),
      conversationId: (json['conversation_id'] ?? '').toString(),
      metadata: rawMetadata is Map<String, dynamic>
          ? rawMetadata
          : <String, dynamic>{},
    );
  }
}
