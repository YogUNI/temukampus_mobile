import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/status_pill.dart';
import '../../../../app/theme/components/sticker_button.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../controllers/tickets_controller.dart';
import '../../data/models/ticket_model.dart';

class MyTicketsScreen extends ConsumerStatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  ConsumerState<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends ConsumerState<MyTicketsScreen> {
  final List<Map<String, String>> _tabs = const [
    {'key': 'upcoming', 'label': 'Akan Datang'},
    {'key': 'pending', 'label': 'Verifikasi'},
    {'key': 'completed', 'label': 'Selesai'},
    {'key': 'cancelled', 'label': 'Dibatalkan'},
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final ticketsState = ref.watch(ticketsControllerProvider);

    // Mode Tamu (Guest)
    if (authState.user == null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
          title: Text('Tiket Saya', style: AppTypography.titleMedium),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TicketContainer(
                  width: 80,
                  height: 80,
                  punchRadius: 10.0,
                  punchPositionPercent: 0.5,
                  borderColor: AppColors.ink,
                  borderWidth: 1.6,
                  hasShadow: true,
                  shadowOffset: const Offset(3, 3),
                  child: const Center(
                    child: Icon(Icons.confirmation_number_outlined, size: 40, color: AppColors.cobalt),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Masuk untuk Melihat Tiketmu',
                  style: AppTypography.hero.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk dengan akun mahasiswa UMB untuk melihat tiket dan riwayat pendaftaranmu.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink500, height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  child: StickerButton(
                    label: 'Masuk ke Akun',
                    variant: StickerButtonVariant.primary,
                    icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                    onPressed: () {
                      AppHaptics.selection();
                      context.push(AppRoutes.login);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
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
          // 1. Tab Bar Stiker 4 Kategori Tiket
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: _tabs.map((tab) {
                final isSelected = ticketsState.activeTab == tab['key'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      AppHaptics.light();
                      ref.read(ticketsControllerProvider.notifier).changeTab(tab['key']!);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.cobalt : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.cobalt : AppColors.ink200,
                          width: 1.2,
                        ),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: AppColors.ink,
                                  offset: Offset(1.5, 1.5),
                                  blurRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        tab['label']!,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? Colors.white : AppColors.ink700,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Daftar Tiket
          Expanded(
            child: RefreshIndicator(
              color: AppColors.cobalt,
              onRefresh: () => ref.read(ticketsControllerProvider.notifier).refresh(),
              child: _buildTicketContent(ticketsState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketContent(TicketsState state) {
    if (state.isLoading && state.tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.cobalt));
    }

    if (state.errorMessage != null && state.tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(state.errorMessage!, textAlign: TextAlign.center, style: AppTypography.bodyMedium),
              const SizedBox(height: 16),
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
      String title;
      String message;
      String buttonLabel = 'Jelajah Acara';

      switch (state.activeTab) {
        case 'pending':
          title = 'Belum Ada Tiket Menunggu Verifikasi';
          message = 'Belum ada tiket yang menunggu verifikasi. Cari acara seru lainnya yuk!';
          break;
        case 'completed':
          title = 'Belum Ada Tiket Selesai';
          message = 'Belum ada riwayat acara yang selesai.';
          break;
        case 'cancelled':
          title = 'Tidak Ada Tiket Dibatalkan';
          message = 'Tidak ada tiket yang dibatalkan.';
          break;
        case 'upcoming':
        default:
          title = 'Belum Ada Tiket Mendatang';
          message = 'Belum ada tiket acara mendatang. Temukan seminar & workshop kampus!';
          buttonLabel = 'Cari Acara';
          break;
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TicketContainer(
                width: 76,
                height: 76,
                punchRadius: 8.0,
                borderColor: AppColors.ink,
                borderWidth: 1.5,
                hasShadow: true,
                shadowOffset: const Offset(2.5, 2.5),
                child: const Center(
                  child: Icon(Icons.confirmation_number_outlined, size: 38, color: AppColors.ink400),
                ),
              ),
              const SizedBox(height: 18),
              Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 180,
                child: StickerButton(
                  label: buttonLabel,
                  variant: StickerButtonVariant.outline,
                  icon: const Icon(Icons.explore_rounded, size: 16, color: AppColors.ink),
                  onPressed: () {
                    AppHaptics.selection();
                    context.go(AppRoutes.explore);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: state.tickets.length,
      itemBuilder: (context, index) {
        final ticket = state.tickets[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildTicketCard(ticket),
        );
      },
    );
  }

  Widget _buildTicketCard(TicketModel ticket) {
    RegistrationStatusType statusType;
    switch (ticket.status) {
      case 'confirmed':
        statusType = RegistrationStatusType.confirmed;
        break;
      case 'needs_revision':
        statusType = RegistrationStatusType.needsRevision;
        break;
      case 'cancelled':
        statusType = RegistrationStatusType.cancelled;
        break;
      case 'rejected':
        statusType = RegistrationStatusType.rejected;
        break;
      case 'pending_verification':
      default:
        statusType = RegistrationStatusType.pendingVerification;
        break;
    }

    return GestureDetector(
      onTap: () {
        AppHaptics.light();
        context.push(AppRoutes.ticketDetailPath(ticket.ticketCode));
      },
      child: TicketContainer(
        punchRadius: 12.0,
        punchPositionPercent: 0.70,
        borderRadius: 16.0,
        borderColor: AppColors.ink,
        borderWidth: 1.4,
        hasShadow: true,
        shadowOffset: const Offset(3, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kode Tiket & Stempel Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ticket.ticketCode,
                        style: AppTypography.numericCode.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cobalt,
                          letterSpacing: 1.1,
                        ),
                      ),
                      StatusPill(status: statusType, isStamp: true),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Judul Acara
                  Text(
                    ticket.event.title,
                    style: AppTypography.titleMedium.copyWith(fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Jadwal & Lokasi
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.ink500),
                      const SizedBox(width: 6),
                      Text(
                        AppFormatters.eventDate(ticket.event.startAt),
                        style: AppTypography.bodySmall.copyWith(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_rounded, size: 13, color: AppColors.ink500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ticket.event.location,
                          style: AppTypography.bodySmall.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Catatan Revisi jika ada
                  if (ticket.isNeedsRevision && ticket.revisionNotes != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.signalLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.signal.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.signal, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Revisi: ${ticket.revisionNotes}',
                              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.ink),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Perforasi
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: DottedTearLine(color: AppColors.ink200),
            ),

            // Stub Bagian Bawah
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.paper,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Peserta: ${ticket.participant.name}',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.ink500),
                  ),
                  Row(
                    children: [
                      Text(
                        'Buka Tiket',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.cobalt, fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.cobalt, size: 13),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
