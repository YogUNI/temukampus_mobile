import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/image_compressor.dart';

/// Area unggah bukti transfer: dropzone bergaris putus-putus, progres kompresi,
/// dan pratinjau thumbnail saat bukti sudah dipilih.
class RegistrationProofUploadCard extends StatelessWidget {
  final PickedImageData? selectedProof;
  final bool isCompressing;
  final VoidCallback onPick;
  final void Function(Uint8List bytes, String fileName) onPreview;

  const RegistrationProofUploadCard({
    super.key,
    required this.selectedProof,
    required this.isCompressing,
    required this.onPick,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unggah Bukti Transfer', style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        if (isCompressing)
          const _CompressingView()
        else if (selectedProof == null)
          _DropZone(onTap: onPick)
        else
          _PreviewView(
            proof: selectedProof!,
            onPreview: onPreview,
            onReplace: onPick,
          ),
      ],
    );
  }
}

class _DropZone extends StatelessWidget {
  final VoidCallback onTap;

  const _DropZone({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.ink300,
          radius: AppRadii.md,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xxxl,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.borderMd,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.cobaltLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  color: AppColors.cobalt,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Klik untuk Pilih Bukti Transfer',
                style: AppTypography.titleSmall.copyWith(fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Kamera langsung atau galeri foto (JPG/PNG, otomatis dikompresi < 2 MB)',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppColors.ink500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompressingView extends StatelessWidget {
  const _CompressingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.cobalt,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Mengompres bukti transfer…',
                style: AppTypography.titleSmall.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const LinearProgressIndicator(
            color: AppColors.cobalt,
            backgroundColor: AppColors.ink100,
            minHeight: 3,
          ),
        ],
      ),
    );
  }
}

class _PreviewView extends StatelessWidget {
  final PickedImageData proof;
  final void Function(Uint8List bytes, String fileName) onPreview;
  final VoidCallback onReplace;

  const _PreviewView({
    required this.proof,
    required this.onPreview,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.mint, width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1414A37F),
            offset: Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AppHaptics.light();
              onPreview(proof.bytes, proof.fileName);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: AppRadii.borderSm,
                  child: Image.memory(
                    proof.bytes,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: AppRadii.borderSm,
                  ),
                  child: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: GestureDetector(
              onTap: () {
                AppHaptics.light();
                onPreview(proof.bytes, proof.fileName);
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.mint, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Bukti Siap Diunggah',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.mintText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    proof.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                  ),
                  Text(
                    '${proof.formattedSize} • Ketuk untuk perbesar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.numericCode.copyWith(
                      fontSize: 10,
                      color: AppColors.cobalt,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: onReplace,
            child: Text(
              'Ganti',
              style: AppTypography.labelSmall.copyWith(color: AppColors.cobalt),
            ),
          ),
        ],
      ),
    );
  }
}

/// Border putus-putus untuk area unggah (dropzone).
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  static const double strokeWidth = 1.5;
  static const double dash = 6;
  static const double gap = 4;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            strokeWidth / 2,
            strokeWidth / 2,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}