import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/features/events/data/models/event_model.dart';

void main() {
  group('EventModel Unit Tests', () {
    test('Berhasil parse EventModel dari JSON berbayar', () {
      final json = {
        'id': 1,
        'title': 'Seminar Nasional AI',
        'slug': 'seminar-nasional-ai',
        'summary': 'Membahas model fondasi AI',
        'format': 'hybrid',
        'start_at': '2026-11-20T09:00:00Z',
        'end_at': '2026-11-20T12:00:00Z',
        'location': 'Auditorium Tower UMB',
        'is_paid': true,
        'price': 25000,
        'formatted_price': 'Rp 25.000',
        'skp_points': 2,
        'has_certificate': true,
        'quota': 200,
        'remaining_quota': 48,
        'is_full': false,
        'organization': {
          'id': 1,
          'name': 'HIMA Teknik Informatika UMB',
          'slug': 'hima-ti',
        },
      };

      final event = EventModel.fromJson(json);

      expect(event.id, equals(1));
      expect(event.isPaid, isTrue);
      expect(event.isFree, isFalse);
      expect(event.hasSkp, isTrue);
      expect(event.skpPoints, equals(2));
      expect(event.isFull, isFalse);
      expect(event.formatLabel, equals('Hybrid (Tatap Muka & Daring)'));
      expect(event.organization.name, equals('HIMA Teknik Informatika UMB'));
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
