import '../../../events/data/models/event_model.dart';
import '../../../../core/network/media_url.dart';

/// Organisasi kampus (BEM, himpunan, UKM, UKK) untuk direktori.
///
/// Bentuknya mengikuti `OrganizationResource` di API v1 — bukan sumber kedua.
class OrganizationModel {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? type;
  final String? typeLabel;
  final String? description;
  final String? instagram;
  final String? contactEmail;
  final String? facultyName;
  final String? studyProgramName;
  final int upcomingEventsCount;

  const OrganizationModel({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.type,
    this.typeLabel,
    this.description,
    this.instagram,
    this.contactEmail,
    this.facultyName,
    this.studyProgramName,
    this.upcomingEventsCount = 0,
  });

  /// Inisial untuk avatar cadangan saat logo belum ada.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) return 'TK';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    final faculty = json['faculty'];
    final studyProgram = json['study_program'];

    return OrganizationModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      logoUrl: MediaUrl.resolve(json['logo_url'] as String?),
      type: json['type'] as String?,
      typeLabel: json['type_label'] as String?,
      description: json['description'] as String?,
      instagram: json['instagram'] as String?,
      contactEmail: json['contact_email'] as String?,
      facultyName: faculty is Map<String, dynamic> ? faculty['name'] as String? : null,
      studyProgramName:
          studyProgram is Map<String, dynamic> ? studyProgram['name'] as String? : null,
      upcomingEventsCount: json['upcoming_events_count'] as int? ?? 0,
    );
  }
}

/// Kelompok chip di direktori (sama dengan web: BEM/DPM, Himpunan, UKM, UKK).
class OrganizationGroupModel {
  final String key;
  final String label;
  final int count;

  const OrganizationGroupModel({
    required this.key,
    required this.label,
    required this.count,
  });
}

/// Hasil satu permintaan direktori: daftar + chip + hitungan.
class OrganizationDirectoryModel {
  final List<OrganizationModel> items;
  final List<OrganizationGroupModel> groups;
  final int total;
  final String activeGroup;

  /// Jumlah seluruh organisasi aktif (chip "Semua").
  final int overallCount;

  const OrganizationDirectoryModel({
    required this.items,
    required this.groups,
    required this.total,
    required this.activeGroup,
    required this.overallCount,
  });

  factory OrganizationDirectoryModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final counts = meta['counts'] as Map<String, dynamic>? ?? {};
    final rawGroups = meta['groups'] as List<dynamic>? ?? [];

    return OrganizationDirectoryModel(
      items: (json['data'] as List<dynamic>? ?? [])
          .map((e) => OrganizationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      groups: rawGroups.map((g) {
        final map = g as Map<String, dynamic>;
        final key = map['key'] as String? ?? '';

        return OrganizationGroupModel(
          key: key,
          label: map['label'] as String? ?? '',
          count: counts[key] as int? ?? 0,
        );
      }).toList(),
      total: meta['total'] as int? ?? 0,
      activeGroup: meta['active_group'] as String? ?? '',
      overallCount: counts['semua'] as int? ?? 0,
    );
  }
}

/// Detail organisasi: profil + acara mendatang + arsip.
class OrganizationDetailModel {
  final OrganizationModel organization;
  final List<EventModel> upcomingEvents;
  final List<EventModel> pastEvents;

  const OrganizationDetailModel({
    required this.organization,
    required this.upcomingEvents,
    required this.pastEvents,
  });

  factory OrganizationDetailModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    List<EventModel> parse(dynamic raw) => (raw as List<dynamic>? ?? [])
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return OrganizationDetailModel(
      organization: OrganizationModel.fromJson(
        data['organization'] as Map<String, dynamic>? ?? {},
      ),
      upcomingEvents: parse(data['upcoming_events']),
      pastEvents: parse(data['past_events']),
    );
  }
}
