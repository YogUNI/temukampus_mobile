import '../../../../core/network/media_url.dart';

/// Model panel panitia: ringkasan dashboard dan satu baris peserta.
///
/// Bentuknya mengikuti `PanitiaController` + `RegistrantResource` di API v1.
class PanitiaDashboardModel {
  final int eventsTotal;
  final int registrationsActive;
  final int pendingVerification;
  final int confirmed;
  final int attended;
  final int confirmedAmount;
  final double attendanceRate;

  const PanitiaDashboardModel({
    this.eventsTotal = 0,
    this.registrationsActive = 0,
    this.pendingVerification = 0,
    this.confirmed = 0,
    this.attended = 0,
    this.confirmedAmount = 0,
    this.attendanceRate = 0,
  });

  factory PanitiaDashboardModel.fromJson(Map<String, dynamic> json) {
    return PanitiaDashboardModel(
      eventsTotal: json['events_total'] as int? ?? 0,
      registrationsActive: json['registrations_active'] as int? ?? 0,
      pendingVerification: json['pending_verification'] as int? ?? 0,
      confirmed: json['confirmed'] as int? ?? 0,
      attended: json['attended'] as int? ?? 0,
      confirmedAmount: json['confirmed_amount'] as int? ?? 0,
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Satu baris peserta di daftar panitia.
class RegistrantModel {
  final int id;
  final String ticketCode;
  final String status;
  final String? statusLabel;
  final int amountDue;
  final int uniqueCode;
  final int totalTransfer;
  final String? registeredAt;
  final String? reviewNote;
  final bool hasProof;
  final String? proofUrl;
  final bool isCheckedIn;
  final String? checkedInAt;
  final String name;
  final String? nim;
  final String? email;
  final String? phone;
  final String? studyProgram;

  const RegistrantModel({
    required this.id,
    required this.ticketCode,
    required this.status,
    this.statusLabel,
    this.amountDue = 0,
    this.uniqueCode = 0,
    this.totalTransfer = 0,
    this.registeredAt,
    this.reviewNote,
    this.hasProof = false,
    this.proofUrl,
    this.isCheckedIn = false,
    this.checkedInAt,
    required this.name,
    this.nim,
    this.email,
    this.phone,
    this.studyProgram,
  });

  /// Status yang menuntut tindakan panitia.
  bool get needsVerification =>
      status == 'pending_verification' || status == 'needs_revision';

  bool get isConfirmed => status == 'confirmed';

  String get statusLabelId {
    if (statusLabel != null && statusLabel!.isNotEmpty) return statusLabel!;

    return switch (status) {
      'pending_verification' => 'Menunggu verifikasi',
      'needs_revision' => 'Perlu revisi',
      'confirmed' => 'Terkonfirmasi',
      'rejected' => 'Ditolak',
      'cancelled' => 'Dibatalkan',
      _ => status,
    };
  }

  String get formattedTotal {
    final value = totalTransfer > 0 ? totalTransfer : amountDue;
    final text = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write('.');
      buffer.write(text[i]);
    }

    return 'Rp $buffer';
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  factory RegistrantModel.fromJson(Map<String, dynamic> json) {
    final participant = json['participant'] as Map<String, dynamic>? ?? {};

    return RegistrantModel(
      id: json['id'] as int? ?? 0,
      ticketCode: json['ticket_code'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String?,
      amountDue: json['amount_due'] as int? ?? 0,
      uniqueCode: json['unique_code'] as int? ?? 0,
      totalTransfer: json['total_transfer'] as int? ?? 0,
      registeredAt: json['registered_at'] as String?,
      reviewNote: json['review_note'] as String?,
      hasProof: json['has_proof'] as bool? ?? false,
      // URL bukti dari backend ber-host web; selaraskan ke origin API.
      proofUrl: MediaUrl.resolve(json['proof_url'] as String?),
      isCheckedIn: json['is_checked_in'] as bool? ?? false,
      checkedInAt: json['checked_in_at'] as String?,
      name: participant['name'] as String? ?? 'Peserta',
      nim: participant['nim'] as String?,
      email: participant['email'] as String?,
      phone: participant['phone'] as String?,
      studyProgram: participant['study_program'] as String?,
    );
  }
}

/// Hasil satu permintaan daftar peserta: baris + hitungan tab.
class RegistrantPageModel {
  final List<RegistrantModel> items;
  final int menunggu;
  final int terkonfirmasi;
  final int hadir;

  const RegistrantPageModel({
    this.items = const [],
    this.menunggu = 0,
    this.terkonfirmasi = 0,
    this.hadir = 0,
  });

  factory RegistrantPageModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final counts = meta['counts'] as Map<String, dynamic>? ?? {};

    return RegistrantPageModel(
      items: (json['data'] as List<dynamic>? ?? [])
          .map((e) => RegistrantModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      menunggu: counts['menunggu'] as int? ?? 0,
      terkonfirmasi: counts['terkonfirmasi'] as int? ?? 0,
      hadir: counts['hadir'] as int? ?? 0,
    );
  }
}

/// Master data kategori, fakultas, program studi untuk wizard acara.
class PanitiaMetaItem {
  final int id;
  final String name;
  final String? slug;
  final int? facultyId;

  const PanitiaMetaItem({
    required this.id,
    required this.name,
    this.slug,
    this.facultyId,
  });

  factory PanitiaMetaItem.fromJson(Map<String, dynamic> json) {
    return PanitiaMetaItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      facultyId: json['faculty_id'] as int?,
    );
  }
}

class PanitiaEventMetaModel {
  final List<PanitiaMetaItem> categories;
  final List<PanitiaMetaItem> faculties;
  final List<PanitiaMetaItem> studyPrograms;

  const PanitiaEventMetaModel({
    this.categories = const [],
    this.faculties = const [],
    this.studyPrograms = const [],
  });

  factory PanitiaEventMetaModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return PanitiaEventMetaModel(
      categories: (data['categories'] as List<dynamic>? ?? [])
          .map((e) => PanitiaMetaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      faculties: (data['faculties'] as List<dynamic>? ?? [])
          .map((e) => PanitiaMetaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      studyPrograms: (data['study_programs'] as List<dynamic>? ?? [])
          .map((e) => PanitiaMetaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Detail lengkap satu acara untuk formulir ubah acara.
class PanitiaEventDetailModel {
  final int id;
  final String title;
  final String slug;
  final int? categoryId;
  final String? categoryName;
  final String? summary;
  final String? description;
  final String format;
  final String? locationName;
  final String? locationAddress;
  final String? onlineUrl;
  final String? startAt;
  final String? endAt;
  final String? registrationOpenAt;
  final String? registrationCloseAt;
  final int? quota;
  final bool isPaid;
  final int price;
  final bool useUniqueCode;
  final String? paymentBankName;
  final String? paymentAccountNumber;
  final String? paymentAccountName;
  final String? paymentInstructions;
  final String? paymentQrisUrl;
  final int? skpPoints;
  final bool certificateProvided;
  final String audience;
  final int? cohortMin;
  final int? cohortMax;
  final String? waGroupLink;
  final String? posterUrl;
  final String status;
  final int activeRegistrationsCount;
  final List<int> facultyIds;
  final List<int> studyProgramIds;

  const PanitiaEventDetailModel({
    required this.id,
    required this.title,
    required this.slug,
    this.categoryId,
    this.categoryName,
    this.summary,
    this.description,
    this.format = 'offline',
    this.locationName,
    this.locationAddress,
    this.onlineUrl,
    this.startAt,
    this.endAt,
    this.registrationOpenAt,
    this.registrationCloseAt,
    this.quota,
    this.isPaid = false,
    this.price = 0,
    this.useUniqueCode = true,
    this.paymentBankName,
    this.paymentAccountNumber,
    this.paymentAccountName,
    this.paymentInstructions,
    this.paymentQrisUrl,
    this.skpPoints,
    this.certificateProvided = false,
    this.audience = 'umb_only',
    this.cohortMin,
    this.cohortMax,
    this.waGroupLink,
    this.posterUrl,
    this.status = 'draft',
    this.activeRegistrationsCount = 0,
    this.facultyIds = const [],
    this.studyProgramIds = const [],
  });

  factory PanitiaEventDetailModel.fromJson(Map<String, dynamic> json) {
    return PanitiaEventDetailModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      format: json['format'] as String? ?? 'offline',
      locationName: json['location_name'] as String?,
      locationAddress: json['location_address'] as String?,
      onlineUrl: json['online_url'] as String?,
      startAt: json['start_at'] as String?,
      endAt: json['end_at'] as String?,
      registrationOpenAt: json['registration_open_at'] as String?,
      registrationCloseAt: json['registration_close_at'] as String?,
      quota: json['quota'] as int?,
      isPaid: json['is_paid'] as bool? ?? false,
      price: json['price'] as int? ?? 0,
      useUniqueCode: json['use_unique_code'] as bool? ?? true,
      paymentBankName: json['payment_bank_name'] as String?,
      paymentAccountNumber: json['payment_account_number'] as String?,
      paymentAccountName: json['payment_account_name'] as String?,
      paymentInstructions: json['payment_instructions'] as String?,
      paymentQrisUrl: MediaUrl.resolve(json['payment_qris_url'] as String?),
      skpPoints: json['skp_points'] as int?,
      certificateProvided: json['certificate_provided'] as bool? ?? false,
      audience: json['audience'] as String? ?? 'umb_only',
      cohortMin: json['cohort_min'] as int?,
      cohortMax: json['cohort_max'] as int?,
      waGroupLink: json['wa_group_link'] as String?,
      posterUrl: MediaUrl.resolve(json['poster_url'] as String?),
      status: json['status'] as String? ?? 'draft',
      activeRegistrationsCount: json['active_registrations_count'] as int? ?? 0,
      facultyIds: (json['faculty_ids'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
      studyProgramIds: (json['study_program_ids'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
    );
  }
}

/// Profil organisasi aktif panitia.
class PanitiaOrganizationModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? email;
  final String? instagram;
  final String? logoUrl;
  final String status;
  final String? faculty;
  final String? studyProgram;
  final int membersCount;
  final int eventsCount;
  final bool isOwner;

  const PanitiaOrganizationModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.email,
    this.instagram,
    this.logoUrl,
    this.status = 'active',
    this.faculty,
    this.studyProgram,
    this.membersCount = 0,
    this.eventsCount = 0,
    this.isOwner = false,
  });

  factory PanitiaOrganizationModel.fromJson(Map<String, dynamic> json) {
    return PanitiaOrganizationModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      email: json['email'] as String?,
      instagram: json['instagram'] as String?,
      logoUrl: MediaUrl.resolve(json['logo_url'] as String?),
      status: json['status'] as String? ?? 'active',
      faculty: json['faculty'] as String?,
      studyProgram: json['study_program'] as String?,
      membersCount: json['members_count'] as int? ?? 0,
      eventsCount: json['events_count'] as int? ?? 0,
      isOwner: json['is_owner'] as bool? ?? false,
    );
  }
}

/// Anggota / staf dalam organisasi.
class PanitiaMemberModel {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String role;
  final String roleLabel;
  final String? avatarUrl;
  final String? joinedAt;

  const PanitiaMemberModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.roleLabel,
    this.avatarUrl,
    this.joinedAt,
  });

  bool get isOwner => role == 'owner';

  factory PanitiaMemberModel.fromJson(Map<String, dynamic> json) {
    return PanitiaMemberModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Anggota',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'staff',
      roleLabel: json['role_label'] as String? ?? 'Staf Panitia',
      avatarUrl: MediaUrl.resolve(json['avatar_url'] as String?),
      joinedAt: json['joined_at'] as String?,
    );
  }
}
