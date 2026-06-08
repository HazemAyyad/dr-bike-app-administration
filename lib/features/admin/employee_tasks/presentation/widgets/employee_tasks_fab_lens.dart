import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/haptic_helper.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/helpers/task_nav_debug.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../employee_section/data/repositorie_imp/employee_implement.dart';
import '../../../employee_section/domain/entities/employee_entity.dart';
import '../../../employee_section/domain/usecases/get_all_employee.dart';
import '../../../employee_section/presentation/controllers/employee_service.dart';
import '../controllers/employee_tasks_controller.dart';

/// Long-press FAB: employees on stacked quarter-arc rows; swipe for more pages.
class EmployeeTasksCreateFab extends StatefulWidget {
  const EmployeeTasksCreateFab({Key? key}) : super(key: key);

  @override
  State<EmployeeTasksCreateFab> createState() => _EmployeeTasksCreateFabState();
}

class _EmployeeTasksCreateFabState extends State<EmployeeTasksCreateFab> {
  final EmployeeTasksController _tasks = Get.find<EmployeeTasksController>();
  final EmployeeService _employeeService = EmployeeService();
  final GlobalKey _fabKey = GlobalKey();

  OverlayEntry? _overlay;
  bool _loadingEmployees = false;

  /// -1 = clear filter (center), 0..n-1 = employee index.
  int _highlightIndex = -1;
  Offset? _anchorCenter;
  bool _fabOnLeft = false;
  int _segmentPage = 0;
  double _pageDragAccum = 0;

  static const double _centerHit = 34;
  static const double _minPickRadius = 44;
  static const double _pageSwipeThreshold = 52;
  static const double _arcSweep = math.pi / 2;

  /// Each arc gets a capacity based on its length (radius × 90°).
  static final List<_ArcRowConfig> _arcRows = _buildArcRows();

  static List<_ArcRowConfig> _buildArcRows() {
    const baseRadius = 72.0;
    const radiusStep = 46.0;
    const arcCount = 6;
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

  int get _employeesPerPage =>
      _arcRows.fold(0, (sum, row) => sum + row.capacity);

  List<EmployeeEntity> get _employees => _employeeService.employeeList;

  int get _pageCount {
    if (_employees.isEmpty) return 1;
    return ((_employees.length + _employeesPerPage - 1) ~/ _employeesPerPage);
  }

  List<EmployeeEntity> get _currentPageEmployees {
    if (_employees.isEmpty) return const [];
    final start = _segmentPage * _employeesPerPage;
    final end = math.min(start + _employeesPerPage, _employees.length);
    return _employees.sublist(start, end);
  }

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
    final screenW = MediaQuery.sizeOf(overlayContext).width;
    _fabOnLeft = center.dx < screenW * 0.5;
  }

  GetAllEmployeeUsecase _employeeUsecase() {
    if (Get.isRegistered<GetAllEmployeeUsecase>()) {
      return Get.find<GetAllEmployeeUsecase>();
    }
    return GetAllEmployeeUsecase(
      employeeRepository: Get.find<EmployeeImplement>(),
    );
  }

  Future<void> _loadEmployees({bool force = false}) async {
    if (!force && _employees.isNotEmpty) return;
    setState(() => _loadingEmployees = true);
    _overlay?.markNeedsBuild();
    try {
      final list = await _employeeUsecase().call();
      _employeeService.employeeList.assignAll(list);
    } catch (_) {
      // keep empty; overlay shows noData
    } finally {
      if (mounted) {
        setState(() => _loadingEmployees = false);
        _overlay?.markNeedsBuild();
      }
    }
  }

  Future<void> _openLens() async {
    HapticHelper.selection();
    _highlightIndex = -1;
    _segmentPage = 0;
    _pageDragAccum = 0;
    _anchorCenter = _readFabCenter();
    _overlay = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlay!);
    await _loadEmployees(force: _employees.isEmpty);
    _overlay?.markNeedsBuild();
  }

  void _removeOverlay({required bool applySelection}) {
    if (_overlay == null) return;
    _overlay?.remove();
    _overlay = null;
    if (applySelection) {
      _commitSelection(_highlightIndex);
    }
    _anchorCenter = null;
  }

  void _commitSelection(int index) {
    if (index < 0) {
      _tasks.employeeNameController.clear();
    } else if (_employees.isNotEmpty) {
      final i = index.clamp(0, _employees.length - 1);
      _tasks.employeeNameController.text = _employees[i].employeeName;
    }
    _scheduleListRefresh();
  }

  void _scheduleListRefresh() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tasks.applyAllFilters();
      _tasks.update(['tasksList', 'periodBar']);
    });
  }

  void _setHighlight(int index, {bool vibrate = true}) {
    if (index == _highlightIndex) return;
    if (vibrate) HapticHelper.confirm();
    _highlightIndex = index;
    if (index >= 0 && _employees.isNotEmpty) {
      final i = index.clamp(0, _employees.length - 1);
      _tasks.employeeNameController.text = _employees[i].employeeName;
      _scheduleListRefresh();
    } else if (index < 0) {
      _tasks.employeeNameController.clear();
      _scheduleListRefresh();
    }
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
    final start = _arcStartAngle();
    return start + t * _arcSweep;
  }

  int _localIndexFromAngle(double angle, int total) {
    final start = _arcStartAngle();
    final t = ((angle - start) / _arcSweep).clamp(0.0, 0.999999);
    return (t * total).floor().clamp(0, total - 1);
  }

  double _bubbleAvatarSize({required int rowCount}) {
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

    final pageEmployees = _currentPageEmployees;
    if (pageEmployees.isEmpty) return -1;

    final angle = math.atan2(delta.dy, delta.dx);
    if (!_angleInArc(angle)) return _highlightIndex;

    final row = _rowFromDistance(delta.distance, pageEmployees.length);
    if (row == null) return _highlightIndex;

    final rowSlots = _layoutSlots(pageEmployees.length)
        .where((s) => s.row == row)
        .toList()
      ..sort((a, b) => a.slotInRow.compareTo(b.slotInRow));
    if (rowSlots.isEmpty) return _highlightIndex;

    final slotInRow = _localIndexFromAngle(angle, rowSlots.length);
    return _segmentPage * _employeesPerPage +
        rowSlots[slotInRow.clamp(0, rowSlots.length - 1)].localIndex;
  }

  Offset _slotPosition(_ArcSlot slot, Offset center) {
    final angle = _angleForSlot(slot.slotInRow, slot.rowCount);
    final radius = _radiusForRow(slot.row);
    return center +
        Offset(math.cos(angle) * radius, math.sin(angle) * radius);
  }

  String? _highlightedEmployeeName() {
    if (_highlightIndex < 0 || _employees.isEmpty) return null;
    final i = _highlightIndex.clamp(0, _employees.length - 1);
    return _employees[i].employeeName;
  }

  void _onCreateTask() {
    TaskNavDebug.log(
      'EmployeeTasksScreen.FAB',
      AppRoutes.CREATETASKSCREEN,
      screen: 'CreateTaskEntryScreen -> CreateEmployeeTaskScreen',
      extra: {'title': 'createNewEmployeeTask', 'isEdit': false},
    );
    Get.toNamed(
      AppRoutes.CREATETASKSCREEN,
      arguments: {'title': 'createNewEmployeeTask', 'isEdit': false},
    );
  }

  Widget _buildOverlay(BuildContext context) {
    _syncAnchor(context);
    final anchor = _anchorCenter;
    final employees = _employees;
    final pageEmployees = _currentPageEmployees;
    final clearSelected = _highlightIndex < 0;
    final totalEmployees = employees.length;
    final pageCount = _pageCount;
    final onPage = pageEmployees.length;
    final slots = _layoutSlots(onPage);
    final guideRadii = _activeRows(onPage).map(_radiusForRow).toList();
    final maxArcRadius =
        guideRadii.isEmpty ? 180.0 : guideRadii.reduce(math.max);
    final highlightedName = _highlightedEmployeeName();

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
        onPointerUp: (_) => _removeOverlay(applySelection: true),
        onPointerCancel: (_) => _removeOverlay(applySelection: true),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _removeOverlay(applySelection: true),
                child: Container(color: Colors.black.withValues(alpha: 0.45)),
              ),
            ),
            if (!_loadingEmployees && highlightedName != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: _CenterSelectionBanner(
                      name: highlightedName,
                      index: _highlightIndex + 1,
                      total: totalEmployees,
                      pageCount: pageCount,
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
              if (_loadingEmployees)
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
              if (!_loadingEmployees && onPage > 0)
                ...slots.map((slot) {
                  final globalIndex =
                      _segmentPage * _employeesPerPage + slot.localIndex;
                  final pos = _slotPosition(slot, anchor);
                  final emp = pageEmployees[slot.localIndex];
                  final selected = globalIndex == _highlightIndex;
                  final avatarSize =
                      _bubbleAvatarSize(rowCount: slot.rowCount);
                  return Positioned(
                    left: pos.dx - avatarSize / 2,
                    top: pos.dy - avatarSize / 2,
                    child: Transform.scale(
                      scale: selected ? 1.16 : 0.94,
                      child: _EmployeeBubble(
                        imageUrl: emp.employeeImg,
                        selected: selected,
                        avatarSize: avatarSize,
                      ),
                    ),
                  );
                }),
              if (!_loadingEmployees &&
                  _highlightIndex < 0 &&
                  pageCount > 1 &&
                  onPage > 0)
                Positioned(
                  left: _fabOnLeft ? anchor.dx + 8 : anchor.dx - 168,
                  top: anchor.dy - maxArcRadius - 48,
                  width: 160,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(pageCount, (i) {
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
                        'اسحب يمين/يسار للمزيد',
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
            if (!_loadingEmployees && employees.isEmpty && anchor != null)
              Positioned(
                left: anchor.dx - 80,
                top: anchor.dy - 120,
                width: 160,
                child: Text(
                  'noData'.tr,
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
    return GestureDetector(
      onLongPressStart: (_) {
        if (_overlay == null) _openLens();
      },
      child: FloatingActionButton(
        key: _fabKey,
        onPressed: _overlay != null ? null : _onCreateTask,
        backgroundColor: AppColors.secondaryColor,
        child: Icon(Icons.add, color: Colors.white, size: 28.sp),
      ),
    );
  }
}

class _CenterSelectionBanner extends StatelessWidget {
  const _CenterSelectionBanner({
    required this.name,
    required this.index,
    required this.total,
    required this.pageCount,
    required this.currentPage,
  });

  final String name;
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '$index / $total',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 8,
          ),
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

class _EmployeeBubble extends StatelessWidget {
  const _EmployeeBubble({
    required this.imageUrl,
    required this.selected,
    required this.avatarSize,
  });

  final String imageUrl;
  final bool selected;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final url = ShowNetImage.getThumbnailPhoto(imageUrl);
    final compact = avatarSize <= 40;

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.secondaryColor : Colors.white,
          width: selected ? 3 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
            : ColoredBox(
                color: AppColors.operationalNavy.withValues(alpha: 0.15),
                child: Icon(
                  Icons.person,
                  size: compact ? 20 : 24,
                  color: AppColors.operationalNavy,
                ),
              ),
      ),
    );
  }
}
