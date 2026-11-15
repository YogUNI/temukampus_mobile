import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:temukampus_mobile/core/network/api_client.dart';
import 'package:temukampus_mobile/core/network/error_interceptor.dart';

/// Fixture JSON yang **direkam langsung dari API v1 sungguhan**
/// (`test/fixtures/api/*.json`), jadi tes memakai bentuk respons nyata —
/// bukan objek karangan yang bisa menyimpang dari backend.
Map<String, dynamic> apiFixture(String name) {
  final file = File('test/fixtures/api/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// Satu rute palsu: cocokkan metode + pola path, balas body JSON tertentu.
class FakeRoute {
  FakeRoute({
    required this.method,
    required this.path,
    required this.body,
    this.status = 200,
    this.query,
    this.bodyMatch,
  });

  final String method;

  /// String (harus sama persis) atau [RegExp] untuk path dinamis.
  final Pattern path;
  final Object body;
  final int status;

  /// Bila diisi, hanya cocok untuk query parameter ini.
  final Map<String, String>? query;

  /// Bila diisi, hanya cocok bila body permintaan memuat nilai-nilai ini
  /// (dipakai untuk membedakan kode tiket pada endpoint POST yang sama).
  final Map<String, Object?>? bodyMatch;

  bool matches(RequestOptions options) {
    if (options.method.toUpperCase() != method.toUpperCase()) return false;

    final ok = switch (path) {
      final String p => options.path == p,
      final RegExp p => p.hasMatch(options.path),
      _ => false,
    };
    if (!ok) return false;

    if (query != null) {
      for (final entry in query!.entries) {
        if (options.queryParameters[entry.key]?.toString() != entry.value) {
          return false;
        }
      }
    }

    if (bodyMatch != null) {
      final data = options.data;
      if (data is! Map) return false;

      for (final entry in bodyMatch!.entries) {
        if (data[entry.key]?.toString() != entry.value?.toString()) {
          return false;
        }
      }
    }

    return true;
  }

  ResponseBody toResponseBody() => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
}

/// Adapter Dio yang menggantikan jaringan: tidak ada koneksi keluar sama sekali.
class FakeApiAdapter implements HttpClientAdapter {
  FakeApiAdapter(this.routes);

  final List<FakeRoute> routes;

  /// Riwayat permintaan ("GET /tickets") untuk memverifikasi endpoint terpanggil.
  final List<String> requests = [];

  /// Riwayat permintaan **beserta query** ("GET /events?category=seminar").
  ///
  /// Dipisah dari [requests] supaya tes lama yang mencocokkan persis
  /// ("GET /events") tetap berlaku, sementara tes yang peduli pada filter
  /// (kategori, format, halaman) bisa memeriksa query-nya.
  final List<String> requestsWithQuery = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final query = options.queryParameters;

    requests.add('${options.method} ${options.path}');
    requestsWithQuery.add(
      query.isEmpty
          ? '${options.method} ${options.path}'
          : '${options.method} ${options.path}?'
              '${query.entries.map((e) => '${e.key}=${e.value}').join('&')}',
    );

    for (final route in routes) {
      if (route.matches(options)) return route.toResponseBody();
    }

    return ResponseBody.fromString(
      jsonEncode({
        'message': 'Rute palsu belum didaftarkan: ${options.method} ${options.path}',
      }),
      404,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// [ApiClient] dengan adapter palsu + [ErrorInterceptor] asli, sehingga
/// pemetaan galat 422/401 yang dipakai produksi tetap ikut diuji.
ApiClient fakeApiClient(FakeApiAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test/api/v1'))
    ..httpClientAdapter = adapter
    ..interceptors.add(ErrorInterceptor());

  return ApiClient(dio);
}
