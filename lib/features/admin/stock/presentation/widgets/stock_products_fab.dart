import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/haptic_helper.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/store_section_model.dart';
import '../../domain/product_location_utils.dart';
import '../controllers/stock_controller.dart';

/// Products FAB: tap = add menu; long-press = full-screen location filter.
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
  final Set<String> _selectedIds = <String>{};

  List<StoreSectionModel> get _activeSections =>
      _stock.storeSections.where((s) => s.isActive).toList(growable: false);

  List<_LocationFilterOption> get _locationFilterOptions {
    final sections = _activeSections;
    return [
      _LocationFilterOption(
        id: kUnassignedStoreSectionFilterId,
        label: 'noLocationAssigned'.tr,
      ),
      ...sections.map(
        (s) => _LocationFilterOption(id: s.id, label: s.name),
      ),
    ];
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
    _selectedIds
      ..clear()
      ..addAll(
          _splitLocationIds(_stock.productListFilters.value.storeSectionId));
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
    if (_selectedIds.isEmpty) {
      _stock.clearStoreLocationFilterFromFab();
    } else {
      _stock.applyStoreLocationFilterFromFab(sectionId: _selectedIds.join(','));
    }
  }

  void _setHighlight(int index, {bool vibrate = true}) {
    if (index == _highlightIndex) return;
    if (vibrate) HapticHelper.confirm();
    _highlightIndex = index;
    _overlay?.markNeedsBuild();
  }

  String? _centerBannerLabel() {
    if (_highlightIndex < 0) return null;
    final options = _locationFilterOptions;
    if (options.isEmpty) return null;
    return options[_highlightIndex.clamp(0, options.length - 1)].label;
  }

  List<String> _splitLocationIds(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return const [];
    return value
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  void _toggleGridItem(int index) {
    _setHighlight(index);
    final options = _locationFilterOptions;
    if (options.isEmpty) return;
    final id = options[index.clamp(0, options.length - 1)].id;
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    _overlay?.markNeedsBuild();
  }

  Widget _buildOverlay(BuildContext context) {
    _syncAnchor(context);
    final anchor = _anchorCenter;
    final options = _locationFilterOptions;
    final bannerLabel = _centerBannerLabel();
    final totalCount = options.length;
    final clearSelected = _selectedIds.isEmpty;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _removeOverlay(applySelection: true),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.45)),
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
                    ),
                  ),
                ),
              ),
            if (anchor != null) ...[
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
              Positioned(
                left: anchor.dx - 28,
                top: anchor.dy - 28,
                child: IgnorePointer(
                  child: clearSelected
                      ? Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: AppColors.secondaryColor,
                              width: 3,
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
                            color: AppColors.secondaryColor,
                            size: 26.sp,
                          ),
                        )
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
            if (!_loading)
              SafeArea(
                child: Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: _LocationGridPanel(
                      options: options,
                      highlightedIndex: _highlightIndex,
                      selectedIds: _selectedIds,
                      clearSelected: clearSelected,
                      onClear: () {
                        _highlightIndex = -1;
                        _selectedIds.clear();
                        _overlay?.markNeedsBuild();
                      },
                      onSelect: _toggleGridItem,
                      onApply: () => _removeOverlay(applySelection: true),
                    ),
                  ),
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
                    onPressed: _overlay != null ? null : widget.onTap,
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

class _LocationFilterOption {
  const _LocationFilterOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class _CenterSelectionBanner extends StatelessWidget {
  const _CenterSelectionBanner({
    required this.title,
    required this.subtitle,
    required this.index,
    required this.total,
  });

  final String title;
  final String subtitle;
  final int index;
  final int total;

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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 4,
              softWrap: true,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
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
        ],
      ),
    );
  }
}

class _LocationGridPanel extends StatelessWidget {
  const _LocationGridPanel({
    required this.options,
    required this.highlightedIndex,
    required this.selectedIds,
    required this.clearSelected,
    required this.onClear,
    required this.onSelect,
    required this.onApply,
  });

  final List<_LocationFilterOption> options;
  final int highlightedIndex;
  final Set<String> selectedIds;
  final bool clearSelected;
  final VoidCallback onClear;
  final ValueChanged<int> onSelect;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 720
        ? 4
        : width >= 430
            ? 3
            : 2;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      constraints: BoxConstraints(
        maxWidth: 720,
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GridClearTile(
            selected: clearSelected,
            onTap: onClear,
          ),
          SizedBox(height: 10.h),
          if (options.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 28.h),
              child: Text(
                'noStoreSectionsYet'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.secondaryColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 8.h,
                  crossAxisSpacing: 8.w,
                  childAspectRatio: columns == 2 ? 2.55 : 2.35,
                ),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return _SectionBubble(
                    name: option.label,
                    selected: selectedIds.contains(option.id),
                    highlighted: highlightedIndex == index,
                    onTap: () => onSelect(index),
                  );
                },
              ),
            ),
          SizedBox(height: 10.h),
          SizedBox(
            height: 42.h,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onPressed: onApply,
              child: Text(
                'apply'.tr,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBubble extends StatelessWidget {
  const _SectionBubble({
    required this.name,
    required this.selected,
    required this.highlighted,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = name.trim().isNotEmpty ? name.trim() : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            color: selected
                ? AppColors.secondaryColor.withValues(alpha: 0.12)
                : Colors.grey.shade100,
            border: Border.all(
              color: selected || highlighted
                  ? AppColors.secondaryColor
                  : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  Icon(
                    Icons.check_circle,
                    color: AppColors.secondaryColor,
                    size: 16.sp,
                  ),
                  SizedBox(width: 5.w),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      softWrap: true,
                      style: TextStyle(
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.sp,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridClearTile extends StatelessWidget {
  const _GridClearTile({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: Ink(
          height: 44.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            color: selected
                ? AppColors.secondaryColor.withValues(alpha: 0.12)
                : Colors.grey.shade100,
            border: Border.all(
              color: selected ? AppColors.secondaryColor : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_alt_off_outlined,
                color: AppColors.secondaryColor,
                size: 21.sp,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  'all'.tr,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
