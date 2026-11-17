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
