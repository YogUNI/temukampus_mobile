import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/features/notifications/data/datasources/push_registrar.dart';

import 'helpers/fake_api.dart';

/// Pendaftaran token perangkat untuk push (FCM).
///
/// Token disuntikkan lewat `tokenProvider` agar tes tidak butuh Firebase.
void main() {
  FakeApiAdapter buildAdapter() => FakeApiAdapter([
        FakeRoute(
          method: 'POST',
          path: '/devices',
          body: {'success': true, 'message': 'Perangkat terdaftar.', 'data': {'id': 1}},
          status: 201,
        ),
        FakeRoute(
          method: 'DELETE',
          path: '/devices',
          body: {'success': true, 'message': 'Perangkat berhenti menerima notifikasi.'},
        ),
      ]);

  test('mendaftarkan token perangkat ke POST /devices', () async {
    final adapter = buildAdapter();
    final registrar = PushRegistrar(
      fakeApiClient(adapter),
      tokenProvider: () async => 'fcm-token-uji',
    );

    await registrar.registerCurrentDevice();

    expect(adapter.requests, contains('POST /devices'));
  });

  test('tidak memanggil API bila token belum tersedia', () async {
    final adapter = buildAdapter();
    final registrar = PushRegistrar(
      fakeApiClient(adapter),
      tokenProvider: () async => null,
    );

    await registrar.registerCurrentDevice();

    expect(adapter.requests, isEmpty);
  });

  test('tidak mengirim ulang token yang sama dua kali', () async {
    final adapter = buildAdapter();
    final registrar = PushRegistrar(
      fakeApiClient(adapter),
      tokenProvider: () async => 'fcm-token-sama',
    );

    await registrar.registerCurrentDevice();
    await registrar.registerCurrentDevice();

    expect(adapter.requests.where((r) => r == 'POST /devices').length, equals(1));
  });

  test('menghapus token saat pengguna keluar', () async {
    final adapter = buildAdapter();
    final registrar = PushRegistrar(
      fakeApiClient(adapter),
      tokenProvider: () async => 'fcm-token-keluar',
    );

    await registrar.registerCurrentDevice();
    await registrar.unregisterCurrentDevice();

    expect(adapter.requests, contains('DELETE /devices'));
  });
}
