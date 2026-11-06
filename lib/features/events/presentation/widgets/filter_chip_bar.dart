import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';

/// Bilah filter horizontal berstiker untuk katalog acara TemuKampus.
class FilterChipBar extends StatelessWidget {
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry padding;

  const FilterChipBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          final title = items[index];

          return GestureDetector(
            onTap: () {
              AppHaptics.light();
              onSelected(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.cobalt : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.cobalt : AppColors.ink200,
                  width: isSelected ? 1.6 : 1.2,
                ),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: AppColors.ink,
                          offset: Offset(1.5, 1.5),
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.ink700,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

