import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../data/models/event_model.dart';

/// Data presentasi sticky CTA (tanpa widget) — hasil pemetaan 11 status CTA.
///
/// Dipisah dari widget supaya bisa diuji tanpa membangun UI.
class EventCtaView {
  /// Label kecil di kiri atas (harga atau status).
  final String statusLabel;

  /// Nilai besar di kiri bawah.
  final String value;

  /// Label tombol aksi (pendek, maksimal ~24 karakter).
  final String buttonLabel;

  final StickerButtonVariant variant;

  /// Ikon tombol (widget, agar bisa di-const dan cocok dengan StickerButton).
  final Widget? icon;
  final bool enabled;

  const EventCtaView({
    required this.statusLabel,
    required this.value,
    required this.buttonLabel,
    required this.variant,
    this.icon,
    this.enabled = false,
  });

  static EventCtaView resolve(CtaStateModel cta, EventModel event) {
    final price = event.isFree ? 'Gratis' : event.formattedPrice;
    final reason = cta.reason;

    switch (cta.status) {
      case EventCtaState.canRegister:
        return EventCtaView(
          statusLabel: 'HARGA TIKET',
          value: price,
          buttonLabel: event.isFree ? 'Daftar Sekarang' : 'Daftar & Bayar',
          variant: StickerButtonVariant.primary,
          icon: const Icon(Icons.arrow_forward_rounded,
              color: Colors.white, size: 18),
          enabled: true,
        );
      case EventCtaState.notLoggedIn:
        return EventCtaView(
          statusLabel: 'HARGA TIKET',
          value: price,
          buttonLabel: 'Masuk & Daftar',
          variant: StickerButtonVariant.primary,
          icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
          enabled: true,
        );
      case EventCtaState.emailUnverified:
        return EventCtaView(
          statusLabel: 'Verifikasi email dulu',
          value: 'Email belum terverifikasi',
          buttonLabel: 'Verifikasi Email',
          variant: StickerButtonVariant.secondary,
          enabled: true,
        );
      case EventCtaState.profileIncomplete:
        return EventCtaView(
          statusLabel: 'Lengkapi profil',
          value: 'Nomor WhatsApp wajib diisi',
          buttonLabel: 'Lengkapi Profil',
          variant: StickerButtonVariant.secondary,
          enabled: true,
        );
      case EventCtaState.alreadyRegistered:
        return EventCtaView(
          statusLabel: 'Kamu sudah terdaftar',
          value: 'Tiket aktif tersedia',
          buttonLabel: 'Lihat Tiket Saya',
          variant: StickerButtonVariant.primary,
          icon: const Icon(Icons.confirmation_number_outlined,
              color: Colors.white, size: 18),
          enabled: true,
        );
      case EventCtaState.notEligible:
        return EventCtaView(
          statusLabel: 'Syarat tidak cocok',
          value: reason ?? 'Tidak terbuka untuk prodi/angkatanmu',
          buttonLabel: 'Syarat Tidak Cocok',
          variant: StickerButtonVariant.outline,
        );
      case EventCtaState.notOpenYet:
        return EventCtaView(
          statusLabel: 'Pendaftaran belum dibuka',
          value: 'Pantau terus halaman ini',
          buttonLabel: 'Belum Dibuka',
          variant: StickerButtonVariant.outline,
        );
      case EventCtaState.registrationClosed:
        return EventCtaView(
          statusLabel: 'Pendaftaran ditutup',
          value: price,
          buttonLabel: 'Ditutup',
          variant: StickerButtonVariant.outline,
        );
      case EventCtaState.quotaFull:
        return EventCtaView(
          statusLabel: 'Kuota penuh',
          value: price,
          buttonLabel: 'Kuota Penuh',
          variant: StickerButtonVariant.danger,
        );
      case EventCtaState.eventCancelled:
        return EventCtaView(
          statusLabel: 'Acara dibatalkan',
          value: reason ?? 'Acara ini telah dibatalkan panitia',
          buttonLabel: 'Dibatalkan',
          variant: StickerButtonVariant.danger,
        );
      case EventCtaState.eventEnded:
        return const EventCtaView(
          statusLabel: 'Acara telah selesai',
          value: 'Pendaftaran ditutup',
          buttonLabel: 'Selesai',
          variant: StickerButtonVariant.outline,
        );
    }
  }
}

/// Sticky bottom bar ala checkout e-commerce: harga di kiri, CTA lebar di kanan.
///
/// Tingginya **tetap** di semua 11 status CTA ([contentHeight]), sehingga bar
/// tidak pernah "meloncat" saat status berubah.
class EventCtaBar extends StatelessWidget {
  final EventCtaView view;
  final VoidCallback? onPressed;

  static const double contentHeight = 76;

  const EventCtaBar({
    super.key,
    required this.view,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.ink100)),
        boxShadow: AppShadows.liftedCard,
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: SizedBox(
          height: contentHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        view.statusLabel.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.micro.copyWith(
                          fontSize: 9.5,
                          color: AppColors.ink400,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        view.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: view.enabled ? AppColors.ink : AppColors.ink500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 6,
                  child: StickerButton(
                    label: view.buttonLabel,
                    variant: view.variant,
                    icon: view.icon,
                    onPressed: view.enabled ? onPressed : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
