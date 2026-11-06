/// Status Respon Check-in Presensi Tiket
enum CheckInStatus {
  success,
  alreadyCheckedIn,
  invalidTicket;

  static CheckInStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'SUCCESS':
        return CheckInStatus.success;
      case 'ALREADY_CHECKED_IN':
        return CheckInStatus.alreadyCheckedIn;
      case 'INVALID_TICKET':
      default:
        return CheckInStatus.invalidTicket;
    }
  }

  String get serialized {
    switch (this) {
      case CheckInStatus.success:
        return 'SUCCESS';
      case CheckInStatus.alreadyCheckedIn:
        return 'ALREADY_CHECKED_IN';
      case CheckInStatus.invalidTicket:
        return 'INVALID_TICKET';
    }
  }
}

/// Model Data Peserta yang Muncul di Layar Scanner Panitia
class ScannerParticipantModel {
  final String name;
  final String? nim;
  final String? studyProgram;
  final int? cohortYear;

  const ScannerParticipantModel({
    required this.name,
    this.nim,
    this.studyProgram,
    this.cohortYear,
  });

  factory ScannerParticipantModel.fromJson(Map<String, dynamic> json) {
    return ScannerParticipantModel(
      name: json['name'] as String? ?? 'Peserta Kampus',
      nim: json['nim'] as String?,
      studyProgram: json['study_program'] as String?,
      cohortYear: json['cohort_year'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (nim != null) 'nim': nim,
      if (studyProgram != null) 'study_program': studyProgram,
      if (cohortYear != null) 'cohort_year': cohortYear,
    };
  }
}

/// Model Respon Pemindaian Tiket Presensi (`POST /panitia/check-in/scan`)
class CheckInResultModel {
  final CheckInStatus status;
  final String message;
  final String? ticketCode;
  final DateTime? checkedInAt;
  final DateTime? firstCheckedInAt;
  final ScannerParticipantModel? participant;

  const CheckInResultModel({
    required this.status,
    required this.message,
    this.ticketCode,
    this.checkedInAt,
    this.firstCheckedInAt,
    this.participant,
  });

  bool get isSuccess => status == CheckInStatus.success;
  bool get isAlreadyCheckedIn => status == CheckInStatus.alreadyCheckedIn;
  bool get isInvalid => status == CheckInStatus.invalidTicket;

  factory CheckInResultModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? 'INVALID_TICKET';
    final status = CheckInStatus.fromString(rawStatus);
    final data = json['data'] as Map<String, dynamic>? ?? {};

    DateTime? checkedIn;
    if (data['checked_in_at'] != null) {
      checkedIn = DateTime.tryParse(data['checked_in_at'] as String);
    }

    DateTime? firstCheckedIn;
    if (data['first_checked_in_at'] != null) {
      firstCheckedIn = DateTime.tryParse(data['first_checked_in_at'] as String);
    }

    ScannerParticipantModel? participant;
    if (data['participant'] is Map<String, dynamic>) {
      participant = ScannerParticipantModel.fromJson(data['participant'] as Map<String, dynamic>);
    } else if (data['participant_name'] != null) {
      participant = ScannerParticipantModel(
        name: data['participant_name'] as String? ?? 'Peserta Kampus',
      );
    }

    return CheckInResultModel(
      status: status,
      message: json['message'] as String? ??
          (status == CheckInStatus.success ? 'Presensi berhasil.' : 'Tiket tidak valid.'),
      ticketCode: data['ticket_code'] as String? ?? json['ticket_code'] as String?,
      checkedInAt: checkedIn,
      firstCheckedInAt: firstCheckedIn,
      participant: participant,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.serialized,
      'message': message,
      'data': {
        if (ticketCode != null) 'ticket_code': ticketCode,
        if (checkedInAt != null) 'checked_in_at': checkedInAt?.toIso8601String(),
        if (firstCheckedInAt != null) 'first_checked_in_at': firstCheckedInAt?.toIso8601String(),
        if (participant != null) 'participant': participant?.toJson(),
      },
    };
  }
}

/// Model Acara Panitia untuk Layar Pemilih Gerbang Presensi (SCR-13)
class GateEventModel {
  final int id;
  final String title;
  final String slug;
  final String location;
  final DateTime startAt;
  final int totalQuota;
  final int attendedCount;
  final String organizationName;

  const GateEventModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.location,
    required this.startAt,
    required this.totalQuota,
    required this.attendedCount,
    required this.organizationName,
  });

  factory GateEventModel.fromJson(Map<String, dynamic> json) {
    return GateEventModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      location: json['location'] as String? ?? 'Kampus Meruya UMB',
      startAt: json['start_at'] != null ? DateTime.parse(json['start_at'] as String) : DateTime.now(),
      totalQuota: json['total_quota'] as int? ?? json['quota'] as int? ?? 100,
      attendedCount: json['attended_count'] as int? ?? 0,
      organizationName: json['organization_name'] as String? ?? 'Ormawa UMB',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'location': location,
      'start_at': startAt.toIso8601String(),
      'total_quota': totalQuota,
      'attended_count': attendedCount,
      'organization_name': organizationName,
    };
  }
}

