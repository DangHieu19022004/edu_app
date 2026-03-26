import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:flutter/material.dart';

class OcrFlowHeader extends StatelessWidget {
  const OcrFlowHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.heroPrimary, Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1D4ED8),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.2),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back, color: AppColors.white),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppFontSizes.dashboardTitle,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: AppFontSizes.dashboardBody,
                        fontWeight: FontWeight.w500,
                        color: Color(0xD9FFFFFF),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            SizedBox(
              width: 40,
              height: 40,
              child: trailing,
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}
