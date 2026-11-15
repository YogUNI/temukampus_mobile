import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/core/network/api_client.dart';
import 'package:temukampus_mobile/features/events/presentation/widgets/home_header.dart';
import 'package:temukampus_mobile/features/notifications/presentation/screens/notifications_screen.dart';

import 'helpers/fake_api.dart';

void main() {
  testWidgets('badge lonceng menampilkan jumlah belum dibaca', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeHeader(
            user: null,
            unreadCount: 3,
            onNotificationTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('badge disembunyikan saat tidak ada notifikasi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeHeader(user: null, unreadCount: 0, onNotificationTap: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0'), findsNothing);
  });

  testWidgets('layar notifikasi memuat daftar dari API', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = FakeApiAdapter([
      FakeRoute(
        method: 'GET',
        path: '/notifications',
        body: apiFixture('notifications_index.json'),
      ),
      FakeRoute(
        method: 'GET',
        path: '/notifications/unread-count',
        body: apiFixture('notifications_unread.json'),
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(fakeApiClient(adapter))],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pendaftaran terkonfirmasi'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Belum dibaca'), findsOneWidget);
    expect(adapter.requests, contains('GET /notifications'));
  });

  testWidgets('layar notifikasi menampilkan empty state saat kosong', (tester) async {
    final adapter = FakeApiAdapter([
      FakeRoute(
        method: 'GET',
        path: '/notifications',
        body: apiFixture('notifications_empty.json'),
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(fakeApiClient(adapter))],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada notifikasi'), findsOneWidget);
  });
}
