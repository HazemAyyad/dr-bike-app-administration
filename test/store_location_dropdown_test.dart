import 'package:doctorbike/features/admin/stock/data/models/store_section_model.dart';
import 'package:doctorbike/features/admin/stock/presentation/widgets/store_location_edit_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('searches locations by name and saves the selected ID',
      (tester) async {
    String? selectedId;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => StoreLocationDropdown(
                sections: [
                  StoreSectionModel(id: '11', name: 'رف البطاريات'),
                  StoreSectionModel(id: '22', name: 'رف الفرامل'),
                  StoreSectionModel(
                    id: '33',
                    name: 'موقع متوقف',
                    isActive: false,
                  ),
                ],
                selectedId: selectedId,
                onChanged: (id) => setState(() => selectedId = id),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('بدون موقع'));
    await tester.pumpAndSettle();
    expect(find.text('موقع متوقف'), findsNothing);
    await tester.enterText(find.byType(TextField), 'فرامل');
    await tester.pumpAndSettle();
    expect(find.text('رف البطاريات'), findsNothing);
    await tester.tap(find.text('رف الفرامل'));
    await tester.pumpAndSettle();
    expect(selectedId, '22');
    expect(find.text('رف الفرامل'), findsOneWidget);

    await tester.tap(find.text('رف الفرامل'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'غير موجود');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد مواقع مطابقة'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('بدون موقع'));
    await tester.pumpAndSettle();
    expect(selectedId, isNull);
    expect(tester.takeException(), isNull);
  });
}
