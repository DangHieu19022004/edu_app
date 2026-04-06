import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/models/classroom_models.dart';
import 'package:edu_app_flutter/models/contact_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/auth_session.dart';
import 'package:edu_app_flutter/services/classroom_service.dart';
import 'package:edu_app_flutter/services/contact_service.dart';
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

  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();

  final TextEditingController _mailSubjectController = TextEditingController();
  final TextEditingController _mailRecipientController = TextEditingController();
  final TextEditingController _mailMessageController = TextEditingController();

  int _selectedTab = 0;
  bool _isSavingParent = false;
  bool _isScheduling = false;
  bool _isLoadingHistory = false;
  bool _isLoadingClasses = false;
  bool _isLoadingStudents = false;
  bool _isLoadingParents = false;

  DateTime? _scheduledAt;
  List<ScheduledEmailItem> _history = const <ScheduledEmailItem>[];
  List<ParentItem> _parents = const <ParentItem>[];
  List<ClassroomItem> _classrooms = const <ClassroomItem>[];
  List<StudentInClassItem> _students = const <StudentInClassItem>[];
  String? _selectedClassId;
  String? _selectedStudentId;

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
        message: 'Khong the tai danh sach lop. Vui long thu lai.',
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
        message: 'Khong the tai danh sach hoc sinh. Vui long thu lai.',
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
        message: 'Khong the tai lich su gui email. Vui long thu lai.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
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
      setState(() => _parents = items);
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
        message: 'Khong the tai danh sach phu huynh. Vui long thu lai.',
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
        message: 'Vui long nhap day du thong tin lien he.',
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
        title: 'Them lien he thanh cong',
        message: response.message.isEmpty ? 'Da luu thong tin phu huynh.' : response.message,
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
        message: 'Khong the them lien he. Vui long thu lai.',
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
    final subject = _mailSubjectController.text.trim();
    final recipient = _mailRecipientController.text.trim();
    final message = _mailMessageController.text.trim();
    final scheduledAt = _scheduledAt;

    if (teacherId.isEmpty || subject.isEmpty || recipient.isEmpty || message.isEmpty || scheduledAt == null) {
      await AppNoticeModal.showError(
        context,
        message: 'Vui long nhap day du thong tin va thoi gian gui.',
      );
      return;
    }

    setState(() => _isScheduling = true);
    try {
      final response = await _contactService.scheduleEmail(
        request: ScheduleEmailRequest(
          subject: subject,
          recipient: recipient,
          message: message,
          scheduledTime: scheduledAt.toIso8601String(),
          teacherId: teacherId,
        ),
      );

      if (!mounted) {
        return;
      }

      _mailSubjectController.clear();
      _mailRecipientController.clear();
      _mailMessageController.clear();
      _scheduledAt = null;

      await _loadHistory();
      if (!mounted) {
        return;
      }

      await AppNoticeModal.showSuccess(
        context,
        title: 'Lap lich thanh cong',
        message: response.message.isEmpty ? 'Da lap lich gui email.' : response.message,
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
        message: 'Khong the lap lich gui email. Vui long thu lai.',
      );
    } finally {
      if (mounted) {
        setState(() => _isScheduling = false);
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
                  title: 'Bao cao hoc tap',
                  subtitle: 'Them lien he, lap lich va theo doi email',
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
        _buildTabChip(0, 'Them lien he', Icons.person_add_alt_1_rounded),
        _buildTabChip(1, 'Lap lich email', Icons.schedule_send_rounded),
        _buildTabChip(2, 'Lich su gui', Icons.history_rounded),
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
      title: 'Them lien he phu huynh',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chon lop',
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
              'Chua co lop. Vui long tao lop truoc.',
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
            'Chon hoc sinh',
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
              'Lop nay chua co hoc sinh.',
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
          _buildInput(_parentNameController, 'Ho ten phu huynh'),
          const SizedBox(height: 10),
          _buildInput(_parentEmailController, 'Email', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 10),
          _buildInput(_parentPhoneController, 'So dien thoai', keyboardType: TextInputType.phone),
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
              label: const Text('Them lien he'),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Danh sach lien he phu huynh',
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
                label: const Text('Tai lai'),
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
                'Chua co lien he phu huynh nao.',
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
                            ? 'Phu huynh'
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
                        'Dien thoai: ${parent.phone}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.dashboardCaption,
                          color: AppColors.subtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Hoc sinh: ${parent.studentName.isEmpty ? parent.studentId : parent.studentName}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.dashboardCaption,
                          color: AppColors.subtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Lop: ${className.isEmpty ? '--' : className}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.dashboardCaption,
                          color: AppColors.subtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Truong: ${schoolName.isEmpty ? '--' : schoolName}',
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
        ? 'Chua chon thoi gian'
        : '${scheduledAt.day.toString().padLeft(2, '0')}/${scheduledAt.month.toString().padLeft(2, '0')}/${scheduledAt.year} ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';

    return _buildPanel(
      title: 'Lap lich gui email',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInput(_mailSubjectController, 'Tieu de'),
          const SizedBox(height: 10),
          _buildInput(_mailRecipientController, 'Nguoi nhan', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 10),
          _buildInput(
            _mailMessageController,
            'Noi dung',
            minLines: 4,
            maxLines: 6,
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
                  child: const Text('Chon'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isScheduling ? null : _scheduleEmail,
              icon: _isScheduling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.schedule_send_rounded),
              label: const Text('Lap lich gui'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return _buildPanel(
      title: 'Lich su gui email',
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _isLoadingHistory ? null : _loadHistory,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tai lai'),
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
                'Chua co lich su gui email.',
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
                      Text(
                        item.subject.isEmpty ? 'Khong co tieu de' : item.subject,
                        style: const TextStyle(
                          fontSize: AppFontSizes.dashboardBody,
                          color: AppColors.title,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nguoi nhan: ${item.recipients}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.dashboardCaption,
                          color: AppColors.subtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Thoi gian: ${item.scheduledDate}',
                        style: const TextStyle(
                          fontSize: AppFontSizes.dashboardCaption,
                          color: AppColors.subtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Trang thai: ${item.status}',
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
