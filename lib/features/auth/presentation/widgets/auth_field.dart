import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// Field formulir autentikasi: label tegas di atas, kotak isian berlatar paper,
/// ikon di kiri, dan galat server (HTTP 422) menempel langsung di bawah input.
class AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffix;
  final String? serverError;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final String? counterText;
  final TextStyle? style;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final String? helperText;
  final bool enabled;
  final String? semanticLabel;

  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.suffix,
    this.serverError,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.maxLength,
    this.counterText,
    this.style,
    this.onFieldSubmitted,
    this.onChanged,
    this.inputFormatters,
    this.helperText,
    this.enabled = true,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontSize: 12,
            color: AppColors.ink700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: semanticLabel,
          textField: true,
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            enabled: enabled,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            style: style ?? AppTypography.bodyMedium.copyWith(fontSize: 14.5),
            onFieldSubmitted: onFieldSubmitted,
            onChanged: onChanged,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              counterText: counterText,
              filled: true,
              fillColor: AppColors.paper,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              prefixIcon: Icon(icon, size: 19, color: AppColors.ink400),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              suffixIcon: suffix,
              suffixIconConstraints: const BoxConstraints(minWidth: 40),
              errorText: serverError,
              errorMaxLines: 2,
              helperText: helperText,
              helperMaxLines: 2,
              helperStyle: AppTypography.micro.copyWith(
                fontSize: 10,
                color: AppColors.ink400,
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadii.borderSm,
                borderSide: const BorderSide(color: AppColors.ink200, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.borderSm,
                borderSide: const BorderSide(color: AppColors.ink200, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.borderSm,
                borderSide: const BorderSide(color: AppColors.cobalt, width: 1.8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppRadii.borderSm,
                borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: AppRadii.borderSm,
                borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Kotak galat global (mis. "Email atau kata sandi salah").
class AuthErrorBanner extends StatelessWidget {
  final String message;

  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: AppRadii.borderSm,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 17,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.dangerText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kotak info ramah (mis. "Perlu masuk akun untuk mendaftar acara ini").
class AuthInfoBanner extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const AuthInfoBanner({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cobaltLight,
        borderRadius: AppRadii.borderSm,
        border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.cobalt, size: 17),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontSize: 12.5,
                    color: AppColors.cobalt,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTypography.micro.copyWith(
                    fontSize: 10.5,
                    color: AppColors.ink700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pembatas bertulisan "atau".
class AuthOrDivider extends StatelessWidget {
  final String label;

  const AuthOrDivider({super.key, this.label = 'atau'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.ink100)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: AppTypography.micro.copyWith(
              fontSize: 10,
              color: AppColors.ink400,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.ink100)),
      ],
    );
  }
}

/// Checkbox persetujuan dengan target sentuh 44pt.
class AuthCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget label;

  const AuthCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadii.borderXs,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                activeColor: AppColors.cobalt,
                side: const BorderSide(color: AppColors.ink300, width: 1.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (val) => onChanged(val ?? false),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(child: label),
          ],
        ),
      ),
    );
  }
}
