import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// The plugin exposes its test platform interface from this entry point.
// ignore: implementation_imports
import 'package:printing/src/interface.dart';

/// Only substitutes the native raster channel in widget tests. Generated PDF
/// documents are checked separately using a real PDF renderer.
class AccountingPrintingStub extends PrintingPlatform {
  int rasterCalls = 0;
  int shareCalls = 0;
  Uint8List? sharedBytes;
  String? sharedFilename;

  @override
  Future<bool> sharePdf(Uint8List bytes, String filename, Rect bounds,
      String? subject, String? body, List<String>? emails) async {
    shareCalls++;
    sharedBytes = bytes;
    sharedFilename = filename;
    return true;
  }

  @override
  Future<PrintingInfo> info() async => const PrintingInfo(canRaster: true);

  @override
  Stream<PdfRaster> raster(
      Uint8List document, List<int>? pages, double dpi) async* {
    rasterCalls++;
    yield PdfRaster(
        100, 140, Uint8List(100 * 140 * 4)..fillRange(0, 56000, 255));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late AccountingPrintingStub accountingPrinting;
Finder get accountingShareButton => find.byWidgetPredicate((widget) =>
    widget is IconButton && widget.tooltip == 'مشاركة التقرير المعروض');
void installAccountingPrintingStub() {
  accountingPrinting = AccountingPrintingStub();
  PrintingPlatform.instance = accountingPrinting;
}

Future<void> settleAccountingPreview(WidgetTester tester) async {
  // Bundle I/O and image decoding use real asynchronous work, while PdfPreview
  // debounces raster requests with a timer on the widget test clock.
  for (var attempt = 0; attempt < 30; attempt++) {
    await tester.pump(const Duration(milliseconds: 150));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    if (attempt >= 4 &&
        find.byType(PdfPreview).evaluate().isNotEmpty &&
        find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      break;
    }
  }
  await tester.pumpAndSettle();
}

Future<void> revealAccountingDetail(WidgetTester tester, Finder target) async {
  final scroll = tester.state<ScrollableState>(find
      .descendant(
          of: find.byKey(const ValueKey('accounting-report-scroll')),
          matching: find.byType(Scrollable))
      .first);
  for (var attempt = 0; attempt < 6 && target.evaluate().isEmpty; attempt++) {
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await settleAccountingPreview(tester);
  }
  await tester.ensureVisible(target);
  await settleAccountingPreview(tester);
}
