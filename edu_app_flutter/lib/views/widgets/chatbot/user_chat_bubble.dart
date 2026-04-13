import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/views/widgets/app_user_avatar.dart';
import 'package:flutter/material.dart';

class UserChatBubble extends StatelessWidget {
  const UserChatBubble({
    super.key,
    required this.message,
    required this.avatar,
    this.label = 'Ban',
  });

  final String message;
  final String avatar;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: AppFontSizes.dashboardBody,
                    color: AppColors.subtitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x120F1D44),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppUserAvatar(
            avatar: avatar,
            size: 34,
            borderRadius: BorderRadius.circular(17),
            iconSize: 18,
          ),
        ],
      ),
    );
  }
}
