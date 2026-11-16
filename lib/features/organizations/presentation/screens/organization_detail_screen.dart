import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/app_network_or_asset_image.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/presentation/widgets/event_ticket_card.dart';
import '../../data/models/organization_model.dart';
import '../controllers/organizations_controller.dart';

/// Profil publik organisasi: identitas, kontak, acara mendatang, dan arsip.
///
/// Padanan halaman /organisasi/{slug} di website — memakai data yang sama
/// (organisasi suspended tidak bisa dibuka, acara mengikuti aturan
/// visibilitas yang sama).
class OrganizationDetailScreen extends ConsumerWidget {
  final String slug;

  const OrganizationDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(organizationDetailProvider(slug));

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Profil Organisasi', style: AppTypography.titleMedium),
      ),
      body: detail.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.cobalt),
        ),
        error: (error, _) => _ErrorState(
          message: error is Exception ? _messageOf(error) : 'Gagal memuat organisasi.',
          onRetry: () => ref.invalidate(organizationDetailProvider(slug)),
        ),
        data: (data) => RefreshIndicator(
          color: AppColors.cobalt,
          onRefresh: () async => ref.invalidate(organizationDetailProvider(slug)),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              _Header(organization: data.organization),
              if ((data.organization.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  data.organization.description!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.ink700,
                    height: 1.55,
                  ),
                ),
              ],
              if ((data.organization.instagram ?? '').isNotEmpty ||
                  (data.organization.contactEmail ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _ContactCard(organization: data.organization),
              ],
              const SizedBox(height: AppSpacing.xl),
              _EventSection(
                title: 'Acara Mendatang',
                emptyText: 'Belum ada acara mendatang dari organisasi ini.',
                events: data.upcomingEvents,
              ),
              if (data.pastEvents.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                _EventSection(
                  title: 'Arsip Acara',
                  emptyText: 'Belum ada arsip.',
                  events: data.pastEvents,
                  muted: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _messageOf(Object error) {
    final text = error.toString();

    return text.contains(':') ? text.split(':').skip(1).join(':').trim() : text;
  }
}

class _Header extends StatelessWidget {
  final OrganizationModel organization;

  const _Header({required this.organization});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cobalt, AppColors.cobaltDark],
        ),
        borderRadius: AppRadii.borderXl,
        boxShadow: AppShadows.liftedCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.borderMd,
                ),
                clipBehavior: Clip.antiAlias,
                child: AppNetworkOrAssetImage(
                  imagePath: organization.logoUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorWidget: Center(
                    child: Text(
                      organization.initials,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.cobalt,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organization.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (organization.typeLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.18),
                          borderRadius: AppRadii.borderPill,
                        ),
                        child: Text(
                          organization.typeLabel!,
                          style: AppTypography.micro.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (organization.facultyName != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.account_balance_rounded,
                    size: 15, color: Colors.white70),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    organization.facultyName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.14),
              borderRadius: AppRadii.borderSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_available_rounded,
                    size: 16, color: AppColors.surface),
                const SizedBox(width: 6),
                Text(
                  '${organization.upcomingEventsCount} acara mendatang',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final OrganizationModel organization;

  const _ContactCard({required this.organization});

  void _copy(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    AppHaptics.selection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label disalin: $value')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.ink200, width: 1.4),
      ),
      child: Column(
        children: [
          if ((organization.instagram ?? '').isNotEmpty)
            _Row(
              icon: Icons.camera_alt_rounded,
              label: 'Instagram',
              value: organization.instagram!,
              onTap: () => _copy(context, organization.instagram!, 'Instagram'),
            ),
          if ((organization.contactEmail ?? '').isNotEmpty)
            _Row(
              icon: Icons.mail_rounded,
              label: 'Email kontak',
              value: organization.contactEmail!,
              onTap: () => _copy(context, organization.contactEmail!, 'Email'),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.cobalt),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.micro.copyWith(color: AppColors.ink500)),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded, size: 16, color: AppColors.ink400),
          ],
        ),
      ),
    );
  }
}

class _EventSection extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<EventModel> events;
  final bool muted;

  const _EventSection({
    required this.title,
    required this.emptyText,
    required this.events,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.borderMd,
              border: Border.all(color: AppColors.ink200, width: 1.2),
            ),
            child: Text(
              emptyText,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
            ),
          )
        else
          // Kartu daftar penuh: tinggi mengikuti isi, jadi tidak ada
          // overflow seperti saat dipaksa memakai tinggi grid 2 kolom.
          Column(
            children: [
              for (final event in events) ...[ 
                Opacity(
                  opacity: muted ? 0.75 : 1,
                  child: EventTicketCard(
                    event: event,
                    onTap: () {
                      AppHaptics.selection();
                      context.push(AppRoutes.eventDetailPath(event.slug));
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.ink500),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
