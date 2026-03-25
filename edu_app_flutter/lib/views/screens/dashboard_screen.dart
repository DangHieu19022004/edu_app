import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_texts.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/views/widgets/common_bottom_nav.dart';
import 'package:edu_app_flutter/views/widgets/dashboard/dashboard_activity_item.dart';
import 'package:edu_app_flutter/views/widgets/dashboard/dashboard_feature_card.dart';
import 'package:edu_app_flutter/views/widgets/dashboard/dashboard_quick_action_chip.dart';
import 'package:edu_app_flutter/views/widgets/dashboard/dashboard_section_header.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _bottomIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DashboardHeroHeader(),
                  // _buildQuickActions(),
                  _buildFeaturesSection(),
                  _buildRecentActivitySection(),
                ],
              ),
            ),
            Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: CommonBottomNav(
                currentIndex: _bottomIndex,
                onTap: (index) => setState(() => _bottomIndex = index),
                centerLabel: 'Quét',
                centerIcon: AppIcons.scan,
                onCenterTap: () {},
                items: const [
                  BottomNavItemData(icon: AppIcons.home, label: 'Trang chủ'),
                  BottomNavItemData(icon: AppIcons.find, label: 'Tra cứu'),
                  BottomNavItemData(icon: AppIcons.chatbot, label: 'Chatbot'),
                  BottomNavItemData(icon: AppIcons.profile, label: 'Cá nhân'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildQuickActions() {
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
  //     child: SingleChildScrollView(
  //       scrollDirection: Axis.horizontal,
  //       child: Row(
  //         children: const [
  //           DashboardQuickActionChip(
  //             icon: Icons.person_add_alt_1_rounded,
  //             title: 'Thêm phụ huynh',
  //             iconColor: AppColors.primary,
  //           ),
  //           SizedBox(width: 8),
  //           DashboardQuickActionChip(
  //             icon: Icons.history_rounded,
  //             title: 'Lịch sử email',
  //             iconColor: Color(0xFF8B5CF6),
  //           ),
  //           SizedBox(width: 8),
  //           DashboardQuickActionChip(
  //             icon: Icons.ios_share_rounded,
  //             title: 'Xuất báo cáo',
  //             iconColor: Color(0xFF14B8A6),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardSectionHeader(
            title: AppTexts.dashboardMainFeatures,
            actionText: AppTexts.viewAll,
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.96,
            children: const [
              DashboardFeatureCard(
                icon: Icons.document_scanner_rounded,
                title: 'Quét học bạ',
                subtitle: 'Số hóa nhanh',
                accent: AppColors.primary,
              ),
              DashboardFeatureCard(
                icon: Icons.manage_search_rounded,
                title: 'Tra cứu học bạ',
                subtitle: 'Tìm kiếm tức thì',
                accent: Color(0xFF8B5CF6),
              ),
              DashboardFeatureCard(
                icon: Icons.smart_toy_rounded,
                title: 'Chatbot hỗ trợ',
                subtitle: 'Trợ lý ảo AI',
                accent: Color(0xFF06B6D4),
              ),
              DashboardFeatureCard(
                icon: Icons.forum_rounded,
                title: 'Chatbot tư vấn',
                subtitle: 'Hỗ trợ phụ huynh',
                accent: Color(0xFF7C3AED),
              ),
              DashboardFeatureCard(
                icon: Icons.bar_chart_rounded,
                title: 'Thống kê điểm',
                subtitle: 'Bảng điểm tự động',
                accent: Color(0xFF16A34A),
              ),
              DashboardFeatureCard(
                icon: Icons.description_rounded,
                title: 'Báo cáo',
                subtitle: 'Định kỳ tháng/quý',
                accent: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    final bodyStyle = const TextStyle(
      fontSize: AppFontSizes.dashboardBody,
      fontWeight: FontWeight.w500,
      color: Color(0xFF334155),
      height: 1.3,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardSectionHeader(title: AppTexts.dashboardRecentActivity),
          const SizedBox(height: 10),
          DashboardActivityItem(
            icon: Icons.document_scanner_rounded,
            iconColor: AppColors.primary,
            time: '10 phút trước',
            richText: TextSpan(
              style: bodyStyle,
              children: const [
                TextSpan(text: 'Bạn vừa '),
                TextSpan(
                  text: 'quét học bạ',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' học sinh Nguyễn Văn A'),
              ],
            ),
          ),
          DashboardActivityItem(
            icon: Icons.mail_rounded,
            iconColor: const Color(0xFF8B5CF6),
            time: '1 giờ trước',
            richText: TextSpan(
              style: bodyStyle,
              children: const [
                TextSpan(text: 'Đã gửi '),
                TextSpan(
                  text: 'thông báo điểm',
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' cho 35 phụ huynh'),
              ],
            ),
          ),
          DashboardActivityItem(
            icon: Icons.analytics_rounded,
            iconColor: const Color(0xFF14B8A6),
            time: 'Hôm qua',
            isLast: true,
            richText: TextSpan(
              style: bodyStyle,
              children: const [
                TextSpan(text: 'Hoàn thành '),
                TextSpan(
                  text: 'phân tích kết quả',
                  style: TextStyle(
                    color: Color(0xFF14B8A6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' học kỳ I'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeroHeader extends StatelessWidget {
  const _DashboardHeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroPrimary, AppColors.heroSecondary],
        ),
        borderRadius: BorderRadius.circular(34),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -26,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -52,
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.38),
                        width: 1.3,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuB3CY0AWwr3WS211jlqooxkPnwy4alV3Qtm_Ft_-oKFnmYE6EAbCxDwOiyTsLzzVTXQ3sIawryu6lfdtpHAvviqfHH2_g4LBPVKa0McQWwrKAYp8L-sYZEBmKX89_Th6C-V5CwM5jFs1oPAWULUHGSzFo-83fWE4N0DAiEAnd0Sz5jHoS4R0r0dpFFBk58bo91rB3Uw5_joFUrZc2XpWq5wTqnbjmjh6btEyUootue8BfxXg3Dp3KFmMm1pB-1bCI-H5Gexxt5RQh2x',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 26,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppTexts.dashboardGreeting} 👋',
                          style: TextStyle(
                            fontSize: AppFontSizes.dashboardGreeting,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          AppTexts.dashboardSubGreeting,
                          style: TextStyle(
                            fontSize: AppFontSizes.dashboardBody,
                            color: Color(0xDBFFFFFF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {},
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        child: const Icon(
                          AppIcons.notifications,
                          color: AppColors.white,
                          size: 23,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x331337EC),
                      blurRadius: 16,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.search, color: AppColors.inputHint, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: AppTexts.dashboardSearchHint,
                          hintStyle: TextStyle(
                            color: AppColors.inputHint,
                            fontSize: AppFontSizes.dashboardBody,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                        style: TextStyle(
                          color: AppColors.title,
                          fontSize: AppFontSizes.dashboardBody,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(AppIcons.tune, color: AppColors.primary, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
