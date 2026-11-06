import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/features/events/data/models/event_model.dart';

void main() {
  group('EventModel Unit Tests', () {
    test('Berhasil parse EventModel dari JSON berbayar lengkap dengan pembatasan & data bank', () {
      final json = {
        'id': 1,
        'title': 'Seminar Nasional AI',
        'slug': 'seminar-nasional-ai',
        'summary': 'Membahas model fondasi AI',
        'description': '## Deskripsi Lengkap AI',
        'format': 'hybrid',
        'start_at': '2026-11-20T09:00:00Z',
        'end_at': '2026-11-20T12:00:00Z',
        'location': 'Auditorium Tower UMB',
        'is_paid': true,
        'price': 25000,
        'formatted_price': 'Rp 25.000',
        'skp_points': 2,
        'has_certificate': true,
        'audience': 'restricted',
        'restrictions': {
          'allowed_faculties': ['Fakultas Ilmu Komputer'],
          'allowed_programs': ['Teknik Informatika', 'Sistem Informasi'],
          'cohort_min': 2022,
          'cohort_max': 2026,
        },
        'quota': 200,
        'remaining_quota': 48,
        'registered_count': 152,
        'is_full': false,
        'bank_name': 'Bank Central Asia (BCA)',
        'bank_account_number': '5410982311',
        'bank_account_name': 'HIMA TEKNIK INFORMATIKA UMB',
        'qris_image_url': 'http://temukampus.test/qris.png',
        'organization': {
          'id': 1,
          'name': 'HIMA Teknik Informatika UMB',
          'slug': 'hima-ti',
        },
        'cta_state': {
          'status': 'can_register',
          'label': 'Daftar & Bayar',
          'reason': null,
          'has_active_ticket': false,
          'active_ticket_code': null,
        },
      };

      final event = EventModel.fromJson(json);

      expect(event.id, equals(1));
      expect(event.isPaid, isTrue);
      expect(event.isFree, isFalse);
      expect(event.hasSkp, isTrue);
      expect(event.skpPoints, equals(2));
      expect(event.isFull, isFalse);
      expect(event.registeredCount, equals(152));
      expect(event.formatLabel, equals('Hybrid (Tatap Muka & Daring)'));
      expect(event.organization.name, equals('HIMA Teknik Informatika UMB'));

      // Check restrictions
      expect(event.restrictions.hasRestrictions, isTrue);
      expect(event.restrictions.allowedFaculties, contains('Fakultas Ilmu Komputer'));
      expect(event.restrictions.allowedPrograms, contains('Teknik Informatika'));
      expect(event.restrictions.cohortMin, equals(2022));
      expect(event.restrictions.cohortMax, equals(2026));

      // Check payment data
      expect(event.bankName, equals('Bank Central Asia (BCA)'));
      expect(event.bankAccountNumber, equals('5410982311'));
      expect(event.qrisImageUrl, equals('http://temukampus.test/qris.png'));

      // Check ctaState
      expect(event.ctaState, isNotNull);
      expect(event.ctaState!.status, equals(EventCtaState.canRegister));
      expect(event.ctaState!.label, equals('Daftar & Bayar'));
    });

    test('Berhasil parse EventModel dari JSON acara gratis', () {
      final json = {
        'id': 2,
        'title': 'Workshop Flutter Mahasiswa',
        'slug': 'workshop-flutter',
        'summary': 'Membangun aplikasi mobile',
        'format': 'offline',
        'location': 'Lab Komputer',
        'is_paid': false,
        'price': 0,
        'formatted_price': 'Gratis',
        'skp_points': 1,
        'quota': 50,
        'remaining_quota': 5,
        'organization': {
          'id': 2,
          'name': 'UKM Computer Club',
          'slug': 'computer-club',
        },
      };

      final event = EventModel.fromJson(json);

      expect(event.isFree, isTrue);
      expect(event.isQuotaAlmostFull, isTrue);
      expect(event.formatLabel, equals('Tatap Muka (Offline)'));
    });

    test('Berhasil menguji CategoryModel & EventFilterModel', () {
      final categoryJson = {
        'id': 2,
        'name': 'Teknologi & Komputer',
        'slug': 'teknologi',
        'icon_name': 'memory',
      };

      final category = CategoryModel.fromJson(categoryJson);
      expect(category.id, equals(2));
      expect(category.name, equals('Teknologi & Komputer'));
      expect(category.slug, equals('teknologi'));
      expect(category.iconName, equals('memory'));

      final filter = EventFilterModel(
        searchQuery: 'flutter',
        categorySlug: 'teknologi',
        format: 'offline',
        isFreeOnly: true,
        suitableForMeOnly: true,
      );

      expect(filter.hasActiveFilter, isTrue);
      final queryParams = filter.toQueryParams();
      expect(queryParams['search'], equals('flutter'));
      expect(queryParams['category'], equals('teknologi'));
      expect(queryParams['format'], equals('offline'));
      expect(queryParams['free_only'], equals(1));
      expect(queryParams['suitable_for_me'], equals(1));
    });

    test('Berhasil parse EligibilityResultModel berbagai CTA state', () {
      final jsonCanRegister = {
        'is_eligible': true,
        'cta_state': 'can_register',
        'cta_label': 'Daftar Sekarang',
      };
      final res1 = EligibilityResultModel.fromJson(jsonCanRegister);
      expect(res1.ctaState, equals(EventCtaState.canRegister));
      expect(res1.isEligible, isTrue);

      final jsonQuotaFull = {
        'is_eligible': false,
        'cta_state': 'quota_full',
        'cta_label': 'Kuota Penuh',
      };
      final res2 = EligibilityResultModel.fromJson(jsonQuotaFull);
      expect(res2.ctaState, equals(EventCtaState.quotaFull));

      final jsonNotEligible = {
        'is_eligible': false,
        'cta_state': 'not_eligible',
        'reasons': ['Khusus Mahasiswa Fasilkom Angkatan 2024'],
      };
      final res3 = EligibilityResultModel.fromJson(jsonNotEligible);
      expect(res3.ctaState, equals(EventCtaState.notEligible));
      expect(res3.reasons.first, contains('Fasilkom'));
    });
  });
}
