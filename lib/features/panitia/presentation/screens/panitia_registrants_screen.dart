import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../data/models/panitia_models.dart';
import '../controllers/panitia_controller.dart';
import '../widgets/proof_sheet.dart';
import '../widgets/review_note_sheet.dart';

/// Daftar peserta satu acara dengan aksi panitia: setujui pembayaran, minta
/// revisi, tolak, dan tandai kehadiran.
///
/// Padanan halaman `/panitia/acara/{event}/verifikasi` + `.../check-in` di web.
class PanitiaRegistrantsScreen extends ConsumerStatefulWidget {
  final int eventId;

  const PanitiaRegistrantsScreen({super.key, required this.eventId});

  @override
  ConsumerState<PanitiaRegistrantsScreen> createState() =>
      _PanitiaRegistrantsScreenState();
}

class _PanitiaRegistrantsScreenState extends ConsumerState<PanitiaRegistrantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _busyId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _run(
    RegistrantModel registrant,
    String action, {
    String? reviewNote,
    bool cancelCheckIn = false,
  }) async {
    setState(() => _busyId = registrant.id);

    final controller = ref.read(registrantsControllerProvider(widget.eventId).notifier);

    try {
      final message = cancelCheckIn
          ? await controller.cancelCheckIn(registrant.id)
          : await controller.runAction(
              registrationId: registrant.id,
              action: action,
              reviewNote: reviewNote,
            );

      if (!mounted) return;

      AppHaptics.success();
      _snack(message);
    } catch (e) {
      if (!mounted) return;

      AppHaptics.error();
      _snack(_clean(e), isError: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.ink,
      ),
    );
  }

  static String _clean(Object error) {
    final text = error.toString();

    return text.contains(':') ? text.split(':').skip(1).join(':').trim() : text;
  }

  Future<void> _approve(RegistrantModel registrant) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Setujui pendaftaran?'),
        content: Text(
          'Tiket ${registrant.name} akan aktif dan tautan grup WhatsApp terbuka.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.cobalt),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );

    if (ok == true) await _run(registrant, 'approve');
  }

  Future<void> _reviseOrReject(RegistrantModel registrant, {required bool reject}) async {
    final note = await showReviewNoteSheet(
      context,
      title: reject ? 'Tolak pendaftaran' : 'Minta revisi bukti',
      hint: reject
          ? 'Contoh: Nominal transfer tidak sesuai tagihan.'
          : 'Contoh: Bukti transfer buram, mohon unggah ulang.',
      confirmLabel: reject ? 'Tolak Pendaftaran' : 'Kirim Permintaan Revisi',
      destructive: reject,
    );

    if (note == null || note.trim().length < 5) return;

    await _run(registrant, reject ? 'reject' : 'revise', reviewNote: note.trim());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrantsControllerProvider(widget.eventId));
    final controller = ref.read(registrantsControllerProvider(widget.eventId).notifier);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Peserta Acara', style: AppTypography.titleMedium),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => controller.load(search: value.trim()),
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Cari nama, NIM, atau kode tiket...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.ink500),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: AppRadii.borderPill,
                  borderSide: BorderSide(color: AppColors.ink200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadii.borderPill,
                  borderSide: BorderSide(color: AppColors.ink200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadii.borderPill,
                  borderSide: const BorderSide(color: AppColors.cobalt, width: 1.6),
                ),
              ),
            ),
          ),
          _TabBar(state: state, onSelect: (tab) => controller.load(tab: tab)),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.cobalt,
              onRefresh: () => controller.load(),
              child: Builder(
                builder: (context) {
                  if (state.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.cobalt),
                    );
                  }

                  if (state.errorMessage != null) {
                    return ListView(
                      children: [
                        const SizedBox(height: 60),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              children: [
                                const Icon(Icons.cloud_off_rounded,
                                    size: 44, color: AppColors.danger),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  _clean(state.errorMessage!),
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall
                                      .copyWith(color: AppColors.ink500),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                OutlinedButton(
                                  onPressed: () => controller.load(),
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (state.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 70),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: const BoxDecoration(
                                  color: AppColors.cobaltLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.people_outline_rounded,
                                    color: AppColors.cobalt, size: 30),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text('Tidak ada peserta di tab ini',
                                  style: AppTypography.titleSmall),
                              const SizedBox(height: 4),
                              Text(
                                'Coba tab lain atau ubah kata kunci.',
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.ink500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    itemCount: state.page.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final registrant = state.page.items[index];

                      return _RegistrantCard(
                        registrant: registrant,
                        busy: _busyId == registrant.id,
                        onProof: () => showProofSheet(context, registrant),
                        onApprove: () => _approve(registrant),
                        onRevise: () => _reviseOrReject(registrant, reject: false),
                        onReject: () => _reviseOrReject(registrant, reject: true),
                        onCheckIn: () => _run(registrant, 'check-in'),
                        onCancelCheckIn: () =>
                            _run(registrant, 'check-in', cancelCheckIn: true),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final RegistrantsState state;
  final ValueChanged<RegistrantTab> onSelect;

  const _TabBar({required this.state, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: RegistrantTab.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final tab = RegistrantTab.values[index];
          final selected = state.tab == tab;

          return GestureDetector(
            onTap: () {
              AppHaptics.selection();
              onSelect(tab);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.cobalt : AppColors.surface,
                borderRadius: AppRadii.borderPill,
                border: Border.all(
                  color: selected ? AppColors.cobalt : AppColors.ink200,
                  width: 1.3,
                ),
              ),
              child: Text(
                '${tab.label} (${state.countFor(tab)})',
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

class _RegistrantCard extends StatelessWidget {
  final RegistrantModel registrant;
  final bool busy;
  final VoidCallback onProof;
  final VoidCallback onApprove;
  final VoidCallback onRevise;
  final VoidCallback onReject;
  final VoidCallback onCheckIn;
  final VoidCallback onCancelCheckIn;

  const _RegistrantCard({
    required this.registrant,
    required this.busy,
    required this.onProof,
    required this.onApprove,
    required this.onRevise,
    required this.onReject,
    required this.onCheckIn,
    required this.onCancelCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.ink200, width: 1.4),
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.cobaltLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  registrant.initials,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.cobalt,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registrant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      [
                        if (registrant.nim != null) registrant.nim!,
                        if (registrant.studyProgram != null) registrant.studyProgram!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
                    ),
                  ],
                ),
              ),
              _StatusBadge(registrant: registrant),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.confirmation_number_rounded, size: 14, color: AppColors.ink400),
              const SizedBox(width: 4),
              Text(
                registrant.ticketCode,
                style: AppTypography.micro.copyWith(
                  color: AppColors.ink500,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                registrant.formattedTotal,
                style: AppTypography.micro.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (registrant.reviewNote != null && registrant.reviewNote!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.signalLight,
                borderRadius: AppRadii.borderSm,
              ),
              child: Text(
                registrant.reviewNote!,
                style: AppTypography.micro.copyWith(color: AppColors.ink700),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 20,
                child: LinearProgressIndicator(
                  color: AppColors.cobalt,
                  backgroundColor: AppColors.cobaltLight,
                ),
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (registrant.hasProof)
                  _Action(
                    label: 'Lihat bukti',
                    icon: Icons.receipt_long_rounded,
                    onTap: onProof,
                  ),
                if (registrant.needsVerification) ...[
                  _Action(
                    label: 'Setujui',
                    icon: Icons.check_circle_rounded,
                    filled: true,
                    onTap: onApprove,
                  ),
                  _Action(
                    label: 'Revisi',
                    icon: Icons.edit_note_rounded,
                    onTap: onRevise,
                  ),
                  _Action(
                    label: 'Tolak',
                    icon: Icons.cancel_rounded,
                    danger: true,
                    onTap: onReject,
                  ),
                ],
                if (registrant.isConfirmed && !registrant.isCheckedIn)
                  _Action(
                    label: 'Tandai hadir',
                    icon: Icons.how_to_reg_rounded,
                    filled: true,
                    onTap: onCheckIn,
                  ),
                if (registrant.isCheckedIn)
                  _Action(
                    label: 'Batalkan hadir',
                    icon: Icons.undo_rounded,
                    danger: true,
                    onTap: onCancelCheckIn,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final RegistrantModel registrant;

  const _StatusBadge({required this.registrant});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (registrant.status) {
      'pending_verification' => (AppColors.amberLight, AppColors.amber),
      'needs_revision' => (AppColors.signalLight, AppColors.signal),
      'confirmed' => (AppColors.mintLight, AppColors.mintText),
      'rejected' => (AppColors.dangerLight, AppColors.dangerText),
      _ => (AppColors.ink100, AppColors.ink500),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadii.borderPill),
      child: Text(
        registrant.isCheckedIn ? 'Hadir' : registrant.statusLabelId,
        style: AppTypography.micro.copyWith(color: fg, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool danger;

  const _Action({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? AppColors.cobalt
        : danger
            ? AppColors.dangerLight
            : AppColors.surface;
    final fg = filled
        ? AppColors.surface
        : danger
            ? AppColors.dangerText
            : AppColors.ink;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadii.borderPill,
          border: Border.all(
            color: filled ? AppColors.cobalt : AppColors.ink200,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.micro.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
