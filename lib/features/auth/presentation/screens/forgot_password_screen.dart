import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../core/utils/haptics.dart';
import '../controllers/auth_notifier.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_shell.dart';

/// Lupa kata sandi — dua langkah dalam satu layar.
///
/// Langkah 1 meminta kode ke email (`POST /auth/forgot-password`), langkah 2
/// mengirim kode + kata sandi baru (`POST /auth/reset-password`). Backend
/// memakai token broker yang sama dengan tautan di web, jadi masa berlaku dan
/// aturan sekali pakai tidak berbeda antara web dan aplikasi.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  String? _serverError;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _serverError = null;
    });

    final error = await ref
        .read(authNotifierProvider.notifier)
        .requestPasswordReset(_emailController.text.trim());

    if (!mounted) return;

    setState(() {
      _busy = false;
      _codeSent = error == null;
      _info = error == null
          ? 'Kode 6 angka sudah dikirim ke ${_emailController.text.trim()}. Cek kotak masuk atau folder spam.'
          : null;
      _serverError = error;
    });

    if (error == null) {
      AppHaptics.success();
    } else {
      AppHaptics.error();
    }
  }

  Future<void> _submitNewPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passwordController.text != _confirmController.text) {
      setState(() => _serverError = 'Konfirmasi kata sandi tidak cocok.');
      AppHaptics.error();
      return;
    }

    setState(() {
      _busy = true;
      _serverError = null;
    });

    final error = await ref.read(authNotifierProvider.notifier).resetPassword(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
          newPassword: _passwordController.text,
          confirmation: _confirmController.text,
        );

    if (!mounted) return;

    setState(() => _busy = false);

    if (error == null) {
      AppHaptics.success();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi berhasil diganti. Silakan masuk.'),
          backgroundColor: AppColors.mint,
        ),
      );
      context.go(AppRoutes.login);
    } else {
      AppHaptics.error();
      setState(() => _serverError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      eyebrow: 'LUPA KATA SANDI',
      headline: _codeSent ? 'Masukkan Kode Verifikasi' : 'Atur Ulang Kata Sandi',
      subtitle: _codeSent
          ? 'Buka email dari TemuKampus, lalu masukkan kode 6 angka beserta kata sandi baru kamu.'
          : 'Masukkan email akunmu. Kami kirim kode 6 angka dan tautan untuk mengatur ulang kata sandi.',
      onBack: () => context.canPop() ? context.pop() : context.go(AppRoutes.login),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_info != null) ...[
              _Banner(message: _info!, isError: false),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (_serverError != null) ...[
              _Banner(message: _serverError!, isError: true),
              const SizedBox(height: AppSpacing.sm),
            ],
            AuthField(
              label: 'Alamat Email',
              hint: 'nama@mercubuana.ac.id',
              icon: Icons.alternate_email_rounded,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !_codeSent,
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return 'Email wajib diisi.';
                if (!text.contains('@') || !text.contains('.')) {
                  return 'Format email belum benar.';
                }
                return null;
              },
            ),
            if (_codeSent) ...[
              const SizedBox(height: AppSpacing.md),
              AuthField(
                label: 'Kode 6 Angka',
                hint: '123456',
                icon: Icons.pin_outlined,
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.length != 6) return 'Kode terdiri dari 6 angka.';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AuthField(
                label: 'Kata Sandi Baru',
                hint: 'Minimal 8 karakter, ada angka',
                icon: Icons.lock_reset_rounded,
                controller: _passwordController,
                obscure: true,
                validator: (value) {
                  final text = value ?? '';
                  if (text.length < 8) return 'Minimal 8 karakter.';
                  if (!RegExp(r'[0-9]').hasMatch(text)) {
                    return 'Sertakan minimal satu angka.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AuthField(
                label: 'Ulangi Kata Sandi Baru',
                hint: 'Ketik ulang kata sandi baru',
                icon: Icons.verified_user_rounded,
                controller: _confirmController,
                obscure: true,
                validator: (value) {
                  if ((value ?? '').isEmpty) return 'Konfirmasi wajib diisi.';
                  return null;
                },
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            StickerButton(
              label: _busy
                  ? 'Memproses…'
                  : (_codeSent ? 'Simpan Kata Sandi Baru' : 'Kirim Kode'),
              variant: StickerButtonVariant.primary,
              onPressed: _busy ? null : (_codeSent ? _submitNewPassword : _requestCode),
            ),
            if (_codeSent) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _busy ? null : _requestCode,
                child: Text(
                  'Kirim ulang kode',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.cobalt),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Banner informasi / galat di dalam kartu formulir.
class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isError ? AppColors.dangerLight : AppColors.mintLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? AppColors.danger : AppColors.mint,
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.mark_email_read_outlined,
            size: 18,
            color: isError ? AppColors.dangerText : AppColors.mintText,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: isError ? AppColors.dangerText : AppColors.mintText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
