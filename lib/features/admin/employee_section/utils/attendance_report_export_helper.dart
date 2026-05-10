import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/attendance_report_model.dart';

/// تصدير تقرير الحضور PDF / جدول يفتح بـ Excel (CSV مع UTF-8 BOM).
class AttendanceReportExportHelper {
  AttendanceReportExportHelper._();

  static String _csvEsc(String s) {
    if (s.contains(';') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static Future<pw.Font> _loadAlmaraiRegular() async {
    final data = await rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf');
    return pw.Font.ttf(data);
  }

  static Future<pw.Font> _loadAlmaraiBold() async {
    final data = await rootBundle.load('assets/fonts/Almarai/Almarai-Bold.ttf');
    return pw.Font.ttf(data);
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
      default:
        return code;
    }
  }

  /// PDF bytes (A4 أفقي، خط المشروع لدعم العربية).
  static Future<Uint8List> buildPdfBytes({
    required AttendanceReportResult result,
    AttendanceReportArgs? filters,
  }) async {
    final regular = await _loadAlmaraiRegular();
    final bold = await _loadAlmaraiBold();
    final rtl = Get.locale?.languageCode == 'ar';

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
      'pointsSummaryReportCol'.tr,
      'rewardAmountReportCol'.tr,
      'finalSalaryReportCol'.tr,
      'employeeDebtsReportCol'.tr,
    ];

    final data = result.employees
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
            '${e.pointsSummary.earnedPoints}/${e.pointsSummary.deductedPoints}/${e.pointsSummary.netPoints}',
            e.rewardAmount,
            e.finalSalary,
            e.employeeDebts,
          ],
        )
        .toList();

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
        build: (ctx) => [
          pw.Text(
            'attendanceReportTitle'.tr,
            style: pw.TextStyle(font: bold, fontSize: 16),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${_typeLabel(result.reportType)} · ${result.month}/${result.year}',
            style: pw.TextStyle(font: bold, fontSize: 11),
          ),
          pw.Text(subTitle, style: pw.TextStyle(font: regular, fontSize: 9)),
          if (filterLine != null) ...[
            pw.Text(
              filterLine,
              style: pw.TextStyle(font: regular, fontSize: 8),
            ),
          ],
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(font: bold, fontSize: 7),
            cellStyle: pw.TextStyle(font: regular, fontSize: 6),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            cellHeight: 18,
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
      'pointsSummaryReportCol'.tr,
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
        '${e.pointsSummary.earnedPoints}/${e.pointsSummary.deductedPoints}/${e.pointsSummary.netPoints}',
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
  }) async {
    final dir = await _exportDirectory();
    final path = p.join(dir.path, fileBaseName(result, 'pdf'));
    final file = File(path);
    await file.writeAsBytes(
      await buildPdfBytes(result: result, filters: filters),
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
