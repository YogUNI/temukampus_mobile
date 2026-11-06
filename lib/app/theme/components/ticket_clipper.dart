import 'package:flutter/material.dart';
import '../app_colors.dart';

/// Clipper untuk menghasilkan bentuk tiket fisik dengan takik setengah lingkaran (notch)
/// di sisi samping kiri dan kanan serta sudut rounded.
class TicketClipper extends CustomClipper<Path> {
  final double punchRadius;
  final double punchPositionPercent;
  final double borderRadius;

  const TicketClipper({
    this.punchRadius = 12.0,
    this.punchPositionPercent = 0.65,
    this.borderRadius = 16.0,
  });

  @override
  Path getClip(Size size) {
    return getTicketPath(
      size,
      punchRadius: punchRadius,
      punchPositionPercent: punchPositionPercent,
      borderRadius: borderRadius,
    );
  }

  static Path getTicketPath(
    Size size, {
    double punchRadius = 12.0,
    double punchPositionPercent = 0.65,
    double borderRadius = 16.0,
  }) {
    final path = Path();
    final punchY = size.height * punchPositionPercent;
    final r = borderRadius;

    // Sudut kiri atas
    path.moveTo(r, 0);
    // Sisi atas
    path.lineTo(size.width - r, 0);
    // Sudut kanan atas
    path.arcToPoint(Offset(size.width, r), radius: Radius.circular(r));

    // Sisi kanan atas menuju takik
    path.lineTo(size.width, punchY - punchRadius);
    // Takik kanan (setengah lingkaran ke dalam)
    path.arcToPoint(
      Offset(size.width, punchY + punchRadius),
      radius: Radius.circular(punchRadius),
      clockwise: false,
    );
    // Sisi kanan bawah
    path.lineTo(size.width, size.height - r);
    // Sudut kanan bawah
    path.arcToPoint(Offset(size.width - r, size.height), radius: Radius.circular(r));

    // Sisi bawah
    path.lineTo(r, size.height);
    // Sudut kiri bawah
    path.arcToPoint(Offset(0, size.height - r), radius: Radius.circular(r));

    // Sisi kiri bawah menuju takik
    path.lineTo(0, punchY + punchRadius);
    // Takik kiri (setengah lingkaran ke dalam)
    path.arcToPoint(
      Offset(0, punchY - punchRadius),
      radius: Radius.circular(punchRadius),
      clockwise: false,
    );
    // Sisi kiri atas
    path.lineTo(0, r);
    // Sudut kiri atas
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant TicketClipper oldClipper) {
    return oldClipper.punchRadius != punchRadius ||
        oldClipper.punchPositionPercent != punchPositionPercent ||
        oldClipper.borderRadius != borderRadius;
  }
}

/// Garis putus-putus untuk efek robekan tiket (tear line).
class DottedTearLine extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const DottedTearLine({
    super.key,
    this.height = 1.5,
    this.color = AppColors.ink200,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Kontainer Tiket lengkap dengan Hard-Shadow stiker dan border tegas.
class TicketContainer extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double punchRadius;
  final double punchPositionPercent;
  final double borderRadius;
  final bool hasShadow;
  final Offset shadowOffset;

  const TicketContainer({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.ink200,
    this.borderWidth = 1.2,
    this.punchRadius = 12.0,
    this.punchPositionPercent = 0.65,
    this.borderRadius = 16.0,
    this.hasShadow = true,
    this.shadowOffset = const Offset(3, 3),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TicketShadowAndBorderPainter(
        punchRadius: punchRadius,
        punchPositionPercent: punchPositionPercent,
        borderRadius: borderRadius,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        borderWidth: borderWidth,
        hasShadow: hasShadow,
        shadowOffset: shadowOffset,
      ),
      child: ClipPath(
        clipper: TicketClipper(
          punchRadius: punchRadius,
          punchPositionPercent: punchPositionPercent,
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }
}

class _TicketShadowAndBorderPainter extends CustomPainter {
  final double punchRadius;
  final double punchPositionPercent;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final bool hasShadow;
  final Offset shadowOffset;

  _TicketShadowAndBorderPainter({
    required this.punchRadius,
    required this.punchPositionPercent,
    required this.borderRadius,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.hasShadow,
    required this.shadowOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = TicketClipper.getTicketPath(
      size,
      punchRadius: punchRadius,
      punchPositionPercent: punchPositionPercent,
      borderRadius: borderRadius,
    );

    // 1. Gambar Hard-Shadow (jika diaktifkan)
    if (hasShadow) {
      final shadowPath = path.shift(shadowOffset);
      final shadowPaint = Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.fill;
      canvas.drawPath(shadowPath, shadowPaint);
    }

    // 2. Gambar Latar Belakang Kartu
    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. Gambar Border Kartu
    if (borderWidth > 0) {
      final strokePaint = Paint()
        ..color = borderColor
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TicketShadowAndBorderPainter oldDelegate) {
    return oldDelegate.punchRadius != punchRadius ||
        oldDelegate.punchPositionPercent != punchPositionPercent ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.hasShadow != hasShadow ||
        oldDelegate.shadowOffset != shadowOffset;
  }
}

