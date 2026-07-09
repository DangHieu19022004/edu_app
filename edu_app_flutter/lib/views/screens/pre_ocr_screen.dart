import 'dart:io';

import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_texts.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/models/ocr_models.dart';
import 'package:edu_app_flutter/views/screens/ocr_screen.dart';
import 'package:edu_app_flutter/views/widgets/app_notice_modal.dart';
import 'package:edu_app_flutter/views/widgets/ocr/ocr_flow_header.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class PreOcrScreen extends StatefulWidget {
  const PreOcrScreen({super.key});

  @override
  State<PreOcrScreen> createState() => _PreOcrScreenState();
}

class _PreOcrScreenState extends State<PreOcrScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<OcrImageRole> _selectedRoles = [];
  String? _selectedPdfPath;
  String? _selectedPdfName;
  bool _isPicking = false;

  static const List<OcrImageRole> _roleOptions = <OcrImageRole>[
    OcrImageRole.studentInfo,
    OcrImageRole.grade10,
    OcrImageRole.grade11,
    OcrImageRole.grade12,
  ];

  Future<void> _pickFromDevice() async {
    await _runPicker(() async {
      final images = await _picker.pickMultiImage(imageQuality: 92);
      if (images.isEmpty || !mounted) return;
      setState(() {
        _selectedPdfPath = null;
        _selectedPdfName = null;
        _selectedImages
          ..clear()
          ..addAll(images);
        _selectedRoles
          ..clear()
          ..addAll(
            List<OcrImageRole>.generate(
              images.length,
              (index) => _defaultRoleForIndex(index),
            ),
          );
      });
    });
  }

  Future<void> _captureByCamera() async {
    await _runPicker(() async {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
      );
      if (image == null || !mounted) return;
      setState(() {
        _selectedPdfPath = null;
        _selectedPdfName = null;
        final nextIndex = _selectedImages.length;
        _selectedImages.add(image);
        _selectedRoles.add(_defaultRoleForIndex(nextIndex));
      });
    });
  }

  Future<void> _pickFromPdf() async {
    await _runPicker(() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        allowMultiple: false,
        withData: false,
      );

      final pdfPath = result?.files.single.path;
      if (pdfPath == null || pdfPath.trim().isEmpty || !mounted) return;

      setState(() {
        _selectedImages.clear();
        _selectedRoles.clear();
        _selectedPdfPath = pdfPath;
        _selectedPdfName =
            result?.files.single.name ?? pdfPath.split(Platform.pathSeparator).last;
      });
    });
  }

  Future<List<XFile>> _renderPdfPagesToImages(String pdfPath) async {
    final document = await PdfDocument.openFile(pdfPath);
    final tempDir = await getTemporaryDirectory();
    final outputDir = Directory(
      '${tempDir.path}${Platform.pathSeparator}edu_app_pdf_ocr_${DateTime.now().millisecondsSinceEpoch}',
    );
    await outputDir.create(recursive: true);

    final pageCount = document.pagesCount < _roleOptions.length
        ? document.pagesCount
        : _roleOptions.length;
    final renderedImages = <XFile>[];

    try {
      for (var pageNumber = 1; pageNumber <= pageCount; pageNumber++) {
        final page = await document.getPage(pageNumber);
        try {
          final width = page.width * 2;
          final height = page.height * 2;
          final pageImage = await page.render(
            width: width,
            height: height,
            format: PdfPageImageFormat.png,
          );

          if (pageImage == null) continue;

          final imageFile = File(
            '${outputDir.path}${Platform.pathSeparator}page_$pageNumber.png',
          );
          await imageFile.writeAsBytes(pageImage.bytes, flush: true);
          renderedImages.add(XFile(imageFile.path));
        } finally {
          await page.close();
        }
      }
    } finally {
      await document.close();
    }

    return renderedImages;
  }

  Future<void> _replaceImage(int index, ImageSource source) async {
    await _runPicker(() async {
      final image = await _picker.pickImage(source: source, imageQuality: 92);
      if (image == null || !mounted) return;
      setState(() {
        _selectedImages[index] = image;
      });
    });
  }

  Future<void> _runPicker(Future<void> Function() action) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _confirmSelection() async {
    if (_selectedImages.isEmpty && _selectedPdfPath == null) return;

    final sortedInputs = _selectedPdfPath == null
        ? _buildSortedImageInputs()
        : await _buildInputsFromSelectedPdf();
    if (sortedInputs.isEmpty) return;

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OcrScreen(
          imageInputs: sortedInputs,
        ),
      ),
    );
  }

  Future<List<OcrDetectImageInput>> _buildInputsFromSelectedPdf() async {
    final pdfPath = _selectedPdfPath;
    if (pdfPath == null || pdfPath.trim().isEmpty) {
      return const <OcrDetectImageInput>[];
    }

    setState(() => _isPicking = true);
    try {
      final renderedImages = await _renderPdfPagesToImages(pdfPath);
      if (renderedImages.length < _roleOptions.length) {
        if (mounted) {
          await AppNoticeModal.showError(
            context,
            title: 'PDF chưa đủ trang',
            message:
                'PDF cần đủ 4 trang theo thứ tự: thông tin chung, lớp 10, lớp 11, lớp 12.',
          );
        }
        return const <OcrDetectImageInput>[];
      }

      return List<OcrDetectImageInput>.generate(
        _roleOptions.length,
        (index) => OcrDetectImageInput(
          path: renderedImages[index].path,
          role: _defaultRoleForIndex(index),
        ),
      );
    } catch (_) {
      if (mounted) {
        await AppNoticeModal.showError(
          context,
          title: 'Không đọc được PDF',
          message: 'Không thể chuyển PDF thành ảnh. Vui lòng thử file khác.',
        );
      }
      return const <OcrDetectImageInput>[];
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _openImagePreview(XFile file, int index) async {
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0xE6000000),
      builder: (dialogContext) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.9,
                    maxScale: 4.5,
                    child: Image.file(
                      File(file.path),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 14,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text(AppTexts.preOcrExitPreview),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xE8121A2F),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: AppFontSizes.dashboardCaption,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC111A31),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x339DB3DB)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ảnh ${index + 1}',
                          style: const TextStyle(
                            fontSize: AppFontSizes.dashboardBody,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          AppTexts.preOcrPreviewHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppFontSizes.dashboardCaption,
                            color: Color(0xD6FFFFFF),
                            fontWeight: FontWeight.w500,
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
      },
    );
  }

  OcrImageRole _defaultRoleForIndex(int index) {
    if (index == 0) return OcrImageRole.studentInfo;
    if (index == 1) return OcrImageRole.grade10;
    if (index == 2) return OcrImageRole.grade11;
    if (index == 3) return OcrImageRole.grade12;
    return OcrImageRole.grade12;
  }

  List<OcrDetectImageInput> _buildSortedImageInputs() {
    final inputs = <OcrDetectImageInput>[];

    for (var i = 0; i < _selectedImages.length; i++) {
      final role = i < _selectedRoles.length
          ? _selectedRoles[i]
          : _defaultRoleForIndex(i);

      inputs.add(OcrDetectImageInput(path: _selectedImages[i].path, role: role));
    }

    inputs.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return inputs;
  }

  @override
  Widget build(BuildContext context) {
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
                    _buildCaptureGuideCard(),
                    const SizedBox(height: 14),
                    _buildOptionButtons(),
                    const SizedBox(height: 18),
                    Text(
                      AppTexts.preOcrSelectedImages,
                      style: const TextStyle(
                        fontSize: AppFontSizes.dashboardTitle,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _selectedImages.isEmpty && _selectedPdfPath == null
                        ? _buildEmptyState()
                        : _selectedPdfPath != null
                            ? _buildPdfSelectedCard()
                            : _buildImagePreviewList(),
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
                          onPressed: _selectedImages.isEmpty &&
                                  _selectedPdfPath == null
                              ? null
                              : _confirmSelection,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white70,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: AppFontSizes.signInButton,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: _isPicking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
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

  Widget _buildOptionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        final itemWidth = isNarrow
            ? (constraints.maxWidth - 10) / 2
            : (constraints.maxWidth - 20) / 3;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: itemWidth,
              height: 116,
              child: _ActionCardButton(
                icon: Icons.photo_library_rounded,
                title: AppTexts.preOcrChooseFromDevice,
                onTap: _pickFromDevice,
              ),
            ),
            SizedBox(
              width: itemWidth,
              height: 116,
              child: _ActionCardButton(
                icon: Icons.camera_alt_rounded,
                title: AppTexts.preOcrCaptureByCamera,
                onTap: _captureByCamera,
              ),
            ),
            SizedBox(
              width: itemWidth,
              height: 116,
              child: _ActionCardButton(
                icon: Icons.picture_as_pdf_rounded,
                title: 'Nhập bằng PDF',
                onTap: _pickFromPdf,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCaptureGuideCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7E4FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.tips_and_updates_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTexts.preOcrGuideTitle,
                  style: TextStyle(
                    fontSize: AppFontSizes.dashboardBody,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  AppTexts.preOcrGuideBody,
                  style: TextStyle(
                    fontSize: AppFontSizes.dashboardCaption,
                    color: AppColors.subtitle,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Text(
        AppTexts.preOcrEmptyHint,
        style: TextStyle(
          fontSize: AppFontSizes.dashboardBody,
          color: AppColors.subtitle,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildPdfSelectedCard() {
    final fileName = _selectedPdfName ?? 'hoc_ba.pdf';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Color(0xFFDC2626),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppFontSizes.dashboardBody,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'PDF sẽ được tách 4 trang khi bấm xác nhận.',
                  style: TextStyle(
                    fontSize: AppFontSizes.dashboardCaption,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _TinyActionButton(
            icon: Icons.folder_open_rounded,
            tooltip: 'Chọn PDF khác',
            onTap: _pickFromPdf,
          ),
          const SizedBox(width: 6),
          _TinyActionButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Xóa PDF',
            isDanger: true,
            onTap: () {
              setState(() {
                _selectedPdfPath = null;
                _selectedPdfName = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewList() {
    return SizedBox(
      height: 224,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final file = _selectedImages[index];

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openImagePreview(file, index),
              child: Container(
                width: 170,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.file(
                              File(file.path),
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            left: 8,
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xB3121A2F),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.open_in_full_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      AppTexts.preOcrTapToPreview,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: AppFontSizes.dashboardTiny,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ảnh ${index + 1}',
                            style: const TextStyle(
                              fontSize: AppFontSizes.dashboardCaption,
                              color: AppColors.label,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            AppTexts.preOcrImageLabel,
                            style: TextStyle(
                              fontSize: AppFontSizes.dashboardTiny,
                              color: AppColors.subtitle,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F6FD),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<OcrImageRole>(
                                value: index < _selectedRoles.length
                                    ? _selectedRoles[index]
                                    : _defaultRoleForIndex(index),
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.expand_more_rounded,
                                  size: 18,
                                  color: AppColors.subtitle,
                                ),
                                style: const TextStyle(
                                  fontSize: AppFontSizes.dashboardTiny,
                                  color: AppColors.title,
                                  fontWeight: FontWeight.w700,
                                ),
                                items: _roleOptions.map((role) {
                                  return DropdownMenuItem<OcrImageRole>(
                                    value: role,
                                    child: Text(
                                      OcrDetectImageInput(path: '', role: role)
                                          .roleLabel,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (role) {
                                  if (role == null) return;
                                  setState(() {
                                    if (index < _selectedRoles.length) {
                                      _selectedRoles[index] = role;
                                    } else {
                                      _selectedRoles.add(role);
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Row(
                        children: [
                          _TinyActionButton(
                            icon: Icons.photo_library_rounded,
                            tooltip: 'Chọn lại từ thư viện',
                            onTap: () =>
                                _replaceImage(index, ImageSource.gallery),
                          ),
                          const SizedBox(width: 6),
                          _TinyActionButton(
                            icon: Icons.camera_alt_rounded,
                            tooltip: 'Chụp lại ảnh này',
                            onTap: () => _replaceImage(index, ImageSource.camera),
                          ),
                          const Spacer(),
                          _TinyActionButton(
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'Xóa ảnh này',
                            isDanger: true,
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                                if (index < _selectedRoles.length) {
                                  _selectedRoles.removeAt(index);
                                }
                              });
                            },
                          ),
                        ],
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
}

class _ActionCardButton extends StatelessWidget {
  const _ActionCardButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppFontSizes.dashboardChip,
                  fontWeight: FontWeight.w700,
                  color: AppColors.title,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyActionButton extends StatelessWidget {
  const _TinyActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final Color fg = isDanger ? const Color(0xFFDC2626) : AppColors.primary;
    final Color bg = isDanger
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFEFF4FF);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(icon, size: 17, color: fg),
          ),
        ),
      ),
    );
  }
}
