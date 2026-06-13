import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/haptic_helper.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/store_section_model.dart';
import '../controllers/stock_controller.dart';

/// Products FAB: tap = add menu; long-press = quarter-arc location filter.
class StockProductsFab extends StatefulWidget {
  const StockProductsFab({
    Key? key,
    required this.isAddMenuOpen,
    required this.onTap,
    required this.sizeAnimation,
    required this.opacityAnimation,
    this.customWidget,
  }) : super(key: key);

  final RxBool isAddMenuOpen;
  final void Function()? onTap;
  final Animation<double> sizeAnimation;
  final Animation<double> opacityAnimation;
  final Widget? customWidget;

  @override
  State<StockProductsFab> createState() => _StockProductsFabState();
}

class _StockProductsFabState extends State<StockProductsFab> {
  final StockController _stock = Get.find<StockController>();
  final GlobalKey _fabKey = GlobalKey();

  OverlayEntry? _overlay;
  bool _loading = false;

  int _highlightIndex = -1;
  Offset? _anchorCenter;
  bool _fabOnLeft = false;
  int _segmentPage = 0;
  double _pageDragAccum = 0;

  static const double _centerHit = 34;
  static const double _minPickRadius = 44;
  static const double _pageSwipeThreshold = 52;
  static const double _arcSweep = math.pi / 2;

  static final List<_ArcRowConfig> _arcRows = _buildArcRows();

  static List<_ArcRowConfig> _buildArcRows() {
    const baseRadius = 72.0;
    const radiusStep = 46.0;
    const arcCount = 5;
    const minBubble = 32.0;
    const gap = 7.0;
    const slotPitch = minBubble + gap;

    return List.generate(arcCount, (i) {
      final radius = baseRadius + i * radiusStep;
      final arcLength = radius * math.pi / 2;
      final capacity = math.max(2, (arcLength / slotPitch).floor());
      return _ArcRowConfig(capacity: capacity, radius: radius);
    });
  }

  List<StoreSectionModel> get _activeSections =>
      _stock.storeSections.where((s) => s.isActive).toList(growable: false);

  int get _itemsPerPage =>
      _arcRows.fold(0, (sum, row) => sum + row.capacity);

  List<StoreSectionModel> get _currentPageItems {
    final source = _activeSections;
    if (source.isEmpty) return const [];
    final start = _segmentPage * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, source.length);
    return source.sublist(start, end);
  }

  int get _pageCount {
    final total = _activeSections.length;
    if (total <= 0) return 1;
    return ((total + _itemsPerPage - 1) ~/ _itemsPerPage);
  }

  bool get _lensEnabled => _stock.currentTab.value == 0;

  @override
  void dispose() {
    _removeOverlay(applySelection: false);
    super.dispose();
  }

  Offset? _readFabCenter([BuildContext? overlayContext]) {
    final box = _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;

    final global = box.localToGlobal(box.size.center(Offset.zero));
    if (overlayContext == null) return global;

    final overlayBox = overlayContext.findRenderObject() as RenderBox?;
    if (overlayBox == null) return global;
    return overlayBox.globalToLocal(global);
  }

  void _syncAnchor(BuildContext overlayContext) {
    final center = _readFabCenter(overlayContext);
    if (center == null) return;
    _anchorCenter = center;
    _fabOnLeft = center.dx < MediaQuery.sizeOf(overlayContext).width * 0.5;
  }

  Future<void> _loadSections() async {
    setState(() => _loading = true);
    _overlay?.markNeedsBuild();
    try {
      await _stock.ensureStoreSectionsLoaded();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _overlay?.markNeedsBuild();
      }
    }
  }

  Future<void> _openLens() async {
    if (!_lensEnabled || _overlay != null) return;
    if (widget.isAddMenuOpen.value) {
      widget.onTap?.call();
    }
    HapticHelper.selection();
    _highlightIndex = -1;
    _segmentPage = 0;
    _pageDragAccum = 0;
    _anchorCenter = _readFabCenter();
    _overlay = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context, rootOverlay: true).insert(_overlay!);
    await _loadSections();
    _overlay?.markNeedsBuild();
  }

  void _removeOverlay({required bool applySelection}) {
    if (_overlay == null) return;
    _overlay?.remove();
    _overlay = null;
    _anchorCenter = null;
    if (applySelection) {
      _commitCurrentSelection();
    }
    if (mounted) setState(() {});
  }

  void _commitCurrentSelection() {
    if (_highlightIndex < 0) {
      _stock.clearStoreLocationFilterFromFab();
    } else {
      final sections = _activeSections;
      if (sections.isNotEmpty) {
        final i = _highlightIndex.clamp(0, sections.length - 1);
        _stock.applyStoreLocationFilterFromFab(sectionId: sections[i].id);
      }
    }
  }

  void _setHighlight(int index, {bool vibrate = true}) {
    if (index == _highlightIndex) return;
    if (vibrate) HapticHelper.confirm();
    _highlightIndex = index;
    _schedulePreview();
    _overlay?.markNeedsBuild();
  }

  void _schedulePreview() {
    // Apply filter only when the lens closes — not while dragging (avoids
    // rebuilding the FAB/parent and leaving a stuck overlay).
    _overlay?.markNeedsBuild();
  }

  void _handlePageSwipe(double deltaX) {
    if (_pageCount <= 1) return;
    _pageDragAccum += deltaX;
    if (_pageDragAccum >= _pageSwipeThreshold) {
      if (_segmentPage < _pageCount - 1) {
        _segmentPage++;
        HapticHelper.selection();
      }
      _pageDragAccum = 0;
      _overlay?.markNeedsBuild();
      return;
    }
    if (_pageDragAccum <= -_pageSwipeThreshold) {
      if (_segmentPage > 0) {
        _segmentPage--;
        HapticHelper.selection();
      }
      _pageDragAccum = 0;
      _overlay?.markNeedsBuild();
    }
  }

  List<_ArcSlot> _layoutSlots(int count) {
    if (count <= 0) return const [];
    final slots = <_ArcSlot>[];
    var local = 0;
    for (var row = 0; row < _arcRows.length && local < count; row++) {
      final inRow = math.min(_arcRows[row].capacity, count - local);
      for (var slot = 0; slot < inRow; slot++) {
        slots.add(
          _ArcSlot(
            localIndex: local,
            row: row,
            slotInRow: slot,
            rowCount: inRow,
          ),
        );
        local++;
      }
    }
    return slots;
  }

  List<int> _activeRows(int count) {
    return _layoutSlots(count).map((s) => s.row).toSet().toList()..sort();
  }

  double _radiusForRow(int row) =>
      _arcRows[row.clamp(0, _arcRows.length - 1)].radius;

  double _arcStartAngle() => _fabOnLeft ? -math.pi / 2 : -math.pi;

  double _arcEndAngle() => _fabOnLeft ? 0.0 : -math.pi / 2;

  bool _angleInArc(double angle) {
    const margin = 0.22;
    final start = _arcStartAngle();
    final end = _arcEndAngle();
    return angle >= (start - margin) && angle <= (end + margin);
  }

  double _angleForSlot(int index, int total) {
    final t = total <= 1 ? 0.5 : (index + 0.5) / total;
    return _arcStartAngle() + t * _arcSweep;
  }

  int _localIndexFromAngle(double angle, int total) {
    final start = _arcStartAngle();
    final t = ((angle - start) / _arcSweep).clamp(0.0, 0.999999);
    return (t * total).floor().clamp(0, total - 1);
  }

  double _bubbleSize({required int rowCount}) {
    if (rowCount >= 9) return 32;
    if (rowCount >= 7) return 36;
    if (rowCount >= 5) return 40;
    if (rowCount >= 3) return 44;
    return 48;
  }

  int? _rowFromDistance(double distance, int pageCount) {
    final rows = _activeRows(pageCount);
    if (rows.isEmpty) return null;

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final radius = _radiusForRow(row);
      final inner = i == 0
          ? _minPickRadius
          : (_radiusForRow(rows[i - 1]) + radius) / 2;
      final outer = i == rows.length - 1
          ? radius + 36
          : (radius + _radiusForRow(rows[i + 1])) / 2;
      if (distance >= inner && distance < outer) return row;
    }

    int? bestRow;
    var bestDiff = double.infinity;
    for (final row in rows) {
      final diff = (distance - _radiusForRow(row)).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestRow = row;
      }
    }
    return bestRow;
  }

  int _indexFromPointer(Offset global, BuildContext overlayContext) {
    _syncAnchor(overlayContext);
    final center = _anchorCenter;
    if (center == null) return -1;

    final delta = global - center;
    if (delta.distance <= _centerHit) return -1;
    if (delta.distance < _minPickRadius) return _highlightIndex;

    final pageItems = _currentPageItems;
    if (pageItems.isEmpty) return -1;

    final angle = math.atan2(delta.dy, delta.dx);
    if (!_angleInArc(angle)) return _highlightIndex;

    final row = _rowFromDistance(delta.distance, pageItems.length);
    if (row == null) return _highlightIndex;

    final rowSlots = _layoutSlots(pageItems.length)
        .where((s) => s.row == row)
        .toList()
      ..sort((a, b) => a.slotInRow.compareTo(b.slotInRow));
    if (rowSlots.isEmpty) return _highlightIndex;

    final slotInRow = _localIndexFromAngle(angle, rowSlots.length);
    return _segmentPage * _itemsPerPage +
        rowSlots[slotInRow.clamp(0, rowSlots.length - 1)].localIndex;
  }

  Offset _slotPosition(_ArcSlot slot, Offset center) {
    final angle = _angleForSlot(slot.slotInRow, slot.rowCount);
    final radius = _radiusForRow(slot.row);
    return center +
        Offset(math.cos(angle) * radius, math.sin(angle) * radius);
  }

  String? _centerBannerLabel() {
    if (_highlightIndex < 0) return null;
    final sections = _activeSections;
    if (sections.isEmpty) return null;
    return sections[_highlightIndex.clamp(0, sections.length - 1)].name;
  }

  void _onPointerUp() {
    _removeOverlay(applySelection: true);
  }

  Widget _buildOverlay(BuildContext context) {
    _syncAnchor(context);
    final anchor = _anchorCenter;
    final pageItems = _currentPageItems;
    final onPage = pageItems.length;
    final slots = _layoutSlots(onPage);
    final guideRadii = _activeRows(onPage).map(_radiusForRow).toList();
    final maxArcRadius =
        guideRadii.isEmpty ? 180.0 : guideRadii.reduce(math.max);
    final bannerLabel = _centerBannerLabel();
    final totalCount = _activeSections.length;
    final clearSelected = _highlightIndex < 0;

    return Material(
      color: Colors.transparent,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          _pageDragAccum = 0;
          _syncAnchor(context);
        },
        onPointerMove: (e) {
          _handlePageSwipe(e.delta.dx);
          _setHighlight(_indexFromPointer(e.position, context));
        },
        onPointerUp: (_) => _onPointerUp(),
        onPointerCancel: (_) => _removeOverlay(applySelection: false),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _removeOverlay(applySelection: true),
                child: Container(color: Colors.black.withValues(alpha: 0.45)),
              ),
            ),
            if (!_loading && bannerLabel != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: _CenterSelectionBanner(
                      title: bannerLabel,
                      subtitle: 'storeLocationFabChooseSection'.tr,
                      index: _highlightIndex + 1,
                      total: totalCount,
                      pageCount: _pageCount,
                      currentPage: _segmentPage,
                    ),
                  ),
                ),
              ),
            if (anchor != null) ...[
              Positioned.fill(
                child: CustomPaint(
                  painter: _QuarterArcGuidePainter(
                    center: anchor,
                    fabOnLeft: _fabOnLeft,
                    radii: guideRadii,
                  ),
                ),
              ),
              if (_loading)
                Positioned(
                  left: anchor.dx - 18,
                  top: anchor.dy - 18,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (!_loading && onPage > 0)
                ...slots.map((slot) {
                  final globalIndex =
                      _segmentPage * _itemsPerPage + slot.localIndex;
                  final pos = _slotPosition(slot, anchor);
                  final selected = globalIndex == _highlightIndex;
                  final bubbleSize =
                      _bubbleSize(rowCount: slot.rowCount);
                  return Positioned(
                    left: pos.dx - bubbleSize / 2,
                    top: pos.dy - bubbleSize / 2,
                    child: Transform.scale(
                      scale: selected ? 1.16 : 0.94,
                      child: _SectionBubble(
                        name: _currentPageItems[slot.localIndex].name,
                        selected: selected,
                        size: bubbleSize,
                      ),
                    ),
                  );
                }),
              if (!_loading && _pageCount > 1 && onPage > 0)
                Positioned(
                  left: _fabOnLeft ? anchor.dx + 8 : anchor.dx - 168,
                  top: anchor.dy - maxArcRadius - 48,
                  width: 160,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pageCount, (i) {
                          final active = i == _segmentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'storeLocationFabSwipeHint'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Positioned(
                left: anchor.dx - 28,
                top: anchor.dy - 28,
                child: IgnorePointer(
                  child: clearSelected
                      ? const _CenterClearBubble(selected: true)
                      : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.secondaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 28.sp,
                          ),
                        ),
                ),
              ),
            ],
            if (!_loading && _activeSections.isEmpty && anchor != null)
              Positioned(
                left: anchor.dx - 80,
                top: anchor.dy - 120,
                width: 160,
                child: Text(
                  'noStoreSectionsYet'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Obx(() {
              if (!widget.isAddMenuOpen.value) return const SizedBox.shrink();
              return Positioned.fill(
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              );
            }),
            Obx(() {
              if (!widget.isAddMenuOpen.value) return const SizedBox.shrink();
              return Positioned(
                bottom: 50.h,
                left: 50.w,
                right: 50.w,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  decoration: BoxDecoration(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.whiteColor2,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'add'.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: AppColors.primaryColor,
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      widget.customWidget ?? const SizedBox.shrink(),
                    ],
                  ),
                ),
              );
            }),
            Positioned(
              right: Get.locale!.languageCode == 'ar' ? 30.w : 0.w,
              child: Obx(() {
                final lensEnabled = _stock.currentTab.value == 0;
                return GestureDetector(
                  onLongPressStart: lensEnabled && _overlay == null
                      ? (_) => _openLens()
                      : null,
                  child: FloatingActionButton(
                    key: _fabKey,
                    onPressed: _overlay != null
                        ? null
                        : widget.onTap,
                    backgroundColor: AppColors.secondaryColor,
                    elevation: 2.0,
                    shape: const CircleBorder(),
                    child: Icon(
                      Icons.add,
                      color: AppColors.whiteColor,
                      size: 42.sp,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterSelectionBanner extends StatelessWidget {
  const _CenterSelectionBanner({
    required this.title,
    required this.subtitle,
    required this.index,
    required this.total,
    required this.pageCount,
    required this.currentPage,
  });

  final String title;
  final String subtitle;
  final int index;
  final int total;
  final int pageCount;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 32.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (total > 0) ...[
            SizedBox(height: 6.h),
            Text(
              '$index / $total',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (pageCount > 1) ...[
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pageCount, (i) {
                final active = i == currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.secondaryColor
                        : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionBubble extends StatelessWidget {
  const _SectionBubble({
    required this.name,
    required this.selected,
    required this.size,
  });

  final String name;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0] : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: selected ? AppColors.secondaryColor : Colors.white,
          width: selected ? 3 : 1.5,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.secondaryColor,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

class _CenterClearBubble extends StatelessWidget {
  const _CenterClearBubble({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: selected ? AppColors.secondaryColor : Colors.white70,
          width: selected ? 3 : 1.5,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 8),
        ],
      ),
      child: Icon(
        Icons.filter_alt_off_outlined,
        color: selected ? AppColors.secondaryColor : Colors.grey.shade600,
        size: 26,
      ),
    );
  }
}

class _ArcRowConfig {
  const _ArcRowConfig({required this.capacity, required this.radius});

  final int capacity;
  final double radius;
}

class _ArcSlot {
  const _ArcSlot({
    required this.localIndex,
    required this.row,
    required this.slotInRow,
    required this.rowCount,
  });

  final int localIndex;
  final int row;
  final int slotInRow;
  final int rowCount;
}

class _QuarterArcGuidePainter extends CustomPainter {
  const _QuarterArcGuidePainter({
    required this.center,
    required this.fabOnLeft,
    required this.radii,
  });

  final Offset center;
  final bool fabOnLeft;
  final List<double> radii;

  @override
  void paint(Canvas canvas, Size size) {
    if (radii.isEmpty) return;

    final startAngle = fabOnLeft ? -math.pi / 2 : -math.pi;
    const sweep = math.pi / 2;

    for (final radius in radii) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final fillPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.07)
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweep, true, fillPaint);

      final strokePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawArc(rect, startAngle, sweep, false, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _QuarterArcGuidePainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.fabOnLeft != fabOnLeft ||
        oldDelegate.radii != radii;
  }
}
