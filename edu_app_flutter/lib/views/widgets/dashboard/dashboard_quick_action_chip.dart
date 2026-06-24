import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:flutter/material.dart';

class DashboardQuickActionChip extends StatelessWidget {
  const DashboardQuickActionChip({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor = AppColors.primary,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.chipGlass,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppFontSizes.dashboardChip,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
