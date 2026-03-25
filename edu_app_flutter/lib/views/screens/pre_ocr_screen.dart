import 'dart:io';

import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_texts.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PreOcrScreen extends StatefulWidget {
  const PreOcrScreen({super.key});

  @override
  State<PreOcrScreen> createState() => _PreOcrScreenState();
}

class _PreOcrScreenState extends State<PreOcrScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  bool _isPicking = false;

  Future<void> _pickFromDevice() async {
    await _runPicker(() async {
      final images = await _picker.pickMultiImage(imageQuality: 92);
      if (images.isEmpty || !mounted) return;
      setState(() {
        _selectedImages
          ..clear()
          ..addAll(images);
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
        _selectedImages.add(image);
      });
    });
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

  void _confirmSelection() {
    if (_selectedImages.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chọn ${_selectedImages.length} ảnh. Sẵn sàng OCR.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildBackButton(),
              ),
            ),
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    _selectedImages.isEmpty
                        ? _buildEmptyState()
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
                          onPressed: _selectedImages.isEmpty
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

  Widget _buildBackButton() {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => Navigator.of(context).pop(),
        child: const SizedBox(
          width: 38,
          height: 38,
          child: Icon(Icons.arrow_back, color: AppColors.title),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.heroPrimary, Color(0xFF2458F3)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              AppTexts.preOcrTitle,
              style: TextStyle(
                fontSize: AppFontSizes.dashboardTitle,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 116,
            child: _ActionCardButton(
              icon: Icons.photo_library_rounded,
              title: AppTexts.preOcrChooseFromDevice,
              onTap: _pickFromDevice,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 116,
            child: _ActionCardButton(
              icon: Icons.camera_alt_rounded,
              title: AppTexts.preOcrCaptureByCamera,
              onTap: _captureByCamera,
            ),
          ),
        ),
      ],
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

  Widget _buildImagePreviewList() {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final file = _selectedImages[index];

          return Container(
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
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.file(
                      File(file.path),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: Text(
                    'Ảnh ${index + 1}',
                    style: const TextStyle(
                      fontSize: AppFontSizes.dashboardCaption,
                      color: AppColors.label,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Row(
                    children: [
                      _TinyActionButton(
                        icon: Icons.photo_library_rounded,
                        tooltip: 'Chọn lại',
                        onTap: () => _replaceImage(index, ImageSource.gallery),
                      ),
                      const SizedBox(width: 6),
                      _TinyActionButton(
                        icon: Icons.camera_alt_rounded,
                        tooltip: 'Chụp lại',
                        onTap: () => _replaceImage(index, ImageSource.camera),
                      ),
                      const Spacer(),
                      _TinyActionButton(
                        icon: Icons.delete_outline_rounded,
                        tooltip: 'Xóa',
                        isDanger: true,
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
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
