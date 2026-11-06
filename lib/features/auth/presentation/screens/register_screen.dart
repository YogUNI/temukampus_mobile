import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../core/utils/nim_parser.dart';
import '../controllers/auth_notifier.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // 0: Mahasiswa UMB, 1: Peserta Eksternal
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
  }

  void _onNimChanged() {
    final text = _nimController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _nimResult = NimParser.parse(text);
      });
    } else {
      setState(() {
        _nimResult = const NimResult(isValid: false);
      });
    }
  }

  @override
  void dispose() {
    _nimController.removeListener(_onNimChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nimController.dispose();
    _institutionController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda wajib menyetujui Syarat & Ketentuan untuk melanjutkan.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_selectedTab == 0 && !_nimResult.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_nimResult.errorMessage ?? 'NIM harus terdiri dari 11 digit angka.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    bool success;
    if (_selectedTab == 0) {
      // Registrasi UMB
      success = await ref.read(authNotifierProvider.notifier).registerUmb(
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            nim: _nimController.text,
            password: _passwordController.text,
            passwordConfirmation: _passwordConfirmController.text,
          );
    } else {
      // Registrasi Eksternal
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            onPressed: () => context.pop(),
          ),
          title: Text('Daftar Akun Baru', style: AppTypography.titleMedium),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab Selektor Jenis Akun (Segmented Stiker)
                  _buildAccountTypeSelector(),
                  const SizedBox(height: 24),

                  // Pesan Galat Global Backend
                  if (authState.errorMessage != null && authState.validationErrors.isEmpty) ...[
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

                  // Field Nama Lengkap
                  Text('Nama Lengkap', style: AppTypography.label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    style: AppTypography.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Yoga Gustira',
                      prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.ink500),
                      errorText: authState.firstErrorFor('name'),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama lengkap wajib diisi.' : null,
                  ),
                  const SizedBox(height: 16),

                  // Field Email
                  Text('Alamat Email', style: AppTypography.label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: AppTypography.bodyLarge,
                    decoration: InputDecoration(
                      hintText: _selectedTab == 0 ? 'yoga@mercubuana.ac.id' : 'dina@gmail.com',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.ink500),
                      errorText: authState.firstErrorFor('email'),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Email wajib diisi.';
                      if (!val.contains('@') || !val.contains('.')) return 'Format email tidak valid.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Field WhatsApp
                  Text('Nomor WhatsApp', style: AppTypography.label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    style: AppTypography.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 081234567890',
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.ink500),
                      errorText: authState.firstErrorFor('phone'),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Nomor WhatsApp wajib diisi.';
                      if (val.trim().length < 10) return 'Nomor WhatsApp minimal 10 digit.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // === FIELD KHUSUS MAHASISWA UMB: NIM DENGAN LIVE PREVIEW ===
                  if (_selectedTab == 0) ...[
                    Text('Nomor Induk Mahasiswa (NIM)', style: AppTypography.label),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nimController,
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.numericCode.copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: '11 Digit Angka (misal: 41524010001)',
                        counterText: '',
                        prefixIcon: const Icon(Icons.school_outlined, color: AppColors.ink500),
                        errorText: authState.firstErrorFor('nim'),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'NIM wajib diisi.';
                        if (val.trim().length != 11) return 'NIM harus terdiri dari 11 digit angka.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // LIVE NIM CARD PREVIEW (SCR-04 Feature)
                    _buildLiveNimCardPreview(),
                    const SizedBox(height: 16),
                  ] else ...[
                    // FIELD KHUSUS EKSTERNAL: INSTITUSI
                    Text('Nama Asal Kampus / Institusi', style: AppTypography.label),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _institutionController,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Universitas Indonesia / Umum',
                        prefixIcon: const Icon(Icons.apartment_outlined, color: AppColors.ink500),
                        errorText: authState.firstErrorFor('institution_name'),
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Nama asal institusi wajib diisi.' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Field Kata Sandi
                  Text('Kata Sandi', style: AppTypography.label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
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
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Kata sandi wajib diisi.';
                      if (val.length < 8) return 'Kata sandi minimal 8 karakter.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Field Konfirmasi Kata Sandi
                  Text('Konfirmasi Kata Sandi', style: AppTypography.label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordConfirmController,
                    obscureText: _obscurePasswordConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleRegister(),
                    style: AppTypography.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Ketik ulang kata sandi Anda',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.ink500),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePasswordConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.ink500,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePasswordConfirm = !_obscurePasswordConfirm),
                      ),
                      errorText: authState.firstErrorFor('password_confirmation'),
                    ),
                    validator: (val) {
                      if (val != _passwordController.text) return 'Konfirmasi kata sandi tidak cocok.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Persetujuan Syarat & Privasi
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          activeColor: AppColors.cobalt,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _agreedToTerms = val ?? true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Saya menyetujui Ketentuan Layanan dan Kebijakan Privasi resmi TemuKampus.',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tombol Daftar
                  StickerButton(
                    label: 'Daftar Sekarang',
                    variant: StickerButtonVariant.primary,
                    isLoading: authState.isAuthenticating,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 20),

                  // Link Kembali ke Login
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: RichText(
                        text: TextSpan(
                          text: 'Sudah punya akun? ',
                          style: AppTypography.bodyMedium,
                          children: [
                            TextSpan(
                              text: 'Masuk di sini',
                              style: AppTypography.label.copyWith(color: AppColors.cobalt),
                            ),
                          ],
                        ),
                      ),
                    ),
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

  Widget _buildAccountTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ink200, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'Mahasiswa UMB',
              isSelected: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: 'Peserta Umum',
              isSelected: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cobalt : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            fontSize: 13,
            color: isSelected ? Colors.white : AppColors.ink500,
          ),
        ),
      ),
    );
  }

  Widget _buildLiveNimCardPreview() {
    if (_nimController.text.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.ink200, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.ink400, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ketik 11 digit NIM untuk memverifikasi program studi dan angkatan.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.ink400),
              ),
            ),
          ],
        ),
      );
    }

    if (_nimResult.isValid) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cobaltLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.cobalt, size: 16),
                const SizedBox(width: 6),
                Text(
                  _nimResult.programName ?? 'Program Studi Valid',
                  style: AppTypography.titleSmall.copyWith(color: AppColors.cobalt, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Kode: ${_nimResult.programCode}',
                    style: AppTypography.badge.copyWith(color: AppColors.cobalt, fontSize: 10),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Angkatan: ${_nimResult.cohortYear}',
                    style: AppTypography.badge.copyWith(color: AppColors.cobalt, fontSize: 10),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _nimResult.facultyName ?? 'Fakultas',
                    style: AppTypography.badge.copyWith(color: AppColors.ink700, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel_rounded, color: AppColors.danger, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _nimResult.errorMessage ?? 'NIM harus 11 digit angka.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.dangerText),
            ),
          ),
        ],
      ),
    );
  }
}
