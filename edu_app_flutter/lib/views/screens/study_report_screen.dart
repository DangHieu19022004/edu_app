import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/models/classroom_models.dart';
import 'package:edu_app_flutter/models/contact_models.dart';
import 'package:edu_app_flutter/models/ocr_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/auth_session.dart';
import 'package:edu_app_flutter/services/classroom_service.dart';
import 'package:edu_app_flutter/services/contact_service.dart';
import 'package:edu_app_flutter/services/ocr_service.dart';
import 'package:edu_app_flutter/views/widgets/app_notice_modal.dart';
import 'package:edu_app_flutter/views/widgets/common_bottom_nav.dart';
import 'package:edu_app_flutter/views/widgets/ocr/ocr_flow_header.dart';
import 'package:flutter/material.dart';

class StudyReportScreen extends StatefulWidget {
  const StudyReportScreen({super.key});

  @override
  State<StudyReportScreen> createState() => _StudyReportScreenState();
}

class _StudyReportScreenState extends State<StudyReportScreen> {
  final ContactService _contactService = ContactService();
  final ClassroomService _classroomService = ClassroomService();
  final OcrService _ocrService = OcrService();

  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();

  final TextEditingController _mailSubjectController = TextEditingController();
  final TextEditingController _mailRecipientController = TextEditingController();
  final TextEditingController _mailMessageController = TextEditingController();

  int _selectedTab = 0;
  bool _isSavingParent = false;
  bool _isScheduling = false;
  bool _isSendingNow = false;
  bool _isLoadingHistory = false;
  bool _isLoadingClasses = false;
  bool _isLoadingStudents = false;
  bool _isLoadingParents = false;
  final Set<String> _deletingHistoryIds = <String>{};

  DateTime? _scheduledAt;
  List<ScheduledEmailItem> _history = const <ScheduledEmailItem>[];
  List<ParentItem> _parents = const <ParentItem>[];
  List<ClassroomItem> _classrooms = const <ClassroomItem>[];
  List<StudentInClassItem> _students = const <StudentInClassItem>[];
  String? _selectedClassId;
  String? _selectedStudentId;
  String? _selectedScheduleClassId;
  final Set<String> _selectedScheduleParentIds = <String>{};
  bool _isGeneratingScheduleMessage = false;
  final Map<String, StudentInClassItem> _studentDetailCache =
      <String, StudentInClassItem>{};
  final Map<String, String> _scoreSummaryCache = <String, String>{};

  String _resolveSchoolForParent(ParentItem parent) {
    final schoolFromApi = parent.studentSchool.trim();
    if (schoolFromApi.isNotEmpty) {
      return schoolFromApi;
    }

    final className = parent.studentClass.trim().toLowerCase();
    if (className.isEmpty) {
      return '';
    }

    for (final classroom in _classrooms) {
      if (classroom.name.trim().toLowerCase() == className) {
        return classroom.schoolName;
      }
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _mailSubjectController.text = _buildScheduleSubjectPreviewTemplate();
    _mailMessageController.text = _buildScheduleMessagePreviewTemplate();
    _loadClassroomsForContact();
    _loadParents();
    _loadHistory();
  }

  @override
  void dispose() {
    _parentNameController.dispose();
    _parentEmailController.dispose();
    _parentPhoneController.dispose();
    _mailSubjectController.dispose();
    _mailRecipientController.dispose();
    _mailMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadClassroomsForContact() async {
    setState(() => _isLoadingClasses = true);
    try {
      final classrooms = await _classroomService.getClassrooms();
      if (!mounted) {
        return;
      }

      final nextClassId = classrooms.isNotEmpty ? classrooms.first.id : null;
      setState(() {
        _classrooms = classrooms;
        _selectedClassId = nextClassId;
        _selectedScheduleClassId = nextClassId;
        _selectedStudentId = null;
      });

      if (nextClassId != null && nextClassId.isNotEmpty) {
        await _loadStudentsForClass(nextClassId);
      }
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
        message: 'Không thể tải danh sách, vui lòng thử lại.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingClasses = false);
      }
    }
  }

  Future<void> _loadStudentsForClass(String classId) async {
    final trimmedClassId = classId.trim();
    if (trimmedClassId.isEmpty) {
      setState(() {
        _students = const <StudentInClassItem>[];
        _selectedStudentId = null;
      });
      return;
    }

    setState(() => _isLoadingStudents = true);
    try {
      final students = await _classroomService.getStudentsByClass(classId: trimmedClassId);
      if (!mounted) {
        return;
      }
      setState(() {
        _students = students;
        _selectedStudentId = null;
      });
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
        message: 'Không thể tải danh sách học sinh. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingStudents = false);
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final items = await _contactService.getScheduledEmails();
      if (!mounted) {
        return;
      }
      setState(() => _history = items);
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
        message: 'Không thể tải lịch sử gửi email. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _deleteScheduledEmail(ScheduledEmailItem item) async {
    final emailId = item.id.trim();
    if (emailId.isEmpty) {
      await AppNoticeModal.showError(
        context,
        message: 'Không tìm thấy id lịch email để xóa.',
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa lịch email'),
          content: const Text('Bạn có chắc muốn xóa lịch gửi email này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _deletingHistoryIds.add(emailId);
    });

    try {
      final response = await _contactService.deleteEmailSchedule(id: emailId);
      if (!mounted) {
        return;
      }

      setState(() {
        _history = _history.where((historyItem) => historyItem.id != emailId).toList();
      });

      await AppNoticeModal.showSuccess(
        context,
        title: 'Xóa thành công',
        message: response.message.isEmpty ? 'Đã xóa lịch email.' : response.message,
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
        message: 'Không thể xóa lịch email. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingHistoryIds.remove(emailId);
        });
      }
    }
  }

  Future<void> _loadParents() async {
    setState(() => _isLoadingParents = true);
    try {
      final items = await _contactService.getParents();
      if (!mounted) {
        return;
      }
      setState(() {
        _parents = items;
        _selectedScheduleParentIds.removeWhere(
          (id) => !_parents.any((item) => item.id == id),
        );
      });
      _refreshSchedulePreview();
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
        message: 'Không thể tải danh sách phụ huynh. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingParents = false);
      }
    }
  }

  Future<void> _saveParentContact() async {
    final teacherId = (AuthSession.instance.uid ?? '').trim();
    final studentId = (_selectedStudentId ?? '').trim();
    final fullName = _parentNameController.text.trim();
    final email = _parentEmailController.text.trim();
    final phone = _parentPhoneController.text.trim();

    if (teacherId.isEmpty || studentId.isEmpty || fullName.isEmpty || email.isEmpty || phone.isEmpty) {
      await AppNoticeModal.showError(
        context,
        message: 'Vui lòng nhập đầy đủ thông tin liên hệ.',
      );
      return;
    }

    setState(() => _isSavingParent = true);
    try {
      final response = await _contactService.saveParent(
        request: SaveParentRequest(
          teacherId: teacherId,
          studentId: studentId,
          fullName: fullName,
          email: email,
          phone: phone,
        ),
      );
      if (!mounted) {
        return;
      }

      _parentNameController.clear();
      _parentEmailController.clear();
      _parentPhoneController.clear();
      _selectedStudentId = null;
      await _loadParents();

      await AppNoticeModal.showSuccess(
        context,
        title: 'Thêm liên hệ thành công',
        message: response.message.isEmpty ? 'Đã lưu thông tin phụ huynh.' : response.message,
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
        message: 'Không thể thêm liên hệ, vui lòng thử lại.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingParent = false);
      }
    }
  }

  Future<void> _pickScheduleDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 10))),
    );
    if (pickedTime == null) {
      return;
    }

    setState(() {
      _scheduledAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _scheduleEmail() async {
    final teacherId = (AuthSession.instance.uid ?? '').trim();
    final subjectTemplate = _mailSubjectController.text.trim();
    final scheduledAt = _scheduledAt;

    if (teacherId.isEmpty ||
        _selectedScheduleParentIds.isEmpty ||
        scheduledAt == null) {
      await AppNoticeModal.showError(
        context,
        message: 'Vui lòng chọn lớp, chọn học sinh và nhập đầy đủ thông tin lập lịch.',
      );
      return;
    }

    setState(() => _isScheduling = true);
    try {
      final selectedParents = _parents
          .where((parent) => _selectedScheduleParentIds.contains(parent.id))
          .toList();

      int successCount = 0;
      final failedTargets = <String>[];

      for (final parent in selectedParents) {
        final recipient = parent.email.trim();
        final name = parent.studentName.trim().isEmpty
            ? parent.studentId
            : parent.studentName.trim();
        if (recipient.isEmpty) {
          failedTargets.add('$name (thiếu email)');
          continue;
        }

        try {
          final message = await _buildScheduleMessageForParent(parent);
          final subject = _buildScheduleSubjectForParent(
            parent: parent,
            subjectTemplate: subjectTemplate,
          );
          await _contactService.scheduleEmail(
            request: ScheduleEmailRequest(
              subject: subject,
              recipient: recipient,
              message: message,
              scheduledTime: scheduledAt.toIso8601String(),
              teacherId: teacherId,
            ),
          );
          successCount += 1;
        } on ApiException catch (e) {
          failedTargets.add('$name (${e.message})');
        } catch (_) {
          failedTargets.add('$name (lỗi không xác định)');
        }
      }

      if (!mounted) {
        return;
      }

      _mailSubjectController.clear();
      _mailRecipientController.clear();
      _mailMessageController.clear();
      _scheduledAt = null;
      _selectedScheduleParentIds.clear();
      _refreshSchedulePreview();

      await _loadHistory();
      if (!mounted) {
        return;
      }

      if (successCount == 0) {
        await AppNoticeModal.showError(
          context,
          message: failedTargets.isEmpty
              ? 'Không lập lịch được email nào. Vui lòng kiểm tra lại dữ liệu.'
              : 'Không lập lịch được email nào. Chi tiết: ${failedTargets.join(', ')}',
        );
      } else if (failedTargets.isEmpty) {
        await AppNoticeModal.showSuccess(
          context,
          title: 'Lập lịch thành công',
          message: 'Đã lập lịch $successCount email',
        );
      } else {
        await AppNoticeModal.showSuccess(
          context,
          title: 'Lập lịch một phần',
          message:
              'Đã lập lịch $successCount email. Không thành công: ${failedTargets.join(', ')}',
        );
      }
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
        message: 'Không thể lập lịch gửi email. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) {
        setState(() => _isScheduling = false);
      }
    }
  }

  Future<void> _sendEmailNow() async {
    final teacherId = (AuthSession.instance.uid ?? '').trim();
    final subjectTemplate = _mailSubjectController.text.trim();

    if (teacherId.isEmpty || _selectedScheduleParentIds.isEmpty) {
      await AppNoticeModal.showError(
        context,
        message: 'Vui lòng chọn lớp và chọn học sinh trước khi gửi ngay.',
      );
      return;
    }

    setState(() => _isSendingNow = true);
    try {
      final selectedParents = _parents
          .where((parent) => _selectedScheduleParentIds.contains(parent.id))
          .toList();

      int successCount = 0;
      final failedTargets = <String>[];

      for (final parent in selectedParents) {
        final recipient = parent.email.trim();
        final name = parent.studentName.trim().isEmpty
            ? parent.studentId
            : parent.studentName.trim();
        if (recipient.isEmpty) {
          failedTargets.add('$name (thiếu email)');
          continue;
        }

        try {
          final message = await _buildScheduleMessageForParent(parent);
          final subject = _buildScheduleSubjectForParent(
            parent: parent,
            subjectTemplate: subjectTemplate,
          );

          await _contactService.sendEmailNow(
            request: SendEmailNowRequest(
              subject: subject,
              recipient: recipient,
              message: message,
              teacherId: teacherId,
            ),
          );
          successCount += 1;
        } on ApiException catch (e) {
          failedTargets.add('$name (${e.message})');
        } catch (_) {
          failedTargets.add('$name (lỗi không xác định)');
        }
      }

      if (!mounted) {
        return;
      }

      if (successCount > 0) {
        await _loadHistory();
        if (!mounted) {
          return;
        }
      }

      if (successCount == 0) {
        await AppNoticeModal.showError(
          context,
          message: failedTargets.isEmpty
              ? 'Không gửi được email nào. Vui lòng kiểm tra lại dữ liệu.'
              : 'Không gửi được email nào. Chi tiết: ${failedTargets.join(', ')}',
        );
      } else if (failedTargets.isEmpty) {
        await AppNoticeModal.showSuccess(
          context,
          title: 'Gửi ngay thành công',
          message: 'Đã gửi ngay $successCount email',
        );
      } else {
        await AppNoticeModal.showSuccess(
          context,
          title: 'Gửi ngay một phần',
          message:
              'Đã gửi ngay $successCount email. Không thành công: ${failedTargets.join(', ')}',
        );
      }

      _mailRecipientController.clear();
      _mailMessageController.text = _buildScheduleMessagePreviewTemplate();
      _selectedScheduleParentIds.clear();
      _refreshSchedulePreview();
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
        message: 'Không thể gửi email ngay lúc này. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingNow = false);
      }
    }
  }

  Future<StudentInClassItem?> _resolveStudentDetailForParent(ParentItem parent) async {
    final studentId = parent.studentId.trim();
    if (studentId.isEmpty) {
      return null;
    }

    final cached = _studentDetailCache[studentId];
    if (cached != null) {
      return cached;
    }

    for (final student in _students) {
      if (student.id == studentId) {
        _studentDetailCache[studentId] = student;
        return student;
      }
    }

    final className = parent.studentClass.trim().toLowerCase();
    String? classId;
    for (final classroom in _classrooms) {
      if (classroom.name.trim().toLowerCase() == className) {
        classId = classroom.id;
        break;
      }
    }

    if (classId == null || classId.isEmpty) {
      return null;
    }

    try {
      final students = await _classroomService.getStudentsByClass(classId: classId);
      for (final student in students) {
        _studentDetailCache[student.id] = student;
        if (student.id == studentId) {
          return student;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  List<ParentItem> _scheduleParentsBySelectedClass() {
    final className = _selectedScheduleClassName().trim().toLowerCase();
    if (className.isEmpty) {
      return const <ParentItem>[];
    }

    final filtered = _parents.where((parent) {
      return parent.studentClass.trim().toLowerCase() == className;
    }).toList();

    filtered.sort((a, b) {
      final aName = a.studentName.trim().toLowerCase();
      final bName = b.studentName.trim().toLowerCase();
      return aName.compareTo(bName);
    });
    return filtered;
  }

  String _selectedScheduleClassName() {
    final classId = (_selectedScheduleClassId ?? '').trim();
    if (classId.isEmpty) {
      return '';
    }
    for (final classroom in _classrooms) {
      if (classroom.id == classId) {
        return classroom.name;
      }
    }
    return '';
  }

  Future<void> _onScheduleClassSelected(String classId) async {
    if (_selectedScheduleClassId == classId) {
      return;
    }

    setState(() {
      _selectedScheduleClassId = classId;
      _selectedScheduleParentIds.clear();
      _mailRecipientController.clear();
      _mailMessageController.text = _buildScheduleMessagePreviewTemplate();
    });

    _mailSubjectController.text = _buildScheduleSubjectPreviewTemplate();

    _refreshSchedulePreview();
  }

  Future<void> _toggleScheduleParentSelection({
    required String parentId,
    required bool selected,
  }) async {
    if (selected) {
      _selectedScheduleParentIds.add(parentId);
    } else {
      _selectedScheduleParentIds.remove(parentId);
    }
    setState(() {});
    _refreshSchedulePreview();
  }

  void _refreshSchedulePreview() {
    final selectedParents = _parents
        .where((parent) => _selectedScheduleParentIds.contains(parent.id))
        .toList();
    final recipients = <String>{};
    for (final parent in selectedParents) {
      final email = parent.email.trim();
      if (email.isNotEmpty) {
        recipients.add(email);
      }
    }

    _mailRecipientController.text = recipients.join(', ');
    if (_mailSubjectController.text.trim().isEmpty) {
      _mailSubjectController.text = _buildScheduleSubjectPreviewTemplate();
    }
    _mailMessageController.text = _buildScheduleMessagePreviewTemplate();
  }

  String _buildScheduleSubjectPreviewTemplate() {
    final className = _selectedScheduleClassName().trim();
    if (className.isNotEmpty) {
      return 'Thông báo học tập lớp $className - [TEN HOC SINH]';
    }
    return 'Thông báo học tập - [TEN HOC SINH]';
  }

  String _buildScheduleSubjectForParent({
    required ParentItem parent,
    required String subjectTemplate,
  }) {
    final studentName = parent.studentName.trim().isNotEmpty
        ? parent.studentName.trim()
        : parent.studentId;
    final className = parent.studentClass.trim();

    String subject = subjectTemplate.trim();
    if (subject.isEmpty) {
      if (className.isNotEmpty) {
        return 'Thông báo học tập lớp $className - $studentName';
      }
      return 'Thông báo học tập - $studentName';
    }

    subject = subject
        .replaceAll('[TEN HOC SINH]', studentName)
        .replaceAll('[TEN LOP]', className.isEmpty ? '--' : className);
    return subject;
  }

  String _buildScheduleMessagePreviewTemplate() {
    return [
      'Mẫu nội dung sẽ gửi cho từng phụ huynh:',
      '',
      'Kính gửi Quý phụ huynh [TEN PHU HUYNH],',
      '',
      'Nhà trường gửi thông tin học tập của học sinh [TEN HOC SINH]:',
      '- Lớp: [TEN LOP]',
      '- Trường: [TEN TRUONG]',
      '- Giới tính: [GIOI TINH]',
      '- Ngày sinh: [NGAY SINH]',
      '- Số điện thoại: [SO DIEN THOAI]',
      '',
      'Bảng điểm:',
      '- [NAM HOC] [MON]: HK1 ..., HK2 ..., Cả năm ...',
      '',
      'Quý phụ huynh vui lòng theo dõi và phối hợp cùng giáo viên chủ nhiệm.',
      'Trân trọng.',
    ].join('\n');
  }

  Future<String> _buildScheduleMessageForParent(ParentItem parent) async {
    final student = await _resolveStudentDetailForParent(parent);
    final scoreSummary = await _buildScoreSummaryForEmail(parent.studentId);

    final studentName = parent.studentName.trim().isNotEmpty
        ? parent.studentName.trim()
        : (student?.name.trim() ?? parent.studentId);
    final className = parent.studentClass.trim();
    final schoolName = _resolveSchoolForParent(parent);
    final gender = student?.gender.trim() ?? '';
    final dob = student?.dob.trim() ?? '';
    final phone = student?.phone.trim() ?? '';

    return [
      'Kính gửi Quý phụ huynh ${parent.parentName.trim().isEmpty ? '' : parent.parentName.trim()},',
      '',
      'Nhà trường gửi thông tin học sinh như sau:',
      '- Họ tên học sinh: $studentName',
      '- Lớp: ${className.isEmpty ? '--' : className}',
      '- Trường: ${schoolName.isEmpty ? '--' : schoolName}',
      '- Giới tính: ${gender.isEmpty ? '--' : gender}',
      '- Ngày sinh: ${dob.isEmpty ? '--' : dob}',
      '- Số điện thoại học sinh: ${phone.isEmpty ? '--' : phone}',
      '',
      'Bảng điểm:',
      scoreSummary,
      '',
      'Quý phụ huynh vui lòng theo dõi và phối hợp cùng giáo viên chủ nhiệm.',
      'Trân trọng.',
    ].join('\n');
  }

  Future<String> _buildScoreSummaryForEmail(String studentId) async {
    final normalizedStudentId = studentId.trim();
    if (normalizedStudentId.isEmpty) {
      return 'Chưa có student_id để lấy bảng điểm.';
    }

    final cached = _scoreSummaryCache[normalizedStudentId];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final report = await _ocrService.getFullReportCard(
        studentId: normalizedStudentId,
      );

      final classList = List<OcrReportCardClassGroup>.from(report.classList);
      classList.sort((a, b) {
        final byYear = _extractYearSortKey(a.className)
            .compareTo(_extractYearSortKey(b.className));
        if (byYear != 0) {
          return byYear;
        }
        return a.className.toLowerCase().compareTo(b.className.toLowerCase());
      });

      final lines = <String>[];
      if (classList.isEmpty) {
        lines.add('- Chưa có dữ liệu bảng điểm.');
      } else {
        for (final classGroup in classList) {
          final title = classGroup.className.trim().isEmpty
              ? 'Năm học không xác định'
              : classGroup.className.trim();
          lines.add('• $title');

          final subjects = List<OcrReportCardClassSubject>.from(
            classGroup.subjects,
          )
            ..sort(
              (x, y) =>
                  x.name.toLowerCase().compareTo(y.name.toLowerCase()),
            );

          if (subjects.isEmpty) {
            lines.add('  - Chưa có môn học.');
            continue;
          }

          for (final subject in subjects) {
            final subjectName = subject.name.trim().isEmpty
                ? 'Môn học'
                : subject.name.trim();
            lines.add(
              '  - $subjectName: HK1 ${_displayScore(subject.hk1)} | HK2 ${_displayScore(subject.hk2)} | Cả năm ${_displayScore(subject.cn)}',
            );
          }
        }
      }

      final summary = lines.join('\n');
      _scoreSummaryCache[normalizedStudentId] = summary;
      return summary;
    } on ApiException {
      return '- Không lấy được bảng điểm do lỗi từ hệ thống. Vui lòng thử lại sau.';
    } catch (_) {
      return '- Không lấy được bảng điểm từ hệ thống vào lúc này.';
    }
  }

  String _displayScore(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? '--' : normalized;
  }

  int _extractYearSortKey(String className) {
    final matches = RegExp(r'\d{4}').allMatches(className);
    if (matches.isNotEmpty) {
      final first = int.tryParse(matches.first.group(0) ?? '');
      if (first != null) {
        return first;
      }
    }

    final classNumMatch = RegExp(r'\d{1,2}').firstMatch(className);
    final classNum = int.tryParse(classNumMatch?.group(0) ?? '');
    if (classNum != null) {
      return 2000 + classNum;
    }
    return 9999;
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
                  title: 'Báo cáo học tập',
                  subtitle: 'Thêm liên hệ, lập lịch và theo dõi email',
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTabs(),
                        const SizedBox(height: 12),
                        if (_selectedTab == 0) _buildAddContactTab(),
                        if (_selectedTab == 1) _buildScheduleTab(),
                        if (_selectedTab == 2) _buildHistoryTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: CommonBottomNav(currentTab: BottomNavTab.home),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildTabChip(0, 'Thêm liên hệ', Icons.person_add_alt_1_rounded),
        _buildTabChip(1, 'Lập lịch email', Icons.schedule_send_rounded),
        _buildTabChip(2, 'Lịch sử gửi', Icons.history_rounded),
      ],
    );
  }

  Widget _buildTabChip(int index, String label, IconData icon) {
    final selected = _selectedTab == index;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? AppColors.white : AppColors.primary,
      ),
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedTab = index),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.white : AppColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: AppFontSizes.dashboardCaption,
      ),
      showCheckmark: false,
      side: const BorderSide(color: AppColors.primary),
      backgroundColor: AppColors.white,
    );
  }

  Widget _buildAddContactTab() {
    final selectedClassId = _selectedClassId;

    return _buildPanel(
      title: 'Thêm liên hệ phụ huynh',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn lớp',
            style: TextStyle(
              fontSize: AppFontSizes.dashboardCaption,
              color: AppColors.subtitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoadingClasses)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_classrooms.isEmpty)
            const Text(
              'Chưa có lớp. Vui lòng tạo lớp trước.',
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
                  final selected = classroom.id == selectedClassId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(classroom.name),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedClassId = classroom.id;
                        });
                        _loadStudentsForClass(classroom.id);
                      },
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.white : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      side: const BorderSide(color: AppColors.primary),
                      backgroundColor: AppColors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 10),
          const Text(
            'Chọn học sinh',
            style: TextStyle(
              fontSize: AppFontSizes.dashboardCaption,
              color: AppColors.subtitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoadingStudents)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_students.isEmpty)
            const Text(
              'Lớp này chưa có học sinh',
              style: TextStyle(
                fontSize: AppFontSizes.dashboardCaption,
                color: AppColors.subtitle,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _students.map((student) {
                final selected = _selectedStudentId == student.id;
                return ChoiceChip(
                  label: Text(student.name.isEmpty ? student.id : student.name),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedStudentId = student.id;
                    });
                  },
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.white : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  side: const BorderSide(color: AppColors.primary),
                  backgroundColor: AppColors.white,
                );
              }).toList(),
            ),
          if ((_selectedStudentId ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 10),
          _buildInput(_parentNameController, 'Họ tên phụ huynh'),
          const SizedBox(height: 10),
          _buildInput(_parentEmailController, 'Email', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 10),
          _buildInput(_parentPhoneController, 'Số điện thoại', keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSavingParent ? null : _saveParentContact,
              icon: _isSavingParent
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('Thêm liên hệ'),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Danh sách liên hệ phụ huynh',
                  style: TextStyle(
                    fontSize: AppFontSizes.dashboardBody,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _isLoadingParents ? null : _loadParents,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tải lại'),
              ),
            ],
          ),
          if (_isLoadingParents)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_parents.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Chưa có liên hệ phụ huynh nào.',
                style: TextStyle(
                  fontSize: AppFontSizes.dashboardCaption,
                  color: AppColors.subtitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Column(
              children: _parents.map((parent) {
                final className = parent.studentClass.trim();
                final schoolName = _resolveSchoolForParent(parent);

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCE5F4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parent.parentName.isEmpty
                            ? 'Phụ huynh'
                            : parent.parentName,
                        style: const TextStyle(
                          fontSize: AppFontSizes.dashboardBody,
                          fontWeight: FontWeight.w700,
                          color: AppColors.title,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Email: ${parent.email}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.dashboardCaption,
                          color: AppColors.subtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Điện thoại: ${parent.phone}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.dashboardCaption,
                          color: AppColors.subtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Học sinh: ${parent.studentName.isEmpty ? parent.studentId : parent.studentName}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.dashboardCaption,
                          color: AppColors.subtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Lớp: ${className.isEmpty ? '--' : className}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.dashboardCaption,
                          color: AppColors.subtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Trường: ${schoolName.isEmpty ? '--' : schoolName}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.dashboardCaption,
                          color: AppColors.subtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    final scheduledAt = _scheduledAt;
    final scheduledText = scheduledAt == null
        ? 'Chưa chọn thời gian'
        : '${scheduledAt.day.toString().padLeft(2, '0')}/${scheduledAt.month.toString().padLeft(2, '0')}/${scheduledAt.year} ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';

    return _buildPanel(
      title: 'Lập lịch gửi email',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn lớp',
            style: TextStyle(
              fontSize: AppFontSizes.dashboardCaption,
              color: AppColors.subtitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoadingClasses)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_classrooms.isEmpty)
            const Text(
              'Chưa có lớp. Vui lòng tạo lớp trước.',
              style: TextStyle(
                fontSize: AppFontSizes.dashboardCaption,
                color: AppColors.subtitle,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _classrooms.map((classroom) {
                final selected = _selectedScheduleClassId == classroom.id;
                return ChoiceChip(
                  label: Text(classroom.name),
                  selected: selected,
                  onSelected: (_) {
                    _onScheduleClassSelected(classroom.id);
                  },
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.white : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  side: const BorderSide(color: AppColors.primary),
                  backgroundColor: AppColors.white,
                );
              }).toList(),
            ),
          const SizedBox(height: 10),
          const Text(
            'Chọn học sinh và email phụ huynh',
            style: TextStyle(
              fontSize: AppFontSizes.dashboardCaption,
              color: AppColors.subtitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoadingParents)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if ((_selectedScheduleClassId ?? '').isEmpty)
            const Text(
              'Vui lòng chọn lớp để hiển thị danh sách học sinh.',
              style: TextStyle(
                fontSize: AppFontSizes.dashboardCaption,
                color: AppColors.subtitle,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (_scheduleParentsBySelectedClass().isEmpty)
            const Text(
              'Lớp này chưa có liên hệ phụ huynh.',
              style: TextStyle(
                fontSize: AppFontSizes.dashboardCaption,
                color: AppColors.subtitle,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCE5F4)),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 28),
                        Expanded(
                          flex: 5,
                          child: Text(
                            'Tên học sinh',
                            style: TextStyle(
                              fontSize: AppFontSizes.dashboardCaption,
                              color: AppColors.title,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Text(
                            'Email phụ huynh',
                            style: TextStyle(
                              fontSize: AppFontSizes.dashboardCaption,
                              color: AppColors.title,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._scheduleParentsBySelectedClass().map((parent) {
                    final checked = _selectedScheduleParentIds.contains(
                      parent.id,
                    );
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFDCE5F4)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: checked,
                            onChanged: (value) {
                              _toggleScheduleParentSelection(
                                parentId: parent.id,
                                selected: value == true,
                              );
                            },
                          ),
                          Expanded(
                            flex: 5,
                            child: Text(
                              parent.studentName.trim().isEmpty
                                  ? parent.studentId
                                  : parent.studentName,
                              style: const TextStyle(
                                fontSize: AppFontSizes.dashboardCaption,
                                color: AppColors.subtitle,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Text(
                              parent.email,
                              style: const TextStyle(
                                fontSize: AppFontSizes.dashboardCaption,
                                color: AppColors.subtitle,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          if (_isGeneratingScheduleMessage)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Đang tạo nội dung email tự động...',
                    style: TextStyle(
                      fontSize: AppFontSizes.dashboardCaption,
                      color: AppColors.subtitle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          _buildInput(_mailSubjectController, 'Tiêu đề'),
          const SizedBox(height: 10),
          _buildInput(
            _mailRecipientController,
            'Người nhận',
            keyboardType: TextInputType.emailAddress,
            readOnly: true,
          ),
          const SizedBox(height: 10),
          _buildInput(
            _mailMessageController,
            'Nội dung',
            minLines: 4,
            maxLines: 6,
            readOnly: true,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCE5F4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scheduledText,
                    style: const TextStyle(
                      fontSize: AppFontSizes.dashboardBody,
                      fontWeight: FontWeight.w600,
                      color: AppColors.title,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _pickScheduleDateTime,
                  child: const Text('Chọn'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      (_isScheduling || _isSendingNow) ? null : _scheduleEmail,
                  icon: _isScheduling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.schedule_send_rounded),
                  label: const Text('Lập lịch gửi'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      (_isScheduling || _isSendingNow) ? null : _sendEmailNow,
                  icon: _isSendingNow
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text('Gửi ngay'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return _buildPanel(
      title: 'Lịch sử gửi email',
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _isLoadingHistory ? null : _loadHistory,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tải lại'),
            ),
          ),
          if (_isLoadingHistory)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chưa có lịch sử gửi email.',
                style: TextStyle(
                  fontSize: AppFontSizes.dashboardCaption,
                  color: AppColors.subtitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Column(
              children: _history.map((item) {
                final isDeleting = _deletingHistoryIds.contains(item.id);
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCE5F4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.subject.isEmpty ? 'Không có tiêu đề' : item.subject,
                              style: const TextStyle(
                                fontSize: AppFontSizes.dashboardBody,
                                color: AppColors.title,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: isDeleting
                                ? null
                                : () {
                                    _deleteScheduledEmail(item);
                                  },
                            tooltip: 'Xóa lịch email',
                            icon: isDeleting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFCC2F2F),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Người nhận: ${item.recipients}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.dashboardCaption,
                          color: AppColors.subtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Thời gian: ${item.scheduledDate}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.dashboardCaption,
                          color: AppColors.subtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Trạng thái: ${item.status}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.dashboardCaption,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPanel({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE5F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppFontSizes.dashboardBody,
              color: AppColors.title,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int minLines = 1,
    int? maxLines = 1,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF6F8FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }
}
