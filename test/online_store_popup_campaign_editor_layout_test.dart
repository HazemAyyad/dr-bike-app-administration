import 'package:doctorbike/features/admin/online_store/presentation/controllers/online_store_popup_campaigns_controller.dart';
import 'package:doctorbike/features/admin/online_store/presentation/widgets/online_store_popup_campaign_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_online_store_repository.dart';

void main() {
  testWidgets('popup campaign editor fits a narrow phone viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = OnlineStorePopupCampaignsController(
      FakeOnlineStoreRepository(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showOnlineStorePopupCampaignEditor(
                context,
                controller: controller,
              ),
              child: const Text('فتح المحرر'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('فتح المحرر'));
    await tester.pumpAndSettle();

    expect(find.text('إضافة إعلان منبثق'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('مرة واحدة لكل مستخدم'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('تكرار الظهور'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
