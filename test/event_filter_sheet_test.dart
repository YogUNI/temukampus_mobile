import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temukampus_mobile/app/theme/app_shadows.dart';
import 'package:temukampus_mobile/features/events/data/models/event_model.dart';
import 'package:temukampus_mobile/features/events/presentation/widgets/event_filter_sheet.dart';

const _orgs = [
  EventOrganizationModel(id: 1, name: 'BEM Fakultas Teknik', slug: 'bem-teknik'),
  EventOrganizationModel(id: 2, name: 'BEM Fakultas Ekonomi', slug: 'bem-ekonomi'),
];

void main() {
  late String? appliedFormat;
  late bool appliedOnlyFree;
  late bool appliedOnlySkp;
  late bool appliedSuitable;
  late int? appliedMaxPrice;
  late Set<String> appliedOrgs;
  var resetCount = 0;

  Future<void> pumpSheet(
    WidgetTester tester, {
    bool onlyFree = false,
  }) async {
    appliedFormat = null;
    appliedOnlyFree = false;
    appliedOnlySkp = false;
    appliedSuitable = false;
    appliedMaxPrice = null;
    appliedOrgs = {};
    resetCount = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => Center(
            child: ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => EventFilterSheet(
                    initialFormat: null,
                    initialOnlyFree: onlyFree,
                    initialOnlySkp: false,
                    initialSuitableForMe: false,
                    availableOrganizations: _orgs,
                    maxPriceLimit: 500000,
                    onApply: ({
                      required format,
                      required onlyFree,
                      required onlySkp,
                      required suitableForMe,
                      required maxPrice,
                      required organizationSlugs,
                    }) {
                      appliedFormat = format;
                      appliedOnlyFree = onlyFree;
                      appliedOnlySkp = onlySkp;
                      appliedSuitable = suitableForMe;
                      appliedMaxPrice = maxPrice;
                      appliedOrgs = organizationSlugs;
                    },
                    onReset: () => resetCount++,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan slider harga & chips ormawa', (tester) async {
    await pumpSheet(tester);

    expect(find.text('Filter Acara Kampus'), findsOneWidget);
    expect(find.text('Rentang Harga'), findsOneWidget);
    expect(find.byType(RangeSlider), findsOneWidget);
    expect(find.text('Ormawa Penyelenggara'), findsOneWidget);
    expect(find.text('BEM Fakultas Teknik'), findsOneWidget);
    expect(find.text('BEM Fakultas Ekonomi'), findsOneWidget);
    expect(find.text('Terapkan'), findsOneWidget);
  });

  testWidgets('preset harga ≤ Rp 100rb mengirim maxPrice 100000',
      (tester) async {
    await pumpSheet(tester);

    await tester.ensureVisible(find.text('≤ Rp 100rb'));
    await tester.pump(AppDurations.fast);
    await tester.tap(find.text('≤ Rp 100rb'));
    await tester.pump(AppDurations.fast);
    await tester.tap(find.textContaining('Terapkan'));
    await tester.pumpAndSettle();

    expect(appliedMaxPrice, 100000);
  });

  testWidgets('chip ormawa terkirim saat terapkan', (tester) async {
    await pumpSheet(tester);

    await tester.ensureVisible(find.text('BEM Fakultas Teknik'));
    await tester.pump(AppDurations.fast);
    await tester.tap(find.text('BEM Fakultas Teknik'));
    await tester.pump(AppDurations.fast);
    await tester.tap(find.textContaining('Terapkan'));
    await tester.pumpAndSettle();

    expect(appliedOrgs, {'bem-teknik'});
    expect(appliedOnlyFree, isFalse);
    expect(appliedOnlySkp, isFalse);
    expect(appliedSuitable, isFalse);
    expect(appliedFormat, isNull);
  });

  testWidgets('hitungan filter aktif muncul pada label tombol', (tester) async {
    await pumpSheet(tester);

    // Tidak ada filter aktif
    expect(find.text('Terapkan'), findsOneWidget);

    // Aktifkan SKP + pilih preset harga
    await tester.tap(find.text('≤ Rp 50rb'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Terapkan (2)'), findsOneWidget);
  });

  testWidgets('mode Gratis Saja menyembunyikan slider harga', (tester) async {
    await pumpSheet(tester, onlyFree: true);

    expect(find.text('Rentang Harga'), findsNothing);
    expect(find.byType(RangeSlider), findsNothing);
    expect(find.text('Gratis Saja'), findsOneWidget);

    await tester.tap(find.textContaining('Terapkan'));
    await tester.pumpAndSettle();
    expect(appliedOnlyFree, isTrue);
  });

  testWidgets('Reset Semua memanggil onReset', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(resetCount, 1);
    expect(find.text('Filter Acara Kampus'), findsNothing);
  });
}