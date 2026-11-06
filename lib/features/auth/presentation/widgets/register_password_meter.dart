import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// Meter kekuatan kata sandi: 4 segmen + label.
///
/// Skor dihitung dari panjang, huruf besar/kecil, angka, dan simbol. Segmen
/// kosong saat kata sandi belum diisi (agar formulir tidak "berteriak" di awal).
class RegisterPasswordMeter extends StatelessWidget {
  final String password;

  const RegisterPasswordMeter({super.key, required this.password});

  static const List<String> _labels = ['Lemah', 'Cukup', 'Kuat', 'Sangat kuat'];

  int get _score {
    if (password.isEmpty) return 0;
    var score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score.clamp(1, 4);
  }

  Color get _color {
    switch (_score) {
      case 1:
        return AppColors.danger;
      case 2:
        return AppColors.signal;
      case 3:
        return AppColors.cobalt;
      default:
        return AppColors.mint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(4, (index) {
              final active = index < score;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: active ? _color : AppColors.ink100,
                    borderRadius: AppRadii.borderPill,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 62,
          child: Text(
            score == 0 ? '' : _labels[score - 1],
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.micro.copyWith(
              fontSize: 9.5,
              color: _color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
