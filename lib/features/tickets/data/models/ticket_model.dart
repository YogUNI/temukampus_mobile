/// Model Informasi Peserta Tiket
class TicketParticipantModel {
  final String name;
  final String? nim;
  final String? studyProgram;

  const TicketParticipantModel({
    required this.name,
    this.nim,
    this.studyProgram,
  });

  factory TicketParticipantModel.fromJson(Map<String, dynamic> json) {
    return TicketParticipantModel(
      name: json['name'] as String? ?? 'Mahasiswa UMB',
      nim: json['nim'] as String?,
      studyProgram: json['study_program'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nim': nim,
      'study_program': studyProgram,
    };
  }
}

/// Model Ringkasan Acara pada Tiket
class TicketEventModel {
  final String title;
  final String slug;
  final String? posterUrl;
  final DateTime startAt;
  final DateTime endAt;
  final String location;
  final String format; // 'offline', 'online', 'hybrid'

  const TicketEventModel({
    required this.title,
    required this.slug,
    this.posterUrl,
    required this.startAt,
    required this.endAt,
    required this.location,
    this.format = 'offline',
  });

  factory TicketEventModel.fromJson(Map<String, dynamic> json) {
    return TicketEventModel(
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      posterUrl: json['poster_url'] as String?,
      startAt: json['start_at'] != null
          ? DateTime.parse(json['start_at'] as String)
          : DateTime.now(),
      endAt: json['end_at'] != null
          ? DateTime.parse(json['end_at'] as String)
          : DateTime.now().add(const Duration(hours: 3)),
      location: json['location'] as String? ?? 'Kampus Meruya UMB',
      format: json['format'] as String? ?? 'offline',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'slug': slug,
      'poster_url': posterUrl,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'location': location,
      'format': format,
    };
  }
}

/// Model Kunci Akses Grup WA & Link Pertemuan (BR-13)
/// Hanya terbuka jika status tiket adalah 'confirmed'
class UnlockedAccessModel {
  final bool canAccessLinks;
  final String? waGroupUrl;
  final String? meetingUrl;

  const UnlockedAccessModel({
    required this.canAccessLinks,
    this.waGroupUrl,
    this.meetingUrl,
  });

  factory UnlockedAccessModel.fromJson(Map<String, dynamic> json, {required String status}) {
    // BR-13: URL bernilai null jika status bukan confirmed
    final isConfirmed = status.toLowerCase() == 'confirmed';
    return UnlockedAccessModel(
      canAccessLinks: isConfirmed && (json['can_access_links'] as bool? ?? true),
      waGroupUrl: isConfirmed ? (json['wa_group_url'] as String?) : null,
      meetingUrl: isConfirmed ? (json['meeting_url'] as String?) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'can_access_links': canAccessLinks,
      'wa_group_url': waGroupUrl,
      'meeting_url': meetingUrl,
    };
  }
}

/// Model Tiket Digital Mahasiswa TemuKampus (SCR-11 & SCR-12)
class TicketModel {
  final String ticketCode;
  final String status; // 'confirmed', 'pending_verification', 'needs_revision', 'cancelled', 'rejected'
  final String statusLabel;
  final TicketParticipantModel participant;
  final TicketEventModel event;
  final int amountPaid;
  final String? revisionNotes;
  final DateTime? checkedInAt;
  final UnlockedAccessModel unlockedAccess;
  final DateTime registeredAt;

  const TicketModel({
    required this.ticketCode,
    required this.status,
    required this.statusLabel,
    required this.participant,
    required this.event,
    this.amountPaid = 0,
    this.revisionNotes,
    this.checkedInAt,
    required this.unlockedAccess,
    required this.registeredAt,
  });

  bool get isConfirmed => status == 'confirmed';
  bool get isPending => status == 'pending_verification';
  bool get isNeedsRevision => status == 'needs_revision';
  bool get isCancelled => status == 'cancelled';
  bool get isRejected => status == 'rejected';
  bool get isCheckedIn => checkedInAt != null;

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'pending_verification';
    final unlockedAccessData = json['unlocked_access'] as Map<String, dynamic>? ?? {};

    return TicketModel(
      ticketCode: json['ticket_code'] as String? ?? 'TK-UNKNOWN',
      status: status,
      statusLabel: json['status_label'] as String? ?? _deriveLabel(status),
      participant: TicketParticipantModel.fromJson(
        json['participant'] as Map<String, dynamic>? ?? {},
      ),
      event: TicketEventModel.fromJson(
        json['event'] as Map<String, dynamic>? ?? {},
      ),
      amountPaid: json['amount_paid'] as int? ?? json['amount_due'] as int? ?? 0,
      revisionNotes: json['revision_notes'] as String?,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'] as String)
          : null,
      unlockedAccess: UnlockedAccessModel.fromJson(unlockedAccessData, status: status),
      registeredAt: json['registered_at'] != null
          ? DateTime.parse(json['registered_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_code': ticketCode,
      'status': status,
      'status_label': statusLabel,
      'participant': participant.toJson(),
      'event': event.toJson(),
      'amount_paid': amountPaid,
      'revision_notes': revisionNotes,
      'checked_in_at': checkedInAt?.toIso8601String(),
      'unlocked_access': unlockedAccess.toJson(),
      'registered_at': registeredAt.toIso8601String(),
    };
  }

  static String _deriveLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Terkonfirmasi';
      case 'needs_revision':
        return 'Perlu Revisi';
      case 'cancelled':
        return 'Dibatalkan';
      case 'rejected':
        return 'Ditolak';
      case 'pending_verification':
      default:
        return 'Menunggu Verifikasi';
    }
  }

  TicketModel copyWith({
    String? status,
    String? statusLabel,
    String? revisionNotes,
    DateTime? checkedInAt,
    UnlockedAccessModel? unlockedAccess,
  }) {
    final newStatus = status ?? this.status;
    return TicketModel(
      ticketCode: ticketCode,
      status: newStatus,
      statusLabel: statusLabel ?? _deriveLabel(newStatus),
      participant: participant,
      event: event,
      amountPaid: amountPaid,
      revisionNotes: revisionNotes ?? this.revisionNotes,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      unlockedAccess: unlockedAccess ?? this.unlockedAccess,
      registeredAt: registeredAt,
    );
  }
}

