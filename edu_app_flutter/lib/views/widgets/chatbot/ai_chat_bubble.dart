import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AiChatBubble extends StatelessWidget {
  const AiChatBubble({
    super.key,
    required this.message,
    this.label = 'EduBot',
  });

  final String message;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.chatbot,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x120F1D44),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: MarkdownBody(
                    data: message,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 16,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                      strong: const TextStyle(
                        fontSize: 16,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                      listBullet: const TextStyle(
                        fontSize: 16,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                      h1: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                      h2: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                      h3: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                      blockquote: const TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                      code: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        color: Color(0xFF0F172A),
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
