import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../data/models/app_notification_model.dart';
import '../../data/repositories/notifications_repository.dart';
import '../providers/notifications_badge_provider.dart';

/// Pusat notifikasi — membaca tabel `notifications` yang sama dengan email
/// dan web, jadi isi lonceng selalu identik dengan riwayat di server.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsControllerProvider.notifier).load();
    });
  }

  Future<void> _open(AppNotificationModel item) async {
    await ref.read(notificationsControllerProvider.notifier).markRead(item);
    ref.invalidate(unreadNotificationsProvider);

    final route = item.actionRoute;
    if (route == null || route.isEmpty || !mounted) return;

    // Rute dari backend memakai jalur aplikasi (/tickets/…, /events/…, /profile).
    if (route.startsWith('/')) {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsControllerProvider);
    final notifier = ref.read(notificationsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'Notifikasi',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium,
              ),
            ),
            if (state.hasUnread) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.signal,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${state.unreadCount}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (state.hasUnread)
            IconButton(
              tooltip: 'Tandai semua dibaca',
              onPressed: () async {
                AppHaptics.light();
                await notifier.markAllRead();
                ref.invalidate(unreadNotificationsProvider);
              },
              icon: const Icon(Icons.done_all_rounded, color: AppColors.cobalt),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  active: state.filter == 'all',
                  onTap: () => notifier.setFilter('all'),
                ),
                const SizedBox(width: AppSpacing.xs),
                _FilterChip(
                  label: 'Belum dibaca',
                  active: state.filter == 'unread',
                  onTap: () => notifier.setFilter('unread'),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(state, notifier)),
        ],
      ),
    );
  }

  Widget _buildBody(NotificationsState state, NotificationsController notifier) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.cobalt),
      );
    }

    if (state.errorMessage != null) {
      return _StateView(
        icon: Icons.cloud_off_rounded,
        title: 'Gagal memuat notifikasi',
        message: state.errorMessage!,
        actionLabel: 'Coba Lagi',
        onAction: () => notifier.load(),
      );
    }

    if (state.isEmpty) {
      return _StateView(
        icon: Icons.notifications_off_outlined,
        title: 'Belum ada notifikasi',
        message: state.filter == 'unread'
            ? 'Semua notifikasi sudah kamu baca.'
            : 'Kabar tentang pendaftaran, pembayaran, dan acara akan muncul di sini.',
      );
    }

    return RefreshIndicator(
      color: AppColors.cobalt,
      onRefresh: () async {
        await notifier.refresh();
        ref.invalidate(unreadNotificationsProvider);
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = state.items[index];

          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: AppRadii.borderMd,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            ),
            onDismissed: (_) async {
              await notifier.delete(item);
              ref.invalidate(unreadNotificationsProvider);
            },
            child: _NotificationCard(
              item: item,
              onTap: () => _open(item),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final AppNotificationModel item;
  final VoidCallback onTap;

  static const Map<String, IconData> _icons = {
    'ticket': Icons.confirmation_number_rounded,
    'clock': Icons.schedule_rounded,
    'alert': Icons.error_outline_rounded,
    'cross': Icons.cancel_outlined,
    'calendar': Icons.event_busy_rounded,
    'eye-off': Icons.visibility_off_rounded,
    'building': Icons.apartment_rounded,
    'check': Icons.verified_rounded,
    'lock': Icons.lock_outline_rounded,
    'bell': Icons.notifications_none_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[item.icon] ?? _icons['bell']!;
    final unread = !item.isRead;

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadii.borderMd,
      child: InkWell(
        borderRadius: AppRadii.borderMd,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.borderMd,
            border: Border.all(
              color: unread ? AppColors.cobalt.withValues(alpha: 0.35) : AppColors.ink100,
              width: unread ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: unread ? AppColors.cobaltLight : AppColors.ink100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: unread ? AppColors.cobalt : AppColors.ink400,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTypography.titleSmall.copyWith(
                              fontSize: 14,
                              fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.signal,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          item.relativeTime,
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 11,
                            color: AppColors.ink400,
                          ),
                        ),
                        if (item.actionLabel != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '· ${item.actionLabel}',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 11,
                              color: AppColors.cobalt,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.cobalt : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? AppColors.cobalt : AppColors.ink200),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: active ? Colors.white : AppColors.ink700,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StateView extends StatelessWidget {
  const _StateView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.ink400),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: AppTypography.titleSmall),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(backgroundColor: AppColors.cobalt),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
