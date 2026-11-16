import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/core/constants/env.dart';
import 'package:temukampus_mobile/core/network/media_url.dart';

/// URL media dari backend memakai host web (`temukampus.test`), sedangkan
/// aplikasi memanggil API di origin lain (10.0.2.2 / 127.0.0.1 / domain prod).
/// Resolver harus selalu menempelkan path ke origin API.
void main() {
  final api = Uri.parse(AppEnv.baseUrl);
  final origin = '${api.scheme}://${api.host}${api.hasPort ? ':${api.port}' : ''}';

  group('MediaUrl.resolve', () {
    test('null dan kosong menghasilkan null', () {
      expect(MediaUrl.resolve(null), isNull);
      expect(MediaUrl.resolve(''), isNull);
      expect(MediaUrl.resolve('   '), isNull);
    });

    test('path relatif ditempel ke origin API', () {
      expect(
        MediaUrl.resolve('/storage/avatars/a.png'),
        '$origin/storage/avatars/a.png',
      );
    });

    test('URL absolut ber-host web diganti ke origin API', () {
      expect(
        MediaUrl.resolve('http://temukampus.test/storage/posters/2026/x.webp'),
        '$origin/storage/posters/2026/x.webp',
      );
    });

    test('query string dipertahankan', () {
      expect(
        MediaUrl.resolve('https://contoh.ac.id/storage/a.png?v=2'),
        '$origin/storage/a.png?v=2',
      );
    });

    test('tidak menggandakan /api/v1 pada path', () {
      final resolved = MediaUrl.resolve('/storage/a.png')!;

      expect(resolved.contains('/api/v1'), isFalse);
    });
  });
}
