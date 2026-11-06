import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../app/theme/components/ticket_clipper.dart';

/// Tampilan ramah mahasiswa saat tidak ada acara yang sesuai dengan pencarian / filter.
class EmptyEventsView extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onResetFilter;

  const EmptyEventsView({
    super.key,
    this.title = 'Belum Ada Acara Ditemukan',
    this.message = 'Coba gunakan kata kunci lain atau bersihkan filter untuk menemukan acara kampus lainnya.',
    this.buttonLabel = 'Bersihkan Filter',
    this.onResetFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikon Tiket Kosong dengan Notch & Hard Shadow
            TicketContainer(
              width: 80,
              height: 80,
              punchRadius: 8.0,
              punchPositionPercent: 0.5,
              borderColor: AppColors.ink,
              borderWidth: 1.6,
              hasShadow: true,
              shadowOffset: const Offset(3, 3),
              child: const Center(
                child: Icon(
                  Icons.confirmation_number_outlined,
                  size: 38,
                  color: AppColors.ink400,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.ink500,
                height: 1.4,
              ),
            ),

            if (onResetFilter != null) ...[
              const SizedBox(height: 22),
              SizedBox(
                width: 200,
                child: StickerButton(
                  label: buttonLabel ?? 'Bersihkan Filter',
                  variant: StickerButtonVariant.outline,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.ink),
                  onPressed: onResetFilter,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

