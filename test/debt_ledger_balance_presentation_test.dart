import 'package:doctorbike/core/services/translations_service.dart';
import 'package:doctorbike/features/admin/debts/data/models/debt_ledger_models.dart';
import 'package:doctorbike/features/admin/debts/domain/repositories/debt_ledger_repository.dart';
import 'package:doctorbike/features/admin/debts/presentation/controllers/debt_ledger_controller.dart';
import 'package:doctorbike/features/admin/debts/presentation/ledger/ledger_colors.dart';
import 'package:doctorbike/features/admin/debts/presentation/ledger/debt_ledger_pdf.dart';
import 'package:doctorbike/features/admin/debts/presentation/ledger/ledger_format.dart';
import 'package:doctorbike/features/admin/debts/presentation/ledger/person_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('ar'));

  test('supplier PDF builds with explicit balance ownership in both layouts',
      () async {
    for (final detail in ['summary', 'detailed']) {
      final bytes = await DebtLedgerPdf.build({
        'person': {'name': 'مورد تجريبي', 'person_type': 'seller'},
        'detail_level': detail,
        'total_taken': 1000,
        'total_given': 1567,
        'balance': -567,
        'period_label': 'جميع المعاملات — شيكل',
        'transactions': [
          {
            'id': 1,
            'type': 'given',
            'amount': 1567,
            'balance_after': -567,
            'transaction_date': '2026-10-19',
          }
        ],
      });
      expect(bytes.take(4), [37, 80, 68, 70]);
    }
  });
  test('supplier purchase, payment and credit use the correct perspective', () {
    final ledger = _Controller();
    ledger.currentTab.value = 1;
    expect(ledger.balanceLabel(2233), 'عليك للمورد');
    expect(ledger.balanceColor(2233), LedgerColors.givenRed);
    expect(ledger.balanceText(-567), 'لك عند المورد 567.00 ₪');
    expect(ledger.balanceColor(-567), LedgerColors.takenGreen);
    expect(ledger.transactionColor('taken'), LedgerColors.takenGreen);
    expect(ledger.transactionColor('given'), LedgerColors.givenRed);
    expect(ledger.balanceLabel(0), 'الحساب مسدّد');
    expect(ledger.balanceColor(0), LedgerColors.neutral);
  });

  test('balance ownership follows the ledger sign for every account', () {
    final ledger = _Controller();
    ledger.currentTab.value = 0;
    expect(ledger.balanceLabel(2233), 'عليك للعميل');
    expect(ledger.balanceColor(2233), LedgerColors.givenRed);
    expect(
        ledger.balanceText(-567, currency: 'دولار'), 'لك عند العميل 567.00 \$');
    ledger.selectedPerson = LedgerPersonInfo(
      id: 4,
      name: 'خاص',
      personType: 'seller',
      labelScope: 'private',
    );
    expect(ledger.balanceLabel(2233), 'عليك');
    expect(ledger.balanceLabel(-567), 'لك');
    expect(ledger.balanceColor(2233), LedgerColors.givenRed);
    final customer = LedgerPerson(
        id: 4,
        name: 'عميل',
        personType: 'customer',
        totalTaken: 0,
        totalGiven: 0,
        balance: 2233,
        transactionsCount: 0);
    expect(ledger.balanceColor(2233, person: customer), LedgerColors.givenRed);
    expect(LedgerFormat.balanceLabel(-0.001, supplier: true), 'الحساب مسدّد');
  });

  for (final size in [const Size(360, 640), const Size(640, 360)]) {
    testWidgets('supplier balance and previous credit fit at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      Get.testMode = true;
      addTearDown(() {
        Get.reset();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final ledger = _Controller();
      final person =
          LedgerPersonInfo(id: 9, name: 'مورد تجريبي', personType: 'seller');
      ledger.selectedPerson = person;
      ledger.personDetail.value = LedgerPersonDetail(
        person: person,
        totalTaken: 26753,
        totalGiven: 24520,
        balance: 2233,
        balancesByCurrency: {
          'شيكل': const LedgerCurrencyBalance(
              totalTaken: 26753, totalGiven: 24520, balance: 2233)
        },
        activeTransactionsCount: 2,
        transactions: [
          LedgerTransaction(
              id: 1,
              type: 'given',
              typeLabel: 'أعطيت',
              amount: 6000,
              balanceBefore: 8233,
              balanceAfter: 2233,
              receiptImages: [],
              transactionDate: '2026-10-19',
              note: 'دفعة للمورد'),
          LedgerTransaction(
              id: 2,
              type: 'taken',
              typeLabel: 'أخذت',
              amount: 8800,
              balanceBefore: -567,
              balanceAfter: 8233,
              receiptImages: [],
              transactionDate: '2026-10-19',
              note: 'استلام بضاعة'),
        ],
      );
      Get.put<DebtLedgerController>(ledger);
      await tester.pumpWidget(ScreenUtilInit(
        designSize: size,
        minTextAdapt: true,
        builder: (_, __) => GetMaterialApp(
          translations: Translation(),
          locale: const Locale('ar'),
          home: const PersonDetailScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('عليك للمورد'), findsWidgets);
      expect(tester.widget<Text>(find.text('2233.0 ₪').first).style?.color,
          LedgerColors.givenRed);
      final previous = find.textContaining('لك عند المورد 567.00 ₪');
      await tester.scrollUntilVisible(previous, 160,
          scrollable: find
              .descendant(
                  of: find.byType(ListView).first,
                  matching: find.byType(Scrollable))
              .first);
      await tester.pumpAndSettle();
      expect(
          tester.widget<Text>(previous).style?.color, LedgerColors.takenGreen);
      expect(find.textContaining('-567'), findsNothing);
      final buttons =
          tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
      expect(
          buttons.map((button) => button.style?.backgroundColor?.resolve({})),
          containsAll([LedgerColors.takenGreen, LedgerColors.givenRed]));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

class _Controller extends DebtLedgerController {
  _Controller() : super(repository: _UnusedRepository());
  @override
  Future<void> loadMainData() async {}
  @override
  Future<void> loadPersonDetail() async {}
}

class _UnusedRepository implements DebtLedgerRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
