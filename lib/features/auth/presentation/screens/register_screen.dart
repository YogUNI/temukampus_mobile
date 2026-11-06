import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../core/utils/nim_parser.dart';
import '../controllers/auth_notifier.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_shell.dart';
import '../widgets/register_account_type_switch.dart';
import '../widgets/register_nim_preview.dart';
import '../widgets/register_password_meter.dart';

/// Layar Daftar Akun (Mahasiswa UMB & Peserta Umum).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  /// 0: Mahasiswa UMB, 1: Peserta Eksternal
  int _selectedTab = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

  NimResult _nimResult = const NimResult(isValid: false);
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _agreedToTerms = true;

  @override
  void initState() {
    super.initState();
    _nimController.addListener(_onNimChanged);
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onNimChanged() {
    final text = _nimController.text.trim();
    setState(() {
      _nimResult = text.isEmpty
          ? const NimResult(isValid: false)
          : NimParser.parse(text);
    });
  }

  void _onPasswordChanged() => setState(() {});

  @override
  void dispose() {
    _nimController.removeListener(_onNimChanged);
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nimController.dispose();
    _institutionController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      _snack('Anda wajib menyetujui Syarat & Ketentuan untuk melanjutkan.');
      return;
    }

    if (_selectedTab == 0 && !_nimResult.isValid) {
      _snack(_nimResult.errorMessage ?? 'NIM harus terdiri dari 11 digit angka.');
      return;
    }

    bool success;
    if (_selectedTab == 0) {
      success = await ref.read(authNotifierProvider.notifier).registerUmb(
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            nim: _nimController.text,
            password: _passwordController.text,
            passwordConfirmation: _passwordConfirmController.text,
          );
    } else {
      success = await ref.read(authNotifierProvider.notifier).registerExternal(
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            institutionName: _institutionController.text,
            password: _passwordController.text,
            passwordConfirmation: _passwordConfirmController.text,
          );
    }

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.verifyEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final showGlobalError = authState.errorMessage != null &&
        authState.validationErrors.isEmpty;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AuthShell(
        eyebrow: 'DAFTAR AKUN',
        headline: 'Buat Akun TemuKampus',
        subtitle:
            'Satu akun untuk semua acara kampus UMB — daftar, unggah bukti transfer, dan simpan tiket QR.',
        onBack: () => context.pop(),
        footer: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.xs,
          children: [
            Text(
              'Sudah punya akun?',
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
            ),
            TextButton(
              onPressed: () => context.pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Masuk di sini',
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
              RegisterAccountTypeSwitch(
                selectedIndex: _selectedTab,
                onChanged: (index) => setState(() => _selectedTab = index),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (showGlobalError) ...[
                AuthErrorBanner(message: authState.errorMessage!),
                const SizedBox(height: AppSpacing.md),
              ],

              AuthField(
                label: 'Nama Lengkap',
                hint: 'Contoh: Yoga Gustira',
                icon: Icons.badge_outlined,
                controller: _nameController,
                textInputAction: TextInputAction.next,
                serverError: authState.firstErrorFor('name'),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Nama lengkap wajib diisi.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              AuthField(
                label: 'Alamat Email',
                hint: _selectedTab == 0
                    ? 'yoga@mercubuana.ac.id'
                    : 'dina@gmail.com',
                icon: Icons.alternate_email_rounded,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                serverError: authState.firstErrorFor('email'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Email wajib diisi.';
                  }
                  if (!val.contains('@') || !val.contains('.')) {
                    return 'Format email tidak valid.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              AuthField(
                label: 'Nomor WhatsApp',
                hint: 'Contoh: 081234567890',
                icon: Icons.phone_outlined,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                serverError: authState.firstErrorFor('phone'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nomor WhatsApp wajib diisi.';
                  }
                  if (val.trim().length < 10) {
                    return 'Nomor WhatsApp minimal 10 digit.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              if (_selectedTab == 0) ...[
                AuthField(
                  label: 'Nomor Induk Mahasiswa (NIM)',
                  hint: '11 digit, misal 41524010001',
                  icon: Icons.school_outlined,
                  controller: _nimController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  maxLength: 11,
                  counterText: '',
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTypography.numericCode.copyWith(fontSize: 15.5),
                  serverError: authState.firstErrorFor('nim'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'NIM wajib diisi.';
                    }
                    if (val.trim().length != 11) {
                      return 'NIM harus terdiri dari 11 digit angka.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                RegisterNimPreview(
                  rawNim: _nimController.text,
                  result: _nimResult,
                ),
                const SizedBox(height: AppSpacing.md),
              ] else ...[
                AuthField(
                  label: 'Nama Asal Kampus / Institusi',
                  hint: 'Contoh: Universitas Indonesia / Umum',
                  icon: Icons.apartment_outlined,
                  controller: _institutionController,
                  textInputAction: TextInputAction.next,
                  serverError: authState.firstErrorFor('institution_name'),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Nama asal institusi wajib diisi.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              AuthField(
                label: 'Kata Sandi',
                hint: 'Minimal 8 karakter',
                icon: Icons.lock_outline_rounded,
                controller: _passwordController,
                obscure: _obscurePassword,
                textInputAction: TextInputAction.next,
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
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Kata sandi wajib diisi.';
                  }
                  if (val.length < 8) {
                    return 'Kata sandi minimal 8 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              RegisterPasswordMeter(password: _passwordController.text),
              const SizedBox(height: AppSpacing.md),

              AuthField(
                label: 'Konfirmasi Kata Sandi',
                hint: 'Ketik ulang kata sandi Anda',
                icon: Icons.lock_reset_rounded,
                controller: _passwordConfirmController,
                obscure: _obscurePasswordConfirm,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleRegister(),
                suffix: IconButton(
                  splashRadius: 18,
                  icon: Icon(
                    _obscurePasswordConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.ink400,
                    size: 19,
                  ),
                  onPressed: () => setState(
                    () => _obscurePasswordConfirm = !_obscurePasswordConfirm,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Konfirmasi kata sandi wajib diisi.';
                  }
                  if (val != _passwordController.text) {
                    return 'Konfirmasi kata sandi tidak cocok.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              AuthCheckbox(
                value: _agreedToTerms,
                onChanged: (val) => setState(() => _agreedToTerms = val),
                label: Text.rich(
                  TextSpan(
                    text: 'Saya menyetujui ',
                    style: AppTypography.micro.copyWith(
                      fontSize: 11,
                      color: AppColors.ink700,
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(
                        text: 'Ketentuan Layanan',
                        style: AppTypography.micro.copyWith(
                          fontSize: 11,
                          color: AppColors.cobalt,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(text: ' dan '),
                      TextSpan(
                        text: 'Kebijakan Privasi',
                        style: AppTypography.micro.copyWith(
                          fontSize: 11,
                          color: AppColors.cobalt,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(text: ' TemuKampus.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              StickerButton(
                label: 'Daftar Sekarang',
                variant: StickerButtonVariant.primary,
                isLoading: authState.isAuthenticating,
                borderRadius: AppRadii.sm,
                onPressed: _handleRegister,
              ),
            ],
          ),
        ),
      ),
    );
  }
}