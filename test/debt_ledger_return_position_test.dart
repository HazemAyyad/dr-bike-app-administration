import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:doctorbike/core/errors/failure.dart';
import 'package:doctorbike/routes/app_routes.dart';
import 'package:doctorbike/core/services/translations_service.dart';
import 'package:doctorbike/features/admin/debts/data/models/debt_ledger_models.dart';
import 'package:doctorbike/features/admin/debts/domain/repositories/debt_ledger_repository.dart';
import 'package:doctorbike/features/admin/debts/presentation/controllers/debt_ledger_controller.dart';
import 'package:doctorbike/features/admin/debts/presentation/ledger/ledger_colors.dart';
import 'package:doctorbike/features/admin/debts/presentation/ledger/person_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  for (final source in ['manual', 'sales_order']) {
    testWidgets('$source return keeps the opened row visible during refresh',
        (tester) async {
      tester.view.physicalSize = const Size(640, 900);
      tester.view.devicePixelRatio = 1;
      Get.testMode = true;
      addTearDown(() {
        Get.reset();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repository = _Repository(source);
      final ledger = _Controller(repository);
      ledger.selectedPerson = repository.person;
      Get.put<DebtLedgerController>(ledger);
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(640, 900),
        builder: (_, __) => GetMaterialApp(
          translations: Translation(),
          locale: const Locale('ar'),
          home: const PersonDetailScreen(),
          getPages: [
            GetPage(
              name: AppRoutes.SALESORDERDETAILSCREEN,
              page: () =>
                  Scaffold(appBar: AppBar(title: const Text('الفاتورة'))),
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      final row = find.text('قيد 18');
      final card = find.ancestor(of: row, matching: find.byType(InkWell)).first;
      final scrollable = find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(row, 250, scrollable: scrollable);
      await tester.pumpAndSettle();
      final position = tester.state<ScrollableState>(scrollable).position;
      final oldPixels = position.pixels;
      final oldTop = tester.getTopLeft(card).dy;
      final untouchedRow = tester.widget(find.text('قيد 17'));
      expect(oldPixels, greaterThan(1000));
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(tester.widget(find.text('قيد 17', skipOffstage: false)),
          same(untouchedRow));

      // Hold the network response after the back arrow is pressed.
      repository.pending = Completer<Either<Failure, LedgerPersonDetail>>();
      await tester.tap(find.byType(BackButton).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(ledger.personLoading.value, isFalse);
      expect(
          tester.state<ScrollableState>(scrollable).position, same(position));
      expect(position.pixels, closeTo(oldPixels, 1));
      expect(tester.getTopLeft(card).dy, closeTo(oldTop, 1));

      // The response changes the amount and adds height above the opened row.
      repository.pending!.complete(Right(repository.detail(updated: true)));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(card).dy, closeTo(oldTop, 1));
      expect(find.textContaining('9876.00'), findsOneWidget);
      final focusedBorders = tester
          .widgetList<Container>(
        find.ancestor(of: row, matching: find.byType(Container)),
      )
          .where((widget) {
        final decoration = widget.decoration;
        return decoration is BoxDecoration &&
            decoration.border is Border &&
            (decoration.border! as Border).top.color ==
                LedgerColors.primaryBlue;
      });
      expect(focusedBorders, hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  test('another account still uses the initial loading state', () async {
    final repository = _Repository('manual');
    final ledger = _Controller(repository);
    ledger.personDetail.value = repository.detail();
    ledger.selectedPerson =
        LedgerPersonInfo(id: 2, name: 'حساب آخر', personType: 'customer');
    repository.pending = Completer<Either<Failure, LedgerPersonDetail>>();
    final loading = ledger.loadPersonDetail();
    expect(ledger.personLoading.value, isTrue);
    ledger.selectedPerson =
        LedgerPersonInfo(id: 3, name: 'حساب أحدث', personType: 'customer');
    repository.pending!.complete(Right(repository.detail()));
    await loading;
    expect(ledger.personLoading.value, isFalse);
    expect(ledger.selectedPerson!.id, 3);
  });
}

class _Controller extends DebtLedgerController {
  _Controller(DebtLedgerRepository repository) : super(repository: repository);

  @override
  Future<void> loadMainData() async {}
}

class _Repository implements DebtLedgerRepository {
  _Repository(this.source);
  final String source;
  final person =
      LedgerPersonInfo(id: 1, name: 'حساب تجريبي', personType: 'customer');
  Completer<Either<Failure, LedgerPersonDetail>>? pending;

  LedgerPersonDetail detail({bool updated = false}) => LedgerPersonDetail(
        person: person,
        totalTaken: 100,
        totalGiven: 0,
        balance: updated ? 9876 : 100,
        activeTransactionsCount: 30,
        transactions: List.generate(
          30,
          (index) => LedgerTransaction(
            id: index + 1,
            type: 'taken',
            typeLabel: 'أخذت',
            amount: updated && index == 18 ? 9876 : 100 + index.toDouble(),
            balanceBefore: 0,
            balanceAfter: 100,
            receiptImages: [],
            transactionDate: '2026-11-19',
            note: updated && index == 4
                ? List.filled(12, 'تفاصيل إضافية بعد التعديل').join('\n')
                : 'قيد $index',
            source: index == 18 ? source : 'manual',
            sourceId: index == 18 && source != 'manual' ? 50 : null,
          ),
        ),
      );

  @override
  Future<Either<Failure, LedgerPersonDetail>> getPerson({
    int? customerId,
    int? sellerId,
    String? startDate,
    String? endDate,
    String? currency,
    String? balanceScope,
  }) async =>
      pending == null ? Right(detail()) : await pending!.future;

  @override
  Future<Either<Failure, LedgerSummary>> getSummary() async =>
      Right(LedgerSummary.fromJson({}));

  @override
  Future<Either<Failure, List<LedgerActivityEntry>>> getPersonActivity({
    int? customerId,
    int? sellerId,
    String? currency,
  }) async =>
      const Right([]);

  @override
  Future<Either<Failure, List<LedgerActivityEntry>>> getTransactionActivity(
          int transactionId) async =>
      const Right([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
