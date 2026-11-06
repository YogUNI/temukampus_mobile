import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import '../../../../core/utils/haptics.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../../data/models/ticket_model.dart';
import '../controllers/tickets_controller.dart';
import '../widgets/ticket_list_card.dart';
import '../widgets/ticket_shimmer.dart';

class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key});

  static const List<({String key, String label})> tabs = [
    (key: 'upcoming', label: 'Akan Datang'),
    (key: 'pending', label: 'Verifikasi'),
    (key: 'completed', label: 'Selesai'),
    (key: 'cancelled', label: 'Dibatalkan'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final ticketsState = ref.watch(ticketsControllerProvider);

    if (authState.user == null) {
      return _GuestTicketsView(
        onLogin: () {
          AppHaptics.selection();
          context.push(AppRoutes.login);
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text('Tiket Saya', style: AppTypography.titleMedium),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab kapsul 4 kategori
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.sm,
              AppSpacing.gutter,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                for (final tab in tabs)
                  Expanded(
                    child: _TabPill(
                      label: tab.label,
                      isSelected: ticketsState.activeTab == tab.key,
                      onTap: () {
                        AppHaptics.light();
                        ref.read(ticketsControllerProvider.notifier).changeTab(tab.key);
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.cobalt,
              onRefresh: () => ref.read(ticketsControllerProvider.notifier).refresh(),
              child: _buildContent(context, ref, ticketsState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    TicketsState state,
  ) {
    if (state.isLoading && state.tickets.isEmpty) {
      return const TicketShimmer(itemCount: 3);
    }

    if (state.errorMessage != null && state.tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => ref.read(ticketsControllerProvider.notifier).refresh(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return _EmptyTicketsView(
        activeTab: state.activeTab,
        onExplore: () {
          AppHaptics.selection();
          context.go(AppRoutes.explore);
        },
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.xxl,
      ),
      itemCount: state.tickets.length,
      itemBuilder: (context, index) {
        final TicketModel ticket = state.tickets[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: TicketListCard(
            ticket: ticket,
            onTap: () => context.push(AppRoutes.ticketDetailPath(ticket.ticketCode)),
          ),
        );
      },
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppDurations.base,
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.ink : AppColors.surface,
            borderRadius: AppRadii.borderPill,
            border: Border.all(
              color: isSelected ? AppColors.ink : AppColors.ink200,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              fontSize: 11.5,
              color: isSelected ? Colors.white : AppColors.ink700,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTicketsView extends StatelessWidget {
  final String activeTab;
  final VoidCallback onExplore;

  const _EmptyTicketsView({required this.activeTab, required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final (title, message, buttonLabel) = switch (activeTab) {
      'pending' => (
          'Belum Ada Tiket Menunggu Verifikasi',
          'Belum ada tiket yang menunggu verifikasi. Cari acara seru lainnya yuk!',
          'Jelajah Acara',
        ),
      'completed' => (
          'Belum Ada Tiket Selesai',
          'Belum ada riwayat acara yang selesai.',
          'Jelajah Acara',
        ),
      'cancelled' => (
          'Tidak Ada Tiket Dibatalkan',
          'Tidak ada tiket yang dibatalkan.',
          'Jelajah Acara',
        ),
      _ => (
          'Belum Ada Tiket Mendatang',
          'Belum ada tiket acara mendatang. Temukan seminar & workshop kampus!',
          'Cari Acara',
        ),
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.huge,
      ),
      children: [
        Center(
          child: TicketContainer(
            width: 76,
            height: 76,
            punchRadius: 8,
            punchPositionPercent: 0.5,
            borderColor: AppColors.ink,
            borderWidth: 1.5,
            hasShadow: true,
            shadowOffset: const Offset(2.5, 2.5),
            child: const Center(
              child: Icon(
                Icons.confirmation_number_outlined,
                size: 38,
                color: AppColors.ink400,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium.copyWith(fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: SizedBox(
            width: 180,
            child: StickerButton(
              label: buttonLabel,
              variant: StickerButtonVariant.outline,
              icon: const Icon(Icons.explore_rounded, size: 16, color: AppColors.ink),
              onPressed: onExplore,
            ),
          ),
        ),
      ],
    );
  }
}

class _GuestTicketsView extends StatelessWidget {
  final VoidCallback onLogin;

  const _GuestTicketsView({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text('Tiket Saya', style: AppTypography.titleMedium),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.huge,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TicketContainer(
                width: 80,
                height: 80,
                punchRadius: 10,
                punchPositionPercent: 0.5,
                borderColor: AppColors.ink,
                borderWidth: 1.6,
                hasShadow: true,
                shadowOffset: const Offset(3, 3),
                child: const Center(
                  child: Icon(
                    Icons.confirmation_number_outlined,
                    size: 40,
                    color: AppColors.cobalt,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Masuk untuk Melihat Tiketmu',
                textAlign: TextAlign.center,
                style: AppTypography.hero.copyWith(fontSize: 20),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Masuk dengan akun mahasiswa UMB untuk melihat tiket dan riwayat pendaftaranmu.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.ink500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: 220,
                child: StickerButton(
                  label: 'Masuk ke Akun',
                  variant: StickerButtonVariant.primary,
                  icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                  onPressed: onLogin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}