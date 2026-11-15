import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temukampus_mobile/core/services/notification_service.dart';
import 'package:temukampus_mobile/features/notifications/presentation/providers/notification_permission_provider.dart';
import 'package:temukampus_mobile/features/notifications/presentation/widgets/notification_permission_prompt.dart';

/// Izin notifikasi: alur pre-prompt → dialog sistem → pilihan disimpan.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationPermissionNotifier', () {
    test('awalnya belum pernah ditanya', () async {
      final notifier = NotificationPermissionNotifier();
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.asked, isFalse);
      expect(notifier.state.granted, isFalse);
    });

    test('pilihan "Nanti" disimpan dan tidak menanyakan lagi', () async {
      final notifier = NotificationPermissionNotifier();
      await Future<void>.delayed(Duration.zero);

      await notifier.decline();

      expect(notifier.state.asked, isTrue);
      expect(notifier.state.granted, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('tk_notification_asked'), isTrue);

      // Instance baru membaca pilihan tersimpan.
      final reloaded = NotificationPermissionNotifier();
      await Future<void>.delayed(Duration.zero);
      expect(reloaded.state.asked, isTrue);
    });

    test('status izin tersimpan di penyimpanan lokal', () async {
      expect(await NotificationService.instance.hasPermission(), isFalse);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tk_notification_permission', true);

      expect(await NotificationService.instance.hasPermission(), isTrue);
    });
  });

  group('NotificationPermissionPrompt', () {
    testWidgets('menampilkan penjelasan sebelum izin sistem', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: NotificationPermissionPrompt())),
        ),
      );

      // Prompt muncul setelah jeda singkat agar beranda sempat tampil.
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      expect(find.text('Jangan Ketinggalan Kabar Kampus'), findsOneWidget);
      expect(find.text('Aktifkan Notifikasi'), findsOneWidget);
      expect(find.text('Nanti saja'), findsOneWidget);
    });

    testWidgets('tombol "Nanti saja" menutup sheet dan menyimpan pilihan', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: NotificationPermissionPrompt())),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nanti saja'));
      await tester.pumpAndSettle();

      expect(find.text('Jangan Ketinggalan Kabar Kampus'), findsNothing);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('tk_notification_asked'), isTrue);
    });
  });
}
