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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildFloatingFilters(),
              _buildOverviewCards(),
              _buildDistributionCard(),
              _buildTrendCard(),
              _buildStrengthWeaknessSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(
        currentTab: BottomNavTab.statistics,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.heroPrimary, Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _headerButton(icon: Icons.arrow_back_rounded, onTap: () {}),
              const Expanded(
                child: Text(
                  'Phân tích học lực',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _headerButton(icon: Icons.notifications_none_rounded, onTap: () {}),
            ],
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Xin chào, Thầy Tuấn',
              style: TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: AppFontSizes.dashboardBody,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Báo cáo tổng quát học kỳ',
              style: TextStyle(
                color: AppColors.white,
                fontSize: AppFontSizes.dashboardTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingFilters() {
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                _FilterChip(label: 'Lớp 12A1', selected: true),
                SizedBox(width: 8),
                _FilterChip(label: 'Học kỳ 1'),
                SizedBox(width: 8),
                _FilterChip(label: '2023-2024'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan',
            style: TextStyle(
              fontSize: AppFontSizes.dashboardTitle,
              fontWeight: FontWeight.w800,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(
                child: _OverviewCard(
                  icon: Icons.analytics_rounded,
                  iconBg: Color(0xFFDBEAFE),
                  iconColor: Color(0xFF2563EB),
                  value: '8.5',
                  label: 'ĐTB Hệ thống',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _OverviewCard(
                  icon: Icons.workspace_premium_rounded,
                  iconBg: Color(0xFFDCFCE7),
                  iconColor: Color(0xFF16A34A),
                  value: '85%',
                  label: 'Giỏi / Khá',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _OverviewCard(
                  icon: Icons.priority_high_rounded,
                  iconBg: Color(0xFFFFEDD5),
                  iconColor: Color(0xFFEA580C),
                  value: 'Toán',
                  label: 'Cần hỗ trợ',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Biểu đồ phân bổ điểm số',
                    style: TextStyle(
                      fontSize: AppFontSizes.dashboardBody,
                      fontWeight: FontWeight.w800,
                      color: AppColors.title,
                    ),
                  ),
                ),
                Icon(Icons.info_outline_rounded, color: AppColors.footer),
              ],
            ),
            const SizedBox(height: 14),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _BarItem(label: 'Kém', height: 24, color: Color(0xFFE2E8F0))),
                SizedBox(width: 6),
                Expanded(child: _BarItem(label: 'TB', height: 40, color: Color(0xFFE2E8F0))),
                SizedBox(width: 6),
                Expanded(child: _BarItem(label: 'Khá', height: 76, color: Color(0x661337EC))),
                SizedBox(width: 6),
                Expanded(child: _BarItem(label: 'Giỏi', height: 96, color: AppColors.primary)),
                SizedBox(width: 6),
                Expanded(child: _BarItem(label: 'XS', height: 32, color: Color(0x991337EC))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Xu hướng học tập',
                    style: TextStyle(
                      fontSize: AppFontSizes.dashboardBody,
                      fontWeight: FontWeight.w800,
                      color: AppColors.title,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8EC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF16A34A)),
                      SizedBox(width: 2),
                      Text(
                        '+0.3',
                        style: TextStyle(
                          fontSize: AppFontSizes.dashboardTiny,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 96,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrendLinePainter(),
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tháng 9', style: TextStyle(fontSize: AppFontSizes.dashboardTiny, color: AppColors.footer)),
                Text('Tháng 11', style: TextStyle(fontSize: AppFontSizes.dashboardTiny, color: AppColors.footer)),
                Text('Tháng 1', style: TextStyle(fontSize: AppFontSizes.dashboardTiny, color: AppColors.footer)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthWeaknessSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B)),
                    SizedBox(width: 6),
                    Text(
                      'Top môn học thế mạnh',
                      style: TextStyle(
                        fontSize: AppFontSizes.dashboardBody,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _StrengthBar(subject: 'Vật lý', score: '9.2', progress: 0.92),
                SizedBox(height: 10),
                _StrengthBar(subject: 'Tiếng Anh', score: '8.8', progress: 0.88),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.eco_rounded, color: Color(0xFFEF4444)),
                    SizedBox(width: 6),
                    Text(
                      'Môn học cần hỗ trợ',
                      style: TextStyle(
                        fontSize: AppFontSizes.dashboardBody,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calculate_rounded, color: AppColors.white),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toán học',
                              style: TextStyle(
                                fontSize: AppFontSizes.dashboardBody,
                                fontWeight: FontWeight.w700,
                                color: AppColors.title,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'ĐTB: 6.4 (-0.5 so với HK trước)',
                              style: TextStyle(
                                fontSize: AppFontSizes.dashboardTiny,
                                color: AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: null,
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(AppColors.white),
                        ),
                        child: Text(
                          'Chi tiết',
                          style: TextStyle(
                            fontSize: AppFontSizes.dashboardCaption,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primary.withValues(alpha: 0.22) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppFontSizes.dashboardBody,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? AppColors.primary : AppColors.subtitle,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: selected ? AppColors.primary : AppColors.subtitle,
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: value.length <= 4 ? 24 : 20,
              fontWeight: FontWeight.w800,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.footer,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({required this.label, required this.height, required this.color});

  final String label;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppFontSizes.dashboardTiny,
            color: AppColors.footer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.subject, required this.score, required this.progress});

  final String subject;
  final String score;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                subject,
                style: const TextStyle(
                  fontSize: AppFontSizes.dashboardCaption,
                  color: AppColors.label,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              score,
              style: const TextStyle(
                fontSize: AppFontSizes.dashboardCaption,
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFE8EEF8),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x331337EC), Color(0x001337EC)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.65,
        size.width * 0.5,
        size.height * 0.35,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.14,
        size.width,
        size.height * 0.08,
      );

    final areaPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(areaPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
