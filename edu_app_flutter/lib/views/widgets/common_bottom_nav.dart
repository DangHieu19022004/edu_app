import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/views/screens/dashboard_screen.dart';
import 'package:edu_app_flutter/views/screens/list_hba_screen.dart';
import 'package:edu_app_flutter/views/screens/pre_ocr_screen.dart';
import 'package:edu_app_flutter/views/screens/profile_screen.dart';
import 'package:edu_app_flutter/views/screens/statistics_screen.dart';
import 'package:flutter/material.dart';

enum BottomNavTab {
  home,
  statistics,
  classes,
  profile,
}

class CommonBottomNav extends StatelessWidget {
  const CommonBottomNav({
    super.key,
    required this.currentTab,
    this.onScanTap,
  });

  final BottomNavTab currentTab;
  final VoidCallback? onScanTap;

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
              Expanded(
                child: _buildNavItem(
                  context: context,
                  tab: BottomNavTab.home,
                  icon: AppIcons.home,
                  label: 'Trang chủ',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  tab: BottomNavTab.statistics,
                  icon: AppIcons.stats,
                  label: 'Thống kê',
                ),
              ),
              _buildCenterAction(context),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  tab: BottomNavTab.classes,
                  icon: AppIcons.classList,
                  label: 'Lớp',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  tab: BottomNavTab.profile,
                  icon: AppIcons.profile,
                  label: 'Cá nhân',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required BottomNavTab tab,
    required IconData icon,
    required String label,
  }) {
    final selected = currentTab == tab;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _onTabTapped(context, tab),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppFontSizes.icon24,
              color: selected ? AppColors.primary : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 2),
            Text(
              label,
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

  Widget _buildCenterAction(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(19),
            child: InkWell(
              onTap: () => _onCenterTap(context),
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
                child: Icon(AppIcons.scan, color: AppColors.white, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Quét',
            style: TextStyle(
              fontSize: AppFontSizes.dashboardTiny,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _onCenterTap(BuildContext context) {
    if (onScanTap != null) {
      onScanTap!.call();
      return;
    }
    _push(context, const PreOcrScreen());
  }

  void _onTabTapped(BuildContext context, BottomNavTab tab) {
    if (tab == currentTab) return;

    switch (tab) {
      case BottomNavTab.home:
        _replaceAll(context, const DashboardScreen());
      case BottomNavTab.statistics:
        _replaceAll(context, const StatisticsScreen());
      case BottomNavTab.classes:
        _replaceAll(context, const ListHbaScreen());
      case BottomNavTab.profile:
        _replaceAll(context, const ProfileScreen());
    }
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _replaceAll(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }
}
