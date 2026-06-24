import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:flutter/material.dart';

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: AppFontSizes.dashboardTitle,
              fontWeight: FontWeight.w800,
              color: AppColors.title,
            ),
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(
                fontSize: AppFontSizes.dashboardBody,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(actionText!),
          ),
      ],
    );
  }
}
