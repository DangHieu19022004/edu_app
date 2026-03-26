import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/views/screens/dashboard_screen.dart';
import 'package:edu_app_flutter/views/screens/detail_academic_transcript_screen.dart';
import 'package:edu_app_flutter/views/screens/pre_ocr_screen.dart';
import 'package:edu_app_flutter/views/widgets/common_bottom_nav.dart';
import 'package:edu_app_flutter/views/widgets/ocr/ocr_flow_header.dart';
import 'package:flutter/material.dart';

class ListHbaScreen extends StatefulWidget {
  const ListHbaScreen({super.key});

  @override
  State<ListHbaScreen> createState() => _ListHbaScreenState();
}

class _ListHbaScreenState extends State<ListHbaScreen> {
  int _selectedClassIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _classTabs = const ['12A3', '11A6', '10A5', '12C1', '9A2'];

  final List<_StudentCardData> _students = const [
    _StudentCardData(
      name: 'Nguyễn Văn An',
      birthday: '20/05/2007',
      school: 'THPT EduTeacher',
      avatar:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuC0Ph2judfi_F8jWCzOU7mPe-6Dhbmj3Bd9IdmQ8o1UOKJDi56ert_EGM4Sdo0L3S3JtsZ_PdJUl99tbT7q6mrfMjmd25OBJpbhPJLGl6x2znykKC00_h_0-4i0-gJ4i_OS_gTDwsgEbTdJnGNRx7xpRiAbUb2Yl-Yf18GNPZyN2wd6PxCuzYvvoFzAwlzBjixHpcrnqmhRlEbJ8N1XV_PawrFnFWqus91L-GO0QbqvGiIlOQkP54DKqZlUv1ljWueN48l_qyBxj2Hy',
      online: true,
      tags: ['TO', 'LY', 'HOA'],
    ),
    _StudentCardData(
      name: 'Trần Thị Bình',
      birthday: '12/08/2007',
      school: 'THPT EduTeacher',
      avatar:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAGpNuCEYfmkyzzf9fbXOzAN2fu4gXVpeFXHriuzhTvRZfkoWKEmLwIaRPhyvIGJAr2qKAmZo34M_2VdsI4stTNWOBgDeEDDqna-Wy83G8tECthRYi6Rz40C18i2yAdT2EhVYKP6JH6K001bZUPC1FakzgxYYcDUXkNUUcAYbENgecSN8Ieqowdm453FnhTMPpbbuihcw0YV3OvmkAKba4O812Pw4iOULH8X8uawLSDERvxstpRvYUIf8aKlCa2wFgj2xTbMSxF3zNo',
      online: true,
      tags: ['VAN', 'ANH', 'SU'],
    ),
    _StudentCardData(
      name: 'Lê Hoàng Cường',
      birthday: '05/01/2007',
      school: 'THPT EduTeacher',
      avatar:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA8_w04h3g2GltXxJraqVrdPJ6QWcD4lF-cbRxJiAdBf0i0c4wRV2XJjFFfXJ-aGYByNBb2BboaUptlhSbIJ093ykYrefjliLYpD1Me0v7RJA2ZG3x5JOMU3EgbcP1dkGgiENz5MbzM-pZbpxKM2XEcR8sd8S6SkLzuwp9n1-wulTDWsdZhj41ZR4FlEv-Y40oKD9jRQMTMTe_O1cpGudWihYCsTHpRvDo9r-k9CZpD2dMwUnSCTuF6xmM9eeRi-BC3IA2-p9jE-By-',
      online: false,
      tags: ['TIN', 'TOAN'],
    ),
    _StudentCardData(
      name: 'Phạm Mỹ Duyên',
      birthday: '29/11/2007',
      school: 'THPT EduTeacher',
      avatar:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB7unOfnMKPJJOd16ZzszNO3k0VGeIkK5CYCUNHRfeJSMTLaTORleBtP7LetD10wrlqD8Q9Nz5GYSJodEVKEb6MKPvSelnRAE3ApqewQmjAbWjQJ-PVeWMVJlNYOum08Io2K-HV5r99GQJ9OLz1miSdRviZTuD3rNvR2IaVFlre9J1ITthg0oWKRd-PupQjZaUhR8rCkOU8F1QqW_pQBkpouPxLX_naCQv0vU5vi76OWMAibeMaZUABUsj_LPaE-tQnHoPRiXsEZYhA',
      online: true,
      tags: ['NHAC', 'ANH'],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _students.where((student) {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      return student.name.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OcrFlowHeader(
              title: 'Học bạ',
              subtitle: 'Quản lý hồ sơ học sinh',
              onBack: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                  return;
                }
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quản lý học bạ',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Theo dõi và cập nhật hồ sơ năng lực học sinh.',
                      style: TextStyle(
                        fontSize: AppFontSizes.dashboardBody,
                        fontWeight: FontWeight.w500,
                        color: AppColors.subtitle,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSearchBox(),
                    const SizedBox(height: 14),
                    _buildClassTabs(),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.0,
                          ),
                      itemCount: filtered.length + 1,
                      itemBuilder: (context, index) {
                        if (index == filtered.length) {
                          return _buildAddCard();
                        }
                        return _StudentCard(
                          student: filtered[index],
                          onView: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DetailHbaScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PreOcrScreen()),
          );
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: const CommonBottomNav(
        currentTab: BottomNavTab.classes,
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm học sinh...',
        hintStyle: const TextStyle(
          fontSize: AppFontSizes.dashboardBody,
          color: AppColors.inputHint,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.inputHint),
        filled: true,
        fillColor: const Color(0xFFF2F6FD),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildClassTabs() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _classTabs.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == _classTabs.length) {
            return Material(
              color: const Color(0xFFE9EEFA),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {},
                child: const SizedBox(
                  width: 44,
                  child: Icon(Icons.add, color: AppColors.primary),
                ),
              ),
            );
          }

          final selected = _selectedClassIndex == index;
          return Material(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => setState(() => _selectedClassIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? Colors.transparent : const Color(0xFFD5DEEA),
                  ),
                ),
                child: Text(
                  _classTabs[index],
                  style: TextStyle(
                    fontSize: AppFontSizes.dashboardChip,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.white : AppColors.subtitle,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddCard() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFC8D3E7), width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: const Color(0xFFF8FBFF),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PreOcrScreen()),
        );
      },
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 30),
          SizedBox(height: 6),
          Text(
            'Thêm học sinh mới',
            style: TextStyle(
              fontSize: AppFontSizes.dashboardBody,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student, required this.onView});

  final _StudentCardData student;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(color: const Color(0xE6FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110B1D47),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x331337EC), width: 1.4),
                      image: DecorationImage(
                        image: NetworkImage(student.avatar),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: student.online
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF9CA3AF),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ngày sinh: ${student.birthday}',
                      style: const TextStyle(
                        fontSize: AppFontSizes.dashboardCaption,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtitle,
                      ),
                    ),
                    Text(
                      'Trường: ${student.school}',
                      style: const TextStyle(
                        fontSize: AppFontSizes.dashboardCaption,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE9EEF7)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: student.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: const Color(0xFFEAF1FF),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              _iconButton(icon: Icons.visibility_rounded, onTap: onView),
              const SizedBox(width: 6),
              _iconButton(icon: Icons.edit_rounded, onTap: () {}),
              const SizedBox(width: 6),
              _iconButton(
                icon: Icons.delete_rounded,
                onTap: () {},
                danger: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final bg = danger ? const Color(0xFFFEE2E2) : const Color(0xFFEFF4FF);
    final fg = danger ? const Color(0xFFDC2626) : AppColors.primary;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(width: 34, height: 34, child: Icon(icon, size: 19, color: fg)),
      ),
    );
  }
}

class _StudentCardData {
  const _StudentCardData({
    required this.name,
    required this.birthday,
    required this.school,
    required this.avatar,
    required this.online,
    required this.tags,
  });

  final String name;
  final String birthday;
  final String school;
  final String avatar;
  final bool online;
  final List<String> tags;
}
