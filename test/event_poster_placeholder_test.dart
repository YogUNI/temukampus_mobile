import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/features/events/data/models/event_model.dart';
import 'package:temukampus_mobile/features/events/presentation/widgets/event_grid_card.dart';
import 'package:temukampus_mobile/shared/widgets/event_poster_placeholder.dart';

/// Data nyata dari API sering **belum punya poster** (berbeda dari data contoh
/// yang selalu bergambar). Kartu wajib tetap tampil rapi, bukan kotak kosong.
void main() {
  Map<String, dynamic> eventJson() {
    final raw = jsonDecode(
      File('test/fixtures/api/events_index.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    return (raw['data'] as List<dynamic>).first as Map<String, dynamic>;
  }

  testWidgets('kartu acara tanpa poster memakai placeholder ber-brand', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final event = EventModel.fromJson(eventJson());
    expect(event.posterUrl, isNull, reason: 'fixture acara demo memang tanpa poster');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 169,
            child: EventGridCard(event: event, onTap: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EventPosterPlaceholder), findsOneWidget);
    expect(find.text(event.title), findsOneWidget);
    // Ada ikon & label kategori di dalam placeholder (bukan kotak kosong).
    expect(find.byType(Icon), findsWidgets);
    expect(find.text((event.category ?? 'Acara Kampus').toUpperCase()), findsOneWidget);
  });

  testWidgets('placeholder memakai ikon kategori yang sesuai', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            height: 200,
            child: EventPosterPlaceholder(
              categorySlug: 'workshop',
              categoryName: 'Workshop',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.build_circle_rounded), findsOneWidget);
    expect(find.text('WORKSHOP'), findsOneWidget);
  });
}
