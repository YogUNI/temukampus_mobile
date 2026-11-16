import '../constants/env.dart';

/// Menyelaraskan URL media (avatar, poster, lampiran) dengan host API yang
/// benar-benar dipakai aplikasi.
///
/// Backend membentuk URL absolut dari `APP_URL` milik web (mis.
/// `http://temukampus.test/storage/...`). Di perangkat, host itu sering tidak
/// bisa dijangkau — emulator memakai `10.0.2.2`, HP memakai `127.0.0.1` lewat
/// `adb reverse`. Akibatnya gambar gagal dimuat dan avatar jatuh ke inisial.
///
/// Aturan: ambil path + query dari URL apa pun, lalu tempelkan pada origin API.
class MediaUrl {
  const MediaUrl._();

  static Uri get _api => Uri.parse(AppEnv.baseUrl);

  /// Mengembalikan URL siap-pakai, atau `null` bila kosong.
  static String? resolve(String? raw) {
    final value = raw?.trim();

    if (value == null || value.isEmpty) return null;

    final parsed = Uri.tryParse(value);

    if (parsed == null) return null;

    // Path relatif ("/storage/x.png") — cukup tempel ke origin API.
    if (!parsed.hasScheme) {
      return _api
          .replace(
            path: parsed.path,
            query: parsed.hasQuery ? parsed.query : null,
          )
          .toString();
    }

    // URL absolut: buang host/skema aslinya, pertahankan path & query.
    return _api
        .replace(
          path: parsed.path,
          query: parsed.hasQuery ? parsed.query : null,
        )
        .toString();
  }
}
