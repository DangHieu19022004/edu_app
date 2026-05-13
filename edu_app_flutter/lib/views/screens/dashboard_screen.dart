import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_texts.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/services/auth_session.dart';
import 'package:edu_app_flutter/views/widgets/common_bottom_nav.dart';
import 'package:edu_app_flutter/views/widgets/app_user_avatar.dart';
import 'package:edu_app_flutter/views/widgets/dashboard/dashboard_activity_item.dart';
import 'package:edu_app_flutter/views/widgets/dashboard/dashboard_feature_card.dart';
// import 'package:edu_app_flutter/views/widgets/dashboard/dashboard_quick_action_chip.dart';
import 'package:edu_app_flutter/views/widgets/dashboard/dashboard_section_header.dart';
import 'package:edu_app_flutter/views/screens/chatbot_screen.dart';
import 'package:edu_app_flutter/views/screens/pre_ocr_screen.dart';
import 'package:edu_app_flutter/views/screens/profile_screen.dart';
import 'package:edu_app_flutter/views/screens/study_report_screen.dart';
import 'package:edu_app_flutter/views/screens/statistics_screen.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = AuthSession.instance.user;
    final displayName = (currentUser?.fullName ?? '').trim();
    final avatar = (currentUser?.avatar ?? '').trim();

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
                  _DashboardHeroHeader(
                    displayName: displayName,
                    avatar: avatar,
                  ),
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
                currentTab: BottomNavTab.home,
                onScanTap: _openPreOcr,
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

  void _openPreOcr() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PreOcrScreen()));
  }

  void _openStudyReport() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StudyReportScreen()));
  }

  void _openStatistics() {
    Navigator.of(
      context
    ).push(MaterialPageRoute(builder: (_) => const StatisticsScreen()));
  }

  void _openChatbot() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChatbotScreen()));
  }

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
            children: [
              DashboardFeatureCard(
                icon: Icons.document_scanner_rounded,
                title: 'Quét học bạ',
                subtitle: 'Số hóa nhanh',
                accent: AppColors.primary,
                onTap: _openPreOcr,
              ),
              DashboardFeatureCard(
                icon: Icons.smart_toy_rounded,
                title: 'Chatbot hỗ trợ',
                subtitle: 'Trợ lý ảo AI',
                accent: Color(0xFF06B6D4),
                onTap: _openChatbot,
              ),
              DashboardFeatureCard(
                icon: Icons.bar_chart_rounded,
                title: 'Thống kê điểm',
                subtitle: 'Trực quan hóa dữ liệu',
                accent: Color(0xFF16A34A),
                onTap: _openStatistics,
              ),
              DashboardFeatureCard(
                icon: Icons.mark_email_read_rounded,
                title: 'Báo cáo học tập',
                subtitle: 'Gửi email phụ huynh',
                accent: AppColors.primary,
                onTap: _openStudyReport,
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
  const _DashboardHeroHeader({required this.displayName, required this.avatar});

  final String displayName;
  final String avatar;

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
                  GestureDetector(
                    onTap: () {
                      Navigator.of(
                        context,
                      ).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: AppUserAvatar(
                      avatar: avatar,
                      size: 48,
                      borderRadius: BorderRadius.circular(16),
                      iconSize: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chào ${displayName.isEmpty ? 'bạn' : displayName} 👋',
                          style: const TextStyle(
                            fontSize: AppFontSizes.dashboardGreeting,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
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
                    const Icon(
                      AppIcons.search,
                      color: AppColors.inputHint,
                      size: 20,
                    ),
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
                      child: const Icon(
                        AppIcons.tune,
                        color: AppColors.primary,
                        size: 18,
                      ),
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
