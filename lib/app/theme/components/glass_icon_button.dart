import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_shadows.dart';

/// Tombol ikon bulat dengan efek kaca (glassmorphism) di atas poster.
///
/// Dipakai sebagai tombol kembali & bagikan di header Detail Acara: tetap
/// terbaca di atas foto apa pun tanpa kotak putih pekat yang menutupi poster.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final double size;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppGlass.blur,
            sigmaY: AppGlass.blur,
          ),
          child: Material(
            color: Colors.white.withValues(alpha: AppGlass.surfaceOpacity),
            child: InkWell(
              onTap: onPressed,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: AppGlass.borderOpacity),
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
