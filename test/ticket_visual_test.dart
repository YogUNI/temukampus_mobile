import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:temukampus_mobile/app/theme/app_spacing.dart';
import 'package:temukampus_mobile/app/theme/components/status_pill.dart';
import 'package:temukampus_mobile/app/theme/components/ticket_clipper.dart';
import 'package:temukampus_mobile/features/tickets/data/models/ticket_model.dart';
import 'package:temukampus_mobile/features/tickets/presentation/widgets/ticket_countdown.dart';
import 'package:temukampus_mobile/features/tickets/presentation/widgets/ticket_list_card.dart';
import 'package:temukampus_mobile/features/tickets/presentation/widgets/ticket_pass_card.dart';

TicketModel _ticket({
  String status = 'confirmed',
  DateTime? startAt,
  String? checkedInAt,
}) {
  return TicketModel.fromJson({
    'ticket_code': 'TK-26A1B2',
    'status': status,
    'participant': {'name': 'Yoga Gustira', 'nim': '41524010001'},
    'event': {
      'title': 'Seminar Nasional Artificial Intelligence untuk Mahasiswa UMB',
      'slug': 'seminar-ai',
      'poster_url': 'assets/images/posters/poster_ai_seminar.jpg',
      'start_at': (startAt ?? DateTime(2026, 12, 1, 9)).toIso8601String(),
      'end_at': (startAt ?? DateTime(2026, 12, 1, 9))
          .add(const Duration(hours: 3))
          .toIso8601String(),
      'location': 'Auditorium Universitas Mercu Buana Meruya',
      'format': 'offline',
    },
    'amount_paid': 25137,
    'checked_in_at': checkedInAt,
    'unlocked_access': {
      'wa_group_url': 'https://chat.whatsapp.com/mock',
      'meeting_url': null,
    },
    'registered_at': DateTime(2026, 11, 20).toIso8601String(),
  });
}

void main() {
  group('TicketCountdown', () {
    final now = DateTime(2026, 11, 20, 10);

    test('label hari-H sesuai jarak tanggal', () {
      expect(TicketCountdown.label(DateTime(2026, 12, 1, 9), now: now), 'H-11');
      expect(TicketCountdown.label(DateTime(2026, 11, 21, 9), now: now), 'Besok');
      expect(TicketCountdown.label(DateTime(2026, 11, 20, 23), now: now), 'Hari ini');
      expect(TicketCountdown.label(DateTime(2026, 11, 19, 9), now: now), 'Selesai');
    });

    test('urgent hanya untuk hari ini & besok', () {
      expect(TicketCountdown.isUrgent(DateTime(2026, 11, 20, 23), now: now), isTrue);
      expect(TicketCountdown.isUrgent(DateTime(2026, 11, 21, 1), now: now), isTrue);
      expect(TicketCountdown.isUrgent(DateTime(2026, 11, 25), now: now), isFalse);
      expect(TicketCountdown.isUrgent(DateTime(2026, 11, 1), now: now), isFalse);
    });
  });

  group('TicketListCard', () {
    for (final width in [360.0, 390.0, 412.0]) {
      testWidgets('tidak overflow & perforasi sejajar notch @${width.toInt()}dp',
          (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              children: [
                TicketListCard(ticket: _ticket(), onTap: () {}),
              ],
            ),
          ),
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final card = tester.getRect(find.byType(TicketContainer));
        final tear = tester.getRect(find.byType(DottedTearLine));
        final notchY = card.top + card.height * TicketListCard.punchPositionPercent;
        expect(tear.center.dy, moreOrLessEquals(notchY, epsilon: 3.0),
            reason: 'garis perforasi harus mendekati lubang notch');

        expect(find.text('TK-26A1B2'), findsOneWidget);
        expect(find.byType(StatusPill), findsOneWidget);
        expect(find.byType(TicketCountdownChip), findsOneWidget);
      });
    }
  });

  group('TicketPassCard', () {
    testWidgets('QR 220pt, kode tiket, stempel status, dan salin kode',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var copyCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: TicketPassCard(
              ticket: _ticket(),
              statusType: RegistrationStatusType.confirmed,
              onCopyCode: () => copyCount++,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(QrImageView), findsOneWidget);
      final qrSize = tester.getSize(find.byType(QrImageView));
      expect(qrSize.width, TicketPassCard.qrSize);
      expect(qrSize.height, TicketPassCard.qrSize);

      expect(find.text('TEMUKAMPUS PASS'), findsOneWidget);
      expect(find.text('TK-26A1B2'), findsOneWidget);
      expect(find.text('Yoga Gustira'), findsOneWidget);
      expect(find.textContaining('Naikkan kecerahan layar'), findsOneWidget);

      await tester.tap(find.text('TK-26A1B2'));
      await tester.pump();
      expect(copyCount, 1);
    });

    testWidgets('sudah check-in menampilkan waktu presensi', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: TicketPassCard(
              ticket: _ticket(
                checkedInAt: DateTime(2026, 12, 1, 9, 5).toIso8601String(),
              ),
              statusType: RegistrationStatusType.confirmed,
              onCopyCode: () {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Presensi masuk berhasil'), findsOneWidget);
      expect(find.textContaining('Naikkan kecerahan layar'), findsNothing);
    });
  });
}