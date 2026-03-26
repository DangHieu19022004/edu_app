import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/views/widgets/common_bottom_nav.dart';
import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const SafeArea(
        child: Center(
          child: Text(
            'Màn Thống kê sẽ được triển khai sau',
            style: TextStyle(
              fontSize: AppFontSizes.dashboardBody,
              color: AppColors.subtitle,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(
        currentTab: BottomNavTab.statistics,
      ),
    );
  }
}
