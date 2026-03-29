import 'package:flutter/material.dart';

import 'package:edu_app_flutter/constants/app_colors.dart';

enum AppNoticeType { success, error, info }

class AppNoticeModal {
  AppNoticeModal._();

  static Future<void> showSuccess(
    BuildContext context, {
    required String message,
    String title = 'Thanh cong',
    String actionLabel = 'Dong',
  }) {
    return show(
      context,
      type: AppNoticeType.success,
      title: title,
      message: message,
      actionLabel: actionLabel,
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required String message,
    String title = 'Co loi xay ra',
    String actionLabel = 'Thu lai',
  }) {
    return show(
      context,
      type: AppNoticeType.error,
      title: title,
      message: message,
      actionLabel: actionLabel,
    );
  }

  static Future<void> show(
    BuildContext context, {
    required AppNoticeType type,
    required String title,
    required String message,
    String actionLabel = 'Da hieu',
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Notice',
      barrierDismissible: barrierDismissible,
      barrierColor: const Color(0xA61A2440),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, _, __) {
        return _AppNoticeSheet(
          type: type,
          title: title,
          message: message,
          actionLabel: actionLabel,
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final scale = Tween<double>(begin: 0.9, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        );

        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }
}

class _AppNoticeSheet extends StatelessWidget {
  const _AppNoticeSheet({
    required this.type,
    required this.title,
    required this.message,
    required this.actionLabel,
  });

  final AppNoticeType type;
  final String title;
  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final visual = _NoticeVisual.fromType(type);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 430),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2611294D),
                    blurRadius: 34,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOutBack,
                      tween: Tween<double>(begin: 0.88, end: 1),
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              visual.baseColor,
                              visual.baseColor.withOpacity(0.75),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(visual.icon, color: Colors.white, size: 34),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.title,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.subtitle,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              visual.baseColor,
                              visual.baseColor.withOpacity(0.82),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text(actionLabel),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeVisual {
  const _NoticeVisual({required this.baseColor, required this.icon});

  final Color baseColor;
  final IconData icon;

  factory _NoticeVisual.fromType(AppNoticeType type) {
    switch (type) {
      case AppNoticeType.success:
        return const _NoticeVisual(
          baseColor: Color(0xFF1B9A58),
          icon: Icons.check_rounded,
        );
      case AppNoticeType.error:
        return const _NoticeVisual(
          baseColor: Color(0xFFDB3A54),
          icon: Icons.close_rounded,
        );
      case AppNoticeType.info:
        return const _NoticeVisual(
          baseColor: AppColors.primary,
          icon: Icons.info_outline_rounded,
        );
    }
  }
}
