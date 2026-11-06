import '../../../auth/data/models/user_model.dart';

/// Model Pembatasan Target Peserta Acara (BR-04).
class EventRestrictions {
  final List<String> allowedFaculties;
  final List<String> allowedPrograms;
  final int? cohortMin;
  final int? cohortMax;

  const EventRestrictions({
    this.allowedFaculties = const [],
    this.allowedPrograms = const [],
    this.cohortMin,
    this.cohortMax,
  });

  factory EventRestrictions.fromJson(Map<String, dynamic> json) {
    return EventRestrictions(
      allowedFaculties: (json['allowed_faculties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      allowedPrograms: (json['allowed_programs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      cohortMin: json['cohort_min'] as int?,
      cohortMax: json['cohort_max'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowed_faculties': allowedFaculties,
      'allowed_programs': allowedPrograms,
      'cohort_min': cohortMin,
      'cohort_max': cohortMax,
    };
  }

  bool get hasRestrictions =>
      allowedFaculties.isNotEmpty ||
      allowedPrograms.isNotEmpty ||
      cohortMin != null ||
      cohortMax != null;
}

/// Status 11 Tombol Aksi (CTA) Detail Acara Sesuai Web PRD §7.4.1.
enum EventCtaState {
  eventCancelled, // 1. Acara Dibatalkan
  eventEnded, // 2. Acara Selesai
  notLoggedIn, // 3. Masuk untuk Mendaftar
  emailUnverified, // 4. Verifikasi Email Terlebih Dahulu
  profileIncomplete, // 5. Lengkapi Profil (No. WhatsApp)
  alreadyRegistered, // 6. Lihat Tiket Saya
  notEligible, // 7. Tidak Memenuhi Syarat (Jurusan/Angkatan)
  notOpenYet, // 8. Pendaftaran Belum Dibuka
  registrationClosed, // 9. Pendaftaran Ditutup
  quotaFull, // 10. Kuota Penuh
  canRegister; // 11. Daftar Sekarang / Daftar & Bayar

  static EventCtaState fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'event_cancelled':
      case 'cancelled':
        return EventCtaState.eventCancelled;
      case 'event_ended':
      case 'ended':
        return EventCtaState.eventEnded;
      case 'not_logged_in':
        return EventCtaState.notLoggedIn;
      case 'email_unverified':
        return EventCtaState.emailUnverified;
      case 'profile_incomplete':
        return EventCtaState.profileIncomplete;
      case 'already_registered':
        return EventCtaState.alreadyRegistered;
      case 'not_eligible':
        return EventCtaState.notEligible;
      case 'not_open_yet':
        return EventCtaState.notOpenYet;
      case 'registration_closed':
        return EventCtaState.registrationClosed;
      case 'quota_full':
        return EventCtaState.quotaFull;
      case 'can_register':
      default:
        return EventCtaState.canRegister;
    }
  }

  String get serializedName {
    switch (this) {
      case EventCtaState.eventCancelled:
        return 'event_cancelled';
      case EventCtaState.eventEnded:
        return 'event_ended';
      case EventCtaState.notLoggedIn:
        return 'not_logged_in';
      case EventCtaState.emailUnverified:
        return 'email_unverified';
      case EventCtaState.profileIncomplete:
        return 'profile_incomplete';
      case EventCtaState.alreadyRegistered:
        return 'already_registered';
      case EventCtaState.notEligible:
        return 'not_eligible';
      case EventCtaState.notOpenYet:
        return 'not_open_yet';
      case EventCtaState.registrationClosed:
        return 'registration_closed';
      case EventCtaState.quotaFull:
        return 'quota_full';
      case EventCtaState.canRegister:
        return 'can_register';
    }
  }
}

/// Model Status Tombol Pendaftaran (CTA State Model).
class CtaStateModel {
  final EventCtaState status;
  final String label;
  final String? reason;
  final bool hasActiveTicket;
  final String? activeTicketCode;

  const CtaStateModel({
    required this.status,
    required this.label,
    this.reason,
    this.hasActiveTicket = false,
    this.activeTicketCode,
  });

  factory CtaStateModel.fromJson(Map<String, dynamic> json) {
    return CtaStateModel(
      status: EventCtaState.fromString(json['status'] as String?),
      label: json['label'] as String? ?? 'Daftar Sekarang',
      reason: json['reason'] as String?,
      hasActiveTicket: json['has_active_ticket'] as bool? ?? false,
      activeTicketCode: json['active_ticket_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.serializedName,
      'label': label,
      'reason': reason,
      'has_active_ticket': hasActiveTicket,
      'active_ticket_code': activeTicketCode,
    };
  }
}

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
class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? iconName;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.iconName,
  });

  String? get icon => iconName;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      iconName: (json['icon_name'] ?? json['icon']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon_name': iconName,
    };
  }
}

/// Alias untuk backward-compatibility
typedef EventCategoryModel = CategoryModel;

/// Model Parameter Pencarian & Filter Katalog Acara TemuKampus.
class EventFilterModel {
  final String searchQuery;
  final String? categorySlug;
  final String? tag;
  final String? format;
  final bool isFreeOnly;
  final bool suitableForMeOnly;
  final bool isSkpOnly;
  final int page;

  const EventFilterModel({
    this.searchQuery = '',
    this.categorySlug,
    this.tag,
    this.format,
    this.isFreeOnly = false,
    this.suitableForMeOnly = false,
    this.isSkpOnly = false,
    this.page = 1,
  });

  bool get hasActiveFilter =>
      (categorySlug != null && categorySlug != 'all') ||
      format != null ||
      tag != null ||
      isFreeOnly ||
      suitableForMeOnly ||
      isSkpOnly;

  EventFilterModel copyWith({
    String? searchQuery,
    String? categorySlug,
    String? tag,
    String? format,
    bool? isFreeOnly,
    bool? suitableForMeOnly,
    bool? isSkpOnly,
    int? page,
    bool clearCategory = false,
    bool clearFormat = false,
    bool clearTag = false,
  }) {
    return EventFilterModel(
      searchQuery: searchQuery ?? this.searchQuery,
      categorySlug: clearCategory ? null : (categorySlug ?? this.categorySlug),
      tag: clearTag ? null : (tag ?? this.tag),
      format: clearFormat ? null : (format ?? this.format),
      isFreeOnly: isFreeOnly ?? this.isFreeOnly,
      suitableForMeOnly: suitableForMeOnly ?? this.suitableForMeOnly,
      isSkpOnly: isSkpOnly ?? this.isSkpOnly,
      page: page ?? this.page,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      'page': page,
      if (searchQuery.trim().isNotEmpty) 'search': searchQuery.trim(),
      if (categorySlug != null && categorySlug != 'all' && categorySlug!.isNotEmpty)
        'category': categorySlug,
      if (format != null && format!.isNotEmpty) 'format': format,
      if (tag != null && tag!.isNotEmpty) 'tag': tag,
      if (suitableForMeOnly) 'suitable_for_me': 1,
      if (isFreeOnly) 'free_only': 1,
    };
  }
}

/// Model Entitas Acara TemuKampus (Katalog & Detail Lengkap).
class EventModel {
  final int id;
  final String title;
  final String slug;
  final String summary;
  final String description;
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
  final EventRestrictions restrictions;
  final int? quota;
  final int? remainingQuota;
  final bool isFull;
  final int registeredCount;
  final EventOrganizationModel organization;
  final String? category;

  // Data Pembayaran Panitia (Khusus Berbayar)
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? qrisImageUrl;

  // Jadwal Pendaftaran
  final DateTime? registrationOpenAt;
  final DateTime? registrationCloseAt;
  final bool isCancelled;

  // CTA State Calculator Objek
  final CtaStateModel? ctaState;

  const EventModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.summary,
    this.description = '',
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
    this.restrictions = const EventRestrictions(),
    this.quota,
    this.remainingQuota,
    this.isFull = false,
    this.registeredCount = 0,
    required this.organization,
    this.category,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.qrisImageUrl,
    this.registrationOpenAt,
    this.registrationCloseAt,
    this.isCancelled = false,
    this.ctaState,
  });

  bool get isFree => !isPaid || price == 0;
  bool get hasSkp => skpPoints > 0;
  bool get isQuotaAlmostFull =>
      remainingQuota != null && remainingQuota! <= 10 && remainingQuota! > 0;

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
    final restrictionsData = json['restrictions'];
    EventRestrictions restrictions;
    if (restrictionsData is Map<String, dynamic>) {
      restrictions = EventRestrictions.fromJson(restrictionsData);
    } else {
      restrictions = EventRestrictions(
        allowedFaculties: (json['allowed_faculties'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        allowedPrograms: (json['allowed_programs'] ?? json['allowed_study_programs'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        cohortMin: json['cohort_min'] as int? ?? json['min_cohort_year'] as int?,
        cohortMax: json['cohort_max'] as int? ?? json['max_cohort_year'] as int?,
      );
    }

    final ctaStateData = json['cta_state'];
    CtaStateModel? ctaState;
    if (ctaStateData is Map<String, dynamic>) {
      ctaState = CtaStateModel.fromJson(ctaStateData);
    }

    final price = json['price'] as int? ?? 0;
    final isPaid = json['is_paid'] as bool? ?? (price > 0);

    return EventModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      description: json['description'] as String? ?? (json['summary'] as String? ?? ''),
      posterUrl: json['poster_url'] as String?,
      format: json['format'] as String? ?? 'offline',
      startAt: json['start_at'] != null
          ? DateTime.parse(json['start_at'] as String)
          : DateTime.now(),
      endAt: json['end_at'] != null
          ? DateTime.parse(json['end_at'] as String)
          : DateTime.now().add(const Duration(hours: 3)),
      location: json['location'] as String? ?? 'Kampus Meruya UMB',
      isPaid: isPaid,
      price: price,
      formattedPrice: json['formatted_price'] as String? ??
          (isPaid ? 'Rp $price' : 'Gratis'),
      skpPoints: json['skp_points'] as int? ?? 0,
      hasCertificate: json['has_certificate'] as bool? ?? false,
      audience: json['audience'] as String? ?? 'public',
      restrictions: restrictions,
      quota: json['quota'] as int?,
      remainingQuota: json['remaining_quota'] as int?,
      isFull: json['is_full'] as bool? ?? false,
      registeredCount: json['registered_count'] as int? ?? 0,
      organization: EventOrganizationModel.fromJson(
        json['organization'] as Map<String, dynamic>? ?? {},
      ),
      category: json['category'] as String?,
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      qrisImageUrl: (json['qris_image_url'] ?? json['qris_url']) as String?,
      registrationOpenAt: json['registration_open_at'] != null
          ? DateTime.parse(json['registration_open_at'] as String)
          : null,
      registrationCloseAt: json['registration_close_at'] != null
          ? DateTime.parse(json['registration_close_at'] as String)
          : null,
      isCancelled: json['is_cancelled'] as bool? ?? false,
      ctaState: ctaState,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'summary': summary,
      'description': description,
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
      'restrictions': restrictions.toJson(),
      'quota': quota,
      'remaining_quota': remainingQuota,
      'is_full': isFull,
      'registered_count': registeredCount,
      'organization': organization.toJson(),
      'category': category,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_account_name': bankAccountName,
      'qris_image_url': qrisImageUrl,
      'registration_open_at': registrationOpenAt?.toIso8601String(),
      'registration_close_at': registrationCloseAt?.toIso8601String(),
      'is_cancelled': isCancelled,
      'cta_state': ctaState?.toJson(),
    };
  }
}

/// Model Detail Acara Lengkap (Wrapper untuk Layar Detail SCR-09).
class EventDetailModel {
  final EventModel event;
  final String? terms;
  final bool hasUserRegistered;
  final String? userRegistrationStatus;
  final String? userTicketCode;

  const EventDetailModel({
    required this.event,
    this.terms,
    this.hasUserRegistered = false,
    this.userRegistrationStatus,
    this.userTicketCode,
  });

  String get description => event.description;
  String? get bankName => event.bankName;
  String? get bankAccountNumber => event.bankAccountNumber;
  String? get bankAccountName => event.bankAccountName;
  String? get qrisUrl => event.qrisImageUrl;
  bool get hasUniqueCode => true;
  List<String> get allowedFaculties => event.restrictions.allowedFaculties;
  List<String> get allowedStudyPrograms => event.restrictions.allowedPrograms;
  int? get minCohortYear => event.restrictions.cohortMin;
  int? get maxCohortYear => event.restrictions.cohortMax;
  DateTime? get registrationOpenAt => event.registrationOpenAt;
  DateTime? get registrationCloseAt => event.registrationCloseAt;

  factory EventDetailModel.fromJson(Map<String, dynamic> json) {
    final event = EventModel.fromJson(json);

    return EventDetailModel(
      event: event,
      terms: json['terms'] as String?,
      hasUserRegistered: json['has_user_registered'] as bool? ??
          (event.ctaState?.hasActiveTicket ?? false),
      userRegistrationStatus: json['user_registration_status'] as String?,
      userTicketCode: json['user_ticket_code'] as String? ??
          event.ctaState?.activeTicketCode,
    );
  }
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
    final state = EventCtaState.fromString(rawState);

    return EligibilityResultModel(
      isEligible: json['is_eligible'] as bool? ?? false,
      reasons: (json['reasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      ctaState: state,
      ctaLabel: json['cta_label'] as String? ?? 'Daftar Sekarang',
      hasActiveTicket: json['has_active_ticket'] as bool? ?? false,
      ticketCode: json['ticket_code'] as String?,
    );
  }
}

/// Kalkulator 11 Status Tombol Aksi (CTA) Pendaftaran Acara Sesuai Web PRD §7.4.1.
class EventCtaCalculator {
  static CtaStateModel calculate({
    required EventModel event,
    UserModel? user,
    DateTime? now,
    bool hasActiveTicket = false,
    String? activeTicketCode,
  }) {
    final currentTime = now ?? DateTime.now();

    // 1. Event dibatalkan
    if (event.isCancelled) {
      return const CtaStateModel(
        status: EventCtaState.eventCancelled,
        label: 'Acara Dibatalkan',
        reason: 'Acara ini telah dibatalkan oleh panitia penyelenggara.',
      );
    }

    // 2. Event sudah berakhir
    if (currentTime.isAfter(event.endAt)) {
      return const CtaStateModel(
        status: EventCtaState.eventEnded,
        label: 'Pendaftaran Ditutup (Acara Selesai)',
        reason: 'Waktu pelaksanaan acara telah selesai.',
      );
    }

    // 3. Belum login
    if (user == null) {
      return const CtaStateModel(
        status: EventCtaState.notLoggedIn,
        label: 'Masuk untuk Mendaftar',
        reason: 'Silakan masuk ke akun TemuKampus Anda terlebih dahulu.',
      );
    }

    // 4. Email belum terverifikasi
    if (!user.emailVerified) {
      return const CtaStateModel(
        status: EventCtaState.emailUnverified,
        label: 'Verifikasi Email Terlebih Dahulu',
        reason: 'Email akun Anda belum diverifikasi.',
      );
    }

    // 5. Profil belum lengkap (No. WhatsApp wajib diisi untuk kirim e-tiket)
    if (user.phone == null || user.phone!.trim().isEmpty) {
      return const CtaStateModel(
        status: EventCtaState.profileIncomplete,
        label: 'Lengkapi Profil (No. WhatsApp)',
        reason: 'Nomor WhatsApp aktif wajib diisi pada profil Anda.',
      );
    }

    // 6. Sudah punya tiket aktif
    final ticketCode = activeTicketCode ??
        event.ctaState?.activeTicketCode ??
        (hasActiveTicket ? 'TICKET-ACTIVE' : null);
    if (hasActiveTicket ||
        event.ctaState?.hasActiveTicket == true ||
        ticketCode != null) {
      return CtaStateModel(
        status: EventCtaState.alreadyRegistered,
        label: 'Lihat Tiket Saya',
        reason: 'Anda sudah terdaftar dan memiliki tiket acara ini.',
        hasActiveTicket: true,
        activeTicketCode: ticketCode,
      );
    }

    // 7. Tidak eligible (Syarat tidak cocok: prodi / angkatan)
    if (event.audience == 'umb_only' && !user.isUmbStudent) {
      return const CtaStateModel(
        status: EventCtaState.notEligible,
        label: 'Syarat Tidak Cocok',
        reason: 'Acara ini khusus mahasiswa aktif Universitas Mercu Buana.',
      );
    }

    if (event.audience == 'restricted') {
      final restrictions = event.restrictions;
      bool matchesFacultyOrProgram = true;

      if (restrictions.allowedPrograms.isNotEmpty ||
          restrictions.allowedFaculties.isNotEmpty) {
        final userProgram = user.studyProgram?.name ?? '';
        final inAllowedPrograms = restrictions.allowedPrograms
            .any((p) => p.toLowerCase() == userProgram.toLowerCase());

        // Asumsi jika hanya ada fakultas, cek apakah user prodi/fakultas cocok
        final inAllowedFaculties = restrictions.allowedFaculties
            .any((f) => userProgram.toLowerCase().contains('informatika') && f.toLowerCase().contains('ilmu komputer'));

        if (!inAllowedPrograms && !inAllowedFaculties) {
          matchesFacultyOrProgram = false;
        }
      }

      if (!matchesFacultyOrProgram) {
        final programNames = restrictions.allowedPrograms.join(', ');
        return CtaStateModel(
          status: EventCtaState.notEligible,
          label: 'Syarat Tidak Cocok',
          reason: restrictions.allowedPrograms.isNotEmpty
              ? 'Acara ini khusus mahasiswa prodi: $programNames.'
              : 'Acara ini khusus fakultas yang ditentukan.',
        );
      }

      // Check Cohort Year range (AND logic)
      final userCohort = user.cohortYear;
      if (userCohort != null) {
        if (restrictions.cohortMin != null && userCohort < restrictions.cohortMin!) {
          return CtaStateModel(
            status: EventCtaState.notEligible,
            label: 'Syarat Tidak Cocok',
            reason: 'Acara ini khusus angkatan ${restrictions.cohortMin} ke atas.',
          );
        }
        if (restrictions.cohortMax != null && userCohort > restrictions.cohortMax!) {
          return CtaStateModel(
            status: EventCtaState.notEligible,
            label: 'Syarat Tidak Cocok',
            reason: 'Acara ini khusus angkatan ${restrictions.cohortMax} ke bawah.',
          );
        }
      }
    }

    // 8. Pendaftaran belum dibuka
    if (event.registrationOpenAt != null &&
        currentTime.isBefore(event.registrationOpenAt!)) {
      return const CtaStateModel(
        status: EventCtaState.notOpenYet,
        label: 'Pendaftaran Belum Dibuka',
        reason: 'Pendaftaran belum dibuka untuk umum.',
      );
    }

    // 9. Pendaftaran ditutup
    if (event.registrationCloseAt != null &&
        currentTime.isAfter(event.registrationCloseAt!)) {
      return const CtaStateModel(
        status: EventCtaState.registrationClosed,
        label: 'Pendaftaran Ditutup',
        reason: 'Periode pendaftaran acara telah ditutup.',
      );
    }

    // 10. Kuota penuh
    if (event.isFull ||
        (event.remainingQuota != null && event.remainingQuota! <= 0)) {
      return const CtaStateModel(
        status: EventCtaState.quotaFull,
        label: 'Kuota Penuh',
        reason: 'Kuota pendaftaran telah habis.',
      );
    }

    // 11. Eligible & Kuota Tersedia
    final registerLabel = event.isFree
        ? 'Daftar Sekarang (Gratis)'
        : 'Daftar & Bayar (${event.formattedPrice})';

    return CtaStateModel(
      status: EventCtaState.canRegister,
      label: registerLabel,
      reason: null,
    );
  }
}
