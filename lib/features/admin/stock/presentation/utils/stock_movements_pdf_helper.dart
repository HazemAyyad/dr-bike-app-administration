import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/product_stock_movement_model.dart';
import '../../domain/stock_movements_filters.dart';

class StockMovementsPdfHelper {
  StockMovementsPdfHelper._();

  static Future<pw.Font> _loadRegular() async {
    final data =
        await rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf');
    return pw.Font.ttf(data);
  }

  static Future<pw.Font> _loadBold() async {
    final data = await rootBundle.load('assets/fonts/Almarai/Almarai-Bold.ttf');
    return pw.Font.ttf(data);
  }

  static String fileBaseName(String productName) {
    final safe = productName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return 'stock_movements_${safe.isEmpty ? 'product' : safe}_$stamp.pdf';
  }

  static String _filterLine(StockMovementsFilters? filters) {
    if (filters == null || !filters.hasActiveFilters) return '—';
    final parts = <String>[];
    if (filters.type != null && filters.type!.isNotEmpty) {
      parts.add('${'stockMoveFilterType'.tr}: ${filters.type!}');
    }
    if (filters.dateFrom != null) {
      parts.add(
        '${'from'.tr}: ${StockMovementsFilters.formatDisplayDate(filters.dateFrom!)}',
      );
    }
    if (filters.dateTo != null) {
      parts.add(
        '${'to'.tr}: ${StockMovementsFilters.formatDisplayDate(filters.dateTo!)}',
      );
    }
    return parts.join(' · ');
  }

  static Future<Uint8List> buildPdfBytes({
    required String productName,
    required StockMovementSummary summary,
    required List<ProductStockMovementModel> movements,
    StockMovementsFilters? filters,
  }) async {
    final regular = await _loadRegular();
    final bold = await _loadBold();
    final rtl = Get.locale?.languageCode == 'ar';

    final headers = [
      'stockMoveColType'.tr,
      'stockMoveColVariant'.tr,
      'quantity'.tr,
      'stockMoveColBefore'.tr,
      'stockMoveColAfter'.tr,
      'stockMoveColCost'.tr,
      'instantSaleInvoice'.tr,
      'notes'.tr,
      'date'.tr,
      'stockMoveColUser'.tr,
    ];

    final rows = movements.map((m) {
      final variant = [
        if (m.size != null && m.size!.isNotEmpty) m.size,
        if (m.colorAr != null && m.colorAr!.isNotEmpty) m.colorAr,
      ].whereType<String>().join(' / ');
      final qty = m.quantity;
      final qtyText = qty >= 0 ? '+$qty' : '$qty';
      return [
        m.movementTypeLabel(),
        variant.isEmpty ? '—' : variant,
        qtyText,
        '${m.stockBefore}',
        '${m.stockAfter}',
        _costText(m),
        m.hasInvoiceLink ? m.displayInvoiceNumber : '—',
        m.note?.trim().isNotEmpty == true ? m.note! : '—',
        m.createdAt ?? '—',
        m.createdByName?.trim().isNotEmpty == true ? m.createdByName! : '—',
      ];
    }).toList();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'stockMovements'.tr,
              style: pw.TextStyle(font: bold, fontSize: 16),
            ),
            pw.SizedBox(height: 4),
            pw.Text(productName, style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 2),
            pw.Text(
              '${'stockTotalIn'.tr}: +${summary.totalIn} · ${'stockTotalOut'.tr}: -${summary.totalOut} · ${'stock'.tr}: ${summary.currentStock}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              '${'filters'.tr}: ${_filterLine(filters)}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey300),
          ],
        ),
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(font: bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerRight,
            cellAlignments: {
              0: pw.Alignment.centerRight,
              6: pw.Alignment.center,
            },
          ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<File> savePdfToFile({
    required String productName,
    required StockMovementSummary summary,
    required List<ProductStockMovementModel> movements,
    StockMovementsFilters? filters,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, fileBaseName(productName));
    final file = File(path);
    await file.writeAsBytes(
      await buildPdfBytes(
        productName: productName,
        summary: summary,
        movements: movements,
        filters: filters,
      ),
    );
    return file;
  }

  static String _costText(ProductStockMovementModel m) {
    if (m.unitCost == null && m.totalCost == null) return '—';
    final parts = <String>[];
    if (m.unitCost != null) {
      parts.add('${'stockMoveUnitCost'.tr}: ${_money(m.unitCost!)}');
    }
    if (m.totalCost != null) {
      parts.add('${'stockMoveTotalCost'.tr}: ${_money(m.totalCost!)}');
    }
    return parts.join(' | ');
  }

  static String _money(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
