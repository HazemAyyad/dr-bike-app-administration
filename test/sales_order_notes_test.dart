import 'package:doctorbike/features/admin/sales_orders/data/models/sales_order_model.dart';
import 'package:doctorbike/features/admin/sales_orders/presentation/widgets/sales_order_modal_theme.dart';
import 'package:doctorbike/features/admin/sales_orders/presentation/widgets/sales_order_notes_badges.dart';
import 'package:doctorbike/features/admin/sales_orders/presentation/widgets/sales_order_notes_sheet.dart';
import 'package:doctorbike/features/admin/whatsapp_center/presentation/views/whatsapp_camera_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  test('list counts and detail counts include legacy internal notes', () {
    final order = SalesOrderListItemModel.fromJson({
      'id': 42,
      'internal_notes_count': 2,
      'external_notes_count': 1,
      'customer_name': 'زبون',
      'total': 25,
      'origin': 'store',
      'reserves_stock': false,
      'delivery_company_id': 8,
    });
    expect(order.hasNotes, isTrue);
    expect(order.internalNotesCount, 2);
    expect(order.externalNotesCount, 1);
    final updated = order.withNoteCounts(3, 1);
    expect(updated.internalNotesCount, 3);
    expect(updated.customerName, order.customerName);
    expect(updated.reservesStock, isFalse);
    expect(updated.deliveryCompanyId, 8);
    expect(updated.origin, 'store');
    expect(_order().internalNotesCount, 1);
    expect(_order().externalNotesCount, 1);
    expect(SalesOrderListItemModel.fromJson({'id': 43}).hasNotes, isFalse);
  });

  test('mixed note attachments preserve type and old image payloads still work',
      () {
    final mixed = SalesOrderNoteModel.fromJson({
      'id': 1,
      'scope': 'external',
      'images': [
        {'url': 'https://example.invalid/a.jpg'}
      ],
      'attachments': [
        {'type': 'image', 'url': 'https://example.invalid/a.jpg'},
        {'type': 'video', 'url': 'https://example.invalid/b.mp4'},
      ],
    });
    expect(mixed.media.length, 2);
    expect(mixed.media.last.isVideo, isTrue);
    expect(mixed.images, ['https://example.invalid/a.jpg']);
    final old = SalesOrderNoteModel.fromJson({
      'id': 2,
      'images': [
        {'url': 'old.jpg'}
      ]
    });
    expect(old.media.single.url, 'old.jpg');
    expect(old.media.single.isVideo, isFalse);
  });

  testWidgets('badges show only existing scopes and open the chosen scope',
      (tester) async {
    String? chosen;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SalesOrderNotesBadges(
                internalCount: 2,
                externalCount: 1,
                onSelected: (scope) => chosen = scope))));
    await tester.tap(find.text('داخلية 2'));
    expect(chosen, 'internal');
    await tester.tap(find.text('خارجية 1'));
    expect(chosen, 'external');
    await tester.pumpWidget(const MaterialApp(
        home: SalesOrderNotesBadges(internalCount: 0, externalCount: 0)));
    expect(find.byType(InkWell), findsNothing);
  });

  for (final size in [const Size(360, 640), const Size(640, 360)]) {
    testWidgets('notes fit at $size with large text and keyboard',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(
            size: size,
            textScaler: const TextScaler.linear(1.3),
            viewInsets: const EdgeInsets.only(bottom: 220)),
        child: Scaffold(
            body: SalesOrderModalTheme(
                child: SalesOrderNotesSheet(
                    order: _order(),
                    initialScope: 'external',
                    onSave: (_, __, ___) async => null))),
      )));
      expect(tester.takeException(), isNull);
      expect(find.text('25/10/2026'), findsOneWidget);
      final local = DateTime.parse('2026-10-25T10:15:00Z').toLocal();
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      expect(
          find.text('$hour:15 ${local.hour < 12 ? 'ص' : 'م'}'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'مسودة خارجية');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('داخلية (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('داخلية (1)'));
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '');
      await tester.enterText(find.byType(TextField), 'مسودة داخلية');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('خارجية (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('خارجية (1)'));
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'مسودة خارجية');
      await tester.ensureVisible(find.text('حفظ الملاحظة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ الملاحظة'));
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'مسودة خارجية');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('note camera uses the WhatsApp photo/video camera with gallery',
      (tester) async {
    Get.testMode = true;
    addTearDown(Get.reset);
    await tester.pumpWidget(GetMaterialApp(
        home: Scaffold(
            body: SalesOrderModalTheme(
                child: SalesOrderNotesSheet(
                    order: _order(),
                    initialScope: 'external',
                    onSave: (_, __, ___) async => null)))));
    await tester.tap(find.text('كاميرا / فيديو'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final camera =
        tester.widget<WhatsAppCameraScreen>(find.byType(WhatsAppCameraScreen));
    expect(camera.allowPhoto, isTrue);
    expect(camera.allowVideo, isTrue);
    expect(camera.allowGallery, isTrue);
    expect(find.byTooltip('المعرض'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

SalesOrderDetailModel _order() => SalesOrderDetailModel(
      id: 42,
      status: 'unconfirmed',
      total: 25,
      subtotal: 25,
      discount: 0,
      calculatedTotal: 25,
      customerDeliveryFee: 0,
      paymentType: 'cash',
      items: [],
      media: [],
      notes: 'ملاحظة داخلية قديمة',
      noteLog: const [
        SalesOrderNoteModel(
            id: 1,
            scope: 'external',
            note: 'تعليق خارجي',
            userName: 'أحمد الموظف',
            createdAt: '2026-10-25T10:15:00Z',
            images: [],
            attachments: [
              SalesOrderNoteAttachmentModel(
                  url: 'https://example.invalid/note.mp4', type: 'video'),
            ]),
      ],
    );
