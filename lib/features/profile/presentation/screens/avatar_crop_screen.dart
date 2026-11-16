import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';

/// Layar atur foto profil: geser & cubit (zoom) foto di dalam bingkai bulat,
/// lalu ambil hasil potongannya sebagai PNG persegi.
///
/// Hasil dikembalikan lewat `Navigator.pop(context, bytes)`; `null` bila batal.
class AvatarCropScreen extends StatefulWidget {
  final Uint8List bytes;

  const AvatarCropScreen({super.key, required this.bytes});

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final GlobalKey _captureKey = GlobalKey();
  final TransformationController _controller = TransformationController();

  Size? _imageSize;
  Size _viewport = Size.zero;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    final codec = await ui.instantiateImageCodec(widget.bytes);
    final frame = await codec.getNextFrame();

    if (!mounted) return;

    setState(() {
      _imageSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Skala awal agar foto menutup penuh bingkai (cover) dan terpusat.
  void _prepareTransform(Size viewport) {
    if (_ready || _imageSize == null || viewport == _viewport) return;

    _viewport = viewport;
    final scale = (viewport.width / _imageSize!.width)
        .clamp(0.0, double.infinity);
    final scaleH = (viewport.height / _imageSize!.height)
        .clamp(0.0, double.infinity);
    final cover = scale > scaleH ? scale : scaleH;

    final displayW = _imageSize!.width * cover;
    final displayH = _imageSize!.height * cover;

    _controller.value = Matrix4.identity()
      ..translate(-(displayW - viewport.width) / 2, -(displayH - viewport.height) / 2);

    _ready = true;
  }

  Future<void> _confirm() async {
    AppHaptics.success();

    final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) {
      Navigator.of(context).pop();
      return;
    }

    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    if (!mounted) return;

    Navigator.of(context).pop(data?.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final side = (media.size.width - AppSpacing.xxxl).clamp(220.0, 380.0);
    final viewport = Size(side, side);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: 'Batal',
                  ),
                  const Expanded(
                    child: Text(
                      'Atur Foto Profil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Spacer(),

            // Bingkai crop
            Center(
              child: SizedBox(
                width: viewport.width,
                height: viewport.height,
                child: _imageSize == null
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final size = Size(constraints.maxWidth, constraints.maxHeight);
                          // Hitung transform setelah layout tersedia.
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _prepareTransform(size));
                          });

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRect(
                                child: RepaintBoundary(
                                  key: _captureKey,
                                  child: Container(
                                    color: AppColors.ink,
                                    child: InteractiveViewer(
                                      transformationController: _controller,
                                      minScale: 0.6,
                                      maxScale: 5,
                                      panEnabled: true,
                                      scaleEnabled: true,
                                      boundaryMargin: const EdgeInsets.all(200),
                                      clipBehavior: Clip.hardEdge,
                                      child: SizedBox(
                                        width: _imageSize!.width *
                                            _coverScale(size),
                                        height: _imageSize!.height *
                                            _coverScale(size),
                                        child: Image.memory(
                                          widget.bytes,
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Panduan lingkaran + area gelap di luar.
                              IgnorePointer(
                                child: CustomPaint(
                                  painter: _CropGuidePainter(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            Text(
              'Cubit untuk zoom · geser untuk mengatur posisi',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),

            // Aksi
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _imageSize == null ? null : _confirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.cobalt,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
                      ),
                      child: const Text(
                        'Gunakan Foto',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _coverScale(Size viewport) {
    final scaleW = viewport.width / _imageSize!.width;
    final scaleH = viewport.height / _imageSize!.height;

    return scaleW > scaleH ? scaleW : scaleH;
  }
}

/// Area di luar lingkaran dibuat gelap + cincin putih tipis sebagai panduan.
class _CropGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final overlay = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlay, Paint()..color = AppColors.ink.withValues(alpha: 0.62));

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _CropGuidePainter oldDelegate) => false;
}
