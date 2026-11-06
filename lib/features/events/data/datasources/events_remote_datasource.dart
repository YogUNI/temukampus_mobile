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
    EventFilterModel? filterModel,
    String? search,
    String? category,
    String? format,
    String? tag,
    bool? suitableForMe,
    int page = 1,
  }) async {
    try {
      final queryParams = filterModel?.toQueryParams() ??
          <String, dynamic>{
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
      return _getMockEvents(
        search: filterModel?.searchQuery ?? search,
        category: filterModel?.categorySlug ?? category,
        format: filterModel?.format ?? format,
        suitableForMe: filterModel?.suitableForMeOnly ?? suitableForMe,
      );
    } on AppException {
      rethrow;
    } catch (_) {
      return _getMockEvents(
        search: filterModel?.searchQuery ?? search,
        category: filterModel?.categorySlug ?? category,
        format: filterModel?.format ?? format,
        suitableForMe: filterModel?.suitableForMeOnly ?? suitableForMe,
      );
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
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.categories);
      final rawList = response.data?['data'] as List<dynamic>? ?? [];
      return rawList.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _mockCategories;
    }
  }

  // === Mock Acara Realistis Kampus UMB ===

  static final List<CategoryModel> _mockCategories = const [
    CategoryModel(id: 1, name: 'Semua Kategori', slug: 'all', iconName: 'grid_view'),
    CategoryModel(id: 2, name: 'Teknologi & Komputer', slug: 'teknologi', iconName: 'memory'),
    CategoryModel(id: 3, name: 'Akademik & Seminar', slug: 'akademik', iconName: 'school'),
    CategoryModel(id: 4, name: 'Seni & Budaya', slug: 'seni-budaya', iconName: 'palette'),
    CategoryModel(id: 5, name: 'Kompetisi & Lomba', slug: 'lomba', iconName: 'emoji_events'),
    CategoryModel(id: 6, name: 'Pengembangan Diri', slug: 'soft-skills', iconName: 'psychology'),
  ];

  static List<EventModel> _getMockEvents({
    String? search,
    String? category,
    String? format,
    bool? suitableForMe,
  }) {
    var list = [
      // 1. Seminar Nasional AI 2026 (Fasilkom UMB, Hybrid, Berbayar Rp 25.000, SKP 2 Poin, Sisa 5 Tiket)
      EventModel(
        id: 1,
        title: 'Seminar Nasional: Masa Depan Artificial Intelligence di Indonesia',
        slug: 'seminar-nasional-ai-2026',
        summary: 'Membahas model fondasi AI terkini dan dampaknya pada industri teknologi bersama pakar nasional.',
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
        format: 'hybrid',
        startAt: DateTime(2026, 11, 20, 9, 0),
        endAt: DateTime(2026, 11, 20, 12, 30),
        location: 'Auditorium Tower Lt. 7 Kampus Meruya & Zoom Meeting',
        isPaid: true,
        price: 25000,
        formattedPrice: 'Rp 25.000',
        skpPoints: 2,
        hasCertificate: true,
        audience: 'restricted',
        restrictions: const EventRestrictions(
          allowedFaculties: ['Fakultas Ilmu Komputer'],
          allowedPrograms: ['Teknik Informatika', 'Sistem Informasi'],
          cohortMin: 2022,
          cohortMax: 2026,
        ),
        quota: 200,
        remainingQuota: 5, // Sisa 5 Tiket (kuota menipis)
        registeredCount: 195,
        isFull: false,
        organization: const EventOrganizationModel(
          id: 1,
          name: 'HIMA Teknik Informatika UMB',
          slug: 'hima-ti',
        ),
        category: 'teknologi',
        bankName: 'Bank Central Asia (BCA)',
        bankAccountNumber: '5410982311',
        bankAccountName: 'HIMA TEKNIK INFORMATIKA UMB',
        qrisImageUrl: null,
      ),

      // 2. Workshop Cyber Security: Penetration Testing (HIMA TI, Offline Auditorium, Gratis, Khusus TI)
      EventModel(
        id: 2,
        title: 'Workshop Cyber Security: Hands-on Penetration Testing & Ethical Hacking',
        slug: 'workshop-cyber-security-pentest',
        summary: 'Praktik langsung menemukan celah kerentanan aplikasi web dan hardening sistem keamanan.',
        description: '''
## Workshop Praktik Keamanan Siber
Workshop intensif mempelajari teknik simulasi serangan siber pada sistem aplikasi berbasis web serta langkah mitigasi pencegahan insiden kebocoran data.

### Agenda Pelatihan:
1. Reconnaissance & Vulnerability Assessment
2. SQL Injection & Cross-Site Scripting (XSS) Exploitation
3. Web Application Firewall (WAF) Hardening

> Peserta wajib membawa laptop dengan RAM minimal 8 GB yang telah terpasang Kali Linux (VirtualBox/WSL).
''',
        format: 'offline',
        startAt: DateTime(2026, 11, 22, 13, 0),
        endAt: DateTime(2026, 11, 22, 17, 0),
        location: 'Auditorium Tower Lt. 7 Kampus Meruya',
        isPaid: false,
        price: 0,
        formattedPrice: 'Gratis',
        skpPoints: 1,
        hasCertificate: true,
        audience: 'restricted',
        restrictions: const EventRestrictions(
          allowedPrograms: ['Teknik Informatika'],
          cohortMin: 2022,
          cohortMax: 2026,
        ),
        quota: 50,
        remainingQuota: 18,
        registeredCount: 32,
        isFull: false,
        organization: const EventOrganizationModel(
          id: 1,
          name: 'HIMA Teknik Informatika UMB',
          slug: 'hima-ti',
        ),
        category: 'teknologi',
      ),

      // 3. Festival Seni & Musik Kampus Meruya (BEM UMB, Terbuka untuk Umum, Tiket Sisa Banyak)
      EventModel(
        id: 3,
        title: 'Festival Seni & Musik Kampus Meruya 2026',
        slug: 'festival-seni-musik-meruya-2026',
        summary: 'Pesta kreasi mahasiswa UMB dengan penampilan band akustik kampus, bazaar kuliner, dan art exhibition.',
        description: '''
## Pesta Budaya & Apresiasi Karya Seni Mahasiswa
Ajang tahunan festival kampus menghadirkan pertunjukan musik akustik, pameran seni instalasi visual, serta puluhan booth kuliner mahasiswa.
''',
        format: 'offline',
        startAt: DateTime(2026, 12, 12, 14, 0),
        endAt: DateTime(2026, 12, 12, 22, 0),
        location: 'Plaza Utama Kampus Meruya UMB',
        isPaid: false,
        price: 0,
        formattedPrice: 'Gratis',
        skpPoints: 0,
        hasCertificate: false,
        audience: 'public',
        quota: 500,
        remainingQuota: 380, // Sisa banyak
        registeredCount: 120,
        isFull: false,
        organization: const EventOrganizationModel(
          id: 2,
          name: 'BEM Universitas Mercu Buana',
          slug: 'bem-umb',
        ),
        category: 'seni-budaya',
      ),

      // 4. Pelatihan Public Speaking & Leadership (UKM Protokoler, Online Zoom, SKP 1 Poin)
      EventModel(
        id: 4,
        title: 'Pelatihan Public Speaking: Berbicara Lugas & Memukau di Depan Publik',
        slug: 'pelatihan-public-speaking-leadership',
        summary: 'Mengembangkan rasa percaya diri saat presentasi akademik dan kepemimpinan organisasi kemahasiswaan.',
        description: '''
## Kembangkan Kemampuan Komunikasi & Kepemimpinan
Pelatihan interaktif bagi mahasiswa yang ingin mengasah kemampuan berbicara persuasif di forum resmi, sidang tugas akhir, maupun organisasi kampus.
''',
        format: 'online',
        startAt: DateTime(2026, 11, 28, 10, 0),
        endAt: DateTime(2026, 11, 28, 12, 30),
        location: 'Zoom Meeting Room TemuKampus',
        isPaid: false,
        price: 0,
        formattedPrice: 'Gratis',
        skpPoints: 1,
        hasCertificate: true,
        audience: 'umb_only',
        quota: 150,
        remainingQuota: 45,
        registeredCount: 105,
        isFull: false,
        organization: const EventOrganizationModel(
          id: 4,
          name: 'UKM Protokoler UMB',
          slug: 'ukm-protokoler',
        ),
        category: 'soft-skills',
      ),

      // 5. Mercu Buana UI/UX Design Competition 2026 (BEM Fasilkom UMB, Online, Berbayar Rp 15.000, SKP 3 Poin)
      EventModel(
        id: 5,
        title: 'Mercu Buana UI/UX Design Competition 2026',
        slug: 'mercu-buana-uiux-competition',
        summary: 'Ajang kreasi mahasiswa dalam memecahkan masalah kemahasiswaan dengan desain antarmuka modern.',
        description: '''
## Kompetisi Desain Antarmuka Tingkat Universitas
Tantang kemampuan riset UX dan visual UI Anda dalam merancang solusi digital ramah pengguna. Pemenang mendapatkan uang pembinaan dan sertifikat penghargaan berbobot 3 SKP.
''',
        format: 'online',
        startAt: DateTime(2026, 12, 1, 8, 30),
        endAt: DateTime(2026, 12, 1, 16, 0),
        location: 'Online via Discord & Google Meet',
        isPaid: true,
        price: 15000,
        formattedPrice: 'Rp 15.000',
        skpPoints: 3,
        hasCertificate: true,
        audience: 'public',
        quota: 100,
        remainingQuota: 32,
        registeredCount: 68,
        isFull: false,
        organization: const EventOrganizationModel(
          id: 3,
          name: 'BEM Fasilkom UMB',
          slug: 'bem-fasilkom',
        ),
        category: 'lomba',
        bankName: 'Bank Mandiri',
        bankAccountNumber: '1230009876543',
        bankAccountName: 'BEM FASILKOM UMB',
      ),

      // 6. Kuliah Tamu Technopreneur: Merintis Startup Kampus dari Nol (Pusat Kewirausahaan UMB, Offline, Kuota Penuh)
      EventModel(
        id: 6,
        title: 'Kuliah Tamu Technopreneur: Merintis Startup Kampus dari Nol',
        slug: 'kuliah-tamu-technopreneur',
        summary: 'Sharing session bersama alumni pendiri tech startup tentang validasi produk dan pendanaan awal.',
        description: '''
## Membangun Produk Digital Dari Kampus
Belajar langsung dari pengalaman nyata para founders alumni UMB dalam menavigasi tahap product-market fit dan program inkubasi bisnis.
''',
        format: 'offline',
        startAt: DateTime(2026, 12, 5, 10, 0),
        endAt: DateTime(2026, 12, 5, 12, 0),
        location: 'Ruang Seminar Utama Tower Lt. 2 Kampus Meruya',
        isPaid: false,
        price: 0,
        formattedPrice: 'Gratis',
        skpPoints: 1,
        hasCertificate: true,
        audience: 'restricted',
        restrictions: const EventRestrictions(
          cohortMin: 2021,
          cohortMax: 2026,
        ),
        quota: 150,
        remainingQuota: 0,
        registeredCount: 150,
        isFull: true, // Kuota Penuh
        organization: const EventOrganizationModel(
          id: 5,
          name: 'Pusat Kewirausahaan UMB',
          slug: 'inkubator-bisnis',
        ),
        category: 'akademik',
      ),
    ];

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list.where((e) =>
          e.title.toLowerCase().contains(q) ||
          e.organization.name.toLowerCase().contains(q) ||
          e.summary.toLowerCase().contains(q)).toList();
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
      terms: '''
1. Peserta wajib hadir tepat waktu 15 menit sebelum acara dimulai.
2. Membawa tiket digital ber-QR code pada aplikasi TemuKampus untuk proses presensi check-in di pintu masuk.
3. Berpakaian sopan dan rapi (kemeja/berkerah dan bersepatu).
''',
      hasUserRegistered: false,
    );
  }
}
