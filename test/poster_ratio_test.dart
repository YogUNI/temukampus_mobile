import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/features/events/data/models/event_model.dart';
import 'package:temukampus_mobile/features/events/presentation/widgets/event_grid_metrics.dart';
import 'package:temukampus_mobile/features/events/presentation/widgets/event_ticket_card.dart';
import 'package:temukampus_mobile/features/events/presentation/widgets/featured_event_carousel.dart';

/// Kontrak "satu rasio poster" lintas backend ↔ aplikasi.
///
/// Backend menyimpan poster master **4:5** (cropper panitia mengekspor
/// 1080×1350, `PosterProcessor` hanya mengecilkan tanpa crop, dan web
/// menampilkannya di `aspect-[4/5]`). Setiap kanvas poster di aplikasi wajib
/// mengikuti rasio itu, kalau tidak poster akan terpotong dan tampil beda
/// dengan website.
EventModel _event() => EventModel.fromJson({
      'id': 1,
      'title': 'Seminar Nasional Artificial Intelligence',
      'slug': 'seminar-ai',
      'start_at': '2026-12-01T09:00:00Z',
      'location': 'Auditorium UMB',
      'price': 25000,
      'skp_points': 4,
      'quota': 100,
      'registered_count': 40,
      'format': 'offline',
      'audience': 'umb_only',
      'status': 'published',
      'poster_url': 'assets/images/posters/poster_ai_seminar.jpg',
      'organization': {'id': 1, 'name': 'BEM Fakultas Teknik'},
    });

void main() {
  group('Kontrak rasio poster 4:5', () {
    test('grid memakai rasio master 0.8 (4:5)', () {
      expect(EventGridMetrics.posterAspectRatio, moreOrLessEquals(0.8));
    });

    testWidgets('poster carousel unggulan 4:5, bukan full-bleed landscape',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeaturedEventCarousel(events: [_event()], onEventTap: (_) {}),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final ratios = tester
          .widgetList<AspectRatio>(find.byType(AspectRatio))
          .map((w) => w.aspectRatio)
          .toList();

      expect(
        ratios.any((r) => (r - 0.8).abs() < 0.001),
        isTrue,
        reason: 'poster carousel harus memakai AspectRatio 4:5',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('thumbnail kartu list 4:5 (bukan kotak 1:1)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventTicketCard(event: _event(), onTap: () {}),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final thumb = tester.getRect(
        find.descendant(
          of: find.byType(EventTicketCard),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(thumb.height / thumb.width, moreOrLessEquals(1.25, epsilon: 0.01));
      expect(tester.takeException(), isNull);
    });
  });
}