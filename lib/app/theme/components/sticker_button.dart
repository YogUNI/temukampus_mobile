import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';
import '../app_typography.dart';

enum StickerButtonVariant {
  primary,
  secondary,
  outline,
  danger,
}

/// Tombol berkarakter "Stiker Kampus" dengan hard-shadow offset dan tactile micro-interaction.
/// Saat ditekan, tombol bergeser ke arah bayangan (pressed-in effect) dan memicu haptic feedback.
class StickerButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final StickerButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool fullWidth;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const StickerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = StickerButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    this.borderRadius = 12.0,
  });

  @override
  State<StickerButton> createState() => _StickerButtonState();
}

class _StickerButtonState extends State<StickerButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color text;
    Color border = AppColors.ink;

    switch (widget.variant) {
      case StickerButtonVariant.primary:
        bg = isEnabled ? AppColors.cobalt : AppColors.ink200;
        text = isEnabled ? Colors.white : AppColors.ink400;
        break;
      case StickerButtonVariant.secondary:
        // Rule: Dilarang teks putih di atas Signal orange (kontras rendah).
        bg = isEnabled ? AppColors.signal : AppColors.ink200;
        text = isEnabled ? AppColors.ink : AppColors.ink400;
        break;
      case StickerButtonVariant.outline:
        bg = isEnabled ? AppColors.surface : AppColors.ink100;
        text = isEnabled ? AppColors.ink : AppColors.ink400;
        border = isEnabled ? AppColors.ink : AppColors.ink300;
        break;
      case StickerButtonVariant.danger:
        bg = isEnabled ? AppColors.danger : AppColors.ink200;
        text = isEnabled ? Colors.white : AppColors.ink400;
        break;
    }

    final shadowOffset = _isPressed ? const Offset(0, 0) : const Offset(3, 3);
    final buttonTranslation = _isPressed ? const Offset(3, 3) : Offset.zero;

    Widget buttonContent = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(text),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: 8),
        ],
        // Flexible + ellipsis: label panjang tidak boleh meluber keluar tombol
        // (mis. saat tombol berada di setengah lebar sticky bar).
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: text,
              fontSize: 15,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTapDown: isEnabled ? _handleTapDown : null,
      onTapUp: isEnabled ? _handleTapUp : null,
      onTapCancel: isEnabled ? _handleTapCancel : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        width: widget.fullWidth ? double.infinity : null,
        transform: Matrix4.translationValues(buttonTranslation.dx, buttonTranslation.dy, 0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: border, width: 1.5),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: shadowOffset,
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        padding: widget.padding,
        child: buttonContent,
      ),
    );
  }
}

