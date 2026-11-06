/// Model data Program Studi UMB.
class StudyProgramModel {
  final int? id;
  final String code;
  final String name;

  const StudyProgramModel({
    this.id,
    required this.code,
    required this.name,
  });

  factory StudyProgramModel.fromJson(Map<String, dynamic> json) {
    return StudyProgramModel(
      id: json['id'] as int?,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'name': name,
    };
  }
}

/// Model Organisasi yang dikelola user (jika user berperan sebagai panitia/admin).
class ManagedOrgModel {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String roleInOrg;

  const ManagedOrgModel({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.roleInOrg = 'panitia',
  });

  factory ManagedOrgModel.fromJson(Map<String, dynamic> json) {
    return ManagedOrgModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      roleInOrg: json['role_in_org'] as String? ?? 'panitia',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'logo_url': logoUrl,
      'role_in_org': roleInOrg,
    };
  }
}

/// Model Pengguna resmi TemuKampus (Mahasiswa UMB, Eksternal, atau Panitia).
/// Sesuai spesifikasi database docs/05-DATABASE-AND-DOMAIN-SPEC.md.
class UserModel {
  final int id;
  final String name;
  final String email;
  final String role; // 'user', 'admin', 'superadmin'
  final String accountType; // 'umb', 'external'
  final String? nim;
  final String? phone;
  final String? avatarUrl;
  final String? institutionName;
  final StudyProgramModel? studyProgram;
  final int? cohortYear;
  final bool emailVerified;
  final bool isOrganizer;
  final List<ManagedOrgModel> managedOrganizations;
  final String status; // 'active', 'suspended'
  final String? suspensionReason;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.accountType = 'umb',
    this.nim,
    this.phone,
    this.avatarUrl,
    this.institutionName,
    this.studyProgram,
    this.cohortYear,
    this.emailVerified = false,
    this.isOrganizer = false,
    this.managedOrganizations = const [],
    this.status = 'active',
    this.suspensionReason,
  });

  bool get isUmbStudent => accountType == 'umb' && nim != null;
  bool get isSuspended => status == 'suspended';
  bool get canScanTickets => isOrganizer || role == 'admin' || role == 'superadmin';

  /// Ringkasan akademik, misal: "Teknik Informatika '24"
  String get academicSummary {
    if (isUmbStudent && studyProgram != null && cohortYear != null) {
      final shortYear = cohortYear.toString().substring(2);
      return "${studyProgram!.name} '$shortYear";
    }
    if (institutionName != null && institutionName!.isNotEmpty) {
      return institutionName!;
    }
    return 'Mahasiswa UMB';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      accountType: json['account_type'] as String? ?? 'umb',
      nim: json['nim'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      institutionName: json['institution_name'] as String?,
      studyProgram: json['study_program'] != null
          ? StudyProgramModel.fromJson(json['study_program'] as Map<String, dynamic>)
          : null,
      cohortYear: json['cohort_year'] as int?,
      emailVerified: json['email_verified'] as bool? ?? false,
      isOrganizer: json['is_organizer'] as bool? ??
          (json['role'] == 'admin' || json['role'] == 'superadmin'),
      managedOrganizations: (json['managed_organizations'] as List<dynamic>?)
              ?.map((e) => ManagedOrgModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      status: json['status'] as String? ?? 'active',
      suspensionReason: json['suspension_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'account_type': accountType,
      'nim': nim,
      'phone': phone,
      'avatar_url': avatarUrl,
      'institution_name': institutionName,
      'study_program': studyProgram?.toJson(),
      'cohort_year': cohortYear,
      'email_verified': emailVerified,
      'is_organizer': isOrganizer,
      'managed_organizations': managedOrganizations.map((e) => e.toJson()).toList(),
      'status': status,
      if (suspensionReason != null) 'suspension_reason': suspensionReason,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? accountType,
    String? nim,
    String? phone,
    String? avatarUrl,
    String? institutionName,
    StudyProgramModel? studyProgram,
    int? cohortYear,
    bool? emailVerified,
    bool? isOrganizer,
    List<ManagedOrgModel>? managedOrganizations,
    String? status,
    String? suspensionReason,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      accountType: accountType ?? this.accountType,
      nim: nim ?? this.nim,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      institutionName: institutionName ?? this.institutionName,
      studyProgram: studyProgram ?? this.studyProgram,
      cohortYear: cohortYear ?? this.cohortYear,
      emailVerified: emailVerified ?? this.emailVerified,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      managedOrganizations: managedOrganizations ?? this.managedOrganizations,
      status: status ?? this.status,
      suspensionReason: suspensionReason ?? this.suspensionReason,
    );
  }
}
