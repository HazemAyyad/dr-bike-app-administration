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

  testWidgets('keeps results selectable during a slow touch', (tester) async {
    const seller = _Partner(41, 'مورد بطيء');
    _Partner? selected;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: UnifiedPartnerSelector<_Partner>(
              customers: const [],
              sellers: const [seller],
              selected: selected,
              selectedIsSeller: true,
              idOf: (partner) => partner.id,
              nameOf: (partner) => partner.name,
              phoneOf: (partner) => partner.phone,
              onSelected: (partner, _) => selected = partner,
              onCleared: () => selected = null,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('مورد بطيء')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(selected, same(seller));
  });

  testWidgets('keeps searched partner selected when a late text event arrives',
      (tester) async {
    const seller = _Partner(51, 'مورد نتيجة البحث', '0599000000');
    _Partner? selected;
    var clearCalls = 0;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setHostState) =>
                  UnifiedPartnerSelector<_Partner>(
                customers: const [],
                sellers: const [seller],
                selected: selected,
                selectedIsSeller: true,
                idOf: (partner) => partner.id,
                nameOf: (partner) => partner.name,
                phoneOf: (partner) => partner.phone,
                onSelected: (partner, _) {
                  setHostState(() => selected = partner);
                },
                onCleared: () {
                  clearCalls++;
                  setHostState(() => selected = null);
                },
              ),
            ),
          ),
        ),
      ),
    );

    final field = find.byType(TextFormField);
    await tester.tap(field);
    await tester.enterText(field, 'نتيجة البحث');
    await tester.pump();
    expect(find.text('مورد نتيجة البحث'), findsOneWidget);

    await tester.tap(find.text('مورد نتيجة البحث'));
    await tester.enterText(field, 'مورد نتيجة البحث');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(selected, same(seller));
    expect(clearCalls, 0);
  });

  testWidgets(
      'keeps tapped search result during transient reactive parent rebuild',
      (tester) async {
    const customer = _Partner(61, 'زبون قديم');
    const seller = _Partner(62, 'مورد نتيجة البحث', '0599111111');
    _Partner? selected = customer;
    var selectedIsSeller = false;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setHostState) =>
                  UnifiedPartnerSelector<_Partner>(
                customers: const [customer],
                sellers: const [seller],
                selected: selected,
                selectedIsSeller: selectedIsSeller,
                idOf: (partner) => partner.id,
                nameOf: (partner) => partner.name,
                phoneOf: (partner) => partner.phone,
                onSelected: (partner, isSeller) async {
                  setHostState(() {
                    selected = null;
                    selectedIsSeller = isSeller;
                  });
                  await Future<void>.delayed(const Duration(milliseconds: 1));
                  setHostState(() => selected = partner);
                },
                onCleared: () => setHostState(() => selected = null),
              ),
            ),
          ),
        ),
      ),
    );

    final field = find.byType(TextFormField);
    await tester.tap(field);
    await tester.enterText(field, 'نتيجة البحث');
    await tester.pump();

    await tester.tap(find.text('مورد نتيجة البحث'));
    await tester.pump();
    expect(tester.widget<TextFormField>(field).controller!.text,
        'مورد نتيجة البحث');

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(selected, same(seller));
    expect(selectedIsSeller, isTrue);
    expect(tester.widget<TextFormField>(field).controller!.text,
        'مورد نتيجة البحث');
  });
  testWidgets(
      'preserves a filtered result through blur and a parent rebuild during touch',
      (tester) async {
    final revision = ValueNotifier<int>(0);
    addTearDown(revision.dispose);
    final sellers = List.generate(
        12, (i) => _Partner(i + 1, i == 11 ? 'المورد المطلوب' : 'مورد $i'));
    _Partner? selected;
    await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
                home: Scaffold(
                    body: ValueListenableBuilder<int>(
              valueListenable: revision,
              builder: (_, __, ___) => UnifiedPartnerSelector<_Partner>(
                  customers: const [],
                  sellers: sellers,
                  selected: selected,
                  selectedIsSeller: true,
                  idOf: (p) => p.id,
                  nameOf: (p) => p.name,
                  phoneOf: (p) => p.phone,
                  onSelected: (p, _) => selected = p,
                  onCleared: () => selected = null),
            )))));
    final field = find.byType(TextFormField);
    await tester.tap(field);
    await tester.enterText(field, 'المطلوب');
    await tester.pump();
    final gesture = await tester
        .startGesture(tester.getCenter(find.text('المورد المطلوب')));
    FocusManager.instance.primaryFocus?.unfocus();
    revision.value++;
    await tester.pump();
    expect(tester.widget<TextFormField>(field).controller!.text, 'المطلوب');
    await tester.pump(const Duration(milliseconds: 250));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(selected?.id, 12);
    expect(
        tester.widget<TextFormField>(field).controller!.text, 'المورد المطلوب');
  });
  testWidgets(
      'clearing a partner does not erase a new query after an asynchronous refresh',
      (tester) async {
    const old = _Partner(1, 'زبون قديم');
    const next = _Partner(2, 'زبون جديد');
    _Partner? selected = old;
    await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
                home: Scaffold(
                    body: StatefulBuilder(
              builder: (context, setHostState) =>
                  UnifiedPartnerSelector<_Partner>(
                      customers: const [old, next],
                      sellers: const [],
                      selected: selected,
                      selectedIsSeller: false,
                      idOf: (p) => p.id,
                      nameOf: (p) => p.name,
                      phoneOf: (p) => p.phone,
                      onSelected: (p, _) => setHostState(() => selected = p),
                      onCleared: () async {
                        setHostState(() => selected = null);
                        await Future<void>.delayed(
                            const Duration(milliseconds: 250));
                      }),
            )))));
    await tester.tap(find.byTooltip('إلغاء الاختيار'));
    await tester.pump();
    final field = find.byType(TextFormField);
    await tester.enterText(field, 'جديد');
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.widget<TextFormField>(field).controller!.text, 'جديد');
    await tester.tap(find.text('زبون جديد'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(selected, same(next));
  });
}

class _Partner {
  const _Partner(this.id, this.name, [this.phone = '']);

  final int id;
  final String name;
  final String phone;
}
