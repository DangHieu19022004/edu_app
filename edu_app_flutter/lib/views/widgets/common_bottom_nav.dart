import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:flutter/material.dart';

class BottomNavItemData {
  const BottomNavItemData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class CommonBottomNav extends StatelessWidget {
  const CommonBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.centerLabel,
    required this.centerIcon,
    this.onCenterTap,
  }) : assert(items.length == 4, 'Bottom nav expects exactly 4 side items.');

  final List<BottomNavItemData> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String centerLabel;
  final IconData centerIcon;
  final VoidCallback? onCenterTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x160B1D47),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(child: _buildNavItem(index: 0)),
              Expanded(child: _buildNavItem(index: 1)),
              _buildCenterAction(),
              Expanded(child: _buildNavItem(index: 2)),
              Expanded(child: _buildNavItem(index: 3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index}) {
    final item = items[index];
    final selected = currentIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => onTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: AppFontSizes.icon24,
              color: selected ? AppColors.primary : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: AppFontSizes.dashboardTiny,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? AppColors.primary : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAction() {
    return Transform.translate(
      offset: const Offset(0, -14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(19),
            child: InkWell(
              onTap: onCenterTap,
              borderRadius: BorderRadius.circular(19),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: AppColors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x401337EC),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(centerIcon, color: AppColors.white, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            centerLabel,
            style: const TextStyle(
              fontSize: AppFontSizes.dashboardTiny,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
