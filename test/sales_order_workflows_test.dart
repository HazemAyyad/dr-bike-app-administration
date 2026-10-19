import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/whatsapp_pdf_share.dart';
import 'package:doctorbike/features/admin/sales_orders/data/datasources/sales_orders_datasource.dart';
import 'package:doctorbike/features/admin/sales_orders/data/models/sales_order_model.dart';
import 'package:doctorbike/features/admin/sales_orders/presentation/widgets/sales_order_invoice_pdf.dart';
import 'package:doctorbike/features/admin/sales_orders/presentation/widgets/sales_order_modal_theme.dart';
import 'package:doctorbike/features/admin/sales_orders/presentation/widgets/sales_order_notes_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'local recipient prefixes can be changed and international numbers stay intact',
      () {
    expect(WhatsAppPdfShare.phoneDigits('+972 599123456', countryCode: '970'),
        '970599123456');
    expect(WhatsAppPdfShare.phoneDigits('٠٥٩٩١٢٣٤٥٦'), '972599123456');
    expect(WhatsAppPdfShare.phoneDigits('+44 7700 900123'), '447700900123');
    expect(WhatsAppPdfShare.phoneDigits('00447700900123'), '447700900123');
    expect(WhatsAppPdfShare.phoneDigits(''), '');
  });

  test(
      'shares the PDF bytes to the explicitly chosen business app and recipient',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(WhatsAppPdfShare.channel, (call) async {
      calls.add(call);
      return call.method == 'whatsAppApps'
          ? [WhatsAppPdfShare.regular, WhatsAppPdfShare.business]
          : true;
    });
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(WhatsAppPdfShare.channel, null);
    });
    expect(await WhatsAppPdfShare.installedApps(),
        contains(WhatsAppPdfShare.business));
    final bytes = Uint8List.fromList(utf8.encode('%PDF-1.7\n'));
    expect(
        await WhatsAppPdfShare.share(
            bytes: bytes,
            filename: 'invoice.pdf',
            packageName: WhatsAppPdfShare.business,
            phone: '970599123456'),
        isTrue);
    final args = calls.last.arguments as Map;
    expect(args['package'], WhatsAppPdfShare.business);
    expect(args['phone'], '970599123456');
    expect(args['bytes'], bytes);
    expect(calls.last.method, 'shareWhatsAppPdf');
  });

  test(
      'invoice excludes hidden items and merges only equal products, variants and prices',
      () {
    final rows = SalesOrderInvoicePdf.invoiceItems([
      _item(1, quantity: 2),
      _item(2, quantity: 3),
      _item(3, hidden: true),
      _item(4, sizeId: 10),
      _item(5, price: 15),
    ]);
    expect(rows.length, 3);
    expect(rows.first.quantity, 5);
    expect(rows.first.lineTotal, 50);
    expect(rows[1].sizeId, 10);
    expect(rows[2].unitPrice, 15);
  });

  test('creates a multipage Arabic Flutter invoice without a server report',
      () async {
    final order = SalesOrderDetailModel(
        id: 42,
        serialNumber: '0000082',
        status: 'unconfirmed',
        customerName: 'زبون تجريبي',
        customerPhone: '+972 599123456',
        customerAddress: 'رام الله - عنوان تجريبي',
        total: 815,
        subtotal: 800,
        discount: 10,
        calculatedTotal: 815,
        customerDeliveryFee: 25,
        paymentType: 'mixed',
        paymentAmount: 100,
        notes: 'ملاحظة داخلية لا ترسل افتراضياً',
        createdAt: '2026-10-19 20:00:00',
        items: List.generate(
            80,
            (i) => SalesOrderItemModel(
                id: i + 1,
                productId: i + 1,
                productName: 'قطعة غيار للدراجة ${i + 1}',
                quantity: 1,
                unitPrice: 10,
                lineTotal: 10)),
        media: []);
    final bytes = await SalesOrderInvoicePdf.build(order);
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    final raw = latin1.decode(bytes);
    expect(RegExp(r'/Type\s*/Page\b').allMatches(raw).length, greaterThan(1));
    // Ignored build output is used for visual QA only; no customer data.
    final file = File('build/sales_order_invoice_preview.pdf');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  });

  test(
      'draft creation keeps structured JSON and note images in the same request',
      () async {
    final api = _RecordingApi();
    final source = SalesOrdersDatasource(api: api);
    await source.createOrder({
      'customer_name': 'تجربة',
      'total': '12.50',
      'items': [
        {'product_id': 9, 'quantity': 2, 'unit_price': '6.25'}
      ],
      'note_images': [
        MultipartFile.fromBytes([1, 2, 3], filename: 'note.jpg')
      ]
    });
    final form = api.data as FormData;
    expect(form.files.single.key, 'note_images[]');
    final payload = jsonDecode(
            form.fields.singleWhere((entry) => entry.key == 'order_data').value)
        as Map;
    expect(payload['total'], '12.50');
    expect((payload['items'] as List).single['quantity'], 2);
    expect(payload.containsKey('note_images'), isFalse);
    expect(api.path, EndPoints.salesOrder);
  });

  test(
      'editing with images retains the selected order id outside the JSON envelope',
      () async {
    final api = _RecordingApi();
    await SalesOrdersDatasource(api: api).updateOrder(43, {
      'notes': 'تجربة',
      'note_images': [
        MultipartFile.fromBytes([1], filename: 'note.jpg')
      ]
    });
    expect(
        (api.data as FormData).fields,
        contains(isA<MapEntry<String, String>>()
            .having((entry) => entry.key, 'key', 'sales_order_id')
            .having((entry) => entry.value, 'value', '43')));
  });

  test('image-only external note uses the note endpoint and parses its history',
      () async {
    final api = _RecordingApi();
    api.order['note_log'] = [
      {
        'id': 7,
        'scope': 'external',
        'note': '',
        'user_name': 'الموظف',
        'images': [
          {'url': 'https://example.invalid/note.jpg'}
        ]
      }
    ];
    final updated =
        await SalesOrdersDatasource(api: api).addNote(43, 'external', '', [
      MultipartFile.fromBytes([1], filename: 'note.jpg')
    ]);
    expect(api.path, EndPoints.salesOrderNote);
    expect((api.data as FormData).files.single.key, 'images[]');
    expect(updated.noteLog.single.images, ['https://example.invalid/note.jpg']);
    expect(updated.noteLog.single.scope, 'external');
  });

  test('forced deletion sends one order id, reason and administrator password',
      () async {
    final api = _RecordingApi();
    await SalesOrdersDatasource(api: api).deleteOrder(37,
        force: true, reason: 'طلب مكرر', password: 'test-only');
    expect(api.path, EndPoints.salesOrderDelete);
    expect(api.data, {
      'sales_order_id': 37,
      'force': true,
      'reason': 'طلب مكرر',
      'password': 'test-only'
    });
  });

  testWidgets(
      'external comments stay separate from internal notes and can be saved',
      (tester) async {
    final order = SalesOrderDetailModel(
        id: 43,
        status: 'unconfirmed',
        total: 10,
        subtotal: 10,
        discount: 0,
        calculatedTotal: 10,
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
              userName: 'موظف',
              createdAt: '',
              images: []),
        ]);
    String? savedScope;
    String? savedText;
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
            body: SalesOrderModalTheme(
                child: SalesOrderNotesSheet(
                    order: order,
                    initialScope: 'external',
                    onSave: (scope, text, images) async {
                      savedScope = scope;
                      savedText = text;
                      return order;
                    })))));
    expect(find.text('تعليق خارجي'), findsOneWidget);
    expect(find.text('ملاحظة داخلية قديمة'), findsNothing);
    final context = tester.element(find.byType(SalesOrderNotesSheet));
    expect(Theme.of(context).brightness, Brightness.light);
    await tester.enterText(find.byType(TextField), 'تعليق جديد');
    await tester.pump();
    await tester.ensureVisible(find.text('حفظ الملاحظة والصور'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ الملاحظة والصور'));
    await tester.pumpAndSettle();
    expect(savedScope, 'external');
    expect(savedText, 'تعليق جديد');
    expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    expect(tester.takeException(), isNull);
  });
}

SalesOrderItemModel _item(int id,
        {int quantity = 1,
        int? sizeId,
        double price = 10,
        bool hidden = false}) =>
    SalesOrderItemModel(
        id: id,
        productId: 1,
        productName: 'صنف',
        sizeId: sizeId,
        quantity: quantity,
        unitPrice: price,
        lineTotal: quantity * price,
        isHidden: hidden);

class _RecordingApi extends Fake implements ApiConsumer {
  String? path;
  Object? data;
  final order = <String, dynamic>{
    'id': 43,
    'status': 'unconfirmed',
    'items': [],
    'media': []
  };
  @override
  Future<dynamic> post(String path,
      {Object? data,
      Options? options,
      Map<String, dynamic>? queryParameters,
      bool isFormData = false,
      Function(int, int)? onSendProgress}) async {
    this.path = path;
    this.data = data;
    return {'status': 'success', 'sales_order': order};
  }
}
