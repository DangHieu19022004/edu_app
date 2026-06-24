import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:flutter/material.dart';

class DashboardActivityItem extends StatelessWidget {
  const DashboardActivityItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.richText,
    required this.time,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final InlineSpan richText;
  final String time;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 52,
                  color: AppColors.timelineLine,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(text: richText),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: AppFontSizes.dashboardTiny,
                    fontWeight: FontWeight.w600,
                    color: AppColors.footer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
