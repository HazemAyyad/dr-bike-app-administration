import 'package:doctorbike/features/admin/debts/data/models/debt_ledger_labels.dart';
import 'package:doctorbike/features/admin/debts/data/models/debt_ledger_models.dart';
import 'package:doctorbike/features/admin/debts/domain/repositories/debt_ledger_repository.dart';
import 'package:doctorbike/features/admin/debts/presentation/controllers/debt_ledger_controller.dart';
import 'package:doctorbike/features/admin/debts/presentation/ledger/debt_labels_settings_sheet.dart';
import 'package:doctorbike/core/services/translations_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const labels = DebtLedgerLabels(
  general: DebtLedgerLabelPair(taken: 'عام أخذت', given: 'عام أعطيت'),
  byType: {
    'customers': DebtLedgerLabelPair(taken: 'قبضت', given: 'بعت'),
    'sellers': DebtLedgerLabelPair(taken: 'اشتريت', given: 'دفعت'),
    'private': DebtLedgerLabelPair(taken: 'خاص أخذت', given: 'خاص أعطيت'),
  },
);

void main() {
  test('legacy custom labels remain the fallback for every account type', () {
    final legacy = DebtLedgerLabels.fromJson({'taken_label': 'استلمت'});
    expect(legacy.forScope('sellers').taken, 'استلمت');
    expect(legacy.forScope('private').given, 'أعطيت');
    final scoped = DebtLedgerLabels.fromJson({
      'taken_label': 'استلمت',
      'by_type': {
        'sellers': {'taken_label': 'اشتريت', 'given_label': '  '}
      },
    });
    expect(scoped.forScope('sellers').taken, 'اشتريت');
    expect(scoped.forScope('customers').taken, 'استلمت');
    expect(scoped.forScope('sellers').given, 'أعطيت');
  });

  test('private and directly opened accounts use their own words', () {
    final controller = _Controller()..debtLabels.value = labels;
    controller.currentTab.value = 1;
    expect(controller.takenLabel, 'اشتريت');
    controller.currentTab.value = 0;
    expect(controller.takenLabel, 'قبضت');
    controller.categories.add(const ContactCategory(
      id: 2,
      name: 'خاص',
      color: '',
      customersCount: 1,
      sellersCount: 0,
      customerIds: [5],
    ));
    controller.selectedPerson = LedgerPersonInfo(
      id: 5,
      name: 'خاص',
      personType: 'customer',
    );
    expect(controller.givenLabel, 'خاص أعطيت');
    controller.categories.clear();
    controller.selectedPerson = LedgerPersonInfo.fromJson({
      'id': 9,
      'name': 'حساب',
      'person_type': 'seller',
      'label_scope': 'private',
    });
    expect(controller.takenLabel, 'خاص أخذت');
    controller.selectedPerson = null;
    expect(controller.takenLabel, 'قبضت');
  });

  for (final size in [const Size(360, 640), const Size(640, 360)]) {
    testWidgets('type settings fit and preserve drafts at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      Get.testMode = true;
      addTearDown(() {
        Get.reset();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final controller = _Controller()..debtLabels.value = labels;
      controller.currentTab.value = 1;
      Get.put<DebtLedgerController>(controller);
      await tester.pumpWidget(ScreenUtilInit(
        designSize: size,
        minTextAdapt: true,
        builder: (_, __) => GetMaterialApp(
          translations: Translation(),
          locale: const Locale('ar'),
          home: const Scaffold(body: DebtLabelsSettingsSheet()),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('اشتريت'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField).first, 'استلمت بضاعة');
      await tester.ensureVisible(find.byWidgetPredicate(
          (widget) => widget is DropdownButtonFormField<String>));
      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('العملاء').last);
      await tester.pumpAndSettle();
      expect(find.text('قبضت'), findsOneWidget);
      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الموردون').last);
      await tester.pumpAndSettle();
      expect(find.text('استلمت بضاعة'), findsOneWidget);
      await tester.ensureVisible(find.text('حفظ لهذا النوع'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

class _Controller extends DebtLedgerController {
  _Controller() : super(repository: _UnusedRepository());
  @override
  Future<void> loadMainData() async {}
}

class _UnusedRepository implements DebtLedgerRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
