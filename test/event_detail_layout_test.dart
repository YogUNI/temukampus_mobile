import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/app/theme/components/ticket_clipper.dart';
import 'package:temukampus_mobile/features/events/data/models/event_model.dart';
import 'package:temukampus_mobile/features/events/presentation/widgets/event_cta_bar.dart';
import 'package:temukampus_mobile/features/events/presentation/widgets/event_ticket_info_card.dart';

EventModel _event({bool free = false, int price = 25000}) => EventModel.fromJson({
      'id': 1,
      'title': 'Seminar Nasional Artificial Intelligence',
      'slug': 'seminar-ai',
      'summary': 'Ringkasan',
      'start_at': '2026-12-01T09:00:00Z',
      'end_at': '2026-12-01T12:00:00Z',
      'location': 'Auditorium UMB',
      'price': free ? 0 : price,
      'quota': 100,
      'registered_count': 40,
      'format': 'offline',
      'audience': 'umb_only',
      'status': 'published',
      'poster_url': 'assets/images/posters/poster_ai_seminar.jpg',
      'organization': {'id': 1, 'name': 'BEM Fakultas Teknik', 'slug': 'bem-teknik'},
    });

CtaStateModel _cta(EventCtaState status, {String? reason}) => CtaStateModel(
      status: status,
      label: 'label',
      reason: reason,
    );

void main() {
  group('EventCtaView.resolve — 11 status CTA', () {
    test('canRegister menampilkan harga & tombol aktif', () {
      final view = EventCtaView.resolve(_cta(EventCtaState.canRegister), _event());
      expect(view.statusLabel, 'HARGA TIKET');
      expect(view.value, _event().formattedPrice);
      expect(view.buttonLabel, 'Daftar & Bayar');
      expect(view.enabled, isTrue);
    });

    test('canRegister acara gratis menampilkan "Gratis" & Daftar Sekarang', () {
      final view = EventCtaView.resolve(
        _cta(EventCtaState.canRegister),
        _event(free: true),
      );
      expect(view.value, 'Gratis');
      expect(view.buttonLabel, 'Daftar Sekarang');
    });

    test('notLoggedIn mengarah ke login dan tetap aktif', () {
      final view = EventCtaView.resolve(_cta(EventCtaState.notLoggedIn), _event());
      expect(view.buttonLabel, 'Masuk & Daftar');
      expect(view.enabled, isTrue);
    });

    test('emailUnverified & profileIncomplete aktif dengan label pendek', () {
      expect(
        EventCtaView.resolve(_cta(EventCtaState.emailUnverified), _event()).buttonLabel,
        'Verifikasi Email',
      );
      expect(
        EventCtaView.resolve(_cta(EventCtaState.profileIncomplete), _event()).buttonLabel,
        'Lengkapi Profil',
      );
    });

    test('alreadyRegistered aktif menuju tiket', () {
      final view =
          EventCtaView.resolve(_cta(EventCtaState.alreadyRegistered), _event());
      expect(view.buttonLabel, 'Lihat Tiket Saya');
      expect(view.enabled, isTrue);
    });

    test('status terminal tidak aktif (disabled)', () {
      for (final status in [
        EventCtaState.notEligible,
        EventCtaState.notOpenYet,
        EventCtaState.registrationClosed,
        EventCtaState.quotaFull,
        EventCtaState.eventCancelled,
        EventCtaState.eventEnded,
      ]) {
        final view = EventCtaView.resolve(_cta(status), _event());
        expect(view.enabled, isFalse, reason: '$status seharusnya disabled');
        expect(view.buttonLabel.length, lessThanOrEqualTo(24),
            reason: 'label tombol $status terlalu panjang untuk bar');
      }
    });

    test('reason dari kalkulator dipakai sebagai nilai status', () {
      final view = EventCtaView.resolve(
        _cta(EventCtaState.notEligible, reason: 'Khusus prodi Teknik Informatika'),
        _event(),
      );
      expect(view.statusLabel, 'Syarat tidak cocok');
      expect(view.value, 'Khusus prodi Teknik Informatika');
    });
  });

  group('EventCtaBar geometri', () {
    testWidgets('harga di kiri, tombol lebar di kanan, tinggi tetap 76pt',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: EventCtaBar(
            view: EventCtaView.resolve(_cta(EventCtaState.canRegister), _event()),
            onPressed: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final priceRect = tester.getRect(find.text(_event().formattedPrice));
            final buttonRect = tester.getRect(
              find.textContaining('Daftar'),
            );
      expect(priceRect.right, lessThan(buttonRect.left),
          reason: 'harga harus di kiri tombol');
      expect(buttonRect.center.dx, greaterThan(195),
          reason: 'tombol harus mendominasi sisi kanan');

      final barRect = tester.getRect(find.byType(EventCtaBar));
      expect(844 - barRect.bottom, lessThanOrEqualTo(1));
    });

    testWidgets('tinggi bar sama untuk status aktif maupun disabled',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<double> heightFor(EventCtaState status) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: EventCtaBar(
              view: EventCtaView.resolve(_cta(status), _event()),
              onPressed: () {},
            ),
          ),
        ));
        await tester.pumpAndSettle();
        return tester.getRect(find.byType(EventCtaBar)).height;
      }

      final a = await heightFor(EventCtaState.canRegister);
      final b = await heightFor(EventCtaState.quotaFull);
      final c = await heightFor(EventCtaState.notEligible);
      expect(b, a);
      expect(c, a);
    });
  });

  group('EventTicketInfoCard', () {
    testWidgets('kartu tiket simetris: perforasi tepat di tengah', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: EventTicketInfoCard(event: _event()),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final card = tester.getRect(find.byType(TicketContainer));
      final tear = tester.getRect(find.byType(DottedTearLine));
      final centerY = card.top + card.height / 2;
      expect(tear.center.dy, moreOrLessEquals(centerY, epsilon: 2.0),
          reason: 'garis perforasi harus sejajar lubang notch (50%)');
      expect(tester.takeException(), isNull);
    });
  });
}
