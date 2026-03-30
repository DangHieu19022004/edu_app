import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/models/classroom_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/classroom_service.dart';
import 'package:edu_app_flutter/views/screens/dashboard_screen.dart';
import 'package:edu_app_flutter/views/screens/detail_academic_transcript_screen.dart';
import 'package:edu_app_flutter/views/screens/pre_ocr_screen.dart';
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

  final List<String> _classTabs = [];
  final List<_StudentCardData> _students = [];
  final List<_StudentCardData> _placeholderStudents = const [
    _StudentCardData.placeholder(),
    _StudentCardData.placeholder(),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _students.where((student) {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      return student.name.toLowerCase().contains(query);
    }).toList();
    final hasStudents = filtered.isNotEmpty;
    final visibleStudents = hasStudents ? filtered : _placeholderStudents;

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
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.0,
                          ),
                      itemCount: visibleStudents.length + 1,
                      itemBuilder: (context, index) {
                        if (index == visibleStudents.length) {
                          return _buildAddCard();
                        }
                        return _StudentCard(
                          student: visibleStudents[index],
                          isPlaceholder: !hasStudents,
                          onView: () {
                            if (!hasStudents) {
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DetailHbaScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),
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
    if (_classTabs.isEmpty) {
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
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _classTabs.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == _classTabs.length) {
            return Material(
              color: const Color(0xFFE9EEFA),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _openCreateClassroomForm,
                child: const SizedBox(
                  width: 44,
                  child: Icon(Icons.add, color: AppColors.primary),
                ),
              ),
            );
          }

          final selected = _selectedClassIndex == index;
          return Material(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => setState(() => _selectedClassIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? Colors.transparent : const Color(0xFFD5DEEA),
                  ),
                ),
                child: Text(
                  _classTabs[index],
                  style: TextStyle(
                    fontSize: AppFontSizes.dashboardChip,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.white : AppColors.subtitle,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddCard() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFC8D3E7), width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: const Color(0xFFF8FBFF),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PreOcrScreen()),
        );
      },
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 30),
          SizedBox(height: 6),
          Text(
            'Thêm học sinh mới',
            style: TextStyle(
              fontSize: AppFontSizes.dashboardBody,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
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

      setState(() {
        final existingIndex = _classTabs.indexOf(result.className);
        if (existingIndex >= 0) {
          _selectedClassIndex = existingIndex;
        } else {
          _classTabs.add(result.className);
          _selectedClassIndex = _classTabs.length - 1;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            response.message.isNotEmpty
                ? response.message
                : 'Da tao lop ${result.className} thanh cong',
          ),
        ),
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
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.onView,
    this.isPlaceholder = false,
  });

  final _StudentCardData student;
  final VoidCallback onView;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(color: const Color(0xE6FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110B1D47),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x331337EC), width: 1.4),
                      color: const Color(0xFFEAF1FF),
                    ),
                    child: student.avatar.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 30,
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              student.avatar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                  size: 30,
                                );
                              },
                            ),
                          ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: student.online
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF9CA3AF),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ngày sinh: ${student.birthday}',
                      style: const TextStyle(
                        fontSize: AppFontSizes.dashboardCaption,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtitle,
                      ),
                    ),
                    Text(
                      'Trường: ${student.school}',
                      style: const TextStyle(
                        fontSize: AppFontSizes.dashboardCaption,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE9EEF7)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: student.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: const Color(0xFFEAF1FF),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              _iconButton(
                icon: Icons.visibility_rounded,
                onTap: onView,
                disabled: isPlaceholder,
              ),
              const SizedBox(width: 6),
              _iconButton(
                icon: Icons.edit_rounded,
                onTap: () {},
                disabled: isPlaceholder,
              ),
              const SizedBox(width: 6),
              _iconButton(
                icon: Icons.delete_rounded,
                onTap: () {},
                danger: true,
                disabled: isPlaceholder,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool danger = false,
    bool disabled = false,
  }) {
    final bg = danger ? const Color(0xFFFEE2E2) : const Color(0xFFEFF4FF);
    final fg = disabled
        ? const Color(0xFF9CA3AF)
        : (danger ? const Color(0xFFDC2626) : AppColors.primary);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: disabled ? null : onTap,
        child: SizedBox(width: 34, height: 34, child: Icon(icon, size: 19, color: fg)),
      ),
    );
  }
}

class _StudentCardData {
  const _StudentCardData({
    required this.name,
    required this.birthday,
    required this.school,
    required this.avatar,
    required this.online,
    required this.tags,
  });

  const _StudentCardData.placeholder()
    : name = 'Hoc sinh',
      birthday = '--/--/----',
      school = 'Chua co truong',
      avatar = '',
      online = false,
      tags = const ['MON'];

  final String name;
  final String birthday;
  final String school;
  final String avatar;
  final bool online;
  final List<String> tags;
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
