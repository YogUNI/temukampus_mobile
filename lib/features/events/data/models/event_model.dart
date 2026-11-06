/// Model Organisasi Penyelenggara Acara di Kampus UMB.
class EventOrganizationModel {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;

  const EventOrganizationModel({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
  });

  factory EventOrganizationModel.fromJson(Map<String, dynamic> json) {
    return EventOrganizationModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'logo_url': logoUrl,
    };
  }
}

/// Model Kategori Acara (Akademik, Teknologi, Seni & Budaya, dll).
class EventCategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? icon;

  const EventCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory EventCategoryModel.fromJson(Map<String, dynamic> json) {
    return EventCategoryModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon': icon,
    };
  }
}

/// Model Kartu Acara di Katalog & Beranda TemuKampus.
class EventModel {
  final int id;
  final String title;
  final String slug;
  final String summary;
  final String? posterUrl;
  final String format; // 'offline', 'online', 'hybrid'
  final DateTime startAt;
  final DateTime endAt;
  final String location;
  final bool isPaid;
  final int price;
  final String formattedPrice;
  final int skpPoints;
  final bool hasCertificate;
  final String audience; // 'public', 'umb_only', 'restricted'
  final int? quota;
  final int? remainingQuota;
  final bool isFull;
  final EventOrganizationModel organization;
  final String? category;

  const EventModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.summary,
    this.posterUrl,
    this.format = 'offline',
    required this.startAt,
    required this.endAt,
    required this.location,
    this.isPaid = false,
    this.price = 0,
    required this.formattedPrice,
    this.skpPoints = 0,
    this.hasCertificate = false,
    this.audience = 'public',
    this.quota,
    this.remainingQuota,
    this.isFull = false,
    required this.organization,
    this.category,
  });

  bool get isFree => !isPaid || price == 0;
  bool get hasSkp => skpPoints > 0;
  bool get isQuotaAlmostFull => remainingQuota != null && remainingQuota! <= 10 && remainingQuota! > 0;

  String get formatLabel {
    switch (format.toLowerCase()) {
      case 'online':
        return 'Daring (Online)';
      case 'hybrid':
        return 'Hybrid (Tatap Muka & Daring)';
      case 'offline':
      default:
        return 'Tatap Muka (Offline)';
    }
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      posterUrl: json['poster_url'] as String?,
      format: json['format'] as String? ?? 'offline',
      startAt: json['start_at'] != null
          ? DateTime.parse(json['start_at'] as String)
          : DateTime.now(),
      endAt: json['end_at'] != null
          ? DateTime.parse(json['end_at'] as String)
          : DateTime.now().add(const Duration(hours: 3)),
      location: json['location'] as String? ?? 'Kampus Meruya UMB',
      isPaid: json['is_paid'] as bool? ?? false,
      price: json['price'] as int? ?? 0,
      formattedPrice: json['formatted_price'] as String? ?? (json['is_paid'] == true ? 'Rp ${json['price']}' : 'Gratis'),
      skpPoints: json['skp_points'] as int? ?? 0,
      hasCertificate: json['has_certificate'] as bool? ?? false,
      audience: json['audience'] as String? ?? 'public',
      quota: json['quota'] as int?,
      remainingQuota: json['remaining_quota'] as int?,
      isFull: json['is_full'] as bool? ?? false,
      organization: EventOrganizationModel.fromJson(
        json['organization'] as Map<String, dynamic>? ?? {},
      ),
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'summary': summary,
      'poster_url': posterUrl,
      'format': format,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'location': location,
      'is_paid': isPaid,
      'price': price,
      'formatted_price': formattedPrice,
      'skp_points': skpPoints,
      'has_certificate': hasCertificate,
      'audience': audience,
      'quota': quota,
      'remaining_quota': remainingQuota,
      'is_full': isFull,
      'organization': organization.toJson(),
      'category': category,
    };
  }
}

/// Model Detail Acara Lengkap (Deskripsi Markdown, Info Bank/QRIS, Syarat Prodi/Angkatan).
class EventDetailModel {
  final EventModel event;
  final String description;
  final String? terms;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? qrisUrl;
  final bool hasUniqueCode;
  final List<String> allowedFaculties;
  final List<String> allowedStudyPrograms;
  final int? minCohortYear;
  final int? maxCohortYear;
  final DateTime? registrationOpenAt;
  final DateTime? registrationCloseAt;
  final bool hasUserRegistered;
  final String? userRegistrationStatus;
  final String? userTicketCode;

  const EventDetailModel({
    required this.event,
    required this.description,
    this.terms,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.qrisUrl,
    this.hasUniqueCode = true,
    this.allowedFaculties = const [],
    this.allowedStudyPrograms = const [],
    this.minCohortYear,
    this.maxCohortYear,
    this.registrationOpenAt,
    this.registrationCloseAt,
    this.hasUserRegistered = false,
    this.userRegistrationStatus,
    this.userTicketCode,
  });

  factory EventDetailModel.fromJson(Map<String, dynamic> json) {
    final event = EventModel.fromJson(json);

    return EventDetailModel(
      event: event,
      description: json['description'] as String? ?? event.summary,
      terms: json['terms'] as String?,
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      qrisUrl: json['qris_url'] as String?,
      hasUniqueCode: json['has_unique_code'] as bool? ?? true,
      allowedFaculties: (json['allowed_faculties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      allowedStudyPrograms: (json['allowed_study_programs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      minCohortYear: json['min_cohort_year'] as int?,
      maxCohortYear: json['max_cohort_year'] as int?,
      registrationOpenAt: json['registration_open_at'] != null
          ? DateTime.parse(json['registration_open_at'] as String)
          : null,
      registrationCloseAt: json['registration_close_at'] != null
          ? DateTime.parse(json['registration_close_at'] as String)
          : null,
      hasUserRegistered: json['has_user_registered'] as bool? ?? false,
      userRegistrationStatus: json['user_registration_status'] as String?,
      userTicketCode: json['user_ticket_code'] as String?,
    );
  }
}

/// Status 11 Tombol Aksi (CTA) Detail Acara Sesuai Web PRD §7.4.1.
enum EventCtaState {
  eventCancelled,       // Acara Dibatalkan
  eventEnded,           // Acara Telah Selesai
  notLoggedIn,          // Masuk untuk Mendaftar
  emailUnverified,      // Verifikasi Email Terlebih Dahulu
  profileIncomplete,    // Lengkapi Profil (No. WA)
  alreadyRegistered,    // Lihat Tiket Saya
  notEligible,          // Tidak Memenuhi Syarat (Jurusan/Angkatan)
  notOpenYet,           // Pendaftaran Belum Dibuka
  registrationClosed,   // Pendaftaran Ditutup
  quotaFull,            // Kuota Penuh
  canRegister,          // Daftar Sekarang
}

/// Model Respon Kelayakan Pendaftaran Mahasiswa (`GET /events/{slug}/eligibility`).
class EligibilityResultModel {
  final bool isEligible;
  final List<String> reasons;
  final EventCtaState ctaState;
  final String ctaLabel;
  final bool hasActiveTicket;
  final String? ticketCode;

  const EligibilityResultModel({
    required this.isEligible,
    this.reasons = const [],
    required this.ctaState,
    required this.ctaLabel,
    this.hasActiveTicket = false,
    this.ticketCode,
  });

  factory EligibilityResultModel.fromJson(Map<String, dynamic> json) {
    final rawState = json['cta_state'] as String? ?? 'can_register';
    EventCtaState state;

    switch (rawState) {
      case 'event_cancelled':
        state = EventCtaState.eventCancelled;
        break;
      case 'event_ended':
        state = EventCtaState.eventEnded;
        break;
      case 'not_logged_in':
        state = EventCtaState.notLoggedIn;
        break;
      case 'email_unverified':
        state = EventCtaState.emailUnverified;
        break;
      case 'already_registered':
        state = EventCtaState.alreadyRegistered;
        break;
      case 'not_eligible':
        state = EventCtaState.notEligible;
        break;
      case 'not_open_yet':
        state = EventCtaState.notOpenYet;
        break;
      case 'registration_closed':
        state = EventCtaState.registrationClosed;
        break;
      case 'quota_full':
        state = EventCtaState.quotaFull;
        break;
      case 'can_register':
      default:
        state = EventCtaState.canRegister;
        break;
    }

    return EligibilityResultModel(
      isEligible: json['is_eligible'] as bool? ?? false,
      reasons: (json['reasons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      ctaState: state,
      ctaLabel: json['cta_label'] as String? ?? 'Daftar Sekarang',
      hasActiveTicket: json['has_active_ticket'] as bool? ?? false,
      ticketCode: json['ticket_code'] as String?,
    );
  }
}
