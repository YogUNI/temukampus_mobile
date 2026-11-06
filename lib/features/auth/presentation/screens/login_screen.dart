import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../controllers/auth_notifier.dart';
import '../controllers/auth_state.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_shell.dart';

/// Layar Masuk.
///
/// Header gradasi cobalt + kartu formulir putih. Semua pesan galat dari Laravel
/// (HTTP 422) ditempel ke field terkait lewat `firstErrorFor`, sedangkan galat
/// umum tampil sebagai banner di atas formulir.
class LoginScreen extends ConsumerStatefulWidget {
  final String? redirectUrl;
  final String? loginReason;

  const LoginScreen({
    super.key,
    this.redirectUrl,
    this.loginReason,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authNotifierProvider.notifier).login(
          login: _loginController.text,
          password: _passwordController.text,
        );

    final authState = ref.read(authNotifierProvider);

    if (!mounted) return;

    if (authState.status == AuthStatus.suspended) {
      _showSuspendedDialog(authState.errorMessage);
    } else if (authState.status == AuthStatus.needsEmailVerification) {
      context.go(AppRoutes.verifyEmail);
    } else if (success) {
      if (widget.redirectUrl != null && widget.redirectUrl!.isNotEmpty) {
        context.go(widget.redirectUrl!);
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  void _showSuspendedDialog(String? reason) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.borderLg,
            side: const BorderSide(color: AppColors.ink, width: 1.5),
          ),
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: AppRadii.borderXs,
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Akun Ditangguhkan',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.dangerText,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reason ??
                    'Akun Anda telah dinonaktifkan sementara oleh pihak kampus UMB.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Silakan hubungi BAAK atau pengelola TemuKampus melalui surel support@mercubuana.ac.id untuk pengaktifan kembali.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Saya Mengerti',
                style: AppTypography.label.copyWith(color: AppColors.cobalt),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showResetHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tautan reset sandi dapat diajukan ke admin/BAAK kampus.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final showLoginBanner =
        widget.loginReason == 'register' || widget.redirectUrl != null;
    final showGlobalError = authState.errorMessage != null &&
        authState.status != AuthStatus.suspended &&
        authState.validationErrors.isEmpty;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AuthShell(
        eyebrow: 'MASUK AKUN',
        headline: 'Selamat Datang di TemuKampus',
        subtitle:
            'Masuk untuk mendaftar acara, memantau verifikasi pembayaran, dan membuka tiket QR kamu.',
        onBack: context.canPop()
            ? () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              }
            : null,
        footer: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.xs,
          children: [
            Text(
              'Belum punya akun?',
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.register),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Daftar Akun Baru',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 12,
                  color: AppColors.cobalt,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showLoginBanner) ...[
                const AuthInfoBanner(
                  title: 'Perlu Masuk Akun',
                  message:
                      'Silakan masuk terlebih dahulu untuk mendaftar acara ini.',
                  icon: Icons.login_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (showGlobalError) ...[
                AuthErrorBanner(message: authState.errorMessage!),
                const SizedBox(height: AppSpacing.md),
              ],

              AuthField(
                label: 'NIM atau Alamat Email',
                hint: 'yoga@mercubuana.ac.id atau 41524010001',
                icon: Icons.person_outline_rounded,
                controller: _loginController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                serverError: authState.firstErrorFor('login'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'NIM atau email wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              AuthField(
                label: 'Kata Sandi',
                hint: 'Minimal 8 karakter',
                icon: Icons.lock_outline_rounded,
                controller: _passwordController,
                obscure: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleLogin(),
                serverError: authState.firstErrorFor('password'),
                suffix: IconButton(
                  splashRadius: 18,
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.ink400,
                    size: 19,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kata sandi wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xs),

              Row(
                children: [
                  Flexible(
                    child: AuthCheckbox(
                      value: _rememberMe,
                      onChanged: (val) => setState(() => _rememberMe = val),
                      label: Text(
                        'Ingat saya',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          color: AppColors.ink700,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _showResetHint,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Lupa kata sandi?',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 11.5,
                        color: AppColors.cobalt,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              StickerButton(
                label: 'Masuk Sekarang',
                variant: StickerButtonVariant.primary,
                isLoading: authState.isAuthenticating,
                borderRadius: AppRadii.sm,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: AppSpacing.lg),

              const AuthOrDivider(),
              const SizedBox(height: AppSpacing.md),

              StickerButton(
                label: 'Jelajahi sebagai Tamu',
                variant: StickerButtonVariant.outline,
                borderRadius: AppRadii.sm,
                icon: const Icon(
                  Icons.explore_outlined,
                  size: 18,
                  color: AppColors.ink,
                ),
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}