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

/// Long-press FAB: employees radiate from the button; drag angle to pick any employee.
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

  static const double _innerRadius = 78;
  static const double _outerRadius = 128;
  static const double _centerHit = 34;
  static const double _minPickRadius = 50;

  List<EmployeeEntity> get _employees => _employeeService.employeeList;

  @override
  void dispose() {
    _removeOverlay(applySelection: false);
    super.dispose();
  }

  Offset? _readFabCenter() {
    final box = _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
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

  /// Pick employee by finger angle around FAB (works for 12+ without tiny hit targets).
  int _indexFromPointer(Offset global) {
    final center = _anchorCenter ?? _readFabCenter();
    if (center == null) return -1;

    final delta = global - center;
    if (delta.distance <= _centerHit) return -1;
    if (delta.distance < _minPickRadius) return _highlightIndex;

    final employees = _employees;
    if (employees.isEmpty) return -1;

    var angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    final n = employees.length;
    var index = (angle / (2 * math.pi) * n).floor();
    if (index >= n) index = n - 1;
    if (index < 0) index = 0;
    return index;
  }

  Offset _bubblePosition(int index, int total, Offset center) {
    if (total <= 8) {
      final angle = -math.pi / 2 + (2 * math.pi * index / total);
      return center +
          Offset(math.cos(angle) * _innerRadius, math.sin(angle) * _innerRadius);
    }
    final innerCount = (total / 2).ceil();
    if (index < innerCount) {
      final angle = -math.pi / 2 + (2 * math.pi * index / innerCount);
      return center +
          Offset(math.cos(angle) * _innerRadius, math.sin(angle) * _innerRadius);
    }
    final outerIndex = index - innerCount;
    final outerCount = total - innerCount;
    final angle = -math.pi / 2 + (2 * math.pi * outerIndex / outerCount);
    return center +
        Offset(math.cos(angle) * _outerRadius, math.sin(angle) * _outerRadius);
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
    final anchor = _anchorCenter ?? _readFabCenter();
    final employees = _employees;
    final clearSelected = _highlightIndex < 0;
    final n = employees.length;

    return Material(
      color: Colors.transparent,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerMove: (e) {
          _anchorCenter ??= _readFabCenter();
          _setHighlight(_indexFromPointer(e.position));
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
            if (anchor != null) ...[
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
              if (!_loadingEmployees && n > 0)
                ...List.generate(n, (i) {
                  final pos = _bubblePosition(i, n, anchor);
                  final emp = employees[i];
                  final selected = i == _highlightIndex;
                  return Positioned(
                    left: pos.dx - 24,
                    top: pos.dy - 24,
                    child: AnimatedScale(
                      scale: selected ? 1.22 : 0.92,
                      duration: const Duration(milliseconds: 90),
                      child: _EmployeeBubble(
                        name: emp.employeeName,
                        imageUrl: emp.employeeImg,
                        selected: selected,
                        compact: n > 8,
                      ),
                    ),
                  );
                }),
              if (!_loadingEmployees && _highlightIndex >= 0 && n > 0)
                Positioned(
                  left: anchor.dx - 70,
                  top: anchor.dy - 150,
                  width: 140,
                  child: Text(
                    '${_highlightIndex + 1}/$n',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 6),
                      ],
                    ),
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

class _CenterClearBubble extends StatelessWidget {
  const _CenterClearBubble({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
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
    required this.name,
    required this.imageUrl,
    required this.selected,
    this.compact = false,
  });

  final String name;
  final String imageUrl;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final url = ShowNetImage.getThumbnailPhoto(imageUrl);
    final size = compact ? 44.0 : 52.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
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
        ),
        if (selected) ...[
          const SizedBox(height: 3),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 64 : 76),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 9.sp : 10.sp,
                fontWeight: FontWeight.w700,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
