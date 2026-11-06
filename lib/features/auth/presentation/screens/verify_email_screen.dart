import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../controllers/auth_notifier.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _countdownSeconds = 60;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _countdownSeconds = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() => _countdownSeconds--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _handleVerify() async {
    final code = _otpCode;
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan 6 digit kode verifikasi lengkap.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);
    final success = await ref.read(authNotifierProvider.notifier).verifyEmail(code);
    setState(() => _isVerifying = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email berhasil diverifikasi! Selamat datang di TemuKampus.'),
          backgroundColor: AppColors.mint,
        ),
      );
      context.go(AppRoutes.home);
    } else {
      final authState = ref.read(authNotifierProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.errorMessage ?? 'Kode verifikasi tidak cocok.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;

    final msg = await ref.read(authNotifierProvider.notifier).resendEmailCode();
    _startCountdown();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg ?? 'Kode verifikasi baru telah dikirimkan ke email Anda.'),
      ),
    );
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      // Jika paste lebih dari 1 digit
      if (value.length > 1) {
        final digits = value.replaceAll(RegExp(r'\D'), '').split('');
        for (int i = 0; i < digits.length && (index + i) < 6; i++) {
          _controllers[index + i].text = digits[i];
        }
        final nextIndex = (index + digits.length) < 6 ? (index + digits.length) : 5;
        _focusNodes[nextIndex].requestFocus();
      } else {
        if (index < 5) {
          _focusNodes[index + 1].requestFocus();
        } else {
          _focusNodes[index].unfocus();
          _handleVerify();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final email = authState.user?.email ?? 'email terdaftar Anda';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            onPressed: () => context.go(AppRoutes.login),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Stiker Motif Amplop
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.cobaltLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.ink, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.ink,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: AppColors.cobalt,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Verifikasi Email Anda',
                  style: AppTypography.hero.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Kami telah mengirimkan 6 digit kode verifikasi ke:',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: AppTypography.titleSmall.copyWith(color: AppColors.cobalt),
                ),
                const SizedBox(height: 36),

                // 6 Kotak Input Angka PIN OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.backspace &&
                              _controllers[index].text.isEmpty &&
                              index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        },
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: AppTypography.numericCode.copyWith(fontSize: 22),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: AppColors.surface,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.ink200, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.cobalt, width: 2),
                            ),
                          ),
                          onChanged: (val) => _onDigitChanged(index, val),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Tombol Verifikasi
                StickerButton(
                  label: 'Verifikasi Kode',
                  variant: StickerButtonVariant.primary,
                  isLoading: _isVerifying,
                  onPressed: _handleVerify,
                ),
                const SizedBox(height: 28),

                // Kirim Ulang Kode & Countdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tidak menerima kode? ',
                      style: AppTypography.bodySmall,
                    ),
                    _canResend
                        ? GestureDetector(
                            onTap: _handleResend,
                            child: Text(
                              'Kirim Ulang',
                              style: AppTypography.label.copyWith(color: AppColors.cobalt),
                            ),
                          )
                        : Text(
                            'Kirim ulang dalam ${_countdownSeconds}d',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.ink400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
