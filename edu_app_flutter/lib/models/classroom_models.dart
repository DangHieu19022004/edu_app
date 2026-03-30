class SaveClassroomRequest {
  const SaveClassroomRequest({
    required this.name,
    required this.schoolName,
    required this.classYear,
  });

  final String name;
  final String schoolName;
  final String classYear;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'school_name': schoolName,
      'class_year': classYear,
    };
  }
}

class SaveClassroomResponse {
  const SaveClassroomResponse({
    required this.message,
    required this.classId,
  });

  final String message;
  final String classId;

  factory SaveClassroomResponse.fromJson(Map<String, dynamic> json) {
    return SaveClassroomResponse(
      message: (json['message'] ?? '').toString(),
      classId: (json['class_id'] ?? json['id'] ?? '').toString(),
    );
  }
}

class ClassroomItem {
  const ClassroomItem({
    required this.id,
    required this.name,
    required this.schoolName,
    required this.classYear,
  });

  final String id;
  final String name;
  final String schoolName;
  final String classYear;

  factory ClassroomItem.fromJson(Map<String, dynamic> json) {
    return ClassroomItem(
      id: (json['id'] ?? json['class_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      schoolName: (json['school_name'] ?? '').toString(),
      classYear: (json['class_year'] ?? '').toString(),
    );
  }
}

class StudentInClassItem {
  const StudentInClassItem({
    required this.id,
    required this.name,
    required this.gender,
    required this.dob,
    required this.phone,
    required this.school,
    required this.academicPerformance,
    required this.conduct,
    required this.transcript,
  });

  final String id;
  final String name;
  final String gender;
  final String dob;
  final String phone;
  final String school;
  final String academicPerformance;
  final String conduct;
  final String transcript;

  factory StudentInClassItem.fromJson(Map<String, dynamic> json) {
    return StudentInClassItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      dob: (json['dob'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      school: (json['school'] ?? '').toString(),
      academicPerformance: (json['academicPerformance'] ?? '').toString(),
      conduct: (json['conduct'] ?? '').toString(),
      transcript: (json['transcript'] ?? '').toString(),
    );
  }
}
