import 'dart:math' as math;

import 'package:flutter/gestures.dart';
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
              onPressed: () {
                final displayedBytes = _bytes;
                final displayedDocument = widget.document;
                Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                          appBar: AppBar(
                              title: Text(displayedDocument.title),
                              actions: [
                                _PdfShareButton(
                                    bytes: displayedBytes,
                                    filename: '${displayedDocument.kind}.pdf'),
                              ]),
                          body: _preview(
                              source: displayedBytes,
                              document: displayedDocument),
                        )));
              },
            )),
        SizedBox(
            height: MediaQuery.sizeOf(context).width < 600 ? 510 : 740,
            child: _preview()),
      ]);
  Widget _preview({
    Future<Uint8List>? source,
    AccountingReportDocument? document,
  }) {
    final bytes = source ?? _bytes;
    final displayedDocument = document ?? widget.document;
    return FutureBuilder<Uint8List>(
        future: bytes,
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
          final media = MediaQuery.of(context);
          final rasterWidth = math.min(
              1800.0,
              math.min(media.size.width, 1200.0) *
                  media.devicePixelRatio *
                  1.5);
          return PdfPreview.builder(
            key: ObjectKey(bytes),
            build: (_) => bytes,
            initialPageFormat: displayedDocument.pageFormat,
            canDebug: false,
            canChangeOrientation: false,
            canChangePageFormat: false,
            allowPrinting: false,
            allowSharing: false,
            useActions: false,
            dynamicLayout: false,
            maxPageWidth: 1200,
            dpi: rasterWidth *
                PdfPageFormat.inch /
                displayedDocument.pageFormat.width,
            pdfFileName: '${displayedDocument.kind}.pdf',
            pagesBuilder: (_, pages) => _ZoomablePdfPages(pages: pages),
            onError: (_, __) =>
                const Center(child: Text('تعذر عرض صفحات التقرير')),
          );
        });
  }

  Future<Uint8List> _buildDocument() =>
      AccountingReportPdf.buildAll(widget.documents ?? [widget.document]);
}

class _ZoomablePdfPages extends StatefulWidget {
  const _ZoomablePdfPages({required this.pages});

  final List<PdfPreviewPageData> pages;

  @override
  State<_ZoomablePdfPages> createState() => _ZoomablePdfPagesState();
}

class _ZoomablePdfPagesState extends State<_ZoomablePdfPages> {
  static const _minZoom = .75;
  static const _maxZoom = 3.0;
  static const _controlsHeight = 48.0;
  final _vertical = ScrollController();
  final _horizontal = ScrollController();
  final _touches = <int, Offset>{};
  double _zoom = 1.0;
  double _pinchStartZoom = 1.0;
  double? _pinchStartDistance;
  Offset? _pinchAnchor;
  Offset? _pendingOffset;

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  double _centerInset(double width, double zoom) =>
      math.max(0, width * (1 - zoom) / 2);

  Offset _documentPoint(Offset focal, Size viewport) {
    final offset =
        _pendingOffset ?? Offset(_horizontal.offset, _vertical.offset);
    return (offset + focal - Offset(_centerInset(viewport.width, _zoom), 0)) /
        _zoom;
  }

  void _zoomAt(double value, Offset focal, Size viewport, {Offset? anchor}) {
    final zoom = value.clamp(_minZoom, _maxZoom).toDouble();
    if (zoom == _zoom && anchor == null) return;
    final point = anchor ?? _documentPoint(focal, viewport);
    final schedule = _pendingOffset == null;
    _pendingOffset =
        point * zoom + Offset(_centerInset(viewport.width, zoom), 0) - focal;
    setState(() => _zoom = zoom);
    if (!schedule) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final offset = _pendingOffset!;
      _pendingOffset = null;
      _scrollTo(_horizontal, offset.dx);
      _scrollTo(_vertical, offset.dy);
    });
  }

  void _scrollTo(ScrollController controller, double offset) {
    if (!controller.hasClients) return;
    final position = controller.position;
    final target =
        offset.clamp(position.minScrollExtent, position.maxScrollExtent);
    if (target != position.pixels) controller.jumpTo(target.toDouble());
  }

  void _touchDown(PointerDownEvent event, Size viewport) {
    if (event.kind != PointerDeviceKind.touch || _touches.length >= 2) return;
    _touches[event.pointer] = event.localPosition;
    if (_touches.length != 2) return;
    final first = _touches.values.first;
    final second = _touches.values.last;
    _pinchStartZoom = _zoom;
    _pinchStartDistance = math.max(1, (first - second).distance);
    setState(
        () => _pinchAnchor = _documentPoint((first + second) / 2, viewport));
  }

  void _touchMove(PointerMoveEvent event, Size viewport) {
    if (!_touches.containsKey(event.pointer)) return;
    _touches[event.pointer] = event.localPosition;
    if (_touches.length != 2 || _pinchStartDistance == null) return;
    final first = _touches.values.first;
    final second = _touches.values.last;
    final zoom =
        _pinchStartZoom * (first - second).distance / _pinchStartDistance!;
    _zoomAt(zoom, (first + second) / 2, viewport, anchor: _pinchAnchor);
  }

  void _touchEnd(PointerEvent event) {
    _touches.remove(event.pointer);
    if (_touches.length < 2 && _pinchAnchor != null) {
      _pinchStartDistance = null;
      setState(() => _pinchAnchor = null);
    }
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth,
            math.max(0, constraints.maxHeight - _controlsHeight));
        final center = viewport.center(Offset.zero);
        final pageWidth = math.max(0, viewport.width - 32) * _zoom;
        final physics =
            _pinchAnchor == null ? null : const NeverScrollableScrollPhysics();
        return Column(children: [
          SizedBox(
            height: _controlsHeight,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                tooltip: 'تصغير التقرير',
                onPressed: _zoom <= _minZoom
                    ? null
                    : () => _zoomAt(_zoom - .25, center, viewport),
                icon: const Icon(Icons.zoom_out),
              ),
              Tooltip(
                message: 'ملاءمة عرض الصفحة',
                child: TextButton(
                  onPressed:
                      _zoom == 1 ? null : () => _zoomAt(1, center, viewport),
                  child: Text('${(_zoom * 100).round()}%',
                      textDirection: TextDirection.ltr),
                ),
              ),
              IconButton(
                tooltip: 'تكبير التقرير',
                onPressed: _zoom >= _maxZoom
                    ? null
                    : () => _zoomAt(_zoom + .25, center, viewport),
                icon: const Icon(Icons.zoom_in),
              ),
            ]),
          ),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) => _touchDown(event, viewport),
                onPointerMove: (event) => _touchMove(event, viewport),
                onPointerUp: _touchEnd,
                onPointerCancel: _touchEnd,
                child: ColoredBox(
                  color: const Color(0xFFE5E7EB),
                  child: Scrollbar(
                    controller: _horizontal,
                    thumbVisibility: _zoom > 1,
                    notificationPredicate: (event) =>
                        event.metrics.axis == Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: _horizontal,
                      scrollDirection: Axis.horizontal,
                      physics: physics,
                      child: SizedBox(
                        width: viewport.width * math.max(1, _zoom),
                        child: ListView.builder(
                          controller: _vertical,
                          physics: physics,
                          padding: EdgeInsets.symmetric(vertical: 8 * _zoom),
                          itemCount: widget.pages.length,
                          itemBuilder: (_, index) => Center(
                            child: Container(
                              width: pageWidth,
                              margin: EdgeInsets.symmetric(vertical: 6 * _zoom),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                      color: Color(0x22000000), blurRadius: 5)
                                ],
                              ),
                              child: AspectRatio(
                                aspectRatio: widget.pages[index].aspectRatio,
                                child: Image(
                                    image: widget.pages[index].image,
                                    fit: BoxFit.contain),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]);
      });
}

class _PdfShareButton extends StatefulWidget {
  const _PdfShareButton({required this.bytes, required this.filename});
  final Future<Uint8List> bytes;
  final String filename;
  @override
  State<_PdfShareButton> createState() => _PdfShareButtonState();
}

class _PdfShareButtonState extends State<_PdfShareButton> {
  bool _sharing = false;
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'مشاركة التقرير المعروض',
        icon: _sharing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.ios_share_outlined),
        onPressed: _sharing
            ? null
            : () async {
                final render = context.findRenderObject();
                final bounds = render is RenderBox && render.hasSize
                    ? render.localToGlobal(Offset.zero) & render.size
                    : null;
                setState(() => _sharing = true);
                try {
                  final bytes = await widget.bytes;
                  if (!mounted) {
                    return;
                  }
                  await Printing.sharePdf(
                      bytes: bytes, filename: widget.filename, bounds: bounds);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تعذرت مشاركة التقرير. حاول مرة أخرى.')));
                  }
                } finally {
                  if (mounted) {
                    setState(() => _sharing = false);
                  }
                }
              },
      );
}
