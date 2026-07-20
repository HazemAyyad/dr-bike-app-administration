import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/haptic_helper.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../stock/data/models/store_section_model.dart';
import '../../../stock/domain/product_location_utils.dart';
import '../controllers/sales_controller.dart';

/// Shared sales picker location filter: tap/long-press opens a multi-select grid.
class SalesLocationFilterFab extends StatefulWidget {
  const SalesLocationFilterFab({Key? key}) : super(key: key);

  @override
  State<SalesLocationFilterFab> createState() => _SalesLocationFilterFabState();
}

class _SalesLocationFilterFabState extends State<SalesLocationFilterFab> {
  final SalesController _sales = Get.find<SalesController>();
  final GlobalKey _fabKey = GlobalKey();

  OverlayEntry? _overlay;
  bool _loading = false;
  int _highlightIndex = -1;
  final Set<String> _selectedIds = <String>{};

  List<StoreSectionModel> get _sections => [
        StoreSectionModel(
          id: kUnassignedStoreSectionFilterId,
          name: 'noLocationAssigned'.tr,
        ),
        ..._sales.pickerStoreSections.where((s) => s.isActive),
      ];

  @override
  void dispose() {
    _removeOverlay(applySelection: false);
    super.dispose();
  }

  Future<void> _openGrid() async {
    if (_overlay != null) return;
    HapticHelper.selection();
    _highlightIndex = -1;
    _selectedIds
      ..clear()
      ..addAll(_splitLocationIds(_sales.pickerLocationSectionId.value));
    _overlay = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context, rootOverlay: true).insert(_overlay!);
    await _loadSections();
    _overlay?.markNeedsBuild();
  }

  Future<void> _loadSections() async {
    setState(() => _loading = true);
    _overlay?.markNeedsBuild();
    try {
      await _sales.ensurePickerStoreSectionsLoaded(force: true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _overlay?.markNeedsBuild();
      }
    }
  }

  void _removeOverlay({required bool applySelection}) {
    if (_overlay == null) return;
    _overlay?.remove();
    _overlay = null;
    if (applySelection) {
      if (_selectedIds.isEmpty) {
        _sales.clearPickerLocationFilter();
      } else {
        _sales.applyPickerLocationFilter(sectionId: _selectedIds.join(','));
      }
    }
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

  void _toggleSection(int index) {
    final sections = _sections;
    if (sections.isEmpty) return;
    HapticHelper.confirm();
    _highlightIndex = index;
    final id = sections[index.clamp(0, sections.length - 1)].id;
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    _overlay?.markNeedsBuild();
  }

  Widget _buildOverlay(BuildContext context) {
    final sections = _sections;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _removeOverlay(applySelection: false),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.45)),
            ),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            else
              SafeArea(
                child: Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: _LocationGridPanel(
                      sections: sections,
                      selectedIds: _selectedIds,
                      highlightedIndex: _highlightIndex,
                      onClear: () {
                        _selectedIds.clear();
                        _highlightIndex = -1;
                        _overlay?.markNeedsBuild();
                      },
                      onSelect: _toggleSection,
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
    return Obx(() {
      final hasFilter = _sales.pickerLocationSectionId.value != null &&
          _sales.pickerLocationSectionId.value!.isNotEmpty;
      return GestureDetector(
        onLongPressStart: _overlay == null ? (_) => _openGrid() : null,
        child: FloatingActionButton(
          key: _fabKey,
          heroTag: 'sales_location_filter_fab',
          onPressed: _overlay != null ? null : _openGrid,
          backgroundColor:
              hasFilter ? AppColors.primaryColor : AppColors.secondaryColor,
          elevation: 4.0,
          shape: const CircleBorder(),
          child: Icon(
            hasFilter ? Icons.filter_alt : Icons.filter_alt_outlined,
            color: AppColors.whiteColor,
            size: 26.sp,
          ),
        ),
      );
    });
  }
}

class _LocationGridPanel extends StatelessWidget {
  const _LocationGridPanel({
    required this.sections,
    required this.selectedIds,
    required this.highlightedIndex,
    required this.onClear,
    required this.onSelect,
    required this.onApply,
  });

  final List<StoreSectionModel> sections;
  final Set<String> selectedIds;
  final int highlightedIndex;
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
            selected: selectedIds.isEmpty,
            onTap: onClear,
          ),
          SizedBox(height: 10.h),
          if (sections.isEmpty)
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
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return _SectionTile(
                    name: section.name,
                    selected: selectedIds.contains(section.id),
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

class _SectionTile extends StatelessWidget {
  const _SectionTile({
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
