import 'dart:io';

import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_texts.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/views/widgets/ocr/ocr_flow_header.dart';
import 'package:flutter/material.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key, required this.imagePaths});

  final List<String> imagePaths;

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  int _selectedGrade = 12;

  final TextEditingController _nameController = TextEditingController(
    text: 'Nguyen Van An',
  );
  final TextEditingController _classController = TextEditingController(
    text: '12A1',
  );
  final TextEditingController _semesterController = TextEditingController(
    text: 'Hoc ky 1',
  );

  final List<_SubjectScore> _scores = const [
    _SubjectScore(subject: 'Toan hoc', score: '9.5'),
    _SubjectScore(subject: 'Ngu van', score: '8.0'),
    _SubjectScore(subject: 'Vat ly', score: '8.8'),
  ];

  static const double _progress = 0.85;

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? firstPath = widget.imagePaths.isEmpty
        ? null
        : widget.imagePaths.first;

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
                    _buildPreviewCard(firstPath),
                    const SizedBox(height: 14),
                    _buildProgressCard(),
                    const SizedBox(height: 16),
                    const Text(
                      AppTexts.ocrResultTitle,
                      style: TextStyle(
                        fontSize: AppFontSizes.dashboardTitle,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildGradeTabs(),
                    const SizedBox(height: 10),
                    _buildResultCard(),
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
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Đã xác nhận và lưu kết quả OCR.',
                                ),
                              ),
                            );
                          },
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
                          child: const Text(AppTexts.preOcrConfirm),
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

  Widget _buildGradeTabs() {
    const List<int> grades = [10, 11, 12];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: grades.map((grade) {
          final bool isSelected = _selectedGrade == grade;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: isSelected ? AppColors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    if (_selectedGrade == grade) return;
                    setState(() => _selectedGrade = grade);
                  },
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return AppColors.primary.withValues(alpha: 0.12);
                    }
                    return null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 90),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0x332348EF)
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      'Lớp $grade',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppFontSizes.dashboardBody,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.subtitle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 42),
                            height: 2,
                            color: AppColors.primary,
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
    final int percent = (_progress * 100).round();

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
              value: _progress,
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

  Widget _buildResultCard() {
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
                  label: AppTexts.ocrClass,
                  controller: _classController,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EditableField(
                  label: AppTexts.ocrSemester,
                  controller: _semesterController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            AppTexts.ocrAverageScore,
            style: TextStyle(
              fontSize: AppFontSizes.dashboardCaption,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 8),
          ..._scores.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.subject,
                        style: const TextStyle(
                          fontSize: AppFontSizes.dashboardBody,
                          fontWeight: FontWeight.w600,
                          color: AppColors.label,
                        ),
                      ),
                    ),
                    Text(
                      item.score,
                      style: const TextStyle(
                        fontSize: AppFontSizes.dashboardBody,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

class _SubjectScore {
  const _SubjectScore({required this.subject, required this.score});

  final String subject;
  final String score;
}
