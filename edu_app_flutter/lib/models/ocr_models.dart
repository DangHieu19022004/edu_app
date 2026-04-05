enum OcrImageRole {
  studentInfo,
  grade10,
  grade11,
  grade12,
}

class OcrDetectImageInput {
  const OcrDetectImageInput({
    required this.path,
    required this.role,
  });

  final String path;
  final OcrImageRole role;

  String? get imageType {
    if (role == OcrImageRole.studentInfo) {
      return 'info';
    }
    return 'report_card';
  }

  String get roleLabel {
    switch (role) {
      case OcrImageRole.studentInfo:
        return 'Thông tin chung';
      case OcrImageRole.grade10:
        return 'Lớp 10';
      case OcrImageRole.grade11:
        return 'Lớp 11';
      case OcrImageRole.grade12:
        return 'Lớp 12';
    }
  }

  int get sortOrder {
    switch (role) {
      case OcrImageRole.studentInfo:
        return 0;
      case OcrImageRole.grade10:
        return 1;
      case OcrImageRole.grade11:
        return 2;
      case OcrImageRole.grade12:
        return 3;
    }
  }
}

class OcrScoreRow {
  const OcrScoreRow({
    required this.subject,
    required this.hk1,
    required this.hk2,
    required this.caNam,
  });

  final String subject;
  final String hk1;
  final String hk2;
  final String caNam;

  factory OcrScoreRow.fromJson(Map<String, dynamic> json) {
    return OcrScoreRow(
      subject: (json['ten_mon'] ?? json['subject'] ?? '').toString().trim(),
      hk1: (json['hky1'] ?? json['hk1'] ?? '').toString().trim(),
      hk2: (json['hky2'] ?? json['hk2'] ?? '').toString().trim(),
      caNam: (json['ca_nam'] ?? json['cn'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ten_mon': subject,
      'hky1': hk1,
      'hky2': hk2,
      'ca_nam': caNam,
    };
  }

  OcrScoreRow copyWith({
    String? subject,
    String? hk1,
    String? hk2,
    String? caNam,
  }) {
    return OcrScoreRow(
      subject: subject ?? this.subject,
      hk1: hk1 ?? this.hk1,
      hk2: hk2 ?? this.hk2,
      caNam: caNam ?? this.caNam,
    );
  }

  bool get hasContent {
    return subject.isNotEmpty || hk1.isNotEmpty || hk2.isNotEmpty || caNam.isNotEmpty;
  }
}

class OcrDetectResult {
  const OcrDetectResult({
    required this.role,
    required this.imageUrl,
    required this.studentInfo,
    required this.scores,
    required this.rawOcrData,
  });

  final OcrImageRole role;
  final String imageUrl;
  final Map<String, dynamic> studentInfo;
  final List<OcrScoreRow> scores;
  final dynamic rawOcrData;

  factory OcrDetectResult.fromJson(Map<String, dynamic> json) {
    final dynamic rawScores = json['ocr_data'];
    final List<OcrScoreRow> parsedScores = <OcrScoreRow>[];

    if (rawScores is List) {
      for (final row in rawScores) {
        if (row is Map<String, dynamic>) {
          final scoreRow = OcrScoreRow.fromJson(row);
          if (scoreRow.hasContent) {
            parsedScores.add(scoreRow);
          }
        }
      }
    }

    final dynamic rawStudentInfo = json['student_info'];

    return OcrDetectResult(
      role: OcrImageRole.studentInfo,
      imageUrl: (json['image_url'] ?? '').toString().trim(),
      studentInfo: rawStudentInfo is Map<String, dynamic>
          ? rawStudentInfo
          : <String, dynamic>{},
      scores: parsedScores,
      rawOcrData: rawScores,
    );
  }

  OcrDetectResult copyWith({
    OcrImageRole? role,
  }) {
    return OcrDetectResult(
      role: role ?? this.role,
      imageUrl: imageUrl,
      studentInfo: studentInfo,
      scores: scores,
      rawOcrData: rawOcrData,
    );
  }
}

class OcrSaveSubjectItem {
  const OcrSaveSubjectItem({
    required this.name,
    required this.year,
    required this.sem1Score,
    required this.sem2Score,
    required this.finalScore,
  });

  final String name;
  final int year;
  final String? sem1Score;
  final String? sem2Score;
  final String? finalScore;

  Map<String, dynamic> toJson() {
    String? _valueForYear(int targetYear, String? value) {
      return year == targetYear ? value : null;
    }

    return {
      'name': name,
      'year': year,
      'year1_sem1_score': _valueForYear(1, sem1Score),
      'year1_sem2_score': _valueForYear(1, sem2Score),
      'year1_final_score': _valueForYear(1, finalScore),
      'year2_sem1_score': _valueForYear(2, sem1Score),
      'year2_sem2_score': _valueForYear(2, sem2Score),
      'year2_final_score': _valueForYear(2, finalScore),
      'year3_sem1_score': _valueForYear(3, sem1Score),
      'year3_sem2_score': _valueForYear(3, sem2Score),
      'year3_final_score': _valueForYear(3, finalScore),
    };
  }
}

class OcrSaveFullReportCardRequest {
  const OcrSaveFullReportCardRequest({
    required this.studentId,
    required this.studentName,
    required this.studentDob,
    required this.studentGender,
    required this.classId,
    required this.schoolYear,
    required this.subjects,
  });

  final String studentId;
  final String studentName;
  final String studentDob;
  final String studentGender;
  final String classId;
  final String schoolYear;
  final List<OcrSaveSubjectItem> subjects;

  Map<String, dynamic> toJson() {
    return {
      'student': {
        'id': studentId,
        'name': studentName,
        'dob': studentDob,
        'gender': studentGender,
        'address': '',
        'father_name': '',
        'mother_name': '',
        'phone': '',
        'parents_email': '',
        'class_id': classId,
        'ethnicity': '',
        'birthplace': '',
      },
      'report_card': {
        'class_id': classId,
        'school_year': schoolYear,
      },
      'subjects': subjects.map((item) => item.toJson()).toList(),
    };
  }
}

class OcrSaveFullReportCardResponse {
  const OcrSaveFullReportCardResponse({required this.message});

  final String message;

  factory OcrSaveFullReportCardResponse.fromJson(Map<String, dynamic> json) {
    return OcrSaveFullReportCardResponse(
      message: (json['message'] ?? '').toString(),
    );
  }
}

class OcrReportCardStudent {
  const OcrReportCardStudent({
    required this.id,
    required this.name,
    required this.dob,
    required this.gender,
    required this.phone,
    required this.school,
    required this.classId,
    required this.academicPerformance,
    required this.conduct,
  });

  final String id;
  final String name;
  final String dob;
  final String gender;
  final String phone;
  final String school;
  final String classId;
  final String academicPerformance;
  final String conduct;

  factory OcrReportCardStudent.fromJson(Map<String, dynamic> json) {
    return OcrReportCardStudent(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      dob: (json['dob'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      school: (json['school'] ?? '').toString(),
      classId: (json['class_id'] ?? '').toString(),
      academicPerformance: (json['academicPerformance'] ?? '').toString(),
      conduct: (json['conduct'] ?? '').toString(),
    );
  }
}

class OcrReportCardInfo {
  const OcrReportCardInfo({
    required this.id,
    required this.schoolYear,
    required this.teacherSigned,
    required this.principalSigned,
    required this.teacherComment,
    required this.approvalDate,
  });

  final String id;
  final String schoolYear;
  final bool teacherSigned;
  final bool principalSigned;
  final String teacherComment;
  final String approvalDate;

  factory OcrReportCardInfo.fromJson(Map<String, dynamic> json) {
    return OcrReportCardInfo(
      id: (json['id'] ?? '').toString(),
      schoolYear: (json['school_year'] ?? '').toString(),
      teacherSigned: json['teacher_signed'] == true,
      principalSigned: json['principal_signed'] == true,
      teacherComment: (json['teacher_comment'] ?? '').toString(),
      approvalDate: (json['approval_date'] ?? '').toString(),
    );
  }
}

class OcrReportCardClassSubject {
  const OcrReportCardClassSubject({
    required this.name,
    required this.hk1,
    required this.hk2,
    required this.cn,
  });

  final String name;
  final String hk1;
  final String hk2;
  final String cn;

  factory OcrReportCardClassSubject.fromJson(Map<String, dynamic> json) {
    return OcrReportCardClassSubject(
      name: (json['name'] ?? '').toString(),
      hk1: (json['hk1'] ?? '').toString(),
      hk2: (json['hk2'] ?? '').toString(),
      cn: (json['cn'] ?? '').toString(),
    );
  }
}

class OcrReportCardClassGroup {
  const OcrReportCardClassGroup({
    required this.className,
    required this.subjects,
  });

  final String className;
  final List<OcrReportCardClassSubject> subjects;

  factory OcrReportCardClassGroup.fromJson(Map<String, dynamic> json) {
    final dynamic rawSubjects = json['subjects'];
    final subjects = rawSubjects is List
        ? rawSubjects
            .whereType<Map<String, dynamic>>()
            .map(OcrReportCardClassSubject.fromJson)
            .toList()
        : const <OcrReportCardClassSubject>[];

    return OcrReportCardClassGroup(
      className: (json['class'] ?? '').toString(),
      subjects: subjects,
    );
  }
}

class OcrFullReportCardResponse {
  const OcrFullReportCardResponse({
    required this.student,
    required this.reportCard,
    required this.classList,
    required this.className,
    required this.schoolName,
  });

  final OcrReportCardStudent student;
  final OcrReportCardInfo? reportCard;
  final List<OcrReportCardClassGroup> classList;
  final String className;
  final String schoolName;

  factory OcrFullReportCardResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawStudent = json['student'];
    final dynamic rawReportCard = json['report_card'];
    final dynamic rawClassList = json['classList'];

    return OcrFullReportCardResponse(
      student: rawStudent is Map<String, dynamic>
          ? OcrReportCardStudent.fromJson(rawStudent)
          : OcrReportCardStudent.fromJson(const <String, dynamic>{}),
      reportCard: rawReportCard is Map<String, dynamic>
          ? OcrReportCardInfo.fromJson(rawReportCard)
          : null,
      classList: rawClassList is List
          ? rawClassList
              .whereType<Map<String, dynamic>>()
              .map(OcrReportCardClassGroup.fromJson)
              .toList()
          : const <OcrReportCardClassGroup>[],
      className: (json['class_name'] ?? '').toString(),
      schoolName: (json['school_name'] ?? '').toString(),
    );
  }
}
