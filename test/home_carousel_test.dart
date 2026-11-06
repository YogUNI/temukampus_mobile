import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/features/events/data/models/event_model.dart';
import 'package:temukampus_mobile/features/events/presentation/widgets/featured_event_carousel.dart';

EventModel _event(int id, String title) => EventModel.fromJson({
      'id': id,
      'title': title,
      'slug': 'event-$id',
      'start_at': '2026-12-0${id}T09:00:00Z',
      'location': 'Auditorium UMB',
      'price': 25000,
      'quota': 100,
      'registered_count': 40,
      'format': 'offline',
      'audience': 'public',
      'status': 'published',
      'poster_url': 'assets/images/posters/poster_ai_seminar.jpg',
      'organization': {'id': 1, 'name': 'BEM UMB'},
    });

final _events = [
  _event(1, 'Seminar AI Nasional'),
  _event(2, 'Workshop UI/UX Design'),
  _event(3, 'Music Fest Kampus'),
];

Widget _harness(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 390, child: child),
        ),
      ),
    );

/// Halaman carousel yang sedang aktif (dibaca dari PageController).
double _page(WidgetTester tester) {
  final view = tester.widget<PageView>(find.byType(PageView));
  return view.controller?.page ?? -1;
}

void main() {
  group('FeaturedEventCarousel', () {
    testWidgets('menampilkan kartu unggulan setinggi 208pt', (tester) async {
      await tester.pumpWidget(_harness(
        FeaturedEventCarousel(events: _events, onEventTap: (_) {}),
      ));
      await tester.pump();

      final rect = tester.getRect(find.byType(PageView));
      expect(rect.height, FeaturedEventCarousel.cardHeight);
      expect(find.text('Seminar AI Nasional'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('auto-advance setelah 6 detik', (tester) async {
      await tester.pumpWidget(_harness(
        FeaturedEventCarousel(events: _events, onEventTap: (_) {}),
      ));
      await tester.pump();

      expect(_page(tester), 0);
      expect(find.text('Seminar AI Nasional'), findsOneWidget);

      await tester.pump(FeaturedEventCarousel.autoAdvanceInterval);
      await tester.pumpAndSettle();

      expect(_page(tester), 1);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('berhenti auto-advance saat pengguna menyentuh carousel',
        (tester) async {
      await tester.pumpWidget(_harness(
        FeaturedEventCarousel(events: _events, onEventTap: (_) {}),
      ));
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await tester.pump(const Duration(seconds: 7));
      expect(_page(tester), 0);

      await gesture.up();
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('titik indikator dapat diketuk untuk pindah kartu',
        (tester) async {
      await tester.pumpWidget(_harness(
        FeaturedEventCarousel(events: _events, onEventTap: (_) {}),
      ));
      await tester.pump();

      // Tiga titik indikator berjejer di bawah carousel.
      final dots = find.byWidgetPredicate(
        (w) => w is AnimatedContainer && (w.decoration as BoxDecoration?) != null,
      );
      expect(dots, findsAtLeastNWidgets(3));

      await tester.tap(dots.at(dots.evaluate().length - 1));
      await tester.pumpAndSettle();
      expect(find.text('Music Fest Kampus'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
