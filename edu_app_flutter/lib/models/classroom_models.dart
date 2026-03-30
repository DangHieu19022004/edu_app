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
