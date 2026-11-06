import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/event_model.dart';

final eventsRemoteDataSourceProvider = Provider<EventsRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EventsRemoteDataSource(apiClient);
});

class EventsRemoteDataSource {
  final ApiClient _apiClient;

  EventsRemoteDataSource(this._apiClient);

  /// Mengambil daftar acara di katalog / beranda dengan filter
  Future<List<EventModel>> getEvents({
    String? search,
    String? category,
    String? format,
    String? tag,
    bool? suitableForMe,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        if (format != null && format.isNotEmpty) 'format': format,
        if (tag != null && tag.isNotEmpty) 'tag': tag,
        if (suitableForMe == true) 'suitable_for_me': 1,
      };

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.events,
        queryParameters: queryParams,
      );

      final rawList = response.data?['data'] as List<dynamic>? ?? [];
      return rawList.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
    } on NetworkException {
      return _getMockEvents(search: search, category: category, format: format, suitableForMe: suitableForMe);
    } on AppException {
      rethrow;
    } catch (_) {
      return _getMockEvents(search: search, category: category, format: format, suitableForMe: suitableForMe);
    }
  }

  /// Mengambil detail acara lengkap berdasarkan slug
  Future<EventDetailModel> getEventDetail(String slug) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.eventDetail(slug),
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return EventDetailModel.fromJson(data);
    } on NetworkException {
      return _getMockEventDetail(slug);
    } on AppException {
      rethrow;
    } catch (_) {
      return _getMockEventDetail(slug);
    }
  }

  /// Memeriksa kelayakan pendaftaran mahasiswa untuk acara tertentu
  Future<EligibilityResultModel> checkEligibility(String slug) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.eventEligibility(slug),
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return EligibilityResultModel.fromJson(data);
    } catch (_) {
      // Mock Fallback Eligibility
      return const EligibilityResultModel(
        isEligible: true,
        reasons: [],
        ctaState: EventCtaState.canRegister,
        ctaLabel: 'Daftar Sekarang',
        hasActiveTicket: false,
      );
    }
  }

  /// Mengambil daftar kategori acara
  Future<List<EventCategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.categories);
      final rawList = response.data?['data'] as List<dynamic>? ?? [];
      return rawList.map((e) => EventCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _mockCategories;
    }
  }

  // === Mock Acara Realistis Kampus UMB ===

  static final List<EventCategoryModel> _mockCategories = const [
    EventCategoryModel(id: 1, name: 'Semua Kategori', slug: 'all', icon: 'grid_view'),
    EventCategoryModel(id: 2, name: 'Teknologi & Komputer', slug: 'teknologi', icon: 'memory'),
    EventCategoryModel(id: 3, name: 'Akademik & Seminar', slug: 'akademik', icon: 'school'),
    EventCategoryModel(id: 4, name: 'Seni & Budaya', slug: 'seni-budaya', icon: 'palette'),
    EventCategoryModel(id: 5, name: 'Kompetisi & Lomba', slug: 'lomba', icon: 'emoji_events'),
  ];

  static List<EventModel> _getMockEvents({
    String? search,
    String? category,
    String? format,
    bool? suitableForMe,
  }) {
    var list = [
      EventModel(
        id: 1,
        title: 'Seminar Nasional: Masa Depan Artificial Intelligence di Indonesia',
        slug: 'seminar-nasional-ai-2026',
        summary: 'Membahas model fondasi AI terkini dan dampaknya pada industri teknologi bersama pakar nasional.',
        format: 'hybrid',
        startAt: DateTime(2026, 11, 20, 9, 0),
        endAt: DateTime(2026, 11, 20, 12, 30),
        location: 'Auditorium Tower Lt. 7 Kampus Meruya & Zoom Meeting',
        isPaid: true,
        price: 25000,
        formattedPrice: 'Rp 25.000',
        skpPoints: 2,
        hasCertificate: true,
        audience: 'public',
        quota: 200,
        remainingQuota: 48,
        isFull: false,
        organization: const EventOrganizationModel(
          id: 1,
          name: 'HIMA Teknik Informatika UMB',
          slug: 'hima-ti',
        ),
        category: 'teknologi',
      ),
      EventModel(
        id: 2,
        title: 'Workshop Flutter 3.24 & Clean Architecture untuk Mahasiswa',
        slug: 'workshop-flutter-clean-architecture',
        summary: 'Membangun aplikasi mobile production-ready dengan Riverpod, Dio, dan Clean Architecture.',
        format: 'offline',
        startAt: DateTime(2026, 11, 23, 13, 0),
        endAt: DateTime(2026, 11, 23, 17, 0),
        location: 'Lab Komputer Gedung B Lt. 3 Kampus Meruya',
        isPaid: false,
        price: 0,
        formattedPrice: 'Gratis',
        skpPoints: 1,
        hasCertificate: true,
        audience: 'umb_only',
        quota: 40,
        remainingQuota: 5, // Sisa sedikit (kuota menipis)
        isFull: false,
        organization: const EventOrganizationModel(
          id: 2,
          name: 'UKM Computer Club UMB',
          slug: 'computer-club',
        ),
        category: 'teknologi',
      ),
      EventModel(
        id: 3,
        title: 'Mercu Buana UI/UX Design Competition 2026',
        slug: 'mercu-buana-uiux-competition',
        summary: 'Ajang kreasi mahasiswa dalam memecahkan masalah kemahasiswaan dengan desain antarmuka modern.',
        format: 'online',
        startAt: DateTime(2026, 11, 26, 8, 30),
        endAt: DateTime(2026, 11, 26, 16, 0),
        location: 'Online via Discord & Google Meet',
        isPaid: true,
        price: 15000,
        formattedPrice: 'Rp 15.000',
        skpPoints: 3,
        hasCertificate: true,
        audience: 'public',
        quota: 100,
        remainingQuota: 32,
        isFull: false,
        organization: const EventOrganizationModel(
          id: 3,
          name: 'BEM Fasilkom UMB',
          slug: 'bem-fasilkom',
        ),
        category: 'lomba',
      ),
      EventModel(
        id: 4,
        title: 'Kuliah Tamu Technopreneur: Merintis Startup Kampus dari Nol',
        slug: 'kuliah-tamu-technopreneur',
        summary: 'Sharing session bersama alumni pendiri tech startup tentang validasi produk dan pendanaan awal.',
        format: 'offline',
        startAt: DateTime(2026, 11, 30, 10, 0),
        endAt: DateTime(2026, 11, 30, 12, 0),
        location: 'Ruang Seminar Utama Tower Lt. 2 Kampus Meruya',
        isPaid: false,
        price: 0,
        formattedPrice: 'Gratis',
        skpPoints: 1,
        hasCertificate: true,
        audience: 'restricted',
        quota: 150,
        remainingQuota: 0,
        isFull: true, // Kuota Penuh
        organization: const EventOrganizationModel(
          id: 4,
          name: 'Pusat Kewirausahaan UMB',
          slug: 'inkubator-bisnis',
        ),
        category: 'akademik',
      ),
      EventModel(
        id: 5,
        title: 'Pekan Raya & Gelar Budaya Mercu Buana 2026',
        slug: 'pekan-raya-budaya-umb-2026',
        summary: 'Pameran kreasi seni mahasiswa, pertunjukan musik akustik, dan bazaar kuliner UMKM kampus.',
        format: 'offline',
        startAt: DateTime(2026, 12, 5, 9, 0),
        endAt: DateTime(2026, 12, 5, 21, 0),
        location: 'Plaza Utama Kampus Meruya UMB',
        isPaid: false,
        price: 0,
        formattedPrice: 'Gratis',
        skpPoints: 0,
        hasCertificate: false,
        audience: 'public',
        quota: null, // Kuota tak terbatas
        remainingQuota: null,
        isFull: false,
        organization: const EventOrganizationModel(
          id: 5,
          name: 'BEM Universitas Mercu Buana',
          slug: 'bem-umb',
        ),
        category: 'seni-budaya',
      ),
    ];

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list.where((e) => e.title.toLowerCase().contains(q) || e.organization.name.toLowerCase().contains(q)).toList();
    }

    if (category != null && category != 'all' && category.isNotEmpty) {
      list = list.where((e) => e.category == category).toList();
    }

    if (format != null && format.isNotEmpty) {
      list = list.where((e) => e.format == format).toList();
    }

    return list;
  }

  static EventDetailModel _getMockEventDetail(String slug) {
    final events = _getMockEvents();
    final event = events.firstWhere(
      (e) => e.slug == slug,
      orElse: () => events.first,
    );

    return EventDetailModel(
      event: event,
      description: '''
## Deskripsi Kegiatan

Perkembangan **Artificial Intelligence (AI)** dan *Large Language Models (LLM)* telah mengubah lanskap industri teknologi dunia secara masif. Seminar Nasional ini menghadirkan para ahli industri dan akademisi terkemuka untuk membahas arah perkembangan teknologi cerdas di Indonesia.

### Materi Utama yang Akan Dibahas:
1. **Generative AI & Agentic Workflows:** Bagaimana AI bertransformasi dari sekadar alat tanya-jawab menjadi agen otomatis mandiri.
2. **Kesiapan Talenta Digital Kampus:** Keterampilan praktis yang wajib dimiliki mahasiswa Fasilkom untuk bersaing di era otomatisasi.
3. **Etika & Tata Kelola AI:** Menghadapi tantangan privasi data dan keamanan sistem cerdas.

---

### Pembicara Terkemuka:
- **Dr. Ir. Hendra Prasetya, M.Kom.** — Dosen Senior & Peneliti Kecerdasan Buatan UMB.
- **Rizky Pratama, S.Kom.** — Senior Machine Learning Engineer di Tech Unicorn Jakarta.

---

### Fasilitas yang Didapatkan Peserta:
- E-Sertifikat resmi bertanda tangan Dekan & Ketua HIMA.
- Angka Kredit SKP/SKPI (2 Poin untuk Mahasiswa UMB).
- Akses rekaman materi dan slide presentasi pembicara.
- Snack box dan merchandise stiker eksklusif bagi peserta luring (*offline*).
''',
      terms: '''
1. Peserta wajib hadir tepat waktu 15 menit sebelum acara dimulai.
2. Membawa tiket digital ber-QR code pada aplikasi TemuKampus untuk proses presensi check-in di pintu masuk.
3. Berpakaian sopan dan rapi (kemeja/berkerah dan bersepatu).
''',
      bankName: 'BCA (Bank Central Asia)',
      bankAccountNumber: '5220394812',
      bankAccountName: 'HIMA TEKNIK INFORMATIKA UMB',
      qrisUrl: null,
      hasUniqueCode: true,
      allowedFaculties: ['Fakultas Ilmu Komputer', 'Fakultas Teknik'],
      allowedStudyPrograms: ['Teknik Informatika', 'Sistem Informasi'],
      minCohortYear: 2021,
      maxCohortYear: 2026,
      hasUserRegistered: false,
    );
  }
}
