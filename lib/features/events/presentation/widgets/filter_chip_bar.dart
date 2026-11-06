import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';

/// Bilah chip filter horizontal (kapsul).
///
/// Mendukung beberapa chip aktif sekaligus: filter cepat Beranda bersifat
/// kombinatif (mis. "Gratis" + "Ber-SKP"), jadi status aktif diterima sebagai
/// himpunan indeks — bukan satu indeks.
class FilterChipBar extends StatelessWidget {
  final List<String> items;
  final Set<int> activeIndexes;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry padding;

  const FilterChipBar({
    super.key,
    required this.items,
    required this.activeIndexes,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final isSelected = activeIndexes.contains(index);
          final title = items[index];

          return Semantics(
            button: true,
            selected: isSelected,
            label: title,
            child: GestureDetector(
              onTap: () {
                AppHaptics.light();
                onSelected(index);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: AppDurations.base,
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.cobalt : AppColors.surface,
                  borderRadius: AppRadii.borderPill,
                  border: Border.all(
                    color: isSelected ? AppColors.cobalt : AppColors.ink200,
                  ),
                ),
                child: Text(
                  title,
                  maxLines: 1,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.ink700,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
