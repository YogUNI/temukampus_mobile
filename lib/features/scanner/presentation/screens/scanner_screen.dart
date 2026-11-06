import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../data/models/check_in_result_model.dart';
import '../controllers/scanner_controller.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  final int eventId;

  const ScannerScreen({super.key, required this.eventId});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _cameraController;
  late final AnimationController _laserAnimController;
  late final Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _showManualInputDialog() {
    AppHaptics.light();
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.ink, width: 1.5),
          ),
          title: Text('Presensi Manual', style: AppTypography.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan 11 digit NIM atau kode tiket (misal: 41524010001 atau TK-7F3KQ9):',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'NIM atau Kode Tiket',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.cobalt),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cobalt,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final query = textController.text.trim();
                if (query.isNotEmpty) {
                  Navigator.pop(ctx);
                  ref
                      .read(scannerControllerProvider(widget.eventId).notifier)
                      .submitManualQuery(query);
                }
              },
              child: const Text('Verifikasi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerControllerProvider(widget.eventId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Kamera Viewport Live
          MobileScanner(
            controller: _cameraController,
            onDetect: (BarcodeCapture capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  ref
                      .read(scannerControllerProvider(widget.eventId).notifier)
                      .onCodeDetected(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // 2. Overlay Bingkai Pemindai dengan Animasi Laser
          SafeArea(
            child: Column(
              children: [
                // Top Bar Scanner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                        onPressed: () => context.pop(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, color: AppColors.signal, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Hadir: ${scannerState.attendedCount} / ${scannerState.totalQuota}',
                              style: AppTypography.numericCode.copyWith(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: scannerState.torchEnabled ? AppColors.signal : Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                scannerState.torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                color: scannerState.torchEnabled ? AppColors.ink : Colors.white,
                                size: 20,
                              ),
                            ),
                            onPressed: () {
                              AppHaptics.selection();
                              _cameraController.toggleTorch();
                              ref.read(scannerControllerProvider(widget.eventId).notifier).toggleTorch();
                            },
                          ),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 20),
                            ),
                            onPressed: () {
                              AppHaptics.selection();
                              _cameraController.switchCamera();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Frame Kotak Pemindai Tiket
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cobalt, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cobalt.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          // Animasi Laser Bergerak Naik-Turun
                          AnimatedBuilder(
                            animation: _laserAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: _laserAnimation.value * 250,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppColors.signal,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.signal.withValues(alpha: 0.8),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'Arahkan kamera ke QR Code Tiket Peserta',
                  style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                ),

                const Spacer(),

                // Tombol Input Manual Fallback
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: StickerButton(
                      label: 'Input Manual NIM / Kode Tiket',
                      variant: StickerButtonVariant.secondary,
                      icon: const Icon(Icons.keyboard_rounded, color: AppColors.ink, size: 18),
                      onPressed: _showManualInputDialog,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Sheet Overlay Hasil Scan Real-Time
          if (scannerState.lastResult != null)
            _buildResultOverlay(scannerState.lastResult!),
        ],
      ),
    );
  }

  Widget _buildResultOverlay(CheckInResultModel result) {
    Color headerBg;
    Color iconColor;
    IconData icon;
    String title;

    if (result.isSuccess) {
      headerBg = AppColors.mintLight;
      iconColor = AppColors.mint;
      icon = Icons.check_circle_rounded;
      title = 'Check-in Berhasil!';
    } else if (result.isAlreadyCheckedIn) {
      headerBg = AppColors.amberLight;
      iconColor = AppColors.amber;
      icon = Icons.warning_rounded;
      title = 'Tiket Sudah Pernah Digunakan!';
    } else {
      headerBg = AppColors.dangerLight;
      iconColor = AppColors.danger;
      icon = Icons.cancel_rounded;
      title = 'Tiket Tidak Valid!';
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: headerBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 36),
              ),
              const SizedBox(height: 12),
              Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 18)),
              const SizedBox(height: 6),
              Text(
                result.message,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
              ),

              // Rincian Peserta jika Sukses atau Sudah Check-in
              if (result.participant != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.ink200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.cobaltLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            result.participant!.name.isNotEmpty ? result.participant!.name[0] : 'U',
                            style: AppTypography.titleSmall.copyWith(color: AppColors.cobalt),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(result.participant!.name, style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              'NIM: ${result.participant!.nim ?? "-"} • ${result.participant!.studyProgram ?? "UMB"}',
                              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.ink500),
                            ),
                            if (result.checkedInAt != null)
                              Text(
                                'Waktu Hadir: ${AppFormatters.eventTime(result.checkedInAt!)} WIB',
                                style: AppTypography.numericCode.copyWith(fontSize: 10, color: AppColors.mintText),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: StickerButton(
                  label: 'Lanjut Scan Berikutnya',
                  variant: StickerButtonVariant.primary,
                  onPressed: () {
                    AppHaptics.light();
                    ref
                        .read(scannerControllerProvider(widget.eventId).notifier)
                        .resumeScanning();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

