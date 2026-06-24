import 'package:edu_app_flutter/constants/api_config.dart';
import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:flutter/material.dart';

class AppUserAvatar extends StatelessWidget {
  const AppUserAvatar({
    super.key,
    required this.avatar,
    required this.size,
    this.borderRadius,
    this.iconSize,
  });

  final String avatar;
  final double size;
  final BorderRadius? borderRadius;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeAvatarUrl(avatar);

    if (normalized == null) {
      return _fallback();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
      child: Image.network(
        normalized,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
      ),
      child: Icon(
        Icons.person_rounded,
        color: AppColors.primary,
        size: iconSize ?? size * 0.52,
      ),
    );
  }

  String? _normalizeAvatarUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('/')) {
      return '${ApiConfig.apiBaseUrl}$value';
    }

    return null;
  }
}
