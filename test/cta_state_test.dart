import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/features/auth/data/models/user_model.dart';
import 'package:temukampus_mobile/features/events/data/models/event_model.dart';

void main() {
  group('EventCtaCalculator (11 CTA States strictly ordered by PRD §7.4.1)', () {
    final now = DateTime(2026, 11, 10, 10, 0);

    final standardOrg = const EventOrganizationModel(
      id: 1,
      name: 'HIMA TI UMB',
      slug: 'hima-ti',
    );

    final validUser = UserModel(
      id: 1,
      name: 'Yoga Pratama',
      email: 'yoga@mercubuana.ac.id',
      phone: '081234567890',
      role: 'user',
      accountType: 'umb',
      nim: '41524010001',
      emailVerified: true,
      studyProgram: const StudyProgramModel(id: 1, code: '415', name: 'Teknik Informatika'),
      cohortYear: 2024,
    );

    EventModel createEvent({
      bool isCancelled = false,
      DateTime? startAt,
      DateTime? endAt,
      DateTime? registrationOpenAt,
      DateTime? registrationCloseAt,
      String audience = 'public',
      EventRestrictions restrictions = const EventRestrictions(),
      int? quota = 100,
      int? remainingQuota = 50,
      bool isFull = false,
      bool isPaid = false,
      int price = 0,
      String formattedPrice = 'Gratis',
    }) {
      return EventModel(
        id: 1,
        title: 'Seminar AI 2026',
        slug: 'seminar-ai-2026',
        summary: 'Seminar ringkas AI',
        startAt: startAt ?? DateTime(2026, 11, 20, 9, 0),
        endAt: endAt ?? DateTime(2026, 11, 20, 12, 0),
        location: 'Auditorium Tower UMB',
        isCancelled: isCancelled,
        registrationOpenAt: registrationOpenAt ?? DateTime(2026, 11, 1, 0, 0),
        registrationCloseAt: registrationCloseAt ?? DateTime(2026, 11, 19, 23, 59),
        audience: audience,
        restrictions: restrictions,
        quota: quota,
        remainingQuota: remainingQuota,
        isFull: isFull,
        isPaid: isPaid,
        price: price,
        formattedPrice: formattedPrice,
        organization: standardOrg,
      );
    }

    // 1. Event Dibatalkan
    test('1. Return eventCancelled if event is cancelled', () {
      final event = createEvent(isCancelled: true);
      final cta = EventCtaCalculator.calculate(event: event, user: validUser, now: now);

      expect(cta.status, EventCtaState.eventCancelled);
      expect(cta.label, 'Acara Dibatalkan');
      expect(cta.reason, contains('dibatalkan'));
    });

    // 2. Event Selesai
    test('2. Return eventEnded if current time is after endAt', () {
      final event = createEvent(
        startAt: DateTime(2026, 11, 1, 9, 0),
        endAt: DateTime(2026, 11, 1, 12, 0),
      );
      final cta = EventCtaCalculator.calculate(event: event, user: validUser, now: now);

      expect(cta.status, EventCtaState.eventEnded);
      expect(cta.label, 'Pendaftaran Ditutup (Acara Selesai)');
    });

    // 3. Belum Login
    test('3. Return notLoggedIn if user is null', () {
      final event = createEvent();
      final cta = EventCtaCalculator.calculate(event: event, user: null, now: now);

      expect(cta.status, EventCtaState.notLoggedIn);
      expect(cta.label, 'Masuk untuk Mendaftar');
    });

    // 4. Email Belum Terverifikasi
    test('4. Return emailUnverified if user email is not verified', () {
      final unverifiedUser = validUser.copyWith(emailVerified: false);
      final event = createEvent();
      final cta = EventCtaCalculator.calculate(event: event, user: unverifiedUser, now: now);

      expect(cta.status, EventCtaState.emailUnverified);
      expect(cta.label, 'Verifikasi Email Terlebih Dahulu');
    });

    // 5. Profil Belum Lengkap (Nomor WhatsApp Kosong)
    test('5. Return profileIncomplete if user phone number is empty', () {
      final incompleteUser = validUser.copyWith(phone: '   ');
      final event = createEvent();
      final cta = EventCtaCalculator.calculate(event: event, user: incompleteUser, now: now);

      expect(cta.status, EventCtaState.profileIncomplete);
      expect(cta.label, 'Lengkapi Profil (No. WhatsApp)');
    });

    // 6. Sudah Punya Tiket Aktif
    test('6. Return alreadyRegistered if user already has an active ticket', () {
      final event = createEvent();
      final cta = EventCtaCalculator.calculate(
        event: event,
        user: validUser,
        now: now,
        hasActiveTicket: true,
        activeTicketCode: 'TK-2026-001',
      );

      expect(cta.status, EventCtaState.alreadyRegistered);
      expect(cta.label, 'Lihat Tiket Saya');
      expect(cta.hasActiveTicket, isTrue);
      expect(cta.activeTicketCode, 'TK-2026-001');
    });

    // 7. Tidak Eligible (Syarat Tidak Cocok)
    test('7a. Return notEligible if event is umb_only and user is external', () {
      final externalUser = validUser.copyWith(accountType: 'external', nim: null);
      final event = createEvent(audience: 'umb_only');
      final cta = EventCtaCalculator.calculate(event: event, user: externalUser, now: now);

      expect(cta.status, EventCtaState.notEligible);
      expect(cta.label, 'Syarat Tidak Cocok');
      expect(cta.reason, contains('khusus mahasiswa aktif'));
    });

    test('7b. Return notEligible if event restricted to another study program', () {
      final event = createEvent(
        audience: 'restricted',
        restrictions: const EventRestrictions(
          allowedPrograms: ['Desain Komunikasi Visual', 'Manajemen'],
        ),
      );
      final cta = EventCtaCalculator.calculate(event: event, user: validUser, now: now);

      expect(cta.status, EventCtaState.notEligible);
      expect(cta.label, 'Syarat Tidak Cocok');
      expect(cta.reason, contains('khusus mahasiswa prodi'));
    });

    test('7c. Return notEligible if user cohort year is outside restriction range', () {
      final event = createEvent(
        audience: 'restricted',
        restrictions: const EventRestrictions(
          allowedPrograms: ['Teknik Informatika'],
          cohortMin: 2021,
          cohortMax: 2023,
        ),
      );
      // validUser is cohort 2024 (higher than 2023)
      final cta = EventCtaCalculator.calculate(event: event, user: validUser, now: now);

      expect(cta.status, EventCtaState.notEligible);
      expect(cta.label, 'Syarat Tidak Cocok');
      expect(cta.reason, contains('2023 ke bawah'));
    });

    // 8. Pendaftaran Belum Dibuka
    test('8. Return notOpenYet if current time is before registrationOpenAt', () {
      final event = createEvent(
        registrationOpenAt: DateTime(2026, 11, 15, 0, 0),
      );
      final cta = EventCtaCalculator.calculate(event: event, user: validUser, now: now);

      expect(cta.status, EventCtaState.notOpenYet);
      expect(cta.label, 'Pendaftaran Belum Dibuka');
    });

    // 9. Pendaftaran Ditutup
    test('9. Return registrationClosed if current time is after registrationCloseAt', () {
      final event = createEvent(
        registrationCloseAt: DateTime(2026, 11, 5, 23, 59),
      );
      final cta = EventCtaCalculator.calculate(event: event, user: validUser, now: now);

      expect(cta.status, EventCtaState.registrationClosed);
      expect(cta.label, 'Pendaftaran Ditutup');
    });

    // 10. Kuota Penuh
    test('10. Return quotaFull if event is full or remainingQuota <= 0', () {
      final event = createEvent(
        isFull: true,
        remainingQuota: 0,
      );
      final cta = EventCtaCalculator.calculate(event: event, user: validUser, now: now);

      expect(cta.status, EventCtaState.quotaFull);
      expect(cta.label, 'Kuota Penuh');
    });

    // 11. Can Register (Eligible & Kuota Tersedia)
    test('11a. Return canRegister for free event', () {
      final event = createEvent(isPaid: false, price: 0, formattedPrice: 'Gratis');
      final cta = EventCtaCalculator.calculate(event: event, user: validUser, now: now);

      expect(cta.status, EventCtaState.canRegister);
      expect(cta.label, 'Daftar Sekarang (Gratis)');
      expect(cta.reason, isNull);
    });

    test('11b. Return canRegister with price label for paid event', () {
      final event = createEvent(isPaid: true, price: 25000, formattedPrice: 'Rp 25.000');
      final cta = EventCtaCalculator.calculate(event: event, user: validUser, now: now);

      expect(cta.status, EventCtaState.canRegister);
      expect(cta.label, 'Daftar & Bayar (Rp 25.000)');
      expect(cta.reason, isNull);
    });
  });
}

