import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/app/shell/main_scaffold.dart';
import 'package:temukampus_mobile/app/theme/app_spacing.dart';
import 'package:temukampus_mobile/features/events/data/models/event_model.dart';
import 'package:temukampus_mobile/features/events/presentation/widgets/event_grid_card.dart';
import 'package:temukampus_mobile/features/events/presentation/widgets/event_grid_metrics.dart';

/// Geometri yang diukur: kartu grid tidak boleh overflow di lebar HP mana pun
/// (360–430dp) dan dock navigasi harus kapsul 64pt dengan target sentuh >= 44pt.
EventModel _event({
  String title = 'Seminar Nasional Artificial Intelligence untuk Mahasiswa UMB',
  int price = 25000,
  int skpPoints = 4,
  int registered = 95,
}) {
  return EventModel.fromJson({
    'id': 1,
    'title': title,
    'slug': 'seminar-ai',
    'start_at': '2026-12-01T09:00:00Z',
    'location': 'Auditorium UMB',
    'price': price,
    'skp_points': skpPoints,
    'quota': 100,
    'registered_count': registered,
    'format': 'offline',
    'audience': 'umb_only',
    'status': 'published',
    'poster_url': 'assets/images/posters/poster_ai_seminar.jpg',
    'organization': {'id': 1, 'name': 'BEM Fakultas Teknik'},
  });
}

void main() {
  group('EventGridCard layout', () {
    for (final width in [360.0, 375.0, 390.0, 412.0, 430.0]) {
      testWidgets('tidak overflow & rasio poster 4:5 pada ${width.toInt()}dp',
          (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const gutter = AppSpacing.gutter;
        final gridWidth = width - gutter * 2;
        final expectedTile = EventGridMetrics.tileWidth(gridWidth);
        final expectedHeight = EventGridMetrics.tileHeight(gridWidth);

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: gutter),
              child: GridView.builder(
                gridDelegate: EventGridMetrics.delegate(gridWidth),
                itemCount: 2,
                itemBuilder: (context, index) => EventGridCard(
                  event: _event(),
                  onTap: () {},
                ),
              ),
            ),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull,
            reason: 'kartu grid overflow pada lebar ${width.toInt()}dp');

        final cardRect = tester.getRect(find.byType(EventGridCard).first);
        expect(cardRect.width, moreOrLessEquals(expectedTile, epsilon: 0.5));
        expect(cardRect.height, moreOrLessEquals(expectedHeight, epsilon: 0.5));

        final posterRect = tester.getRect(
          find.descendant(
            of: find.byType(EventGridCard).first,
            matching: find.byType(AspectRatio),
          ),
        );
        // 4:5 portrait — sama dengan rasio master poster backend (1080×1350),
        // supaya poster tidak terpotong di grid.
        expect(
          posterRect.height / posterRect.width,
          moreOrLessEquals(1 / EventGridMetrics.posterAspectRatio, epsilon: 0.01),
        );
        expect(EventGridMetrics.posterAspectRatio, moreOrLessEquals(0.8));
      });
    }

    testWidgets('judul sangat panjang & kuota tipis tetap tidak overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const gridWidth = 360.0 - AppSpacing.gutter * 2;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: GridView.builder(
              gridDelegate: EventGridMetrics.delegate(gridWidth),
              itemCount: 1,
              itemBuilder: (context, index) => EventGridCard(
                event: _event(
                  title: 'Workshop UI/UX Design Sprint untuk Mahasiswa Semester '
                      'Awal Program Studi Teknik Informatika Fakultas Teknik UMB',
                  registered: 100,
                ),
                onTap: () {},
              ),
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });

  group('FloatingNavDock', () {
    testWidgets('kapsul 64pt, inset 16pt, target sentuh >= 44pt',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var tapped = -1;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: FloatingNavDock(
            selectedIndex: 1,
            onIndexChanged: (index) => tapped = index,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final dockRect = tester.getRect(find.byKey(const ValueKey('nav_dock')));
      expect(dockRect.height, 64);
      expect(dockRect.left, AppSpacing.lg);
      expect(dockRect.right, 390 - AppSpacing.lg);
      expect(844 - dockRect.bottom, AppSpacing.md);

      for (final label in ['Beranda', 'Jelajah', 'Tiket Saya', 'Profil']) {
        final rect = tester.getRect(
          find.byKey(ValueKey('nav_dock_item_$label')),
        );
        expect(rect.height, greaterThanOrEqualTo(44),
            reason: 'target sentuh $label terlalu kecil');
        expect(rect.width, greaterThanOrEqualTo(44),
            reason: 'target sentuh $label terlalu kecil');
      }

      await tester.tap(find.byKey(const ValueKey('nav_dock_item_Tiket Saya')));
      expect(tapped, 2);
    });
  });
}
