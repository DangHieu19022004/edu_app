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
