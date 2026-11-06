import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../controllers/auth_notifier.dart';
import '../controllers/auth_state.dart';

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
  final TextEditingController _loginController = TextEditingController(text: '41524010001');
  final TextEditingController _passwordController = TextEditingController(text: 'Password123!');
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
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.ink, width: 1.5),
          ),
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.gavel_rounded, color: AppColors.danger, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Akun Ditangguhkan',
                style: AppTypography.titleSmall.copyWith(color: AppColors.dangerText),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reason ?? 'Akun Anda telah dinonaktifkan sementara oleh pihak kampus UMB.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 12),
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner ajakan ramah jika dialihkan dari pendaftaran acara
                  if (widget.loginReason == 'register' || widget.redirectUrl != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cobaltLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cobalt, width: 1.4),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.ink,
                            offset: Offset(2.5, 2.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.cobalt,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.login_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Perlu Masuk Akun',
                                  style: AppTypography.titleSmall.copyWith(
                                    color: AppColors.cobalt,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Silakan masuk terlebih dahulu untuk mendaftar acara ini.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.ink700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Logo TemuKampus Stiker Motif
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.cobalt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.ink, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.ink,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.confirmation_number_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('Selamat Datang di TemuKampus', style: AppTypography.hero.copyWith(fontSize: 24)),
                  const SizedBox(height: 6),
                  Text(
                    'Masuk dengan akun UMB atau akun umum untuk menjelajahi kegiatan kampus.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 28),

                  // Pesan Galat Global (jika ada)
                  if (authState.errorMessage != null &&
                      authState.status != AuthStatus.suspended &&
                      authState.validationErrors.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.dangerText),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Field NIM atau Email
                  Text('NIM atau Alamat Email', style: AppTypography.label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _loginController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: AppTypography.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'yoga@mercubuana.ac.id atau 41524010001',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.ink500),
                      errorText: authState.firstErrorFor('login'),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'NIM atau email wajib diisi.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Field Kata Sandi
                  Text('Kata Sandi', style: AppTypography.label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    style: AppTypography.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Minimal 8 karakter',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.ink500),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.ink500,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      errorText: authState.firstErrorFor('password'),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kata sandi wajib diisi.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Ingat Saya & Lupa Kata Sandi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: AppColors.cobalt,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) => setState(() => _rememberMe = val ?? true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Ingat saya', style: AppTypography.bodySmall),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tautan reset sandi dapat diajukan ke admin/BAAK kampus.'),
                            ),
                          );
                        },
                        child: Text(
                          'Lupa kata sandi?',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.cobalt),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tombol Masuk
                  StickerButton(
                    label: 'Masuk Sekarang',
                    variant: StickerButtonVariant.primary,
                    isLoading: authState.isAuthenticating,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 24),

                  // Divider "atau"
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Belum punya akun?',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.ink400),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tombol Buat Akun Baru (Outline)
                  StickerButton(
                    label: 'Daftar Akun Baru',
                    variant: StickerButtonVariant.outline,
                    onPressed: () => context.push(AppRoutes.register),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

