import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../../core/utils/assets_manger.dart';
import '../data/models/employee_attendance_history_model.dart';
import '../data/models/employee_advances_model.dart';

class EmployeeAttendanceHistoryPdfHelper {
  EmployeeAttendanceHistoryPdfHelper._();

  static Future<pw.Font> _loadRegular() async {
    final data =
        await rootBundle.load('assets/fonts/Almarai/Almarai-Regular.ttf');
    return pw.Font.ttf(data);
  }

  static Future<pw.Font> _loadBold() async {
    final data = await rootBundle.load('assets/fonts/Almarai/Almarai-Bold.ttf');
    return pw.Font.ttf(data);
  }

  static Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final data = await rootBundle.load(AssetsManager.darkLogo);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static String _time(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final h = hour12.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final marker = local.hour < 12 ? 'صباحاً' : 'مساءً';
    return '$h:$m $marker';
  }

  static String _dateWithDay(String value) {
    final names = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    try {
      final date = DateTime.parse(value);
      final formatted = DateFormat('yyyy-MM-dd').format(date);
      return '${names[date.weekday - 1]} - $formatted';
    } catch (_) {
      return value;
    }
  }

  static String _hoursFromMinutes(int minutes) {
    return (minutes / 60).toStringAsFixed(2);
  }

  static double _number(String? value) {
    return double.tryParse((value ?? '').replaceAll(',', '')) ?? 0;
  }

  static String _money(String? value) {
    final n = _number(value);
    if (n == 0 && value != null && value.isNotEmpty) {
      final parsed = double.tryParse(value.replaceAll(',', ''));
      if (parsed == null) return value;
    }
    return n.toStringAsFixed(2);
  }

  static String _sumMoney(Iterable<String?> values) {
    final total = values.fold<double>(0, (sum, value) => sum + _number(value));
    return total.toStringAsFixed(2);
  }

  static String _dayWorkLabel(EmployeeAttendanceDay day) {
    final holidayNotice = day.attendanceStatus == 'present_on_weekly_day_off'
        ? (day.attendanceStatusLabel ?? 'حضور في يوم عطلة رسمية')
        : null;

    if (day.segments.isNotEmpty) {
      final workedSegments = day.segments.map((segment) {
        final from = _time(segment.checkInAt);
        final to = segment.open ? 'داخل العمل' : _time(segment.checkOutAt);
        return '$from - $to';
      }).join('\n');

      return holidayNotice == null
          ? workedSegments
          : '$workedSegments\n$holidayNotice';
    }
    if (day.firstCheckIn != null || day.lastCheckOut != null) {
      final workedTime =
          '${_time(day.firstCheckIn)} - ${day.currentlyIn ? 'داخل العمل' : _time(day.lastCheckOut)}';

      return holidayNotice == null ? workedTime : '$workedTime\n$holidayNotice';
    }
    return day.attendanceStatusLabel ??
        (day.expectedWorkMinutes <= 0 ? 'عطلة رسمية' : 'عدم حضور');
  }

  static List<List<String>> _rows(EmployeeAttendanceHistoryResult result) {
    return result.days.map((day) {
      final required =
          day.requiredHours ?? _hoursFromMinutes(day.expectedWorkMinutes);
      final worked = day.workedHours ?? _hoursFromMinutes(day.workedMinutes);
      final salary = day.totalSalary ?? '0.00';
      return [
        _dateWithDay(day.date),
        _dayWorkLabel(day),
        worked,
        required,
        salary,
      ];
    }).toList();
  }

  static String _advanceStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'مقبولة';
      case 'rejected':
        return 'مرفوضة';
      case 'paid':
        return 'مدفوعة';
      case 'pending':
        return 'قيد الانتظار';
      default:
        return status;
    }
  }

  static pw.Widget _buildAdvancesSection({
    required List<EmployeeAdvanceModel> advances,
    required String advancesTotal,
    required String approvedAdvancesTotal,
    required pw.Font regular,
    required pw.Font bold,
    required bool rtl,
  }) {
    final title = pw.Container(
      width: double.infinity,
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'السلف خلال الفترة',
        textAlign: pw.TextAlign.right,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(
          font: bold,
          fontSize: 12,
          color: const PdfColor.fromInt(0xFF1F2937),
        ),
      ),
    );

    if (advances.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          title,
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFD0D7E2)),
            ),
            child: pw.Text(
              'لا توجد سلف ضمن هذه الفترة',
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: regular, fontSize: 8),
            ),
          ),
        ],
      );
    }

    final headers = [
      'تاريخ الطلب',
      'الوقت',
      'الحالة',
      'قيمة الطلب',
      'القيمة المقبولة',
    ];
    final rows = advances.map((advance) {
      final approvedValue =
          advance.status == 'approved' || advance.status == 'paid'
              ? (advance.approvedLoanValue ?? advance.amount)
              : '-';
      return [
        advance.date,
        advance.time,
        _advanceStatusLabel(advance.status),
        _money(advance.amount),
        approvedValue == '-' ? '-' : _money(approvedValue),
      ];
    }).toList();
    rows.add([
      'المجموع',
      '-',
      '-',
      _money(advancesTotal),
      _money(approvedAdvancesTotal),
    ]);

    final displayHeaders = rtl ? headers.reversed.toList() : headers;
    final displayRows =
        rtl ? rows.map((row) => row.reversed.toList()).toList() : rows;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        title,
        pw.SizedBox(height: 6),
        _buildTable(
          headers: displayHeaders,
          rows: displayRows,
          regular: regular,
          bold: bold,
        ),
      ],
    );
  }

  static pw.Widget _buildFinalPayrollSection({
    required EmployeeAttendanceHistoryResult result,
    required String approvedAdvancesTotal,
    required pw.Font regular,
    required pw.Font bold,
    required bool rtl,
  }) {
    final summary = result.monthlySummary;
    final normalHours = summary?.rangeNormalHours ??
        summary?.monthlyNormalHours ??
        result.days
            .fold<double>(0, (sum, day) => sum + _number(day.normalHours))
            .toStringAsFixed(2);
    final overtimeHours = summary?.rangeOvertimeHours ??
        summary?.monthlyOvertimeHours ??
        result.days
            .fold<double>(0, (sum, day) => sum + _number(day.overtimeHours))
            .toStringAsFixed(2);
    final normalSalary = summary?.rangeNormalSalary ??
        _sumMoney(result.days.map((day) => day.normalSalary));
    final overtimeSalary = summary?.rangeOvertimeSalary ??
        _sumMoney(result.days.map((day) => day.overtimeSalary));
    final grossSalary = summary?.rangeTotalSalary ??
        (_number(normalSalary) + _number(overtimeSalary)).toStringAsFixed(2);
    final advancesDeduction = _money(approvedAdvancesTotal);
    final netSalary =
        (_number(grossSalary) - _number(advancesDeduction)).toStringAsFixed(2);

    final headers = ['البند', 'القيمة'];
    final rows = [
      ['إجمالي الساعات العادية', '$normalHours ساعة'],
      ['إجمالي ساعات الأوفر تايم', '$overtimeHours ساعة'],
      ['إجمالي مبلغ الساعات العادية', _money(normalSalary)],
      ['إجمالي مبلغ الأوفر تايم', _money(overtimeSalary)],
      ['الإجمالي قبل السلف', _money(grossSalary)],
      ['خصم السلف المقبولة', advancesDeduction],
      ['الصافي المفروض يقبضه الموظف', _money(netSalary)],
    ];

    final displayHeaders = rtl ? headers.reversed.toList() : headers;
    final displayRows =
        rtl ? rows.map((row) => row.reversed.toList()).toList() : rows;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(
          width: double.infinity,
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'الخلاصة النهائية',
            textAlign: pw.TextAlign.right,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: bold,
              fontSize: 12,
              color: const PdfColor.fromInt(0xFF1F2937),
            ),
          ),
        ),
        pw.SizedBox(height: 6),
        _buildTable(
          headers: displayHeaders,
          rows: displayRows,
          regular: regular,
          bold: bold,
        ),
      ],
    );
  }

  static Future<Uint8List> buildPdfBytes({
    required EmployeeAttendanceHistoryResult result,
    required String periodLabel,
    List<EmployeeAdvanceModel> advances = const [],
    String advancesTotal = '0.00',
    String approvedAdvancesTotal = '0.00',
  }) async {
    final regular = await _loadRegular();
    final bold = await _loadBold();
    final logo = await _loadLogo();
    final rtl = Get.locale?.languageCode == 'ar';

    final summary = result.monthlySummary;
    final workedTotal = summary?.rangeWorkedHours ??
        summary?.monthlyWorkedHours ??
        _hoursFromMinutes(
          result.days.fold<int>(0, (sum, day) => sum + day.workedMinutes),
        );
    final requiredTotal = summary?.rangeRequiredHours ??
        summary?.monthlyRequiredHours ??
        _hoursFromMinutes(
          result.days.fold<int>(
            0,
            (sum, day) => sum + day.expectedWorkMinutes,
          ),
        );
    final salaryTotal = summary?.rangeTotalSalary ?? '0.00';

    final headers = [
      'اليوم والتاريخ',
      'الدوام',
      'الصافي',
      'المطلوب',
      'الحساب',
    ];
    final rows = [
      ..._rows(result),
      [
        'المجموع',
        '-',
        workedTotal,
        requiredTotal,
        _money(salaryTotal),
      ],
    ];
    final displayHeaders = rtl ? headers.reversed.toList() : headers;
    final displayRows =
        rtl ? rows.map((row) => row.reversed.toList()).toList() : rows;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColor.fromInt(0xFF6B65BD),
                  width: 2,
                ),
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
                            'دكتور بايك - تقرير دوام موظف',
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
                            result.employee.name ?? '-',
                            textAlign: pw.TextAlign.right,
                            textDirection: pw.TextDirection.rtl,
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
            'تقرير الدوام',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: bold, fontSize: 15),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            alignment: rtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
            child: pw.Column(
              crossAxisAlignment:
                  rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'الموظف: ${result.employee.name ?? '-'}',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(font: regular, fontSize: 9),
                ),
                pw.Text(
                  'الفترة: $periodLabel',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(font: regular, fontSize: 9),
                ),
                pw.Text(
                  'سعر الساعة: ${_money(result.employee.hourWorkPrice)}',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(font: regular, fontSize: 9),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          _buildTable(
            headers: displayHeaders,
            rows: displayRows,
            regular: regular,
            bold: bold,
          ),
          pw.SizedBox(height: 14),
          _buildAdvancesSection(
            advances: advances,
            advancesTotal: advancesTotal,
            approvedAdvancesTotal: approvedAdvancesTotal,
            regular: regular,
            bold: bold,
            rtl: rtl,
          ),
          pw.SizedBox(height: 14),
          _buildFinalPayrollSection(
            result: result,
            approvedAdvancesTotal: approvedAdvancesTotal,
            regular: regular,
            bold: bold,
            rtl: rtl,
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildTable({
    required List<String> headers,
    required List<List<String>> rows,
    required pw.Font regular,
    required pw.Font bold,
  }) {
    pw.Widget cell(
      String value, {
      bool header = false,
      bool total = false,
    }) {
      return pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        color: header
            ? const PdfColor.fromInt(0xFF6B65BD)
            : total
                ? const PdfColor.fromInt(0xFFEEF4FF)
                : null,
        child: pw.Text(
          value,
          textAlign: pw.TextAlign.center,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(
            font: header || total ? bold : regular,
            fontSize: header ? 8 : 7,
            color: header ? PdfColors.white : PdfColors.black,
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(
        color: const PdfColor.fromInt(0xFFD0D7E2),
        width: 0.8,
      ),
      children: [
        pw.TableRow(
          children:
              headers.map((header) => cell(header, header: true)).toList(),
        ),
        ...rows.asMap().entries.map((entry) {
          final isTotal = entry.key == rows.length - 1;
          return pw.TableRow(
            children: entry.value
                .map((value) => cell(value, total: isTotal))
                .toList(),
          );
        }),
      ],
    );
  }

  static Future<File> savePdfToFile({
    required EmployeeAttendanceHistoryResult result,
    required String periodLabel,
    List<EmployeeAdvanceModel> advances = const [],
    String advancesTotal = '0.00',
    String approvedAdvancesTotal = '0.00',
  }) async {
    late Directory directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download/Doctor Bike/Reports');
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      directory = Directory('${appDocDir.path}/Doctor Bike/Reports');
    }
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final employeeName = (result.employee.name ?? 'employee')
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final fileName =
        'employee_attendance_${employeeName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(p.join(directory.path, fileName));
    await file.writeAsBytes(
      await buildPdfBytes(
        result: result,
        periodLabel: periodLabel,
        advances: advances,
        advancesTotal: advancesTotal,
        approvedAdvancesTotal: approvedAdvancesTotal,
      ),
    );
    return file;
  }
}
