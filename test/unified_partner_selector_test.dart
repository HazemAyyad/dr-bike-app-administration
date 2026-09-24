import 'package:doctorbike/features/admin/widgets/unified_partner_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'keeps the tapped partner identity when results reorder during the tap',
    (tester) async {
      final sellers = ValueNotifier<List<_Partner>>([
        const _Partner(31, 'عبيدة الباز'),
        const _Partner(32, 'وليد مريدي', '0597179989'),
        const _Partner(33, 'احمد رجبي'),
      ]);
      _Partner? selected;
      bool? selectedIsSeller;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<List<_Partner>>(
                valueListenable: sellers,
                builder: (_, values, __) => UnifiedPartnerSelector<_Partner>(
                  customers: const [],
                  sellers: values,
                  selected: selected,
                  selectedIsSeller: selectedIsSeller ?? false,
                  idOf: (partner) => partner.id,
                  nameOf: (partner) => partner.name,
                  phoneOf: (partner) => partner.phone,
                  onSelected: (partner, isSeller) {
                    selected = partner;
                    selectedIsSeller = isSeller;
                  },
                  onCleared: () => selected = null,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('وليد مريدي')),
      );
      sellers.value = const [
        _Partner(33, 'احمد رجبي'),
        _Partner(31, 'عبيدة الباز'),
        _Partner(32, 'وليد مريدي', '0597179989'),
      ];
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(selected?.id, 32);
      expect(selected?.name, 'وليد مريدي');
      expect(selectedIsSeller, isTrue);
    },
  );

  testWidgets('distinguishes a customer and seller that share the same id',
      (tester) async {
    const customer = _Partner(32, 'زبون رقم 32');
    const seller = _Partner(32, 'مورد رقم 32');
    _Partner? selected;
    bool? selectedIsSeller;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: UnifiedPartnerSelector<_Partner>(
              customers: const [customer],
              sellers: const [seller],
              selected: selected,
              selectedIsSeller: selectedIsSeller ?? false,
              idOf: (partner) => partner.id,
              nameOf: (partner) => partner.name,
              phoneOf: (partner) => partner.phone,
              onSelected: (partner, isSeller) {
                selected = partner;
                selectedIsSeller = isSeller;
              },
              onCleared: () => selected = null,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    await tester.tap(find.text('مورد رقم 32'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(selected, same(seller));
    expect(selectedIsSeller, isTrue);
  });
}

class _Partner {
  const _Partner(this.id, this.name, [this.phone = '']);

  final int id;
  final String name;
  final String phone;
}
