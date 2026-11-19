import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AccountingReportChartEntry {
  const AccountingReportChartEntry(this.label, this.values);
  final String label;
  final List<double?> values;
}

class AccountingReportChart {
  const AccountingReportChart({
    required this.title,
    required this.series,
    required this.entries,
    required this.unit,
  });
  final String title;
  final List<String> series;
  final List<AccountingReportChartEntry> entries;
  final String unit;

  double get minimum => entries
      .expand((entry) => entry.values)
      .whereType<double>()
      .fold(0.0, math.min);
  double get maximum => entries
      .expand((entry) => entry.values)
      .whereType<double>()
      .fold(0.0, math.max);
  double get span => math.max(maximum - minimum, 1);
  String valueLabel(double? value) => value == null
      ? 'غير مكتمل'
      : '${NumberFormat('#,##0.00', 'en').format(value)} $unit';
}

const _chartColors = [Color(0xFF2278BD), Color(0xFF2D9D65)];

class AccountingReportChartView extends StatelessWidget {
  const AccountingReportChartView({Key? key, required this.chart})
      : super(key: key);
  final AccountingReportChart chart;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(chart.title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(spacing: 16, runSpacing: 6, children: [
                for (var i = 0; i < chart.series.length; i++)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.circle, size: 10, color: _chartColors[i]),
                    const SizedBox(width: 6),
                    Text(chart.series[i]),
                  ]),
              ]),
              if (chart.entries.isEmpty)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('لا توجد بيانات مكتملة لعرض الرسم.')),
              for (final entry in chart.entries) ...[
                const SizedBox(height: 14),
                Text(entry.label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                for (var i = 0; i < entry.values.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(chart.valueLabel(entry.values[i]),
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                color: _chartColors[i], fontSize: 13)),
                        const SizedBox(height: 3),
                        LayoutBuilder(builder: (_, constraints) {
                          final zero = -chart.minimum / chart.span;
                          final value = entry.values[i] ?? 0;
                          final start = value < 0
                              ? (value - chart.minimum) / chart.span
                              : zero;
                          return SizedBox(
                            height: 12,
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Stack(children: [
                                Container(color: const Color(0xFFF0F3F7)),
                                if (entry.values[i] != null && value != 0)
                                  Positioned(
                                    left: constraints.maxWidth * start,
                                    width: constraints.maxWidth *
                                        value.abs() /
                                        chart.span,
                                    top: 0,
                                    bottom: 0,
                                    child: ColoredBox(color: _chartColors[i]),
                                  ),
                                Positioned(
                                    left: (constraints.maxWidth * zero)
                                        .clamp(0, constraints.maxWidth - 1),
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                        width: 1, color: Colors.blueGrey)),
                              ]),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 10),
              Text('الوحدة: ${chart.unit} • خط الأساس = 0',
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            ],
          ),
        ),
      );
}

pw.Widget accountingPdfChart(AccountingReportChart chart, pw.Font bold) {
  final colors = [PdfColor.fromHex('#2278BD'), PdfColor.fromHex('#2D9D65')];
  return pw.Inseparable(
      child: pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5)),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(chart.title, style: pw.TextStyle(font: bold, fontSize: 12)),
        pw.SizedBox(height: 8),
        pw.Wrap(spacing: 16, children: [
          for (var i = 0; i < chart.series.length; i++)
            pw.Text(chart.series[i],
                style: pw.TextStyle(color: colors[i], fontSize: 9)),
        ]),
        if (chart.entries.isEmpty)
          pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text('لا توجد بيانات مكتملة لعرض الرسم.')),
        for (final entry in chart.entries) ...[
          pw.SizedBox(height: 9),
          pw.Text(entry.label, style: pw.TextStyle(font: bold, fontSize: 9)),
          for (var i = 0; i < entry.values.length; i++) ...[
            pw.SizedBox(height: 3),
            pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      if (entry.values[i] != null) ...[
                        pw.Text(
                            NumberFormat('#,##0.00', 'en')
                                .format(entry.values[i]),
                            textDirection: pw.TextDirection.ltr,
                            style: pw.TextStyle(fontSize: 8, color: colors[i])),
                        pw.SizedBox(width: 4),
                        pw.Text(chart.unit,
                            textDirection: pw.TextDirection.rtl,
                            style: pw.TextStyle(fontSize: 8, color: colors[i])),
                      ] else
                        pw.Text('غير مكتمل',
                            textDirection: pw.TextDirection.rtl,
                            style: pw.TextStyle(fontSize: 8, color: colors[i])),
                    ])),
            pw.LayoutBuilder(builder: (_, constraints) {
              final width = constraints!.maxWidth;
              final value = entry.values[i] ?? 0;
              final zero = -chart.minimum / chart.span;
              final start =
                  value < 0 ? (value - chart.minimum) / chart.span : zero;
              return pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.SizedBox(
                  height: 7,
                  child: pw.Stack(children: [
                    pw.Container(width: width, color: PdfColors.grey100),
                    if (entry.values[i] != null && value != 0)
                      pw.Positioned(
                          left: width * start,
                          top: 0,
                          child: pw.Container(
                              height: 7,
                              width: width * value.abs() / chart.span,
                              color: colors[i])),
                    pw.Positioned(
                        left: (width * zero).clamp(0, width - 1).toDouble(),
                        top: 0,
                        child: pw.Container(
                            height: 7, width: .5, color: PdfColors.blueGrey)),
                  ]),
                ),
              );
            }),
          ],
        ],
        pw.SizedBox(height: 8),
        pw.Text('الوحدة: ${chart.unit} • خط الأساس = 0',
            style: const pw.TextStyle(fontSize: 8)),
      ],
    ),
  ));
}
