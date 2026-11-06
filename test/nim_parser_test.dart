import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/core/utils/nim_parser.dart';

void main() {
  group('NimParser UMB Validation & Parsing Tests', () {
    test('Berhasil mem-parse NIM Teknik Informatika 2024', () {
      final result = NimParser.parse('41524010001');

      expect(result.isValid, isTrue);
      expect(result.programCode, equals('415'));
      expect(result.programName, equals('Teknik Informatika'));
      expect(result.facultyName, equals('Fakultas Ilmu Komputer'));
      expect(result.cohortYear, equals(2024));
      expect(result.sequenceNumber, equals('010001'));
      expect(result.summary, equals("Teknik Informatika '24"));
    });

    test('Berhasil mem-parse NIM Sistem Informasi 2023', () {
      final result = NimParser.parse('41823010055');

      expect(result.isValid, isTrue);
      expect(result.programCode, equals('418'));
      expect(result.programName, equals('Sistem Informasi'));
      expect(result.cohortYear, equals(2023));
      expect(result.summary, equals("Sistem Informasi '23"));
    });

    test('Menolak NIM yang kurang dari 11 digit', () {
      final result = NimParser.parse('4152401000'); // 10 digit

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('11 digit angka'));
    });

    test('Menolak NIM yang lebih dari 11 digit', () {
      final result = NimParser.parse('4152401000199'); // 13 digit

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('11 digit angka'));
    });

    test('Menolak NIM yang mengandung karakter non-angka', () {
      final result = NimParser.parse('4152401000A');

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('hanya boleh berisi digit angka'));
    });

    test('Menolak input kosong atau null', () {
      final emptyResult = NimParser.parse('');
      expect(emptyResult.isValid, isFalse);

      final nullResult = NimParser.parse(null);
      expect(nullResult.isValid, isFalse);
    });
  });
}

