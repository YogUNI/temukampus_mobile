import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../data/models/organization_model.dart';
import '../controllers/organizations_controller.dart';
import '../widgets/organization_card.dart';

/// Direktori organisasi kampus — padanan halaman /organisasi di website.
///
/// Mengikuti empat keadaan wajib: memuat, kosong, galat, dan sukses.
class OrganizationsScreen extends ConsumerStatefulWidget {
  const OrganizationsScreen({super.key});

  @override
  ConsumerState<OrganizationsScreen> createState() => _OrganizationsScreenState();
}

class _OrganizationsScreenState extends ConsumerState<OrganizationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _group = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(organizationsControllerProvider);
    final controller = ref.read(organizationsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text('Organisasi Kampus', style: AppTypography.titleMedium),
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.cobalt,
        onRefresh: controller.retry,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            _SearchField(
              controller: _searchController,
              onSubmit: (value) {
                AppHaptics.selection();
                controller.search(value.trim());
              },
              onClear: () {
                _searchController.clear();
                controller.search('');
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _GroupChips(
              groups: state.groups,
              total: state.overallCount,
              active: _group,
              onSelect: (key) {
                AppHaptics.selection();
                setState(() => _group = key);
                controller.selectGroup(key);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.isLoading)
              const _LoadingState()
            else if (state.errorMessage != null)
              _ErrorState(message: state.errorMessage!, onRetry: controller.retry)
            else if (state.isEmpty)
              const _EmptyState()
            else ...[
              Text(
                '${state.total} organisasi',
                style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final organization in state.items) ...[
                OrganizationCard(
                  organization: organization,
                  onTap: () {
                    AppHaptics.selection();
                    context.push(AppRoutes.organizationDetailPath(organization.slug));
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onSubmit,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmit,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Cari nama organisasi...',
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.ink500),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.ink500),
        suffixIcon: IconButton(
          onPressed: onClear,
          icon: const Icon(Icons.close_rounded, color: AppColors.ink500),
          tooltip: 'Hapus pencarian',
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadii.borderLg,
          borderSide: BorderSide(color: AppColors.ink200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderLg,
          borderSide: BorderSide(color: AppColors.ink200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderLg,
          borderSide: const BorderSide(color: AppColors.cobalt, width: 1.6),
        ),
      ),
    );
  }
}

class _GroupChips extends StatelessWidget {
  final List<OrganizationGroupModel> groups;
  final int total;
  final String active;
  final ValueChanged<String> onSelect;

  const _GroupChips({
    required this.groups,
    required this.total,
    required this.active,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final entries = <(String, String, int)>[
      ('', 'Semua', total),
      for (final group in groups) (group.key, group.label, group.count),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final (key, label, count) = entries[index];
          final selected = key == active;

          return GestureDetector(
            onTap: () => onSelect(key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.cobalt : AppColors.surface,
                borderRadius: AppRadii.borderPill,
                border: Border.all(
                  color: selected ? AppColors.cobalt : AppColors.ink200,
                  width: 1.4,
                ),
                boxShadow: selected ? AppShadows.softCard : null,
              ),
              child: Text(
                '$label ($count)',
                style: AppTypography.labelSmall.copyWith(
                  color: selected ? AppColors.surface : AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Center(child: CircularProgressIndicator(color: AppColors.cobalt)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.cobaltLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_rounded, color: AppColors.cobalt, size: 34),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Belum ada organisasi', style: AppTypography.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Coba kata kunci lain atau pilih kelompok berbeda.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
          ),
        ],
      ),
    );
  }
}
