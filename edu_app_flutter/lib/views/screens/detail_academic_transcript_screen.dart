import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_texts.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/models/classroom_models.dart';
import 'package:edu_app_flutter/models/ocr_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/classroom_service.dart';
import 'package:edu_app_flutter/services/ocr_service.dart';
import 'package:edu_app_flutter/views/screens/manage_academic_transcript_screen.dart';
import 'package:edu_app_flutter/views/widgets/app_notice_modal.dart';
import 'package:edu_app_flutter/views/widgets/common_bottom_nav.dart';
import 'package:edu_app_flutter/views/widgets/grade_tabs.dart';
import 'package:edu_app_flutter/views/widgets/ocr/editable_score_table.dart';
import 'package:edu_app_flutter/views/widgets/ocr/ocr_flow_header.dart';
import 'package:flutter/material.dart';

class DetailHbaScreen extends StatefulWidget {
  const DetailHbaScreen({
    super.key,
    required this.studentId,
    this.initialClassId,
    this.editable = false,
  });

  final String studentId;
  final String? initialClassId;
  final bool editable;

  @override
  State<DetailHbaScreen> createState() => _DetailHbaScreenState();
}

class _DetailHbaScreenState extends State<DetailHbaScreen> {
  final OcrService _ocrService = OcrService();
  final ClassroomService _classroomService = ClassroomService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  int _selectedGrade = 12;
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isDeleting = false;
  bool _isLoadingClassrooms = false;
  String? _errorMessage;
  String? _selectedClassId;

  OcrFullReportCardResponse? _data;
  List<ClassroomItem> _classrooms = const <ClassroomItem>[];

  final Map<int, List<OcrScoreRow>> _editableRowsByGrade =
      <int, List<OcrScoreRow>>{
    10: const <OcrScoreRow>[],
    11: const <OcrScoreRow>[],
    12: const <OcrScoreRow>[],
  };

  @override
  void initState() {
    super.initState();
    _selectedGrade = widget.editable ? 10 : 12;
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait(<Future<void>>[
      _loadClassrooms(),
      _loadFullReportCard(),
    ]);
  }

  Future<void> _loadClassrooms() async {
    setState(() => _isLoadingClassrooms = true);
    try {
      final classrooms = await _classroomService.getClassrooms();
      if (!mounted) {
        return;
      }

      setState(() {
        _classrooms = classrooms;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _classrooms = const <ClassroomItem>[];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingClassrooms = false);
      }
    }
  }

  Future<void> _loadFullReportCard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _ocrService.getFullReportCard(
        studentId: widget.studentId,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _data = response;
        _seedEditableRows(response);
        _seedStudentInfo(response);
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Khong tai duoc chi tiet hoc ba. Vui long thu lai.';
        _isLoading = false;
      });
    }
  }

  void _seedStudentInfo(OcrFullReportCardResponse response) {
    final student = response.student;
    _nameController.text = student.name;
    _genderController.text = student.gender;
    _dobController.text = student.dob;
    _phoneController.text = student.phone;
    final passedClassId = (widget.initialClassId ?? '').trim();
    if (passedClassId.isNotEmpty) {
      _selectedClassId = passedClassId;
      return;
    }

    _selectedClassId = student.classId.isNotEmpty ? student.classId : null;
  }

  void _seedEditableRows(OcrFullReportCardResponse response) {
    final next = <int, List<OcrScoreRow>>{
      10: const <OcrScoreRow>[],
      11: const <OcrScoreRow>[],
      12: const <OcrScoreRow>[],
    };

    for (final group in response.classList) {
      final grade = int.tryParse(group.className.trim());
      if (grade == null || !next.containsKey(grade)) {
        continue;
      }

      next[grade] = group.subjects
          .map(
            (subject) => OcrScoreRow(
              subject: subject.name,
              hk1: subject.hk1,
              hk2: subject.hk2,
              caNam: subject.cn,
            ),
          )
          .toList();
    }

    _editableRowsByGrade
      ..clear()
      ..addAll(next);
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

  List<OcrScoreRow> _selectedGradeRows() {
    return _editableRowsByGrade[_selectedGrade] ?? const <OcrScoreRow>[];
  }

  void _updateRowsForSelectedGrade(List<OcrScoreRow> rows) {
    _editableRowsByGrade[_selectedGrade] = rows;
  }

  String _normalizeSubjectKey(String subject) {
    return _sanitizeSubjectName(subject).toLowerCase();
  }

  String _sanitizeSubjectName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final parts = trimmed.split(':');
    return parts.first.trim();
  }

  int? _yearFromClassLabel(String classLabel) {
    final label = classLabel.toLowerCase();
    if (label.contains('10')) {
      return 1;
    }
    if (label.contains('11')) {
      return 2;
    }
    if (label.trim().isNotEmpty) {
      return 3;
    }
    return null;
  }

  String _removeVietnameseMarks(String value) {
    return value
        .replaceAll('à', 'a')
        .replaceAll('á', 'a')
        .replaceAll('ả', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ạ', 'a')
        .replaceAll('ă', 'a')
        .replaceAll('ằ', 'a')
        .replaceAll('ắ', 'a')
        .replaceAll('ẳ', 'a')
        .replaceAll('ẵ', 'a')
        .replaceAll('ặ', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ầ', 'a')
        .replaceAll('ấ', 'a')
        .replaceAll('ẩ', 'a')
        .replaceAll('ẫ', 'a')
        .replaceAll('ậ', 'a')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ẻ', 'e')
        .replaceAll('ẽ', 'e')
        .replaceAll('ẹ', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ề', 'e')
        .replaceAll('ế', 'e')
        .replaceAll('ể', 'e')
        .replaceAll('ễ', 'e')
        .replaceAll('ệ', 'e')
        .replaceAll('ì', 'i')
        .replaceAll('í', 'i')
        .replaceAll('ỉ', 'i')
        .replaceAll('ĩ', 'i')
        .replaceAll('ị', 'i')
        .replaceAll('ò', 'o')
        .replaceAll('ó', 'o')
        .replaceAll('ỏ', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ọ', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ồ', 'o')
        .replaceAll('ố', 'o')
        .replaceAll('ổ', 'o')
        .replaceAll('ỗ', 'o')
        .replaceAll('ộ', 'o')
        .replaceAll('ơ', 'o')
        .replaceAll('ờ', 'o')
        .replaceAll('ớ', 'o')
        .replaceAll('ở', 'o')
        .replaceAll('ỡ', 'o')
        .replaceAll('ợ', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('ú', 'u')
        .replaceAll('ủ', 'u')
        .replaceAll('ũ', 'u')
        .replaceAll('ụ', 'u')
        .replaceAll('ư', 'u')
        .replaceAll('ừ', 'u')
        .replaceAll('ứ', 'u')
        .replaceAll('ử', 'u')
        .replaceAll('ữ', 'u')
        .replaceAll('ự', 'u')
        .replaceAll('ỳ', 'y')
        .replaceAll('ý', 'y')
        .replaceAll('ỷ', 'y')
        .replaceAll('ỹ', 'y')
        .replaceAll('ỵ', 'y')
        .replaceAll('đ', 'd');
  }

  String _normalizeScoreForPayload(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final normalizedText = _removeVietnameseMarks(trimmed.toLowerCase())
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalizedText == 'dat') {
      return 'dat';
    }
    if (normalizedText == 'khong dat') {
      return 'khong_dat';
    }

    final withDot = trimmed.replaceAll(',', '.');
    final number = double.tryParse(withDot);
    if (number != null) {
      return number.toString();
    }

    return trimmed;
  }

  Map<int, Map<String, OcrScoreRow>> _buildRowsByGradeFromExistingSubjects() {
    final rowsByGrade = <int, Map<String, OcrScoreRow>>{
      10: <String, OcrScoreRow>{},
      11: <String, OcrScoreRow>{},
      12: <String, OcrScoreRow>{},
    };

    final data = _data;
    if (data == null) {
      return rowsByGrade;
    }

    for (final classGroup in data.classList) {
      final grade = int.tryParse(classGroup.className.trim());
      final safeGrade = grade ?? (9 + (_yearFromClassLabel(classGroup.className) ?? 0));
      if (!rowsByGrade.containsKey(safeGrade)) {
        continue;
      }
      final gradeRows = rowsByGrade[safeGrade]!;

      for (final subject in classGroup.subjects) {
        final name = _sanitizeSubjectName(subject.name);
        if (name.isEmpty) {
          continue;
        }

        final key = _normalizeSubjectKey(name);
        gradeRows[key] = OcrScoreRow(
          subject: name,
          hk1: _normalizeScoreForPayload(subject.hk1),
          hk2: _normalizeScoreForPayload(subject.hk2),
          caNam: _normalizeScoreForPayload(subject.cn),
        );
      }
    }

    return rowsByGrade;
  }

  void _overlayEditedRowsOnRowsByGrade(Map<int, Map<String, OcrScoreRow>> rowsByGrade) {
    for (final grade in <int>[10, 11, 12]) {
      final gradeRows = rowsByGrade.putIfAbsent(grade, () => <String, OcrScoreRow>{});
      final rows = _editableRowsByGrade[grade] ?? const <OcrScoreRow>[];
      for (final row in rows) {
        final subjectName = _sanitizeSubjectName(row.subject);
        if (subjectName.isEmpty) {
          continue;
        }

        final key = _normalizeSubjectKey(subjectName);
        gradeRows[key] = OcrScoreRow(
          subject: subjectName,
          hk1: _normalizeScoreForPayload(row.hk1),
          hk2: _normalizeScoreForPayload(row.hk2),
          caNam: _normalizeScoreForPayload(row.caNam),
        );
      }
    }
  }

  List<OcrUpdateSubjectItem> _buildSubjectsForUpdate() {
    final rowsByGrade = _buildRowsByGradeFromExistingSubjects();
    _overlayEditedRowsOnRowsByGrade(rowsByGrade);

    final items = <OcrUpdateSubjectItem>[];
    const yearByGrade = <int, int>{10: 1, 11: 2, 12: 3};

    for (final grade in <int>[10, 11, 12]) {
      final year = yearByGrade[grade]!;
      final rows = rowsByGrade[grade]?.values.toList() ?? const <OcrScoreRow>[];
      for (final row in rows) {
        final subjectName = _sanitizeSubjectName(row.subject);
        if (subjectName.isEmpty) {
          continue;
        }

        final hk1 = _normalizeScoreForPayload(row.hk1);
        final hk2 = _normalizeScoreForPayload(row.hk2);
        final cn = _normalizeScoreForPayload(row.caNam);

        items.add(
          OcrUpdateSubjectItem(
            name: subjectName,
            year: year,
            year1Sem1Score: year == 1 ? hk1 : null,
            year1Sem2Score: year == 1 ? hk2 : null,
            year1FinalScore: year == 1 ? cn : null,
            year2Sem1Score: year == 2 ? hk1 : null,
            year2Sem2Score: year == 2 ? hk2 : null,
            year2FinalScore: year == 2 ? cn : null,
            year3Sem1Score: year == 3 ? hk1 : null,
            year3Sem2Score: year == 3 ? hk2 : null,
            year3FinalScore: year == 3 ? cn : null,
          ),
        );
      }
    }

    return items;
  }

  Future<void> _confirmUpdateReportCard() async {
    if (_isUpdating) {
      return;
    }

    final data = _data;
    if (data == null) {
      return;
    }

    final reportCardId = data.reportCard?.id.trim() ?? '';
    if (reportCardId.isEmpty) {
      await AppNoticeModal.showError(
        context,
        title: 'Khong co hoc ba',
        message: 'Khong tim thay report_card_id de cap nhat.',
      );
      return;
    }

    final selectedClass = _selectedClassroom;
    final classId = selectedClass?.id.trim() ?? data.student.classId.trim();
    if (classId.isEmpty) {
      await AppNoticeModal.showError(
        context,
        title: 'Thieu thong tin lop',
        message: 'Khong tim thay class_id de cap nhat hoc ba.',
      );
      return;
    }

    if (data.classList.isEmpty) {
      await AppNoticeModal.showError(
        context,
        title: 'Thieu du lieu hoc ba',
        message: 'Chua co classList de cap nhat hoc ba.',
      );
      return;
    }

    final subjects = _buildSubjectsForUpdate();
    if (subjects.isEmpty) {
      await AppNoticeModal.showError(
        context,
        title: 'Du lieu khong hop le',
        message: 'Khong co mon hop le de cap nhat.',
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final response = await _ocrService.updateReportCard(
        reportCardId: reportCardId,
        request: OcrUpdateReportCardRequest(
          studentId: data.student.id.trim().isEmpty
              ? widget.studentId
              : data.student.id,
          classId: classId,
          subjects: subjects,
        ),
      );

      if (!mounted) {
        return;
      }

      await AppNoticeModal.showSuccess(
        context,
        title: 'Cap nhat thanh cong',
        message: response.message.isEmpty
            ? 'Da cap nhat hoc ba thanh cong.'
            : response.message,
        showAction: false,
        autoDismissDuration: const Duration(milliseconds: 1200),
        barrierDismissible: false,
      );

      if (!mounted) {
        return;
      }

      await _loadFullReportCard();
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      await AppNoticeModal.showError(context, message: e.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      await AppNoticeModal.showError(
        context,
        message: 'Khong the cap nhat hoc ba. Vui long thu lai.',
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<bool?> _showDeleteReportCardConfirm() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xac nhan xoa hoc ba'),
          content: const Text('Ban co chac chan muon xoa hoc ba nay khong?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Huy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xoa'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmAndDeleteCurrentReportCard() async {
    if (_isDeleting) {
      return;
    }

    final shouldDelete = await _showDeleteReportCardConfirm();
    if (!mounted || shouldDelete != true) {
      return;
    }

    final reportCardId = _data?.reportCard?.id.trim() ?? '';
    if (reportCardId.isEmpty) {
      await AppNoticeModal.showError(
        context,
        title: 'Khong co hoc ba de xoa',
        message: 'Khong tim thay report_card_id hop le.',
      );
      return;
    }

    setState(() => _isDeleting = true);

    try {
      final message = await _ocrService.deleteFullReportCard(
        reportCardId: reportCardId,
      );

      if (!mounted) {
        return;
      }

      await AppNoticeModal.showSuccess(
        context,
        title: 'Xoa hoc ba thanh cong',
        message: message,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ListHbaScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      await AppNoticeModal.showError(context, message: e.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      await AppNoticeModal.showError(
        context,
        message: 'Khong the xoa hoc ba. Vui long thu lai.',
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                OcrFlowHeader(
                  title: AppTexts.detailHbaTitle,
                  subtitle: AppTexts.detailHbaSubtitle,
                  onBack: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const ListHbaScreen()),
                    );
                  },
                  trailing: Material(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _isDeleting ? null : _confirmAndDeleteCurrentReportCard,
                      child: _isDeleting
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white,
                                  ),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.white,
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 150),
                    child: _buildBody(),
                  ),
                ),
              ],
            ),
            const Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: CommonBottomNav(currentTab: BottomNavTab.classes),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD4D4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Khong the tai hoc ba',
              style: TextStyle(
                fontSize: AppFontSizes.dashboardBody,
                fontWeight: FontWeight.w800,
                color: Color(0xFFB42318),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: AppFontSizes.dashboardCaption,
                color: AppColors.label,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: OutlinedButton.icon(
                onPressed: _loadFullReportCard,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thu lai'),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildProfileCard(),
        const SizedBox(height: 12),
        _buildResultTableCard(),
        if (widget.editable) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isUpdating ? null : _confirmUpdateReportCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Xac nhan',
                      style: TextStyle(
                        fontSize: AppFontSizes.dashboardBody,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildTeacherCommentCard(),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildProfileCard() {
    final student = _data?.student;
    final className = _selectedClassroom?.name ?? _data?.className ?? '';
    final schoolName = _selectedClassroom?.schoolName ?? _data?.schoolName ?? '';

    if (widget.editable) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thong tin chung sinh vien',
              style: TextStyle(
                fontSize: AppFontSizes.dashboardBody,
                fontWeight: FontWeight.w800,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 10),
            _buildEditableField('Ho ten', _nameController),
            const SizedBox(height: 10),
            _buildEditableField('Gioi tinh', _genderController),
            const SizedBox(height: 10),
            _buildEditableField('Ngay thang nam sinh', _dobController),
            const SizedBox(height: 10),
            _buildEditableField('So dien thoai', _phoneController),
            const SizedBox(height: 12),
            const Text(
              'Lop',
              style: TextStyle(
                fontSize: AppFontSizes.dashboardCaption,
                fontWeight: FontWeight.w700,
                color: AppColors.subtitle,
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoadingClassrooms)
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _classrooms.map((classroom) {
                    final selected = _selectedClassId == classroom.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(classroom.name),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _selectedClassId = classroom.id;
                          });
                        },
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 10),
            _buildInfoRow('Truong', schoolName),
            _buildInfoRow('Lop', className),
          ],
        ),
      );
    }

    final studentName = student?.name ?? '';
    final gender = student?.gender ?? '';
    final dob = student?.dob ?? '';
    final phone = student?.phone ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thong tin chung sinh vien',
            style: TextStyle(
              fontSize: AppFontSizes.dashboardBody,
              fontWeight: FontWeight.w800,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Ho ten', studentName),
          _buildInfoRow('Lop', className),
          _buildInfoRow('Gioi tinh', gender),
          _buildInfoRow('Ngay thang nam sinh', dob),
          _buildInfoRow('Truong', schoolName),
          _buildInfoRow('So dien thoai', phone),
        ],
      ),
    );
  }

  Widget _buildResultTableCard() {
    final rows = _selectedGradeRows();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: GradeTabs(
              selectedGrade: _selectedGrade,
              onChanged: (grade) {
                if (_selectedGrade == grade) {
                  return;
                }
                setState(() => _selectedGrade = grade);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: rows.isEmpty
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Khong co du lieu diem cho lop nay.',
                      style: TextStyle(
                        fontSize: AppFontSizes.dashboardCaption,
                        color: AppColors.subtitle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : EditableScoreTable(
                    rows: rows,
                    readOnly: !widget.editable,
                    onChanged: widget.editable ? _updateRowsForSelectedGrade : null,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCommentCard() {
    final comment = _data?.reportCard?.teacherComment ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.comment_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 6),
              Text(
                AppTexts.detailTeacherComment,
                style: TextStyle(
                  fontSize: AppFontSizes.dashboardBody,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F7FF),
              borderRadius: BorderRadius.circular(10),
              border: const Border(
                left: BorderSide(color: AppColors.primary, width: 4),
              ),
            ),
            child: Text(
              comment.isNotEmpty ? comment : 'Chua co nhan xet tu giao vien.',
              style: const TextStyle(
                fontSize: AppFontSizes.dashboardBody,
                height: 1.45,
                color: AppColors.label,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppFontSizes.dashboardCaption,
                fontWeight: FontWeight.w700,
                color: AppColors.subtitle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppFontSizes.dashboardBody,
                fontWeight: FontWeight.w600,
                color: AppColors.title,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
