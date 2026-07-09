import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../../core/utils/assets_manger.dart';
import '../data/models/attendance_report_model.dart';

/// تصدير تقرير الحضور PDF / جدول يفتح بـ Excel (CSV مع UTF-8 BOM).
class AttendanceReportExportHelper {
  AttendanceReportExportHelper._();

  static String _csvEsc(String s) {
    if (s.contains(';') ||
        s.contains('"') ||
        s.contains('\n') ||
        s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static Future<pw.Font> _loadAlmaraiRegular() async {
    final data =
        await rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf');
    return pw.Font.ttf(data);
  }

  static Future<pw.Font> _loadAlmaraiBold() async {
    final data = await rootBundle.load('assets/fonts/Almarai/Almarai-Bold.ttf');
    return pw.Font.ttf(data);
  }

  static Future<pw.MemoryImage?> _loadLogoImage() async {
    try {
      final data = await rootBundle.load(AssetsManager.darkLogo);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static String _weeklyOffLabel(List<String> days) {
    if (days.isEmpty) return '—';
    return days.map((d) => 'day_${d.toLowerCase()}'.tr).join(', ');
  }

  static String _typeLabel(String code) {
    switch (code) {
      case 'daily':
        return 'reportTypeDaily'.tr;
      case 'weekly':
        return 'reportTypeWeekly'.tr;
      case 'monthly':
        return 'reportTypeMonthly'.tr;
      case 'custom':
        return 'reportTypeCustom'.tr;
      default:
        return code;
    }
  }

  /// PDF bytes (A4 أفقي، خط المشروع لدعم العربية).
  static Future<Uint8List> buildPdfBytes({
    required AttendanceReportResult result,
    AttendanceReportArgs? filters,
    bool simple = true,
  }) async {
    final regular = await _loadAlmaraiRegular();
    final bold = await _loadAlmaraiBold();
    final logo = await _loadLogoImage();
    final rtl = Get.locale?.languageCode == 'ar';

    final headers = simple
        ? [
            'employeeNameReportCol'.tr,
            'hourWorkPriceReportCol'.tr,
            'requiredHoursLabel'.tr,
            'workedHoursLabel'.tr,
            'hoursDifferenceLabel'.tr,
            'salaryForWorkedHoursCol'.tr,
          ]
        : [
            'employeeNameReportCol'.tr,
            'weeklyDaysOffTitle'.tr,
            'hourWorkPriceReportCol'.tr,
            'overtimeHourPriceEffectiveCol'.tr,
            'requiredWorkingDaysCol'.tr,
            'requiredHoursLabel'.tr,
            'workedHoursLabel'.tr,
            'normalHoursLabel'.tr,
            'overtimeHoursLabel'.tr,
            'normalSalaryReportCol'.tr,
            'overtimeSalaryReportCol'.tr,
            'salaryForWorkedHoursCol'.tr,
            'earnedPointsCol'.tr,
            'deductedPointsCol'.tr,
            'netPointsCol'.tr,
            'rewardAmountReportCol'.tr,
            'finalSalaryReportCol'.tr,
            'employeeDebtsReportCol'.tr,
          ];

    final data = simple
        ? result.employees.map((e) {
            final required = double.tryParse(e.requiredHours) ?? 0;
            final worked = double.tryParse(e.workedHours) ?? 0;
            final diff = worked - required;
            return [
              e.employeeName,
              e.hourWorkPrice,
              e.requiredHours,
              e.workedHours,
              '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(2)}',
              e.totalSalary,
            ];
          }).toList()
        : result.employees
            .map(
              (e) => [
                e.employeeName,
                _weeklyOffLabel(e.weeklyDaysOff),
                e.hourWorkPrice,
                e.overtimeHourPriceEffective,
                '${e.requiredWorkingDays}',
                e.requiredHours,
                e.workedHours,
                e.normalHours,
                e.overtimeHours,
                e.normalSalary,
                e.overtimeSalary,
                e.totalSalary,
                '${e.pointsSummary.earnedPoints}',
                '${e.pointsSummary.deductedPoints}',
                '${e.pointsSummary.netPoints}',
                e.rewardAmount,
                e.finalSalary,
                e.employeeDebts,
              ],
            )
            .toList();

    final displayHeaders = rtl ? headers.reversed.toList() : headers;
    final displayData =
        rtl ? data.map((row) => row.reversed.toList()).toList() : data;

    final doc = pw.Document();
    final subTitle =
        '${'periodLabel'.tr}: ${result.periodFrom} → ${result.periodTo}';
    final filterLine = filters == null
        ? null
        : (filters.allEmployees
            ? '${'allEmployeesToggle'.tr}: ✓'
            : '${'pickEmployeesHint'.tr} — ${filters.employeeIds.length}');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                    color: PdfColor.fromInt(0xFF6B65BD), width: 2),
              ),
            ),
            child: pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(7),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Container(
                      alignment: pw.Alignment.centerLeft,
                      child: logo == null
                          ? pw.Text(
                              'DoctorBike',
                              style: pw.TextStyle(font: bold, fontSize: 12),
                            )
                          : pw.Image(logo, height: 55, fit: pw.BoxFit.contain),
                    ),
                    pw.Container(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'دكتور بايك - تقرير الدوام',
                            textAlign: pw.TextAlign.right,
                            textDirection: pw.TextDirection.rtl,
                            style: pw.TextStyle(
                              font: bold,
                              fontSize: 18,
                              color: const PdfColor.fromInt(0xFF6B65BD),
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            _typeLabel(result.reportType),
                            textAlign: pw.TextAlign.right,
                            textDirection: rtl
                                ? pw.TextDirection.rtl
                                : pw.TextDirection.ltr,
                            style: pw.TextStyle(font: regular, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'attendanceReportTitle'.tr,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: bold, fontSize: 15),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            alignment: rtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
            child: pw.Column(
              crossAxisAlignment:
                  rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  subTitle,
                  textAlign: rtl ? pw.TextAlign.right : pw.TextAlign.left,
                  textDirection:
                      rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                  style: pw.TextStyle(font: regular, fontSize: 9),
                ),
                pw.Text(
                  '${_typeLabel(result.reportType)} · ${result.month}/${result.year}',
                  textAlign: rtl ? pw.TextAlign.right : pw.TextAlign.left,
                  textDirection:
                      rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                  style: pw.TextStyle(font: regular, fontSize: 9),
                ),
                if (filterLine != null)
                  pw.Text(
                    filterLine,
                    textAlign: rtl ? pw.TextAlign.right : pw.TextAlign.left,
                    textDirection:
                        rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                    style: pw.TextStyle(font: regular, fontSize: 8),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: displayHeaders,
            data: displayData,
            border: pw.TableBorder.all(
              color: const PdfColor.fromInt(0xFFD0D7E2),
              width: 0.8,
            ),
            headerAlignment: pw.Alignment.center,
            cellAlignment: pw.Alignment.center,
            headerStyle: pw.TextStyle(
              font: bold,
              fontSize: simple ? 9 : 7,
              color: PdfColors.white,
            ),
            cellStyle: pw.TextStyle(font: regular, fontSize: simple ? 8 : 6),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF6B65BD),
            ),
            cellHeight: simple ? 22 : 18,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 4,
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// CSV مع فاصل `;` و BOM — يفتح في Excel ويحافظ على العربية.
  static String buildCsvString({
    required AttendanceReportResult result,
  }) {
    final headers = [
      'employeeNameReportCol'.tr,
      'weeklyDaysOffTitle'.tr,
      'hourWorkPriceReportCol'.tr,
      'overtimeHourPriceEffectiveCol'.tr,
      'requiredWorkingDaysCol'.tr,
      'requiredHoursLabel'.tr,
      'workedHoursLabel'.tr,
      'normalHoursLabel'.tr,
      'overtimeHoursLabel'.tr,
      'normalSalaryReportCol'.tr,
      'overtimeSalaryReportCol'.tr,
      'salaryForWorkedHoursCol'.tr,
      'earnedPointsCol'.tr,
      'deductedPointsCol'.tr,
      'netPointsCol'.tr,
      'rewardAmountReportCol'.tr,
      'finalSalaryReportCol'.tr,
      'employeeDebtsReportCol'.tr,
    ];

    final sb = StringBuffer('\uFEFF');
    sb.writeln(headers.map(_csvEsc).join(';'));

    for (final e in result.employees) {
      final row = [
        e.employeeName,
        _weeklyOffLabel(e.weeklyDaysOff),
        e.hourWorkPrice,
        e.overtimeHourPriceEffective,
        '${e.requiredWorkingDays}',
        e.requiredHours,
        e.workedHours,
        e.normalHours,
        e.overtimeHours,
        e.normalSalary,
        e.overtimeSalary,
        e.totalSalary,
        '${e.pointsSummary.earnedPoints}',
        '${e.pointsSummary.deductedPoints}',
        '${e.pointsSummary.netPoints}',
        e.rewardAmount,
        e.finalSalary,
        e.employeeDebts,
      ];
      sb.writeln(row.map(_csvEsc).join(';'));
    }
    return sb.toString();
  }

  static Future<Directory> _exportDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Web export not supported');
    }
    late Directory directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download/Doctor Bike/Reports');
    } else if (Platform.isIOS) {
      final appDocDir = await getApplicationDocumentsDirectory();
      directory = Directory('${appDocDir.path}/Doctor Bike/Reports');
    } else {
      directory = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/Doctor Bike/Reports',
      );
    }
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  static String fileBaseName(AttendanceReportResult r, String ext) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'attendance_report_${r.year}_${r.month}_$ts.$ext';
  }

  static Future<File> savePdfToFile({
    required AttendanceReportResult result,
    required AttendanceReportArgs filters,
    bool simple = true,
  }) async {
    final dir = await _exportDirectory();
    final path = p.join(dir.path, fileBaseName(result, 'pdf'));
    final file = File(path);
    await file.writeAsBytes(
      await buildPdfBytes(result: result, filters: filters, simple: simple),
    );
    return file;
  }

  static Future<File> saveCsvToFile({
    required AttendanceReportResult result,
  }) async {
    final dir = await _exportDirectory();
    final path = p.join(dir.path, fileBaseName(result, 'csv'));
    final file = File(path);
    await file.writeAsString(buildCsvString(result: result), encoding: utf8);
    return file;
  }
}
