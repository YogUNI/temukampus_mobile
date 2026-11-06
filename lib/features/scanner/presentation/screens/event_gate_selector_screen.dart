import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/components/ticket_clipper.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../data/models/check_in_result_model.dart';
import '../../data/repositories/scanner_repository.dart';

final managedEventsFutureProvider = FutureProvider.autoDispose<List<GateEventModel>>((ref) async {
  final repository = ref.watch(scannerRepositoryProvider);
  return await repository.getManagedEvents();
});

class EventGateSelectorScreen extends ConsumerWidget {
  const EventGateSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(managedEventsFutureProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text('Pintu Gerbang Presensi', style: AppTypography.titleMedium),
        elevation: 0,
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.cobalt)),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
                const SizedBox(height: 12),
                Text('Gagal memuat acara yang dikelola.', style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(managedEventsFutureProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_busy_rounded, size: 48, color: AppColors.ink400),
                    const SizedBox(height: 12),
                    Text('Belum Ada Acara Aktif', style: AppTypography.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Organisasi Anda belum memiliki acara yang membutuhkan presensi hari ini.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.ink500),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final percent = ((event.attendedCount / event.totalQuota) * 100).round();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () {
                    AppHaptics.selection();
                    context.push(AppRoutes.scannerGatePath(event.id));
                  },
                  child: TicketContainer(
                    punchRadius: 12.0,
                    punchPositionPercent: 0.68,
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.cobaltLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      event.organizationName,
                                      style: AppTypography.badge.copyWith(color: AppColors.cobalt, fontSize: 10),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.signalLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'SCANNER AKTIF',
                                      style: AppTypography.badge.copyWith(color: AppColors.ink, fontSize: 9, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(event.title, style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.ink500),
                                  const SizedBox(width: 6),
                                  Text(AppFormatters.eventDate(event.startAt), style: AppTypography.bodySmall.copyWith(fontSize: 12)),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.location_on_rounded, size: 13, color: AppColors.ink500),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      style: AppTypography.bodySmall.copyWith(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: DottedTearLine(color: AppColors.ink200),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: AppColors.paper,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.how_to_reg_rounded, size: 16, color: AppColors.mintText),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Hadir: ${event.attendedCount} / ${event.totalQuota} ($percent%)',
                                    style: AppTypography.numericCode.copyWith(fontSize: 12, color: AppColors.ink700),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text('Buka Scanner', style: AppTypography.labelSmall.copyWith(color: AppColors.cobalt)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.qr_code_scanner_rounded, size: 16, color: AppColors.cobalt),
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
            },
          );
        },
      ),
    );
  }
}

