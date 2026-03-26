import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_texts.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/views/widgets/common_bottom_nav.dart';
import 'package:edu_app_flutter/views/widgets/grade_tabs.dart';
import 'package:edu_app_flutter/views/widgets/ocr/ocr_flow_header.dart';
import 'package:flutter/material.dart';

class DetailHbaScreen extends StatefulWidget {
  const DetailHbaScreen({super.key});

  @override
  State<DetailHbaScreen> createState() => _DetailHbaScreenState();
}

class _DetailHbaScreenState extends State<DetailHbaScreen> {
  int _selectedGrade = 12;

  final List<_SubjectScoreRow> _scores = const [
    _SubjectScoreRow(subject: 'Toán học', gk: '9.0', ck: '8.5', tb: '8.8'),
    _SubjectScoreRow(subject: 'Ngữ văn', gk: '8.0', ck: '8.0', tb: '8.0'),
    _SubjectScoreRow(subject: 'Tiếng Anh', gk: '8.5', ck: '9.0', tb: '8.7'),
    _SubjectScoreRow(subject: 'Vật lý', gk: '7.5', ck: '8.5', tb: '8.0'),
    _SubjectScoreRow(subject: 'Hóa học', gk: '9.0', ck: '9.5', tb: '9.2'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                OcrFlowHeader(
                  title: AppTexts.detailHbaTitle,
                  subtitle: AppTexts.detailHbaSubtitle,
                  onBack: () => Navigator.of(context).pop(),
                  trailing: Material(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {},
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.more_vert, color: AppColors.white),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 150),
                    child: Column(
                      children: [
                        _buildProfileCard(),
                        const SizedBox(height: 12),
                        _buildResultTableCard(),
                        const SizedBox(height: 12),
                        _buildTeacherCommentCard(),
                        const SizedBox(height: 14),
                        _buildActionRow(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: CommonBottomNav(
                currentTab: BottomNavTab.classes,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(37),
              border: Border.all(color: AppColors.primary, width: 2),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuC5saDI24jFTHAqzdobNrBSGghQEx9gIXpYmkCqr0KDbjLD_ur5gH_hht_mAUnsEo_mx-zd6jUDE0CpnnQX36g4E3BAv2fH7vc6lSutYydeiKjBxgO_-v6KLWiUAQDKV3ZHfDR8wj__BVxUSiKRgc1GOXELEtVC_ctc3Mcnl_YM29iKpw61VlSkZaxzsuL1Tn_7v6rt284mASxs8ysiECKLCw7ldOlMUXDsRRyHCzi0ervnUtzYMJ8pozg8L-_n1QJnMowIG9UaSFhh',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nguyễn Văn An',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Lớp: 12A1 • MSV: 2024001',
                  style: TextStyle(
                    fontSize: AppFontSizes.dashboardBody,
                    color: AppColors.subtitle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _badge(
                      text: 'GPA: 8.5',
                      fg: AppColors.primary,
                      bg: const Color(0x1A1337EC),
                    ),
                    _badge(
                      text: 'Xếp loại: Giỏi',
                      fg: const Color(0xFF15803D),
                      bg: const Color(0x1A16A34A),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTableCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 6),
                const Text(
                  AppTexts.detailResultTitle,
                  style: TextStyle(
                    fontSize: AppFontSizes.dashboardBody,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(
                      fontSize: AppFontSizes.dashboardCaption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Xem biểu đồ'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Divider(height: 1, color: Color(0xFFE9EEF7)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: GradeTabs(
              selectedGrade: _selectedGrade,
              onChanged: (grade) {
                if (_selectedGrade == grade) return;
                setState(() => _selectedGrade = grade);
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: const WidgetStatePropertyAll(Color(0xFFF6F9FF)),
              headingTextStyle: const TextStyle(
                fontSize: AppFontSizes.dashboardCaption,
                fontWeight: FontWeight.w800,
                color: AppColors.subtitle,
              ),
              dataTextStyle: const TextStyle(
                fontSize: AppFontSizes.dashboardBody,
                color: AppColors.label,
                fontWeight: FontWeight.w600,
              ),
              columns: const [
                DataColumn(label: Text('Môn học')),
                DataColumn(numeric: true, label: Text('GK')),
                DataColumn(numeric: true, label: Text('CK')),
                DataColumn(numeric: true, label: Text('TB')),
              ],
              rows: _scores.map((row) {
                return DataRow(
                  cells: [
                    DataCell(Text(row.subject)),
                    DataCell(Text(row.gk)),
                    DataCell(Text(row.ck)),
                    DataCell(
                      Text(
                        row.tb,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTeacherCommentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
              Icon(Icons.comment_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 6),
              Text(
                AppTexts.detailTeacherComment,
                style: TextStyle(
                  fontSize: AppFontSizes.dashboardBody,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F7FF),
              borderRadius: BorderRadius.circular(10),
              border: const Border(
                left: BorderSide(color: AppColors.primary, width: 4),
              ),
            ),
            child: const Text(
              '"Em An là học sinh có tư duy tốt, đặc biệt ở các môn tự nhiên như Toán và Hóa. Em cần tích cực phát biểu xây dựng bài hơn trong giờ Ngữ văn để cải thiện kỹ năng diễn đạt. Ý thức kỷ luật tốt, tham gia đầy đủ các hoạt động của lớp."',
              style: TextStyle(
                fontSize: AppFontSizes.dashboardBody,
                height: 1.45,
                color: AppColors.label,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontSize: AppFontSizes.dashboardCaption,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Chỉnh sửa'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: _solidActionButton(
            icon: Icons.auto_awesome_rounded,
            text: AppTexts.detailAnalyzeAi,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _outlineActionButton(
            icon: Icons.description_rounded,
            text: AppTexts.detailExportReport,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 8),
        _dangerDeleteButton(),
      ],
    );
  }

  Widget _badge({required String text, required Color fg, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppFontSizes.dashboardCaption,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _solidActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1337EC), Color(0xFF2458F3)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x332348EF),
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: TextButton.icon(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
              fontSize: AppFontSizes.dashboardChip,
              fontWeight: FontWeight.w800,
            ),
          ),
          icon: Icon(icon, size: 18),
          label: Text(text),
        ),
      ),
    );
  }

  Widget _outlineActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.title,
          side: const BorderSide(color: Color(0xFFDCE4F2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: AppFontSizes.dashboardChip,
            fontWeight: FontWeight.w700,
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(text),
      ),
    );
  }

  Widget _dangerDeleteButton() {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: const Icon(Icons.delete_rounded, color: Color(0xFFDC2626)),
        ),
      ),
    );
  }
}

class _SubjectScoreRow {
  const _SubjectScoreRow({
    required this.subject,
    required this.gk,
    required this.ck,
    required this.tb,
  });

  final String subject;
  final String gk;
  final String ck;
  final String tb;
}
