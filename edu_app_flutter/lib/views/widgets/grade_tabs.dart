import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:flutter/material.dart';

class GradeTabs extends StatelessWidget {
  const GradeTabs({
    super.key,
    required this.selectedGrade,
    required this.onChanged,
    this.grades = const [10, 11, 12],
  });

  final int selectedGrade;
  final ValueChanged<int> onChanged;
  final List<int> grades;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: grades.map((grade) {
          final bool isSelected = selectedGrade == grade;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: isSelected ? AppColors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onChanged(grade),
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return AppColors.primary.withValues(alpha: 0.12);
                    }
                    return null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 90),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0x332348EF)
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      'Lớp $grade',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppFontSizes.dashboardBody,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppColors.primary : AppColors.subtitle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
