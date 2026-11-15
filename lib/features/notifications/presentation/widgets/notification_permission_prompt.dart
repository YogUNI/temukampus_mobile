import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/haptics.dart';
import '../providers/notification_permission_provider.dart';

/// Dialog permintaan izin notifikasi — muncul sekali setelah pengguna masuk.
///
/// Alurnya meniru aplikasi produksi: penjelasan singkat (pre-prompt) dulu,
/// baru dialog izin sistem. Kalau pengguna menolak, aplikasi tidak bertanya
/// lagi otomatis; mereka bisa mengaktifkannya dari Profil.
class NotificationPermissionPrompt extends ConsumerStatefulWidget {
  const NotificationPermissionPrompt({super.key});

  @override
  ConsumerState<NotificationPermissionPrompt> createState() =>
      _NotificationPermissionPromptState();
}

class _NotificationPermissionPromptState extends ConsumerState<NotificationPermissionPrompt> {
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAsk());
  }

  Future<void> _maybeAsk() async {
    if (_scheduled || !mounted) return;

    // Web/desktop: tidak ada izin notifikasi sistem untuk alur ini.
    if (!NotificationService.instance.isSupported) return;

    final state = ref.read(notificationPermissionProvider);
    if (state.asked || state.granted) return;

    _scheduled = true;

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final wantsToEnable = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _PermissionSheet(),
    );

    if (wantsToEnable == true) {
      final granted = await ref.read(notificationPermissionProvider.notifier).request();
      if (!mounted) return;

      if (granted) {
        AppHaptics.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifikasi aktif. Kabar tiket & acara akan muncul di layar HP-mu.'),
            backgroundColor: AppColors.mint,
          ),
        );
      } else {
        AppHaptics.error();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin notifikasi belum diberikan. Kamu bisa mengaktifkannya di Profil.'),
          ),
        );
      }
    } else {
      await ref.read(notificationPermissionProvider.notifier).decline();
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _PermissionSheet extends StatelessWidget {
  const _PermissionSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.ink200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.cobaltLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: AppColors.cobalt,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Jangan Ketinggalan Kabar Kampus',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Aktifkan notifikasi supaya kamu langsung tahu saat pembayaran diverifikasi, '
              'tiket terbit, atau acara yang kamu ikuti berubah jadwal.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: StickerButton(
                label: 'Aktifkan Notifikasi',
                variant: StickerButtonVariant.primary,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Nanti saja',
                style: AppTypography.labelSmall.copyWith(color: AppColors.ink500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
