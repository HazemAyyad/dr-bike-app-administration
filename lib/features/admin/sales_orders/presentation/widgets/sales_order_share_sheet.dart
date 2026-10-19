import 'dart:io';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../../core/helpers/whatsapp_pdf_share.dart';
import '../../data/models/sales_order_model.dart';
import 'sales_order_invoice_pdf.dart';

class SalesOrderShareSheet extends StatefulWidget {
  const SalesOrderShareSheet({Key? key, required this.order}) : super(key: key);
  final SalesOrderDetailModel order;

  @override
  State<SalesOrderShareSheet> createState() => _SalesOrderShareSheetState();
}

class _SalesOrderShareSheetState extends State<SalesOrderShareSheet> {
  final otherPhone = TextEditingController();
  bool customer = true;
  bool includeImages = false;
  bool includeNotes = false;
  bool busy = false;
  bool loadingApps = true;
  String country = '972';
  String? packageName;
  List<String> apps = [];

  @override
  void initState() {
    super.initState();
    country =
        (widget.order.customerPhone ?? '').contains('970') ? '970' : '972';
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      apps = await WhatsAppPdfShare.installedApps();
      packageName = apps.contains(WhatsAppPdfShare.regular)
          ? WhatsAppPdfShare.regular
          : (apps.isEmpty ? null : apps.first);
    } catch (_) {
      apps = [];
    }
    if (mounted) setState(() => loadingApps = false);
  }

  @override
  void dispose() {
    otherPhone.dispose();
    super.dispose();
  }

  void _error(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _export(String action) async {
    if (busy) return;
    final phone = WhatsAppPdfShare.phoneDigits(
        customer ? widget.order.customerPhone ?? '' : otherPhone.text,
        countryCode: country);
    if (action == 'whatsapp' &&
        (packageName == null ||
            !RegExp(r'^[1-9][0-9]{7,14}$').hasMatch(phone))) {
      _error(packageName == null
          ? 'اختر نسخة واتساب مثبتة على الجهاز'
          : 'أدخل رقم هاتف صحيحًا');
      return;
    }
    setState(() => busy = true);
    try {
      final bytes = await SalesOrderInvoicePdf.build(widget.order,
          includeNotes: includeNotes, includeProductImages: includeImages);
      final filename =
          'sales_order_${widget.order.serialNumber ?? widget.order.id}.pdf';
      if (action == 'print') {
        await Printing.layoutPdf(onLayout: (_) async => bytes);
      } else if (action == 'whatsapp') {
        final opened = await WhatsAppPdfShare.share(
            bytes: bytes,
            filename: filename,
            packageName: packageName!,
            phone: phone);
        if (!opened && mounted) _error('تعذر فتح نسخة واتساب المختارة');
      } else {
        await Printing.sharePdf(bytes: bytes, filename: filename);
      }
    } catch (_) {
      if (mounted) _error('تعذر تجهيز الفاتورة أو مشاركتها. أعد المحاولة.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: const Color(0xFFF3F4F6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
            child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              18, 18, 18, 18 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    'فاتورة الطلبية ${widget.order.serialNumber ?? widget.order.id}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Color(0xFF111827))),
                CheckboxListTile(
                    value: includeImages,
                    onChanged:
                        busy ? null : (v) => setState(() => includeImages = v!),
                    title: const Text('تضمين صور الأصناف')),
                CheckboxListTile(
                    value: includeNotes,
                    onChanged:
                        busy ? null : (v) => setState(() => includeNotes = v!),
                    title: const Text('تضمين الملاحظات وصورها'),
                    subtitle: const Text(
                        'قد تحتوي معلومات داخلية؛ راجعها قبل إرسالها للزبون')),
                if (Platform.isAndroid) ...[
                  const Divider(),
                  if (loadingApps) const LinearProgressIndicator(),
                  DropdownButtonFormField<String>(
                    initialValue: packageName,
                    decoration: const InputDecoration(
                        labelText: 'نسخة واتساب', border: OutlineInputBorder()),
                    items: [
                      for (final app in apps)
                        DropdownMenuItem(
                            value: app,
                            child: Text(app == WhatsAppPdfShare.regular
                                ? 'واتساب العادي'
                                : 'واتساب الأعمال'))
                    ],
                    onChanged:
                        busy ? null : (v) => setState(() => packageName = v),
                  ),
                  if (!loadingApps && apps.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                            'واتساب غير مثبت، أو يلزم تحديث التطبيق. يمكنك استخدام المشاركة العامة.')),
                  SwitchListTile(
                      value: customer,
                      onChanged:
                          busy ? null : (v) => setState(() => customer = v),
                      title: const Text('الإرسال لزبون هذه الفاتورة'),
                      subtitle: Text(customer
                          ? widget.order.customerPhone ?? 'لا يوجد رقم للزبون'
                          : 'الإرسال إلى رقم آخر')),
                  if (!customer)
                    TextField(
                        controller: otherPhone,
                        enabled: !busy,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                            labelText: 'الرقم الآخر',
                            hintText: '059… أو +رمز الدولة',
                            border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: country,
                    decoration: const InputDecoration(
                        labelText: 'مقدمة الأرقام المحلية',
                        border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: '972', child: Text('+972')),
                      DropdownMenuItem(value: '970', child: Text('+970'))
                    ],
                    onChanged:
                        busy ? null : (v) => setState(() => country = v!),
                  ),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                          'سيفتح ملف PDF في النسخة المختارة. قد يطلب واتساب تأكيد المستلم قبل الإرسال.')),
                  OutlinedButton.icon(
                      onPressed: busy || loadingApps || apps.isEmpty
                          ? null
                          : () => _export('whatsapp'),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('مشاركة PDF عبر واتساب')),
                ] else
                  const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                          'اختر نسخة واتساب والمستلم من نافذة مشاركة النظام.')),
                OutlinedButton.icon(
                    onPressed: busy ? null : () => _export('share'),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('مشاركة PDF عبر تطبيق آخر')),
                OutlinedButton.icon(
                    onPressed: busy ? null : () => _export('print'),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('طباعة الفاتورة')),
                if (busy)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator())),
              ]),
        )),
      ),
    );
  }
}
