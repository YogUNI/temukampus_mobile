import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../scanner/data/models/check_in_result_model.dart';
import '../../data/models/panitia_models.dart';
import '../controllers/panitia_controller.dart';
import '../widgets/proof_sheet.dart';
import '../widgets/review_note_sheet.dart';

/// Daftar peserta satu acara dengan aksi panitia:
/// - Verifikasi pembayaran perorangan (Setujui / Revisi / Tolak)
/// - Setujui massal (Bulk Approve) pada tab Menunggu
/// - Siklus hidup acara (Publikasikan, Kembalikan ke Draf, Batalkan Acara)
/// - Presensi kehadiran (Tandai Hadir / Batalkan Hadir)
///
/// Padanan halaman `/panitia/acara/{event}/verifikasi` + `.../check-in` di web.
class PanitiaRegistrantsScreen extends ConsumerStatefulWidget {
  final int eventId;

  const PanitiaRegistrantsScreen({super.key, required this.eventId});

  @override
  ConsumerState<PanitiaRegistrantsScreen> createState() =>
      _PanitiaRegistrantsScreenState();
}

class _PanitiaRegistrantsScreenState
    extends ConsumerState<PanitiaRegistrantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = <int>{};
  int? _busyId;
  bool _isBulkApproving = false;
  bool _isEventActionBusy = false;

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

    final controller =
        ref.read(registrantsControllerProvider(widget.eventId).notifier);

    try {
      final message = cancelCheckIn
          ? await controller.cancelCheckIn(registrant.id)
          : await controller.runAction(
              registrationId: registrant.id,
              action: action,
              reviewNote: reviewNote,
            );

      if (!mounted) return;

      // Hapus dari pilihan bila baru saja disetujui
      setState(() => _selectedIds.remove(registrant.id));

      AppHaptics.success();
      _snack(message);

      // Refresh ringkasan global dashboard
      ref.invalidate(panitiaDashboardProvider);
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
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

  Future<void> _reviseOrReject(
    RegistrantModel registrant, {
    required bool reject,
  }) async {
    final note = await showReviewNoteSheet(
      context,
      title: reject ? 'Tolak pendaftaran' : 'Minta revisi bukti',
      hint: reject
          ? 'Contoh: Nominal transfer tidak sesuai tagihan.'
          : 'Contoh: Bukti transfer buram, mohon unggah ulang.',
      confirmLabel: reject ? 'Tolak Pendaftaran' : 'Kirim Permintaan Revisi',
      destructive: reject,
      minLength: 5,
    );

    if (note == null || note.trim().length < 5) return;

    await _run(registrant, reject ? 'reject' : 'revise', reviewNote: note.trim());
  }

  /// Eksekusi persetujuan massal untuk peserta terpilih di tab Menunggu.
  Future<void> _bulkApprove() async {
    if (_selectedIds.isEmpty) return;

    AppHaptics.selection();
    final count = _selectedIds.length;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Setujui $count pendaftaran?'),
        content: Text(
          'Semua tiket dari $count peserta terpilih akan diaktifkan dan tautan grup WhatsApp dibuka.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.cobalt),
            child: Text('Setujui $count Peserta'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _isBulkApproving = true);
    final controller =
        ref.read(registrantsControllerProvider(widget.eventId).notifier);

    try {
      final message = await controller.bulkApprove(_selectedIds.toList());
      if (!mounted) return;

      setState(() => _selectedIds.clear());
      AppHaptics.success();
      _snack(message);

      // Refresh ringkasan global dashboard
      ref.invalidate(panitiaDashboardProvider);
    } catch (e) {
      if (!mounted) return;
      AppHaptics.error();
      _snack(_clean(e), isError: true);
    } finally {
      if (mounted) setState(() => _isBulkApproving = false);
    }
  }

  /// Menangani aksi siklus hidup acara dari menu titik tiga di AppBar.
  Future<void> _handleEventAction(String action, GateEventModel? event) async {
    AppHaptics.selection();
    final eventTitle = event?.title ?? 'acara ini';

    if (action == 'export_csv' || action == 'export_sheet') {
      final isPdf = action == 'export_sheet';
      setState(() => _isEventActionBusy = true);
      final controller =
          ref.read(registrantsControllerProvider(widget.eventId).notifier);

      try {
        final message = await controller.exportFile(
          isPdf: isPdf,
          eventSlug: event?.slug,
        );
        if (!mounted) return;

        AppHaptics.success();
        _snack(message);
      } catch (e) {
        if (!mounted) return;
        AppHaptics.error();
        _snack(_clean(e), isError: true);
      } finally {
        if (mounted) setState(() => _isEventActionBusy = false);
      }
      return;
    }

    if (action == 'publish') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Publikasikan acara?'),
          content: Text(
            'Acara "$eventTitle" akan tayang di katalog publik dan mahasiswa dapat mulai mendaftar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.cobalt),
              child: const Text('Publikasikan'),
            ),
          ],
        ),
      );

      if (ok == true) {
        await _runEventAction('publish');
      }
    } else if (action == 'unpublish') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Kembalikan ke Draf?'),
          content: Text(
            'Acara "$eventTitle" akan ditarik dari katalog publik. Mahasiswa tidak dapat melihat atau mendaftar sampai dipublikasikan kembali.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
              child: const Text('Jadikan Draf'),
            ),
          ],
        ),
      );

      if (ok == true) {
        await _runEventAction('unpublish');
      }
    } else if (action == 'cancel') {
      final reason = await showReviewNoteSheet(
        context,
        title: 'Batalkan Acara',
        subtitle:
            'Tindakan ini tidak dapat dibatalkan. Seluruh peserta terdaftar akan dikabari melalui email dan notifikasi.',
        hint: 'Tuliskan alasan pembatalan acara secara jelas (min. 10 karakter)...',
        confirmLabel: 'Batalkan Acara',
        destructive: true,
        minLength: 10,
      );

      if (reason != null && reason.trim().length >= 10) {
        await _runEventAction('cancel', reason: reason.trim());
      }
    }
  }

  Future<void> _runEventAction(String action, {String? reason}) async {
    setState(() => _isEventActionBusy = true);
    final controller =
        ref.read(registrantsControllerProvider(widget.eventId).notifier);

    try {
      final message = await controller.eventAction(action, reason: reason);
      if (!mounted) return;

      AppHaptics.success();
      _snack(message);

      // Refresh daftar acara panitia & ringkasan dashboard
      ref.invalidate(panitiaEventsProvider);
      ref.invalidate(panitiaDashboardProvider);
    } catch (e) {
      if (!mounted) return;
      AppHaptics.error();
      _snack(_clean(e), isError: true);
    } finally {
      if (mounted) setState(() => _isEventActionBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrantsControllerProvider(widget.eventId));
    final controller =
        ref.read(registrantsControllerProvider(widget.eventId).notifier);

    final events = ref.watch(panitiaEventsProvider).valueOrNull ?? [];
    final currentEvent =
        events.where((e) => e.id == widget.eventId).firstOrNull;

    final isMenungguTab = state.tab == RegistrantTab.menunggu;
    final hasItems = state.page.items.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Peserta Acara', style: AppTypography.titleMedium),
            if (currentEvent != null)
              Text(
                currentEvent.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.micro.copyWith(color: AppColors.ink500),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.ink),
            shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
            elevation: 4,
            tooltip: 'Aksi Acara',
            onSelected: (action) => _handleEventAction(action, currentEvent),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'export_csv',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart_rounded,
                        size: 18, color: AppColors.cobalt),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Ekspor Peserta (CSV)',
                          style: AppTypography.bodySmall),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'export_sheet',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded,
                        size: 18, color: AppColors.signal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Unduh Lembar Hadir (PDF)',
                          style: AppTypography.bodySmall),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'publish',
                child: Row(
                  children: [
                    const Icon(Icons.rocket_launch_rounded,
                        size: 18, color: AppColors.cobalt),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Publikasikan Acara',
                          style: AppTypography.bodySmall),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'unpublish',
                child: Row(
                  children: [
                    const Icon(Icons.drafts_rounded,
                        size: 18, color: AppColors.ink500),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Kembalikan ke Draf',
                          style: AppTypography.bodySmall),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'cancel',
                child: Row(
                  children: [
                    const Icon(Icons.event_busy_rounded,
                        size: 18, color: AppColors.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Batalkan Acara',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: _isEventActionBusy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(
                  color: AppColors.cobalt,
                  backgroundColor: AppColors.cobaltLight,
                ),
              )
            : null,
      ),
      bottomNavigationBar: _selectedIds.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: AppShadows.liftedCard,
                  border:
                      const Border(top: BorderSide(color: AppColors.ink200)),
                ),
                child: FilledButton.icon(
                  onPressed: _isBulkApproving ? null : _bulkApprove,
                  icon: _isBulkApproving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.surface,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    _isBulkApproving
                        ? 'Menyetujui pendaftaran...'
                        : 'Setujui (${_selectedIds.length}) Peserta Terpilih',
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.surface,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.cobalt,
                    disabledBackgroundColor:
                        AppColors.cobalt.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadii.borderPill),
                  ),
                ),
              ),
            )
          : null,
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
              onSubmitted: (value) {
                setState(() => _selectedIds.clear());
                controller.load(search: value.trim());
              },
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Cari nama, NIM, atau kode tiket...',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.ink500),
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
                  borderSide:
                      const BorderSide(color: AppColors.cobalt, width: 1.6),
                ),
              ),
            ),
          ),
          _TabBar(
            state: state,
            onSelect: (tab) {
              setState(() => _selectedIds.clear());
              controller.load(tab: tab);
            },
          ),
          if (isMenungguTab && hasItems)
            Container(
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _selectedIds.isNotEmpty
                    ? AppColors.cobaltLight
                    : AppColors.surface,
                borderRadius: AppRadii.borderMd,
                border: Border.all(
                  color: _selectedIds.isNotEmpty
                      ? AppColors.cobalt
                      : AppColors.ink200,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _selectedIds.length == state.page.items.length &&
                          state.page.items.isNotEmpty,
                      tristate: _selectedIds.isNotEmpty &&
                          _selectedIds.length < state.page.items.length,
                      activeColor: AppColors.cobalt,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (checked) {
                        AppHaptics.selection();
                        setState(() {
                          if (checked == true) {
                            _selectedIds.addAll(
                              state.page.items.map((e) => e.id),
                            );
                          } else {
                            _selectedIds.clear();
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedIds.isEmpty
                          ? 'Pilih semua (${state.page.items.length} menunggu)'
                          : '${_selectedIds.length} dari ${state.page.items.length} dipilih',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _selectedIds.isNotEmpty
                            ? AppColors.cobalt
                            : AppColors.ink,
                      ),
                    ),
                  ),
                  if (_selectedIds.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        AppHaptics.selection();
                        setState(() => _selectedIds.clear());
                      },
                      child: Text(
                        'Batal',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.ink500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.cobalt,
              onRefresh: () async {
                setState(() => _selectedIds.clear());
                await controller.load();
              },
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
                                child: const Icon(
                                  Icons.people_outline_rounded,
                                  color: AppColors.cobalt,
                                  size: 30,
                                ),
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
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final registrant = state.page.items[index];
                      final isSelected = _selectedIds.contains(registrant.id);

                      return _RegistrantCard(
                        registrant: registrant,
                        busy: _busyId == registrant.id,
                        isSelectable: isMenungguTab,
                        isSelected: isSelected,
                        onSelectChanged: (checked) {
                          AppHaptics.selection();
                          setState(() {
                            if (checked == true) {
                              _selectedIds.add(registrant.id);
                            } else {
                              _selectedIds.remove(registrant.id);
                            }
                          });
                        },
                        onProof: () => showProofSheet(context, registrant),
                        onApprove: () => _approve(registrant),
                        onRevise: () =>
                            _reviseOrReject(registrant, reject: false),
                        onReject: () =>
                            _reviseOrReject(registrant, reject: true),
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
  final bool isSelectable;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;
  final VoidCallback onProof;
  final VoidCallback onApprove;
  final VoidCallback onRevise;
  final VoidCallback onReject;
  final VoidCallback onCheckIn;
  final VoidCallback onCancelCheckIn;

  const _RegistrantCard({
    required this.registrant,
    required this.busy,
    this.isSelectable = false,
    this.isSelected = false,
    this.onSelectChanged,
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
        color: isSelected
            ? AppColors.cobaltLight.withValues(alpha: 0.25)
            : AppColors.surface,
        borderRadius: AppRadii.borderLg,
        border: Border.all(
          color: isSelected ? AppColors.cobalt : AppColors.ink200,
          width: isSelected ? 1.8 : 1.4,
        ),
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isSelectable) ...[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isSelected,
                    activeColor: AppColors.cobalt,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: onSelectChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
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
                      style: AppTypography.titleSmall
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      [
                        if (registrant.nim != null) registrant.nim!,
                        if (registrant.studyProgram != null)
                          registrant.studyProgram!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.ink500),
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
              if (isSelectable) const SizedBox(width: 32),
              Icon(Icons.confirmation_number_rounded,
                  size: 14, color: AppColors.ink400),
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
          if (registrant.reviewNote != null &&
              registrant.reviewNote!.isNotEmpty) ...[
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
        style: AppTypography.micro.copyWith(
          color: fg,
          fontWeight: FontWeight.w800,
        ),
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
