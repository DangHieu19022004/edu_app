import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/views/widgets/common_bottom_nav.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  children: [
                    _buildHeader(context),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle(text: 'Tài khoản & Quản lý'),
                          const SizedBox(height: 8),
                          const _MenuTile(
                            icon: Icons.person_rounded,
                            title: 'Thông tin cá nhân',
                          ),
                          const SizedBox(height: 8),
                          const _MenuTile(
                            icon: Icons.school_rounded,
                            title: 'Quản lý lớp học',
                          ),
                          const SizedBox(height: 8),
                          const _MenuTile(
                            icon: Icons.notifications_rounded,
                            title: 'Cài đặt thông báo',
                          ),
                          const SizedBox(height: 16),
                          const _SectionTitle(text: 'Hỗ trợ & Bảo mật'),
                          const SizedBox(height: 8),
                          const _MenuTile(
                            icon: Icons.security_rounded,
                            title: 'Bảo mật & Đổi mật khẩu',
                          ),
                          const SizedBox(height: 8),
                          const _MenuTile(
                            icon: Icons.help_rounded,
                            title: 'Trợ giúp & Hỗ trợ',
                          ),
                          const SizedBox(height: 8),
                          const _MenuTile(
                            icon: Icons.policy_rounded,
                            title: 'Điều khoản & Chính sách',
                          ),
                          const SizedBox(height: 16),
                          _buildLogoutButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(
        currentTab: BottomNavTab.profile,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroPrimary, Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _headerIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const Expanded(
                child: Text(
                  'Hồ sơ của tôi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: AppFontSizes.dashboardTitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _headerIconButton(icon: Icons.settings_rounded, onTap: () {}),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 4),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAxBED0k4qqelxi_cJy_ksyiYTNB7FklYiHkilHwF2_B4uIfvSI_lROsvcxTRUULI8VoVsTjW_jKTTB86FsT1vkpzjALt2MZCFvP-EEwb7SYoB_niBjwc_c1ejg25q96JEJzdVo18fjcEUczBJqaMl64clfLx5WwwyoEF0CCEDSXjQhS3-bHxRFQw-z0N4c5TcMAfddf3W3jdiGXSj-NBMO2Z6OB_DmRTaXZxmigYgzmraLunFwq9ijvyagt_rs3AWzEwnPFxWkVRkE',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 4,
                bottom: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Cô Lan',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Trường Tiểu học Chu Văn An',
            style: TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: AppFontSizes.dashboardBody,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text(
              'THÀNH VIÊN TỪ 2022',
              style: TextStyle(
                color: AppColors.white,
                fontSize: AppFontSizes.dashboardTiny,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFFF1F2),
          side: const BorderSide(color: Color(0xFFFECACA)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: const Color(0xFFDC2626),
          textStyle: const TextStyle(
            fontSize: AppFontSizes.dashboardBody,
            fontWeight: FontWeight.w700,
          ),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Đăng xuất'),
      ),
    );
  }

  Widget _headerIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppColors.white),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: AppFontSizes.dashboardTiny,
          fontWeight: FontWeight.w800,
          color: AppColors.footer,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSizes.dashboardBody,
                    fontWeight: FontWeight.w600,
                    color: AppColors.title,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.footer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
