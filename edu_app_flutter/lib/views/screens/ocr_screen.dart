import 'dart:io';
import 'dart:convert';

import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_texts.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/ocr_service.dart';
import 'package:edu_app_flutter/views/screens/detail_academic_transcript_screen.dart';
import 'package:edu_app_flutter/views/widgets/grade_tabs.dart';
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
  final OcrService _ocrService = OcrService();
  bool _isDetecting = true;
  String? _detectError;
  List<Map<String, dynamic>> _ocrResults = const <Map<String, dynamic>>[];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();

  final List<_SubjectScore> _scores = const <_SubjectScore>[];

  @override
  void initState() {
    super.initState();
    _runDetect();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  Future<void> _runDetect() async {
    if (widget.imagePaths.isEmpty) {
      setState(() {
        _isDetecting = false;
        _detectError = 'Khong co anh de quet.';
      });
      return;
    }

    setState(() {
      _isDetecting = true;
      _detectError = null;
    });

    try {
      final results = await _ocrService.detectReportCard(
        imagePaths: widget.imagePaths,
      );

      if (!mounted) return;

      _logOcrData(results);
      _applyStudentInfo(results);

      setState(() {
        _ocrResults = results;
        _isDetecting = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isDetecting = false;
        _detectError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDetecting = false;
        _detectError = 'Quet hoc ba that bai. Vui long thu lai.';
      });
    }
  }

  void _applyStudentInfo(List<Map<String, dynamic>> results) {
    if (results.isEmpty) return;

    final dynamic first = results.first;
    if (first is! Map<String, dynamic>) return;

    final dynamic studentInfo = first['student_info'];
    if (studentInfo is! Map<String, dynamic>) return;

    final name = (studentInfo['name'] ?? studentInfo['full_name'] ?? '')
        .toString()
        .trim();
    final className =
        (studentInfo['class'] ?? studentInfo['class_name'] ?? '').toString().trim();
    final semester =
        (studentInfo['semester'] ?? studentInfo['hoc_ky'] ?? '').toString().trim();

    _nameController.text = name;
    _classController.text = className;
    _semesterController.text = semester;
  }

  void _logOcrData(List<Map<String, dynamic>> results) {
    if (results.isEmpty) {
      debugPrint('[OCR][detect] Khong co result nao tu backend.');
      return;
    }

    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      final dynamic ocrData = result['ocr_data'];

      debugPrint('[OCR][detect] result_index=$i');
      debugPrint('[OCR][detect] ocr_data_type=${ocrData.runtimeType}');

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
                    GradeTabs(
                      selectedGrade: _selectedGrade,
                      onChanged: (grade) {
                        if (_selectedGrade == grade) return;
                        setState(() => _selectedGrade = grade);
                      },
                    ),
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
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DetailHbaScreen(),
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
          if (_detectError != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
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
          if (!_isDetecting && _detectError == null && _ocrResults.isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF8FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCFE8FF)),
              ),
              child: Text(
                'Da nhan ${_ocrResults.length} ket qua OCR. Du lieu ocr_data da duoc log ra console de phan tich.',
                style: const TextStyle(
                  fontSize: AppFontSizes.dashboardCaption,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ),
          ],
          const Text(
            AppTexts.ocrAverageScore,
            style: TextStyle(
              fontSize: AppFontSizes.dashboardCaption,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 8),
          if (_scores.isEmpty)
            const Text(
              'Dang doi phan tich ocr_data de map bang diem.',
              style: TextStyle(
                fontSize: AppFontSizes.dashboardCaption,
                color: AppColors.subtitle,
                fontWeight: FontWeight.w600,
              ),
            )
          else
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
