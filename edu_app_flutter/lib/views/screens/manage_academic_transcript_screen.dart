import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/models/classroom_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/classroom_service.dart';
import 'package:edu_app_flutter/services/ocr_service.dart';
import 'package:edu_app_flutter/views/screens/dashboard_screen.dart';
import 'package:edu_app_flutter/views/screens/detail_academic_transcript_screen.dart';
import 'package:edu_app_flutter/views/widgets/app_notice_modal.dart';
import 'package:edu_app_flutter/views/widgets/common_bottom_nav.dart';
import 'package:edu_app_flutter/views/widgets/ocr/ocr_flow_header.dart';
import 'package:flutter/material.dart';

class ListHbaScreen extends StatefulWidget {
  const ListHbaScreen({super.key});

  @override
  State<ListHbaScreen> createState() => _ListHbaScreenState();
}

class _ListHbaScreenState extends State<ListHbaScreen> {
  int _selectedClassIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final ClassroomService _classroomService = ClassroomService();
  final OcrService _ocrService = OcrService();

  final List<ClassroomItem> _classrooms = [];
  final List<StudentInClassItem> _students = [];
  bool _isLoadingClasses = false;
  bool _isLoadingStudents = false;

  @override
  void initState() {
    super.initState();
    _refreshClassrooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _students.where((student) {
      if (query.isEmpty) return true;
      return student.name.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OcrFlowHeader(
              title: 'Học bạ',
              subtitle: 'Quản lý hồ sơ học sinh',
              onBack: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                  return;
                }
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quản lý học bạ',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Theo dõi và cập nhật hồ sơ năng lực học sinh.',
                      style: TextStyle(
                        fontSize: AppFontSizes.dashboardBody,
                        fontWeight: FontWeight.w500,
                        color: AppColors.subtitle,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSearchBox(),
                    const SizedBox(height: 14),
                    _buildClassTabs(),
                    const SizedBox(height: 14),
                    if (_isLoadingStudents)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                      )
                    else if (filtered.isEmpty)
                      _buildEmptyStudentState()
                    else
                      _buildStudentCards(filtered),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        onPressed: _openCreateClassroomForm,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: const CommonBottomNav(
        currentTab: BottomNavTab.classes,
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm học sinh...',
        hintStyle: const TextStyle(
          fontSize: AppFontSizes.dashboardBody,
          color: AppColors.inputHint,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.inputHint),
        filled: true,
        fillColor: const Color(0xFFF2F6FD),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildClassTabs() {
    if (_isLoadingClasses) {
      return const SizedBox(
        height: 44,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.2)),
      );
    }

    if (_classrooms.isEmpty) {
      return Row(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EEFA),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Chua co lop',
              style: TextStyle(
                fontSize: AppFontSizes.dashboardBody,
                fontWeight: FontWeight.w600,
                color: AppColors.subtitle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFFE9EEFA),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _openCreateClassroomForm,
              child: const SizedBox(
                width: 44,
                height: 40,
                child: Icon(Icons.add, color: AppColors.primary),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _classrooms.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == _classrooms.length) {
            return Material(
              color: const Color(0xFFE9EEFA),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _openCreateClassroomForm,
                child: const SizedBox(
                  width: 44,
                  height: 56,
                  child: Icon(Icons.add, color: AppColors.primary),
                ),
              ),
            );
          }

          final selected = _selectedClassIndex == index;
          final classroom = _classrooms[index];
          return Material(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                setState(() => _selectedClassIndex = index);
                _refreshStudentsForSelectedClass();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? Colors.transparent : const Color(0xFFD5DEEA),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classroom.name,
                          style: TextStyle(
                            fontSize: AppFontSizes.dashboardChip,
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.white : AppColors.subtitle,
                          ),
                        ),
                        if (classroom.classYear.trim().isNotEmpty)
                          Text(
                            classroom.classYear,
                            style: TextStyle(
                              fontSize: AppFontSizes.dashboardTiny,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? const Color(0xD9FFFFFF)
                                  : AppColors.inputHint,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () async {
                        await _confirmAndDeleteClassroom(classroom);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: selected
                              ? const Color(0xE6FFFFFF)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmAndDeleteClassroom(ClassroomItem classroom) async {
    final shouldDelete = await _showDeleteClassroomConfirm(classroom.name);
    if (!mounted || shouldDelete != true) {
      return;
    }

    try {
      final message = await _classroomService.deleteClassroom(classId: classroom.id);
      if (!mounted) {
        return;
      }

      await _refreshClassrooms();

      if (!mounted) {
        return;
      }

      await AppNoticeModal.showSuccess(
        context,
        title: 'Xoa lop thanh cong',
        message: message,
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(e.message),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Khong the xoa lop. Vui long thu lai.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<bool?> _showDeleteClassroomConfirm(String className) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xac nhan xoa lop'),
          content: Text(
            'Ban co chac chan muon xoa lop ${className.trim().isEmpty ? '' : className}?',
          ),
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

  Widget _buildEmptyStudentState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE5F4)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_rounded, color: AppColors.inputHint, size: 34),
          SizedBox(height: 10),
          Text(
            'Chưa có dữ liệu học sinh',
            style: TextStyle(
              fontSize: AppFontSizes.dashboardBody,
              fontWeight: FontWeight.w700,
              color: AppColors.title,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Danh sach hoc sinh trống',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFontSizes.dashboardCaption,
              fontWeight: FontWeight.w500,
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCards(List<StudentInClassItem> students) {
    final selectedClassroom = (_classrooms.isNotEmpty &&
            _selectedClassIndex >= 0 &&
            _selectedClassIndex < _classrooms.length)
        ? _classrooms[_selectedClassIndex]
        : null;

    return Column(
      children: students.map((student) {
        final schoolDisplay = student.school.trim().isNotEmpty
            ? student.school
            : (selectedClassroom?.schoolName ?? '');

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openStudentDetail(student),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDCE5F4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.name.isEmpty ? 'Hoc sinh' : student.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.title,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Sua hoc ba',
                          onPressed: () => _openStudentDetail(
                            student,
                            editable: true,
                          ),
                          icon: const Icon(
                            Icons.edit_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Xoa hoc ba',
                          onPressed: () => _confirmAndDeleteStudent(student),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _infoRow('Gioi tinh', student.gender),
                    _infoRow('Ngay sinh', student.dob),
                    _infoRow('Dien thoai', student.phone),
                    _infoRow('Truong', schoolDisplay),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _openStudentDetail(
    StudentInClassItem student, {
    bool editable = false,
  }) async {
    final studentId = student.id.trim();
    if (studentId.isEmpty) {
      await AppNoticeModal.showError(
        context,
        title: 'Khong tim thay hoc sinh',
        message: 'Ban ghi hoc sinh khong co student_id hop le.',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailHbaScreen(
          studentId: studentId,
          editable: editable,
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteStudent(StudentInClassItem student) async {
    final shouldDelete = await _showDeleteStudentConfirm(student.name);
    if (!mounted || shouldDelete != true) {
      return;
    }

    final studentId = student.id.trim();
    if (studentId.isEmpty) {
      await AppNoticeModal.showError(
        context,
        title: 'Khong tim thay hoc sinh',
        message: 'Ban ghi hoc sinh khong co student_id hop le.',
      );
      return;
    }

    try {
      final fullData = await _ocrService.getFullReportCard(studentId: studentId);
      final reportCardId = fullData.reportCard?.id.trim() ?? '';

      if (reportCardId.isEmpty) {
        if (!mounted) {
          return;
        }
        await AppNoticeModal.showError(
          context,
          title: 'Khong co hoc ba de xoa',
          message: 'Hoc sinh nay chua co hoc ba da luu.',
        );
        return;
      }

      final message = await _ocrService.deleteFullReportCard(
        reportCardId: reportCardId,
      );

      if (!mounted) {
        return;
      }

      await _refreshStudentsForSelectedClass();

      if (!mounted) {
        return;
      }

      await AppNoticeModal.showSuccess(
        context,
        title: 'Xoa hoc ba thanh cong',
        message: message,
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      await AppNoticeModal.showError(
        context,
        message: e.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      await AppNoticeModal.showError(
        context,
        message: 'Khong the xoa hoc ba. Vui long thu lai.',
      );
    }
  }

  Future<bool?> _showDeleteStudentConfirm(String studentName) {
    final displayName = studentName.trim();
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xac nhan xoa hoc ba'),
          content: Text(
            'Ban co chac chan muon xoa hoc ba cua ${displayName.isEmpty ? 'hoc sinh nay' : displayName}?',
          ),
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

  Widget _infoRow(String label, String value) {
    final normalized = value.trim().isEmpty ? '--' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: AppFontSizes.dashboardCaption,
            color: AppColors.subtitle,
            fontWeight: FontWeight.w500,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: normalized,
              style: const TextStyle(
                color: AppColors.title,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateClassroomForm() async {
    final result = await showDialog<_CreateClassroomFormData>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _CreateClassroomDialog(),
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      final response = await _classroomService.saveClassroom(
        SaveClassroomRequest(
          name: result.className,
          schoolName: result.schoolName,
          classYear: result.schoolYear,
        ),
      );

      if (!mounted) {
        return;
      }

      await _refreshClassrooms(selectClassName: result.className);

      if (!mounted) {
        return;
      }

      await AppNoticeModal.showSuccess(
        context,
        title: 'Tao lop thanh cong',
        message: response.message.isNotEmpty
            ? response.message
            : 'Da tao lop ${result.className} thanh cong',
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(e.message),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Co loi xay ra khi tao lop. Vui long thu lai.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _refreshClassrooms({String? selectClassName}) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingClasses = true;
    });

    try {
      final classrooms = await _classroomService.getClassrooms();
      if (!mounted) {
        return;
      }

      setState(() {
        _classrooms
          ..clear()
          ..addAll(classrooms);

        if (_classrooms.isEmpty) {
          _selectedClassIndex = 0;
        } else if (selectClassName != null && selectClassName.trim().isNotEmpty) {
          final targetIndex = _classrooms.indexWhere(
            (item) => item.name == selectClassName,
          );
          _selectedClassIndex = targetIndex >= 0 ? targetIndex : 0;
        } else if (_selectedClassIndex >= _classrooms.length) {
          _selectedClassIndex = _classrooms.length - 1;
        }
      });

      await _refreshStudentsForSelectedClass();
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(e.message),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Khong the tai danh sach lop. Vui long thu lai.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingClasses = false;
        });
      }
    }
  }

  Future<void> _refreshStudentsForSelectedClass() async {
    if (!mounted) {
      return;
    }

    if (_classrooms.isEmpty || _selectedClassIndex >= _classrooms.length) {
      setState(() {
        _students.clear();
        _isLoadingStudents = false;
      });
      return;
    }

    final classId = _classrooms[_selectedClassIndex].id;

    setState(() {
      _isLoadingStudents = true;
    });

    try {
      final students = await _classroomService.getStudentsByClass(classId: classId);
      if (!mounted) {
        return;
      }

      setState(() {
        _students
          ..clear()
          ..addAll(students);
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(e.message),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Khong the tai danh sach hoc sinh. Vui long thu lai.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
        });
      }
    }
  }
}

class _CreateClassroomFormData {
  const _CreateClassroomFormData({
    required this.className,
    required this.schoolName,
    required this.schoolYear,
  });

  final String className;
  final String schoolName;
  final String schoolYear;
}

class _CreateClassroomDialog extends StatefulWidget {
  const _CreateClassroomDialog();

  @override
  State<_CreateClassroomDialog> createState() => _CreateClassroomDialogState();
}

class _CreateClassroomDialogState extends State<_CreateClassroomDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolYearController = TextEditingController();

  @override
  void dispose() {
    _classNameController.dispose();
    _schoolNameController.dispose();
    _schoolYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tao lop hoc',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Dong form',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInput(
                controller: _classNameController,
                label: 'Ten lop',
                hint: 'Vi du: 10A1',
              ),
              const SizedBox(height: 10),
              _buildInput(
                controller: _schoolNameController,
                label: 'Ten truong',
                hint: 'Vi du: THPT EduTeacher',
              ),
              const SizedBox(height: 10),
              _buildInput(
                controller: _schoolYearController,
                label: 'Nam hoc',
                hint: 'Vi du: 2025-2026',
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) {
                    return 'Vui long nhap nam hoc';
                  }
                  if (!_isValidSchoolYear(text)) {
                    return 'Nam hoc dung dinh dang yyyy-yyyy';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Xac nhan',
                    style: TextStyle(
                      fontSize: AppFontSizes.dashboardBody,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator ??
          (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Vui long nhap $label';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _CreateClassroomFormData(
        className: _classNameController.text.trim(),
        schoolName: _schoolNameController.text.trim(),
        schoolYear: _schoolYearController.text.trim(),
      ),
    );
  }

  bool _isValidSchoolYear(String input) {
    final compact = input.replaceAll(' ', '');
    final parts = compact.split('-');
    if (parts.length != 2) {
      return false;
    }

    final startYear = int.tryParse(parts[0]);
    final endYear = int.tryParse(parts[1]);
    if (startYear == null || endYear == null) {
      return false;
    }

    return endYear == startYear + 1;
  }
}
