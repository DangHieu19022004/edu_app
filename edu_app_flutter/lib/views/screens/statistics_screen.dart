import 'dart:math' as math;

import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/models/classroom_models.dart';
import 'package:edu_app_flutter/models/ocr_models.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/auth_session.dart';
import 'package:edu_app_flutter/services/classroom_service.dart';
import 'package:edu_app_flutter/views/screens/dashboard_screen.dart';
import 'package:edu_app_flutter/services/ocr_service.dart';
import 'package:edu_app_flutter/views/widgets/common_bottom_nav.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final OcrService _ocrService = OcrService();
  final ClassroomService _classroomService = ClassroomService();

  bool _isLoading = false;
  String? _errorMessage;
  List<OcrAllStudentDataItem> _allStudents = const <OcrAllStudentDataItem>[];
  List<_ClassFilterOption> _classOptions = const <_ClassFilterOption>[];
  Map<String, Set<String>> _studentIdsByClassId = const <String, Set<String>>{};

  String? _selectedClassKey;
  _SemesterOption _selectedSemester = _SemesterOption.fullYear;
  String _selectedGrade = _allGrade;

  static const String _allGrade = 'all';
  static const List<String> _passFailSubjects = <String>['the duc'];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _ocrService.getAllStudentData();
      if (!mounted) {
        return;
      }

      final fallbackClassOptions = _classOptionsFromStudents(response.students);
      var classOptions = fallbackClassOptions;
      var studentIdsByClassId = <String, Set<String>>{};

      try {
        final classrooms = await _classroomService.getClassrooms();
        for (final classroom in classrooms) {
          final classId = classroom.id.trim();
          if (classId.isEmpty) {
            continue;
          }

          try {
            final students = await _classroomService.getStudentsByClass(
              classId: classId,
            );
            studentIdsByClassId[classId] = students
                .map((item) => item.id.trim())
                .where((id) => id.isNotEmpty)
                .toSet();
          } catch (_) {
            studentIdsByClassId[classId] = <String>{};
          }
        }

        final classroomOptions = _classOptionsFromClassrooms(classrooms);
        if (classroomOptions.isNotEmpty) {
          classOptions = classroomOptions;
        }
      } catch (_) {
        // Fallback to classes inferred from OCR data when classroom API fails.
      }

      final classKeys = classOptions.map((option) => option.key).toSet();
      final nextClassKey =
          (_selectedClassKey != null && classKeys.contains(_selectedClassKey))
          ? _selectedClassKey
          : null;

      if (kDebugMode) {
        debugPrint(
          'Statistics API: total=${response.students.length}, classOptions=${classOptions.length}',
        );
        if (response.students.isNotEmpty) {
          final sample = response.students.first;
          debugPrint(
            'Sample student: ${sample.student.name} | class=${sample.student.className} | subjects=${sample.subjects.length}',
          );
        }
      }

      setState(() {
        _allStudents = response.students;
        _classOptions = classOptions;
        _studentIdsByClassId = studentIdsByClassId;
        _selectedClassKey = nextClassKey;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Khong the tai du lieu thong ke. Vui long thu lai.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _studentsByFilters();
    final statistics = _buildStatistics(filteredStudents);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStatistics,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildFilterPanel(),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_errorMessage != null)
                  _buildErrorState()
                else if (_allStudents.isEmpty)
                  _buildEmptyState('Chua co du lieu hoc sinh de thong ke.')
                else if ((_selectedClassKey ?? '').trim().isEmpty)
                  _buildEmptyState('Vui long chon lop de xem thong ke.')
                else if (filteredStudents.isEmpty)
                  _buildEmptyState('Bo loc hien tai khong co du lieu phu hop.')
                else ...[
                  _buildOverviewCards(statistics),
                  _buildDistributionCard(statistics.distribution),
                  _buildTrendCard(statistics.trendPoints),
                  _buildWeaknessSection(statistics.weaknessItems),
                  _buildStrengthSection(statistics.strongSubjects),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(
        currentTab: BottomNavTab.statistics,
      ),
    );
  }

  List<_ClassFilterOption> _classOptionsFromStudents(
    List<OcrAllStudentDataItem> students,
  ) {
    final map = <String, _ClassFilterOption>{};

    for (final item in students) {
      final className = item.student.className.trim();
      if (className.isEmpty) {
        continue;
      }
      final key = _classKeyForStudent(item);
      map.putIfAbsent(
        key,
        () => _ClassFilterOption(
          key: key,
          label: _classLabelForStudent(item),
          classId: null,
        ),
      );
    }

    final options = map.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    return options;
  }

  List<_ClassFilterOption> _classOptionsFromClassrooms(
    List<ClassroomItem> classrooms,
  ) {
    final map = <String, _ClassFilterOption>{};
    for (final classroom in classrooms) {
      final className = classroom.name.trim();
      if (className.isEmpty) {
        continue;
      }
      final key = _classKeyForClassroom(classroom);
      map.putIfAbsent(
        key,
        () => _ClassFilterOption(
          key: key,
          label: _classLabelForClassroom(classroom),
          classId: classroom.id.trim(),
        ),
      );
    }

    final options = map.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    return options;
  }

  List<OcrAllStudentDataItem> _studentsByFilters() {
    final classKey = (_selectedClassKey ?? '').trim();
    if (classKey.isEmpty) {
      return const <OcrAllStudentDataItem>[];
    }

    Iterable<OcrAllStudentDataItem> data = _allStudents;
    final option = _classOptionByKey(classKey);
    final classId = option?.classId?.trim() ?? '';
    if (classId.isNotEmpty) {
      final studentIds = _studentIdsByClassId[classId] ?? const <String>{};
      data = data.where((item) => studentIds.contains(item.student.id.trim()));
    } else {
      data = data.where((item) => _classKeyForStudent(item) == classKey);
    }

    return data.toList();
  }

  _ClassFilterOption? _classOptionByKey(String key) {
    for (final option in _classOptions) {
      if (option.key == key) {
        return option;
      }
    }
    return null;
  }

  _StatisticsData _buildStatistics(List<OcrAllStudentDataItem> students) {
    final rows = _buildStudentRows(students);
    if (rows.isEmpty) {
      return _StatisticsData.empty();
    }

    final distribution = _calculatePerformanceDistribution(rows);
    final weaknessItems = _calculateWeaknessAnalysis(rows);
    final strongSubjects = _calculateStrongSubjects(rows);

    final numericAverages = rows
        .map(_calculateStudentAverage)
        .whereType<double>()
        .toList();

    final classAverage = _average(numericAverages);
    final validStudentCount =
        distribution.excellent +
        distribution.good +
        distribution.needsImprovement;
    final gioiKhaPercent = validStudentCount == 0
        ? 0.0
        : ((distribution.excellent + distribution.good) / validStudentCount) *
              100;

    final trendPoints = _buildTrendPoints(students);

    return _StatisticsData(
      studentCount: rows.length,
      validStudentCount: validStudentCount,
      classAverage: classAverage,
      gioiKhaPercent: gioiKhaPercent,
      distribution: distribution,
      weaknessItems: weaknessItems,
      strongSubjects: strongSubjects,
      trendPoints: trendPoints,
    );
  }

  List<_StudentForAnalysis> _buildStudentRows(
    List<OcrAllStudentDataItem> students,
  ) {
    final rows = <_StudentForAnalysis>[];

    for (final item in students) {
      final subjects = <_SubjectScore>[];

      for (final subject in item.subjects) {
        final grade = _gradeFromYear(subject.year);
        if (_selectedGrade != _allGrade && grade != _selectedGrade) {
          continue;
        }

        final subjectName = _sanitizeSubjectName(subject.name);
        if (subjectName.isEmpty) {
          continue;
        }

        subjects.add(
          _SubjectScore(
            name: subjectName,
            hk1: subject.hk1.trim(),
            hk2: subject.hk2.trim(),
            cn: subject.cn.trim(),
          ),
        );
      }

      if (subjects.isEmpty) {
        continue;
      }

      rows.add(
        _StudentForAnalysis(
          id: item.student.id,
          name: item.student.name.trim().isEmpty
              ? item.student.id
              : item.student.name,
          subjects: subjects,
        ),
      );
    }

    return rows;
  }

  List<_WeaknessItem> _calculateWeaknessAnalysis(
    List<_StudentForAnalysis> students,
  ) {
    final subjects =
        students
            .expand(
              (student) => student.subjects.map((subject) => subject.name),
            )
            .toSet()
            .toList()
          ..sort();

    final averages = <String, double>{};
    final failedStudents = <String, List<String>>{};

    for (final subject in subjects) {
      if (_isPassFailSubject(subject)) {
        for (final student in students) {
          final data = student.subjects.where((s) => s.name == subject);
          for (final item in data) {
            final raw = _pickScoreBySemester(
              item,
              _selectedSemester,
            ).toLowerCase();
            if (raw.isEmpty) {
              continue;
            }
            if (_isPassFailFailScore(raw)) {
              failedStudents
                  .putIfAbsent(subject, () => <String>[])
                  .add(student.name);
            }
          }
        }
        continue;
      }

      var total = 0.0;
      var count = 0;
      for (final student in students) {
        final data = student.subjects.where((s) => s.name == subject);
        for (final item in data) {
          final score = double.tryParse(
            _pickScoreBySemester(item, _selectedSemester),
          );
          if (score != null) {
            total += score;
            count += 1;
          }
        }
      }
      if (count > 0) {
        averages[subject] = total / count;
      }
    }

    final result = <_WeaknessItem>[];

    for (final entry in averages.entries) {
      if (entry.value < 5.5) {
        result.add(
          _WeaknessItem(
            subject: entry.key,
            score: entry.value,
            improvement: 'Can cai thien ky nang mon ${entry.key}',
          ),
        );
      }
    }

    for (final entry in failedStudents.entries) {
      result.add(
        _WeaknessItem(
          subject: entry.key,
          score: 0,
          improvement:
              'Co ${entry.value.length} hoc sinh khong dat: ${entry.value.join(', ')}',
        ),
      );
    }

    result.sort((a, b) => a.score.compareTo(b.score));
    return result;
  }

  _DistributionData _calculatePerformanceDistribution(
    List<_StudentForAnalysis> students,
  ) {
    var excellent = 0;
    var good = 0;
    var needsImprovement = 0;

    for (final student in students) {
      final average = _calculateStudentAverage(student);
      if (average == null) {
        continue;
      }

      if (average >= 8.0) {
        excellent += 1;
      } else if (average >= 6.5) {
        good += 1;
      } else {
        needsImprovement += 1;
      }
    }

    return _DistributionData(
      excellent: excellent,
      good: good,
      needsImprovement: needsImprovement,
    );
  }

  List<_SubjectAverage> _calculateStrongSubjects(
    List<_StudentForAnalysis> students,
  ) {
    final totals = <String, double>{};
    final counts = <String, int>{};

    for (final student in students) {
      for (final subject in student.subjects) {
        if (_isPassFailSubject(subject.name)) {
          continue;
        }

        final score = double.tryParse(
          _pickScoreBySemester(subject, _selectedSemester),
        );
        if (score == null) {
          continue;
        }

        totals[subject.name] = (totals[subject.name] ?? 0) + score;
        counts[subject.name] = (counts[subject.name] ?? 0) + 1;
      }
    }

    final result = <_SubjectAverage>[];
    for (final entry in totals.entries) {
      final count = counts[entry.key] ?? 0;
      if (count == 0) {
        continue;
      }
      result.add(
        _SubjectAverage(name: entry.key, average: entry.value / count),
      );
    }

    result.sort((a, b) => b.average.compareTo(a.average));
    return result.take(3).toList();
  }

  List<double> _buildTrendPoints(List<OcrAllStudentDataItem> students) {
    final grades = <String>['10', '11', '12'];
    final points = <double>[];

    for (final grade in grades) {
      final scores = <double>[];

      for (final item in students) {
        final gpa = item.reportCard.gpa[grade];
        if (gpa != null) {
          scores.add(gpa);
          continue;
        }

        final fallback = item.subjects
            .where((subject) => _gradeFromYear(subject.year) == grade)
            .map((subject) => double.tryParse(subject.cn))
            .whereType<double>()
            .toList();

        if (fallback.isNotEmpty) {
          scores.add(_average(fallback));
        }
      }

      points.add(_average(scores));
    }

    return points;
  }

  double? _calculateStudentAverage(_StudentForAnalysis student) {
    final validScores = <double>[];

    for (final subject in student.subjects) {
      if (_isPassFailSubject(subject.name)) {
        continue;
      }

      final score = double.tryParse(
        _pickScoreBySemester(subject, _selectedSemester),
      );
      if (score != null) {
        validScores.add(score);
      }
    }

    if (validScores.isEmpty) {
      return null;
    }

    return _average(validScores);
  }

  String _sanitizeSubjectName(String name) {
    final raw = name.trim();
    if (raw.isEmpty) {
      return '';
    }
    final cleaned = raw.contains(':') ? raw.split(':').first.trim() : raw;
    return cleaned.replaceAll('.', '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _isPassFailSubject(String subjectName) {
    final normalized = _normalizeForMatch(subjectName);
    return _passFailSubjects.any(
      (subject) => normalized.contains(_normalizeForMatch(subject)),
    );
  }

  bool _isPassFailFailScore(String rawScore) {
    final normalized = _normalizeForMatch(rawScore);
    if (normalized.isEmpty) {
      return false;
    }
    if (normalized == 'dat' || normalized == 'pass') {
      return false;
    }
    if (normalized == 'khong dat' ||
        normalized == 'chua dat' ||
        normalized == 'fail') {
      return true;
    }

    return double.tryParse(normalized) == null;
  }

  String _normalizeForMatch(String value) {
    return value
        .toLowerCase()
        .replaceAll('đ', 'd')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ả', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ạ', 'a')
        .replaceAll('ă', 'a')
        .replaceAll('ắ', 'a')
        .replaceAll('ằ', 'a')
        .replaceAll('ẳ', 'a')
        .replaceAll('ẵ', 'a')
        .replaceAll('ặ', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ấ', 'a')
        .replaceAll('ầ', 'a')
        .replaceAll('ẩ', 'a')
        .replaceAll('ẫ', 'a')
        .replaceAll('ậ', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ẻ', 'e')
        .replaceAll('ẽ', 'e')
        .replaceAll('ẹ', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ế', 'e')
        .replaceAll('ề', 'e')
        .replaceAll('ể', 'e')
        .replaceAll('ễ', 'e')
        .replaceAll('ệ', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ỉ', 'i')
        .replaceAll('ĩ', 'i')
        .replaceAll('ị', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ỏ', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ọ', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ố', 'o')
        .replaceAll('ồ', 'o')
        .replaceAll('ổ', 'o')
        .replaceAll('ỗ', 'o')
        .replaceAll('ộ', 'o')
        .replaceAll('ơ', 'o')
        .replaceAll('ớ', 'o')
        .replaceAll('ờ', 'o')
        .replaceAll('ở', 'o')
        .replaceAll('ỡ', 'o')
        .replaceAll('ợ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ủ', 'u')
        .replaceAll('ũ', 'u')
        .replaceAll('ụ', 'u')
        .replaceAll('ư', 'u')
        .replaceAll('ứ', 'u')
        .replaceAll('ừ', 'u')
        .replaceAll('ử', 'u')
        .replaceAll('ữ', 'u')
        .replaceAll('ự', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('ỳ', 'y')
        .replaceAll('ỷ', 'y')
        .replaceAll('ỹ', 'y')
        .replaceAll('ỵ', 'y')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _pickScoreBySemester(_SubjectScore subject, _SemesterOption semester) {
    switch (semester) {
      case _SemesterOption.hk1:
        return subject.hk1;
      case _SemesterOption.hk2:
        return subject.hk2;
      case _SemesterOption.fullYear:
        return subject.cn;
    }
  }

  String _gradeFromYear(String year) {
    switch (year.trim()) {
      case '1':
        return '10';
      case '2':
        return '11';
      case '3':
        return '12';
      default:
        return '';
    }
  }

  double _average(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }
    final total = values.fold<double>(0, (sum, value) => sum + value);
    return total / values.length;
  }

  String _classKeyForStudent(OcrAllStudentDataItem item) {
    final className = item.student.className.trim().toLowerCase();
    final classYear = item.student.classYear.trim().toLowerCase();
    final school = item.student.school.trim().toLowerCase();
    return '$className|$classYear|$school';
  }

  String _classKeyForClassroom(ClassroomItem item) {
    final classId = item.id.trim();
    if (classId.isNotEmpty) {
      return 'class_id:$classId';
    }
    final className = item.name.trim().toLowerCase();
    final classYear = item.classYear.trim().toLowerCase();
    final school = item.schoolName.trim().toLowerCase();
    return '$className|$classYear|$school';
  }

  String _classLabelForStudent(OcrAllStudentDataItem item) {
    final className = item.student.className.trim();
    final classYear = item.student.classYear.trim();
    final school = item.student.school.trim();

    final parts = <String>[className];
    if (classYear.isNotEmpty) {
      parts.add(classYear);
    }
    if (school.isNotEmpty) {
      parts.add(school);
    }
    return parts.join(' - ');
  }

  String _classLabelForClassroom(ClassroomItem item) {
    final className = item.name.trim();
    final classYear = item.classYear.trim();
    final school = item.schoolName.trim();

    final parts = <String>[className];
    if (classYear.isNotEmpty) {
      parts.add(classYear);
    }
    if (school.isNotEmpty) {
      parts.add(school);
    }
    return parts.join(' - ');
  }

  String _labelForClassKey(List<_ClassFilterOption> options, String key) {
    for (final option in options) {
      if (option.key == key) {
        return option.label;
      }
    }
    return key;
  }

  Widget _buildHeader() {
    final userName = (AuthSession.instance.user?.fullName ?? '').trim();
    final displayName = userName.isEmpty ? 'Thay/Co' : userName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.heroPrimary, Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _headerButton(
                icon: Icons.arrow_back_rounded,
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    (route) => false,
                  );
                },
              ),
              const Expanded(
                child: Text(
                  'Phan tich hoc luc',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _headerButton(
                icon: Icons.refresh_rounded,
                onTap: _loadStatistics,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Xin chao, $displayName',
              style: const TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: AppFontSizes.dashboardBody,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Bao cao tong quat hoc luc',
              style: TextStyle(
                color: AppColors.white,
                fontSize: AppFontSizes.dashboardTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    final classOptions = _classOptions;
    final classKeys = classOptions.map((option) => option.key).toList();

    return Transform.translate(
      offset: const Offset(0, -24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown<String>(
                      hint: 'Chon lop',
                      value: _selectedClassKey,
                      items: classKeys,
                      itemLabel: (item) =>
                          _labelForClassKey(classOptions, item),
                      onChanged: (value) {
                        setState(() {
                          _selectedClassKey = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdown<_SemesterOption>(
                      hint: 'Hoc ky',
                      value: _selectedSemester,
                      items: _SemesterOption.values,
                      itemLabel: (item) => item.label,
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedSemester = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildDropdown<String>(
                hint: 'Khoi',
                value: _selectedGrade,
                items: const <String>[_allGrade, '10', '11', '12'],
                itemLabel: (item) =>
                    item == _allGrade ? 'Tat ca khoi' : 'Khoi $item',
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedGrade = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T item) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      hint: Text(
        hint,
        style: const TextStyle(
          fontSize: AppFontSizes.dashboardCaption,
          color: AppColors.subtitle,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppFontSizes.dashboardCaption,
                  fontWeight: FontWeight.w600,
                  color: AppColors.title,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildOverviewCards(_StatisticsData statistics) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tong quan (${statistics.studentCount} hoc sinh)',
            style: const TextStyle(
              fontSize: AppFontSizes.dashboardTitle,
              fontWeight: FontWeight.w800,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _OverviewCard(
                  icon: Icons.analytics_rounded,
                  iconBg: const Color(0xFFDBEAFE),
                  iconColor: const Color(0xFF2563EB),
                  value: statistics.classAverage <= 0
                      ? '--'
                      : statistics.classAverage.toStringAsFixed(2),
                  label: 'DTB lop',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewCard(
                  icon: Icons.workspace_premium_rounded,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                  value: '${statistics.gioiKhaPercent.toStringAsFixed(0)}%',
                  label: 'Gioi + Kha',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewCard(
                  icon: Icons.people_rounded,
                  iconBg: const Color(0xFFFFEDD5),
                  iconColor: const Color(0xFFEA580C),
                  value: '${statistics.validStudentCount}',
                  label: 'HS hop le',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionCard(_DistributionData distribution) {
    final buckets = <_DistributionBucket>[
      _DistributionBucket(
        label: 'Xuat sac',
        count: distribution.excellent,
        color: const Color(0xFF38A169),
      ),
      _DistributionBucket(
        label: 'Kha',
        count: distribution.good,
        color: const Color(0xFF3182CE),
      ),
      _DistributionBucket(
        label: 'Can cai thien',
        count: distribution.needsImprovement,
        color: const Color(0xFFDD6B20),
      ),
    ];

    final maxCount = buckets.fold<int>(
      1,
      (maxValue, item) => math.max(maxValue, item.count),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Container(
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
              'Phan bo hoc luc',
              style: TextStyle(
                fontSize: AppFontSizes.dashboardBody,
                fontWeight: FontWeight.w800,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: buckets
                  .map(
                    (bucket) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _BarItem(
                          label: bucket.label,
                          value: bucket.count,
                          height: 26 + (bucket.count / maxCount) * 80,
                          color: bucket.color,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(List<double> points) {
    final delta = points[2] - points[0];
    final isUp = delta >= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Container(
        width: double.infinity,
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
                const Expanded(
                  child: Text(
                    'Xu huong GPA theo khoi',
                    style: TextStyle(
                      fontSize: AppFontSizes.dashboardBody,
                      fontWeight: FontWeight.w800,
                      color: AppColors.title,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isUp
                        ? const Color(0xFFE8F8EC)
                        : const Color(0xFFFFECEC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${isUp ? '+' : ''}${delta.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: AppFontSizes.dashboardTiny,
                      fontWeight: FontWeight.w700,
                      color: isUp
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 96,
              width: double.infinity,
              child: CustomPaint(painter: _TrendLinePainter(points: points)),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Khoi 10',
                  style: TextStyle(
                    fontSize: AppFontSizes.dashboardTiny,
                    color: AppColors.footer,
                  ),
                ),
                Text(
                  'Khoi 11',
                  style: TextStyle(
                    fontSize: AppFontSizes.dashboardTiny,
                    color: AppColors.footer,
                  ),
                ),
                Text(
                  'Khoi 12',
                  style: TextStyle(
                    fontSize: AppFontSizes.dashboardTiny,
                    color: AppColors.footer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeaknessSection(List<_WeaknessItem> weaknessItems) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Container(
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
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
                SizedBox(width: 6),
                Text(
                  'Diem yeu can cai thien',
                  style: TextStyle(
                    fontSize: AppFontSizes.dashboardBody,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (weaknessItems.isEmpty)
              const Text(
                'Khong co mon yeu theo nguong hien tai.',
                style: TextStyle(
                  fontSize: AppFontSizes.dashboardCaption,
                  color: AppColors.subtitle,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              ...weaknessItems
                  .take(3)
                  .map(
                    (item) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.subject,
                            style: const TextStyle(
                              fontSize: AppFontSizes.dashboardBody,
                              fontWeight: FontWeight.w700,
                              color: AppColors.title,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Diem: ${item.score.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: AppFontSizes.dashboardTiny,
                              color: AppColors.subtitle,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.improvement,
                            style: const TextStyle(
                              fontSize: AppFontSizes.dashboardTiny,
                              color: AppColors.subtitle,
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

  Widget _buildStrengthSection(List<_SubjectAverage> strongSubjects) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Container(
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
            const Row(
              children: [
                Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B)),
                SizedBox(width: 6),
                Text(
                  'Top mon hoc the manh',
                  style: TextStyle(
                    fontSize: AppFontSizes.dashboardBody,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (strongSubjects.isEmpty)
              const Text(
                'Chua du du lieu mon hoc.',
                style: TextStyle(
                  fontSize: AppFontSizes.dashboardCaption,
                  color: AppColors.subtitle,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              ...strongSubjects.map(
                (subject) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StrengthBar(
                    subject: subject.name,
                    score: subject.average.toStringAsFixed(2),
                    progress: (subject.average / 10).clamp(0, 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Khong tai duoc thong ke',
              style: TextStyle(
                fontSize: AppFontSizes.dashboardBody,
                fontWeight: FontWeight.w800,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Da xay ra loi.',
              style: const TextStyle(
                fontSize: AppFontSizes.dashboardCaption,
                color: AppColors.subtitle,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadStatistics,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thu lai'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: AppFontSizes.dashboardCaption,
            color: AppColors.subtitle,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _headerButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppColors.white),
        ),
      ),
    );
  }
}

enum _SemesterOption {
  hk1('Hoc ky 1'),
  hk2('Hoc ky 2'),
  fullYear('Ca nam');

  const _SemesterOption(this.label);
  final String label;
}

class _SubjectScore {
  const _SubjectScore({
    required this.name,
    required this.hk1,
    required this.hk2,
    required this.cn,
  });

  final String name;
  final String hk1;
  final String hk2;
  final String cn;
}

class _StudentForAnalysis {
  const _StudentForAnalysis({
    required this.id,
    required this.name,
    required this.subjects,
  });

  final String id;
  final String name;
  final List<_SubjectScore> subjects;
}

class _WeaknessItem {
  const _WeaknessItem({
    required this.subject,
    required this.score,
    required this.improvement,
  });

  final String subject;
  final double score;
  final String improvement;
}

class _SubjectAverage {
  const _SubjectAverage({required this.name, required this.average});

  final String name;
  final double average;
}

class _DistributionData {
  const _DistributionData({
    required this.excellent,
    required this.good,
    required this.needsImprovement,
  });

  final int excellent;
  final int good;
  final int needsImprovement;
}

class _DistributionBucket {
  const _DistributionBucket({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

class _ClassFilterOption {
  const _ClassFilterOption({
    required this.key,
    required this.label,
    required this.classId,
  });

  final String key;
  final String label;
  final String? classId;
}

class _StatisticsData {
  const _StatisticsData({
    required this.studentCount,
    required this.validStudentCount,
    required this.classAverage,
    required this.gioiKhaPercent,
    required this.distribution,
    required this.weaknessItems,
    required this.strongSubjects,
    required this.trendPoints,
  });

  final int studentCount;
  final int validStudentCount;
  final double classAverage;
  final double gioiKhaPercent;
  final _DistributionData distribution;
  final List<_WeaknessItem> weaknessItems;
  final List<_SubjectAverage> strongSubjects;
  final List<double> trendPoints;

  factory _StatisticsData.empty() {
    return const _StatisticsData(
      studentCount: 0,
      validStudentCount: 0,
      classAverage: 0,
      gioiKhaPercent: 0,
      distribution: _DistributionData(
        excellent: 0,
        good: 0,
        needsImprovement: 0,
      ),
      weaknessItems: <_WeaknessItem>[],
      strongSubjects: <_SubjectAverage>[],
      trendPoints: <double>[0, 0, 0],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: value.length <= 4 ? 24 : 16,
              fontWeight: FontWeight.w800,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.footer,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.label,
    required this.value,
    required this.height,
    required this.color,
  });

  final String label;
  final int value;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: AppFontSizes.dashboardTiny,
            color: AppColors.footer,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppFontSizes.dashboardTiny,
            color: AppColors.footer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({
    required this.subject,
    required this.score,
    required this.progress,
  });

  final String subject;
  final String score;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                subject,
                style: const TextStyle(
                  fontSize: AppFontSizes.dashboardCaption,
                  color: AppColors.label,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              score,
              style: const TextStyle(
                fontSize: AppFontSizes.dashboardCaption,
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFE8EEF8),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter({required this.points});

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    final safePoints = points.length >= 3 ? points : const <double>[0, 0, 0];
    final maxPoint = safePoints.reduce(math.max);
    final minPoint = safePoints.reduce(math.min);
    final range = (maxPoint - minPoint).abs() < 0.001
        ? 1.0
        : (maxPoint - minPoint);

    double yFor(double value) {
      final normalized = (value - minPoint) / range;
      return size.height * (0.85 - (normalized * 0.7));
    }

    final p1 = Offset(0, yFor(safePoints[0]));
    final p2 = Offset(size.width * 0.5, yFor(safePoints[1]));
    final p3 = Offset(size.width, yFor(safePoints[2]));

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x331337EC), Color(0x001337EC)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..quadraticBezierTo(size.width * 0.25, (p1.dy + p2.dy) / 2, p2.dx, p2.dy)
      ..quadraticBezierTo(size.width * 0.75, (p2.dy + p3.dy) / 2, p3.dx, p3.dy);

    final areaPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(areaPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(p1, 3.5, dotPaint);
    canvas.drawCircle(p2, 3.5, dotPaint);
    canvas.drawCircle(p3, 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    if (oldDelegate.points.length != points.length) {
      return true;
    }
    for (var i = 0; i < points.length; i += 1) {
      if ((oldDelegate.points[i] - points[i]).abs() > 0.0001) {
        return true;
      }
    }
    return false;
  }
}
