import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_typography.dart';

/// Pemilih jenis akun dengan indikator pil yang meluncur (bukan dua tombol
/// terpisah) supaya peralihan terasa halus dan jelas.
class RegisterAccountTypeSwitch extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const List<String> _labels = ['Mahasiswa UMB', 'Peserta Umum'];
  static const List<IconData> _icons = [
    Icons.school_rounded,
    Icons.public_rounded,
  ];

  const RegisterAccountTypeSwitch({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppRadii.borderSm,
        border: Border.all(color: AppColors.ink200, width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = (constraints.maxWidth - 8) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: selectedIndex == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: segmentWidth,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.cobalt,
                    borderRadius: AppRadii.borderXs,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cobalt.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(_labels.length, (index) {
                  final isSelected = index == selectedIndex;
                  return Expanded(
                    child: Semantics(
                      button: true,
                      selected: isSelected,
                      label: _labels[index],
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (index == selectedIndex) return;
                          HapticFeedback.selectionClick();
                          onChanged(index);
                        },
                        child: SizedBox(
                          height: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _icons[index],
                                size: 15,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.ink500,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _labels[index],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.ink500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
