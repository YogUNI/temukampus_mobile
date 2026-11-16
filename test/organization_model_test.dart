import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/features/organizations/data/models/organization_model.dart';

/// Model direktori organisasi harus membaca respons API v1 apa adanya —
/// fixture di bawah direkam langsung dari `GET /api/v1/organizations`.
void main() {
  test('direktori membaca data, chip kelompok, dan hitungan', () {
    final json = {
      'success': true,
      'data': [
        {
          'id': 3,
          'name': 'HIMA Teknik Informatika',
          'slug': 'hima-ti',
          'logo_url': 'http://temukampus.test/storage/logos/hima.png',
          'type': 'hima',
          'type_label': 'Himpunan',
          'description': 'Himpunan mahasiswa TI.',
          'instagram': '@himati',
          'contact_email': 'hima.ti@example.test',
          'faculty': {'id': 2, 'name': 'Fakultas Ilmu Komputer'},
          'study_program': {'id': 1, 'code': '415', 'name': 'Teknik Informatika'},
          'upcoming_events_count': 3,
        },
      ],
      'meta': {
        'active_group': 'hima',
        'query': '',
        'faculty_id': null,
        'total': 1,
        'counts': {'semua': 46, 'bem-dpm': 11, 'hima': 19, 'ukm': 14, 'ukk': 2},
        'groups': [
          {'key': 'bem-dpm', 'label': 'BEM dan DPM'},
          {'key': 'hima', 'label': 'Himpunan'},
        ],
      },
    };

    final directory = OrganizationDirectoryModel.fromJson(json);

    expect(directory.items, hasLength(1));
    expect(directory.total, 1);
    expect(directory.activeGroup, 'hima');
    expect(directory.overallCount, 46);
    expect(directory.groups, hasLength(2));
    expect(directory.groups.first.count, 11);

    final organization = directory.items.first;

    expect(organization.name, 'HIMA Teknik Informatika');
    expect(organization.typeLabel, 'Himpunan');
    expect(organization.facultyName, 'Fakultas Ilmu Komputer');
    expect(organization.studyProgramName, 'Teknik Informatika');
    expect(organization.upcomingEventsCount, 3);
    expect(organization.initials, 'HT');
  });

  test('logo absolut ber-host web diselaraskan ke origin API', () {
    final organization = OrganizationModel.fromJson({
      'id': 1,
      'name': 'UKM Musik',
      'slug': 'ukm-musik',
      'logo_url': 'http://temukampus.test/storage/logos/ukm.png',
    });

    expect(organization.logoUrl, isNotNull);
    expect(organization.logoUrl!.endsWith('/storage/logos/ukm.png'), isTrue);
  });

  test('inisial diambil dari dua kata pertama', () {
    expect(
      const OrganizationModel(id: 1, name: 'BEM Fakultas Teknik', slug: 'bem-ft').initials,
      'BF',
    );
    expect(
      const OrganizationModel(id: 2, name: 'UKM', slug: 'ukm').initials,
      'U',
    );
  });
}
