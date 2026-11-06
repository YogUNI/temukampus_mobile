import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/app_network_or_asset_image.dart';
import '../../data/models/event_model.dart';

/// Carousel acara unggulan untuk Beranda.
///
/// Perilaku (disengaja, standar aplikasi mobile):
/// - geser manual dengan snap per kartu (peek 8% kartu berikutnya),
/// - auto-advance tiap 6 detik, **berhenti saat pengguna menyentuh** carousel,
/// - parallax poster + skala 0.96→1.0 saat kartu masuk,
/// - indikator titik yang bisa diketuk.
class FeaturedEventCarousel extends StatefulWidget {
  final List<EventModel> events;
  final void Function(EventModel event) onEventTap;

  const FeaturedEventCarousel({
    super.key,
    required this.events,
    required this.onEventTap,
  });

  /// Tinggi kartu hero (pt). Diverifikasi `home_carousel_test.dart`.
  static const double cardHeight = 208;

  /// Jeda auto-advance.
  static const Duration autoAdvanceInterval = Duration(seconds: 6);

  @override
  State<FeaturedEventCarousel> createState() => _FeaturedEventCarouselState();
}

class _FeaturedEventCarouselState extends State<FeaturedEventCarousel> {
  late final PageController _controller =
      PageController(viewportFraction: 0.92);
  Timer? _autoTimer;
  int _index = 0;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _startAutoAdvance();
  }

  @override
  void didUpdateWidget(covariant FeaturedEventCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events.length != widget.events.length) {
      _index = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
      _startAutoAdvance();
    }
  }

  void _startAutoAdvance() {
    _autoTimer?.cancel();
    if (widget.events.length < 2) return;
    _autoTimer = Timer.periodic(FeaturedEventCarousel.autoAdvanceInterval, (_) {
      if (!mounted || _paused || !_controller.hasClients) return;
      final next = (_index + 1) % widget.events.length;
      _controller.animateToPage(
        next,
        duration: AppDurations.slow,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _setPaused(bool value) {
    if (_paused == value) return;
    _paused = value;
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: FeaturedEventCarousel.cardHeight,
          child: Listener(
            onPointerDown: (_) => _setPaused(true),
            onPointerUp: (_) => _setPaused(false),
            onPointerCancel: (_) => _setPaused(false),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.events.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double delta;
                    if (_controller.hasClients && _controller.position.haveDimensions) {
                      delta = (_controller.page ?? _index.toDouble()) - index;
                    } else {
                      delta = _index.toDouble() - index;
                    }
                    final clamped = delta.clamp(-1.0, 1.0);
                    return Transform.scale(
                      scale: 1 - clamped.abs() * 0.04,
                      child: _HeroCard(
                        event: widget.events[index],
                        parallax: -clamped * 18,
                        onTap: () {
                          AppHaptics.selection();
                          widget.onEventTap(widget.events[index]);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.events.length; i++)
              GestureDetector(
                onTap: () {
                  AppHaptics.light();
                  _controller.animateToPage(
                    i,
                    duration: AppDurations.base,
                    curve: Curves.easeOutCubic,
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    curve: Curves.easeOutCubic,
                    width: i == _index ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.cobalt : AppColors.ink200,
                      borderRadius: AppRadii.borderPill,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final EventModel event;
  final double parallax;
  final VoidCallback onTap;

  const _HeroCard({
    required this.event,
    required this.parallax,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Material(
        color: AppColors.ink900,
        borderRadius: AppRadii.borderLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster dengan parallax halus (diperbesar agar tidak ada celah).
              ClipRect(
                child: Transform.scale(
                  scale: 1.12,
                  child: Transform.translate(
                    offset: Offset(0, parallax),
                    child: AppNetworkOrAssetImage(
                      imagePath: event.posterUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Scrim: cukup gelap di bawah untuk teks, tetap terang di atas.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.30),
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.md,
                right: AppSpacing.md,
                child: Row(
                  children: [
                    _HeroTag(
                      label: (event.category ?? 'Acara Kampus').toUpperCase(),
                      background: AppColors.signal,
                      foreground: AppColors.ink,
                    ),
                    if (event.skpPoints > 0) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _HeroTag(
                        label: '${event.skpPoints} SKP',
                        background: Colors.white.withValues(alpha: 0.94),
                        foreground: AppColors.ink,
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontSize: 19,
                        height: 1.22,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: Colors.white70),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            AppFormatters.eventDate(event.startAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white70,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: Colors.white70),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            event.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white70,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.formattedPrice,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadii.borderPill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lihat Acara',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 14, color: AppColors.ink),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _HeroTag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.borderXs,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.micro.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Placeholder carousel saat katalog pertama kali dimuat.
class FeaturedEventSkeleton extends StatelessWidget {
  const FeaturedEventSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.ink100,
      highlightColor: AppColors.surface,
      child: Container(
        height: FeaturedEventCarousel.cardHeight,
        decoration: BoxDecoration(
          color: AppColors.ink200,
          borderRadius: AppRadii.borderLg,
        ),
      ),
    );
  }
}
