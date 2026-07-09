import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/api_config.dart';
import 'package:edu_app_flutter/constants/app_texts.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/models/classroom_models.dart';
import 'package:edu_app_flutter/models/ocr_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/classroom_service.dart';
import 'package:edu_app_flutter/services/ocr_service.dart';
import 'package:edu_app_flutter/views/screens/detail_academic_transcript_screen.dart';
import 'package:edu_app_flutter/views/widgets/app_notice_modal.dart';
import 'package:edu_app_flutter/views/widgets/grade_tabs.dart';
import 'package:edu_app_flutter/views/widgets/ocr/editable_score_table.dart';
import 'package:edu_app_flutter/views/widgets/ocr/ocr_flow_header.dart';
import 'package:flutter/material.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key, required this.imageInputs});

  final List<OcrDetectImageInput> imageInputs;

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen>
    with SingleTickerProviderStateMixin {
  static final Random _random = Random();
  int _selectedGrade = 10;
  String? _selectedClassId;
  String? _studentId;
  final OcrService _ocrService = OcrService();
  final ClassroomService _classroomService = ClassroomService();
  bool _isDetecting = true;
  bool _isLoadingClassrooms = true;
  bool _isSaving = false;
  String? _detectError;
  String? _classroomError;
  List<OcrDetectResult> _ocrResults = const <OcrDetectResult>[];
  List<ClassroomItem> _classrooms = const <ClassroomItem>[];
  late final AnimationController _scanController;
  late final Animation<double> _scanPosition;
  final Map<int, List<OcrScoreRow>> _scoresByGrade = <int, List<OcrScoreRow>>{
    10: const <OcrScoreRow>[],
    11: const <OcrScoreRow>[],
    12: const <OcrScoreRow>[],
  };
  final Map<int, String> _cropImageUrlByGrade = <int, String>{};

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scanPosition = CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    );
    _loadClassrooms();
    _runDetect();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _nameController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    super.dispose();
  }

// animation scanning
  void _syncScanAnimation() {
    if (_isDetecting) {
      if (!_scanController.isAnimating) {
        _scanController.repeat(reverse: true);
      }
    } else {
      _scanController.stop();
      _scanController.value = 0;
    }
  }

  Future<void> _runDetect() async {
    if (widget.imageInputs.isEmpty) {
      setState(() {
        _isDetecting = false;
        _detectError = 'Không có ảnh để quét.';
      });
      _syncScanAnimation();
      return;
    }

    setState(() {
      _isDetecting = true;
      _detectError = null;
      _cropImageUrlByGrade.clear();
    });
    _syncScanAnimation();

    try {
      final results = await _ocrService.detectReportCard(
        images: widget.imageInputs,
      );

      if (!mounted) return;

      _logOcrData(results);
      _applyStudentInfo(results);
      _mapScoresToGrades(results);

      setState(() {
        _ocrResults = results;
        _isDetecting = false;
      });
      _syncScanAnimation();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isDetecting = false;
        _detectError = e.message;
      });
      _syncScanAnimation();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDetecting = false;
        _detectError = 'Quét học bạ thất bại. Vui lòng thử lại.';
      });
      _syncScanAnimation();
    }
  }

  Future<void> _loadClassrooms() async {
    setState(() {
      _isLoadingClassrooms = true;
      _classroomError = null;
    });

    try {
      final classrooms = await _classroomService.getClassrooms();
      if (!mounted) return;

      setState(() {
        _classrooms = classrooms;
        _selectedClassId = classrooms.isNotEmpty ? classrooms.first.id : null;
        _isLoadingClassrooms = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingClassrooms = false;
        _classroomError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingClassrooms = false;
        _classroomError = 'Không tải được danh sách lớp. Vui lòng thử lại.';
      });
    }
  }

  void _applyStudentInfo(List<OcrDetectResult> results) {
    if (results.isEmpty) return;

    OcrDetectResult firstResult = results.first;
    for (final item in results) {
      if (item.role == OcrImageRole.studentInfo) {
        firstResult = item;
        break;
      }
    }

    final studentInfo = firstResult.studentInfo;

    final name = (studentInfo['name'] ?? studentInfo['full_name'] ?? '')
        .toString()
        .trim();
    final gender =
      (studentInfo['gender'] ?? studentInfo['sex'] ?? '').toString().trim();
    final dob =
      (studentInfo['dob'] ?? studentInfo['date_of_birth'] ?? '').toString().trim();

    _nameController.text = name;
    _genderController.text = gender;
    _dobController.text = dob;
    _studentId ??= _generateStudentId();
  }

  void _mapScoresToGrades(List<OcrDetectResult> results) {
    final next = <int, List<OcrScoreRow>>{
      10: const <OcrScoreRow>[],
      11: const <OcrScoreRow>[],
      12: const <OcrScoreRow>[],
    };
    final nextCropUrls = <int, String>{};

    for (final item in results) {
      if (item.role == OcrImageRole.grade10) {
        next[10] = List<OcrScoreRow>.from(item.scores);
        if (item.imageUrl.trim().isNotEmpty) {
          nextCropUrls[10] = item.imageUrl.trim();
        }
      }
      if (item.role == OcrImageRole.grade11) {
        next[11] = List<OcrScoreRow>.from(item.scores);
        if (item.imageUrl.trim().isNotEmpty) {
          nextCropUrls[11] = item.imageUrl.trim();
        }
      }
      if (item.role == OcrImageRole.grade12) {
        next[12] = List<OcrScoreRow>.from(item.scores);
        if (item.imageUrl.trim().isNotEmpty) {
          nextCropUrls[12] = item.imageUrl.trim();
        }
      }
    }

    _scoresByGrade
      ..clear()
      ..addAll(next);
    _cropImageUrlByGrade
      ..clear()
      ..addAll(nextCropUrls);
  }

  void _updateScoresForSelectedGrade(List<OcrScoreRow> rows) {
    _scoresByGrade[_selectedGrade] = rows;
  }

  void _logOcrData(List<OcrDetectResult> results) {
    if (results.isEmpty) {
      debugPrint('Không có kết quả.');
      return;
    }

    for (var i = 0; i < results.length; i++) {
      final item = results[i];
      final dynamic ocrData = item.rawOcrData;
      final fullResultMap = <String, dynamic>{
        'image_url': item.imageUrl,
        'student_info': item.studentInfo,
        'ocr_data': item.rawOcrData,
      };

      debugPrint('[OCR][detect] result_index=$i role=${item.role.name}');
      debugPrint('[OCR][detect] ocr_data_type=${ocrData.runtimeType}');
      _debugPrintLong(
        '[OCR][detect] full_result_json=${jsonEncode(fullResultMap)}',
      );

      try {
        _debugPrintLong('[OCR][detect] ocr_data_json=${jsonEncode(ocrData)}');
      } catch (_) {
        debugPrint('[OCR][detect] ocr_data_toString=$ocrData');
      }
    }
  }

  void _debugPrintLong(String message) {
    const chunkSize = 700;
    for (var i = 0; i < message.length; i += chunkSize) {
      final end = (i + chunkSize < message.length)
          ? i + chunkSize
          : message.length;
      debugPrint(message.substring(i, end));
    }
  }

  ClassroomItem? get _selectedClassroom {
    final id = _selectedClassId;
    if (id == null || id.isEmpty) {
      return null;
    }

    for (final classroom in _classrooms) {
      if (classroom.id == id) {
        return classroom;
      }
    }
    return null;
  }

  List<OcrSaveSubjectItem> _buildSubjectsForSave() {
    final List<OcrSaveSubjectItem> subjects = <OcrSaveSubjectItem>[];
    final gradeYearMap = <int, int>{10: 1, 11: 2, 12: 3};

    for (final entry in gradeYearMap.entries) {
      final rows = _scoresByGrade[entry.key] ?? const <OcrScoreRow>[];
      for (final row in rows) {
        final subjectName = row.subject.trim();
        final hk1 = row.hk1.trim();
        final hk2 = row.hk2.trim();
        final caNam = row.caNam.trim();

        // Skip subject when either semester score is empty.
        if (hk1.isEmpty || hk2.isEmpty) {
          continue;
        }

        if (subjectName.isEmpty) {
          continue;
        }

        subjects.add(
          OcrSaveSubjectItem(
            name: subjectName,
            year: entry.value,
            sem1Score: hk1,
            sem2Score: hk2,
            finalScore: caNam.isEmpty ? null : caNam,
          ),
        );
      }
    }

    return subjects;
  }

  String _generateStudentId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomSuffix = _random.nextInt(10000).toString().padLeft(4, '0');
    return 'student_$timestamp$randomSuffix';
  }

  String _resolveStudentId() {
    _studentId ??= _generateStudentId();
    return _studentId!;
  }

  String _resolveCropImageUrl(String imageUrl) {
    final trimmed = imageUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '${ApiConfig.baseUrl}$trimmed';
    }
    return '${ApiConfig.baseUrl}/$trimmed';
  }

  Future<void> _showCropImageDialog(int grade) async {
    final imageUrl = _cropImageUrlByGrade[grade]?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      await AppNoticeModal.showError(
        context,
        title: 'Chưa có ảnh đối chiếu',
        message: 'Không tìm thấy ảnh crop của lớp $grade trong kết quả OCR.',
      );
      return;
    }

    final resolvedUrl = _resolveCropImageUrl(imageUrl);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF4FF),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFDCE5F4)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ảnh crop lớp $grade',
                          style: const TextStyle(
                            fontSize: AppFontSizes.dashboardBody,
                            fontWeight: FontWeight.w800,
                            color: AppColors.title,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.72,
                    ),
                    color: const Color(0xFFF8FAFF),
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      child: Image.network(
                        resolvedUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            height: 360,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return SizedBox(
                            height: 260,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Text(
                                  'Không tải được ảnh crop.\n$resolvedUrl',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: AppFontSizes.dashboardCaption,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFB42318),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveReportCard() async {
    if (_isSaving) {
      return;
    }

    final selectedClassroom = _selectedClassroom;
    if (selectedClassroom == null) {
      await AppNoticeModal.showError(
        context,
        title: 'Thiếu thông tin',
        message: 'Vui lòng chọn lớp trước khi lưu học bạ.',
      );
      return;
    }

    final studentName = _nameController.text.trim();
    if (studentName.isEmpty) {
      await AppNoticeModal.showError(
        context,
        title: 'Thiếu thông tin',
        message: 'Vui lòng nhập tên học sinh.',
      );
      return;
    }

    final subjects = _buildSubjectsForSave();
    if (subjects.isEmpty) {
      await AppNoticeModal.showError(
        context,
        title: 'Dữ liệu không hợp lệ',
        message: 'Cần ít nhất điểm HK1 hoặc HK2.',
      );
      return;
    }

    final request = OcrSaveFullReportCardRequest(
      studentId: _resolveStudentId(),
      studentName: studentName,
      studentDob: _dobController.text.trim(),
      studentGender: _genderController.text.trim(),
      classId: selectedClassroom.id,
      schoolYear: selectedClassroom.classYear,
      subjects: subjects,
    );

    setState(() => _isSaving = true);

    try {
      final response = await _ocrService.saveFullReportCard(request: request);
      if (!mounted) return;

      await AppNoticeModal.showSuccess(
        context,
        title: 'Lưu thành công',
        message: response.message.isEmpty
            ? 'Lưu học bạ thành công.'
            : response.message,
        showAction: false,
        autoDismissDuration: const Duration(milliseconds: 1400),
        barrierDismissible: false,
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DetailHbaScreen(studentId: _resolveStudentId()),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      await AppNoticeModal.showError(
        context,
        message: e.message,
      );
    } catch (_) {
      if (!mounted) return;
      await AppNoticeModal.showError(
        context,
        message: 'Lưu học bạ thất bại. Vui lòng thử lại.',
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? firstPath = widget.imageInputs.isEmpty
        ? null
      : widget.imageInputs.first.path;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OcrFlowHeader(
              title: AppTexts.preOcrTitle,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isDetecting) ...[
                      _buildPreviewCard(firstPath),
                      const SizedBox(height: 14),
                      _buildProgressCard(),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      AppTexts.ocrResultTitle,
                      style: TextStyle(
                        fontSize: AppFontSizes.dashboardTitle,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildGeneralInfoCard(),
                    const SizedBox(height: 14),
                    GradeTabs(
                      selectedGrade: _selectedGrade,
                      onChanged: (grade) {
                        if (_selectedGrade == grade) return;
                        setState(() => _selectedGrade = grade);
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildScoresCard(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1337EC), Color(0xFF2458F3)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x332348EF),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: _isSaving ? null : _saveReportCard,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: AppFontSizes.signInButton,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(AppTexts.preOcrConfirm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(String? firstPath) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: firstPath == null
                  ? Container(
                      color: const Color(0xFFE9EEFA),
                      child: const Center(
                        child: Icon(
                          Icons.document_scanner_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(firstPath), fit: BoxFit.cover),
                        Container(
                          color: AppColors.primary.withValues(alpha: 0.136),
                        ),
                        if (_isDetecting)
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _scanPosition,
                              builder: (context, child) {
                                final double usableHeight =
                                    MediaQuery.sizeOf(context).width * 0.75;
                                final double scannerHeight = 84;
                                final double maxTop =
                                    (usableHeight - scannerHeight).clamp(
                                  0.0,
                                  double.infinity,
                                );
                                final double top = maxTop * _scanPosition.value;

                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double overlayHeight =
                                        constraints.maxHeight;
                                    final double safeMaxTop =
                                        (overlayHeight - scannerHeight)
                                            .clamp(0.0, double.infinity);
                                    final double safeTop =
                                        safeMaxTop * _scanPosition.value;

                                    return Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          top: safeTop,
                                          child: IgnorePointer(
                                            child: Container(
                                              height: scannerHeight,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    AppColors.primary
                                                        .withValues(alpha: 0.0),
                                                    AppColors.primary
                                                        .withValues(alpha: 0.26),
                                                    AppColors.primary
                                                        .withValues(alpha: 0.78),
                                                    AppColors.primary
                                                        .withValues(alpha: 0.26),
                                                    AppColors.primary
                                                        .withValues(alpha: 0.0),
                                                  ],
                                                  stops: const [
                                                    0.0,
                                                    0.35,
                                                    0.5,
                                                    0.65,
                                                    1.0,
                                                  ],
                                                ),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Color(0x661337EC),
                                                    blurRadius: 18,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 12,
                                          right: 12,
                                          top: safeTop + 26,
                                          child: IgnorePointer(
                                            child: Container(
                                              height: 2.5,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.9),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        AppTexts.ocrPreviewTitle,
                        style: TextStyle(
                          fontSize: AppFontSizes.dashboardBody,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      firstPath == null
                          ? 'Không có ảnh'
                          : firstPath.split(Platform.pathSeparator).last,
                      style: const TextStyle(
                        fontSize: AppFontSizes.dashboardCaption,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  AppTexts.ocrPreviewHint,
                  style: TextStyle(
                    fontSize: AppFontSizes.dashboardCaption,
                    fontWeight: FontWeight.w500,
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final int percent = _isDetecting ? 0 : 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.sync_rounded,
                color: AppColors.primary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  AppTexts.ocrProgressLabel,
                  style: TextStyle(
                    fontSize: AppFontSizes.dashboardBody,
                    fontWeight: FontWeight.w600,
                    color: AppColors.label,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: AppFontSizes.dashboardBody,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _isDetecting ? null : 1,
              minHeight: 8,
              backgroundColor: const Color(0xFFE8EEFF),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EditableField(
            label: AppTexts.ocrStudentName,
            controller: _nameController,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _EditableField(
                  label: AppTexts.ocrGender,
                  controller: _genderController,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EditableField(
                  label: AppTexts.ocrDateOfBirth,
                  controller: _dobController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Lớp',
            style: TextStyle(
              fontSize: AppFontSizes.dashboardCaption,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoadingClassrooms)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_classroomError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD4D4)),
              ),
              child: Text(
                _classroomError!,
                style: const TextStyle(
                  fontSize: AppFontSizes.dashboardCaption,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB42318),
                ),
              ),
            )
          else if (_classrooms.isEmpty)
            const Text(
              'Bạn chưa có lớp học nào. Hãy tạo lớp trước khi lưu học bạ.',
              style: TextStyle(
                fontSize: AppFontSizes.dashboardCaption,
                color: AppColors.subtitle,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _classrooms.map((classroom) {
                  final bool isSelected = _selectedClassId == classroom.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(classroom.name),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedClassId = classroom.id);
                      },
                      labelStyle: TextStyle(
                        fontSize: AppFontSizes.dashboardCaption,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: const Color(0xFFEFF3FF),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFD8E2FF),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          if (_detectError != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD4D4)),
              ),
              child: Text(
                _detectError!,
                style: const TextStyle(
                  fontSize: AppFontSizes.dashboardCaption,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB42318),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoresCard() {
    final cropImageUrl = _cropImageUrlByGrade[_selectedGrade]?.trim();
    final hasCropImage = cropImageUrl != null && cropImageUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bảng điểm lớp $_selectedGrade',
                  style: const TextStyle(
                    fontSize: AppFontSizes.dashboardBody,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: hasCropImage
                    ? () => _showCropImageDialog(_selectedGrade)
                    : null,
                icon: const Icon(Icons.image_search_rounded, size: 18),
                label: const Text('Kiểm tra lại điểm'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  disabledForegroundColor: AppColors.subtitle,
                  side: BorderSide(
                    color: hasCropImage
                        ? AppColors.primary
                        : const Color(0xFFD6DFEE),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if ((_scoresByGrade[_selectedGrade] ?? const <OcrScoreRow>[]).isEmpty)
            const Text(
              'Lớp này chưa có dữ liệu điểm OCR.',
              style: TextStyle(
                fontSize: AppFontSizes.dashboardCaption,
                color: AppColors.subtitle,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            EditableScoreTable(
              rows: _scoresByGrade[_selectedGrade] ?? const <OcrScoreRow>[],
              onChanged: _updateScoresForSelectedGrade,
            ),
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppFontSizes.dashboardCaption,
            fontWeight: FontWeight.w700,
            color: AppColors.subtitle,
          ),
        ),
        TextField(
          controller: controller,
          style: const TextStyle(
            fontSize: AppFontSizes.dashboardBody,
            fontWeight: FontWeight.w700,
            color: AppColors.title,
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.only(top: 8, bottom: 6),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE9EEF7)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

