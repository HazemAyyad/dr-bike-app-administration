import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'accounting_report_pdf.dart';

class AccountingReportPreview extends StatefulWidget {
  const AccountingReportPreview(
      {Key? key,
      required this.snapshot,
      required this.document,
      this.documents})
      : super(key: key);
  final Object snapshot;
  final AccountingReportDocument document;
  final List<AccountingReportDocument>? documents;
  @override
  State<AccountingReportPreview> createState() =>
      _AccountingReportPreviewState();
}

class _AccountingReportPreviewState extends State<AccountingReportPreview> {
  late Future<Uint8List> _bytes;
  @override
  void initState() {
    super.initState();
    _bytes = _buildDocument();
  }

  @override
  void didUpdateWidget(AccountingReportPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.snapshot, widget.snapshot)) {
      _bytes = _buildDocument();
    }
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              icon: const Icon(Icons.fullscreen),
              label: const Text('فتح التقرير بملء الشاشة'),
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                            appBar: AppBar(title: Text(widget.document.title)),
                            body: _preview(),
                          ))),
            )),
        SizedBox(
            height: MediaQuery.sizeOf(context).width < 600 ? 510 : 740,
            child: _preview()),
      ]);
  Widget _preview() => FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: TextButton.icon(
                  onPressed: () => setState(() => _bytes = _buildDocument()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('تعذر تجهيز التقرير • إعادة المحاولة')));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return PdfPreview(
          build: _layout,
          initialPageFormat: widget.document.pageFormat,
          canDebug: false,
          canChangeOrientation: false,
          canChangePageFormat: false,
          allowPrinting: false,
          allowSharing: false,
          useActions: false,
          dynamicLayout: false,
          maxPageWidth: 1200,
          pdfFileName: '${widget.document.kind}.pdf',
          pdfPreviewPageDecoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 5)]),
          scrollViewDecoration: const BoxDecoration(color: Color(0xFFE5E7EB)),
          onError: (_, __) =>
              const Center(child: Text('تعذر عرض صفحات التقرير')),
        );
      });

  Future<Uint8List> _layout(PdfPageFormat _) => _bytes;
  Future<Uint8List> _buildDocument() =>
      AccountingReportPdf.buildAll(widget.documents ?? [widget.document]);
}
