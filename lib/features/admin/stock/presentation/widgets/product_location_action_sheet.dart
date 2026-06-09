import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../data/models/store_section_model.dart';
import '../../domain/product_location_utils.dart';
import 'product_location_modal_shell.dart';
import 'section_shelf_picker_field.dart';

enum ProductLocationAction { move, swap }

Future<ProductLocationAction?> showProductLocationActionSheet(
  BuildContext context,
) async {
  return showModalBottomSheet<ProductLocationAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          border: Border.all(color: AppColors.operationalCardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.customGreyColor6,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: Text(
                'locationActionSheetTitle'.tr,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.operationalNavy,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.drive_file_move_outline,
                color: AppColors.operationalNavy,
              ),
              title: Text(
                'moveProductLocation'.tr,
                style: TextStyle(
                  color: AppColors.operationalNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'selectTargetSection'.tr,
                style: TextStyle(fontSize: 11.sp, color: AppColors.customGreyColor5),
              ),
              onTap: () => Navigator.pop(ctx, ProductLocationAction.move),
            ),
            ListTile(
              leading: Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.customOrange3,
              ),
              title: Text(
                'swapProductLocation'.tr,
                style: TextStyle(
                  color: AppColors.operationalNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'swapGroupsHint'.tr,
                style: TextStyle(fontSize: 11.sp, color: AppColors.customGreyColor5),
              ),
              onTap: () => Navigator.pop(ctx, ProductLocationAction.swap),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    ),
  );
}

class ProductLocationMoveTarget {
  const ProductLocationMoveTarget({
    required this.sectionId,
    this.shelfNumber,
  });

  final String sectionId;
  final String? shelfNumber;
}

Widget _sectionShelfPicker({
  required String? selectedSectionId,
  required ValueChanged<String?> onSectionChanged,
  required TextEditingController shelfCtrl,
  required List<StoreSectionModel> sections,
  ValueChanged<String?>? onShelfChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<String>(
        value: selectedSectionId,
        decoration: InputDecoration(
          labelText: 'selectTargetSection'.tr,
          labelStyle: TextStyle(color: AppColors.customGreyColor5, fontSize: 12.sp),
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.operationalCardBorder),
          ),
        ),
        style: TextStyle(color: AppColors.operationalNavy, fontSize: 13.sp),
        dropdownColor: AppColors.whiteColor,
        items: sections
            .map(
              (s) => DropdownMenuItem<String>(
                value: s.id,
                child: Text(s.name, style: TextStyle(color: AppColors.operationalNavy)),
              ),
            )
            .toList(),
        onChanged: onSectionChanged,
      ),
      SizedBox(height: 10.h),
      SectionShelfPickerField(
        sectionId: selectedSectionId,
        controller: shelfCtrl,
        onChanged: onShelfChanged,
        required: true,
      ),
    ],
  );
}

Future<ProductLocationMoveTarget?> showProductLocationMoveDialog({
  required BuildContext context,
  required List<StoreSectionModel> sections,
}) {
  return showDialog<ProductLocationMoveTarget>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ProductLocationMoveDialog(
      sections: sections,
    ),
  );
}

Future<SwapGroupTargets?> showSwapGroupTargetsDialog({
  required BuildContext context,
  required List<StoreSectionModel> sections,
}) async {
  return showDialog<SwapGroupTargets>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _SwapGroupTargetsDialog(
      sections: sections,
    ),
  );
}

class _ProductLocationMoveDialog extends StatefulWidget {
  const _ProductLocationMoveDialog({
    required this.sections,
  });

  final List<StoreSectionModel> sections;

  @override
  State<_ProductLocationMoveDialog> createState() =>
      _ProductLocationMoveDialogState();
}

class _ProductLocationMoveDialogState extends State<_ProductLocationMoveDialog> {
  String? _selectedSectionId;
  final _shelfCtrl = TextEditingController();

  @override
  void dispose() {
    _shelfCtrl.dispose();
    super.dispose();
  }

  void _onSectionChanged(String? id) {
    setState(() {
      _selectedSectionId = id;
      _shelfCtrl.clear();
    });
  }

  void _onShelfChanged(String? _) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final shelf = _shelfCtrl.text.trim();
    final canSubmit = _selectedSectionId != null &&
        _selectedSectionId!.isNotEmpty &&
        shelf.isNotEmpty;

    return ProductLocationModalShell(
      title: 'moveProductsTitle'.tr,
      confirmLabel: 'continue'.tr,
      confirmEnabled: canSubmit,
      onCancel: () => Navigator.pop(context),
      onConfirm: () {
        Navigator.pop(
          context,
          ProductLocationMoveTarget(
            sectionId: _selectedSectionId!,
            shelfNumber: shelf,
          ),
        );
      },
      body: ListView(
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
        children: [
          _sectionShelfPicker(
            selectedSectionId: _selectedSectionId,
            onSectionChanged: _onSectionChanged,
            shelfCtrl: _shelfCtrl,
            sections: widget.sections,
            onShelfChanged: _onShelfChanged,
          ),
        ],
      ),
    );
  }
}

class _SwapGroupTargetsDialog extends StatefulWidget {
  const _SwapGroupTargetsDialog({
    required this.sections,
  });

  final List<StoreSectionModel> sections;

  @override
  State<_SwapGroupTargetsDialog> createState() => _SwapGroupTargetsDialogState();
}

class _SwapGroupTargetsDialogState extends State<_SwapGroupTargetsDialog> {
  String? _sectionIdA;
  String? _sectionIdB;
  final _shelfCtrlA = TextEditingController();
  final _shelfCtrlB = TextEditingController();

  @override
  void dispose() {
    _shelfCtrlA.dispose();
    _shelfCtrlB.dispose();
    super.dispose();
  }

  void _onShelfChanged(String? _) {
    if (mounted) setState(() {});
  }

  String _nameFor(String? id) {
    if (id == null) return '';
    for (final s in widget.sections) {
      if (s.id == id) return s.name;
    }
    return id;
  }

  void _onSectionAChanged(String? id) {
    setState(() {
      _sectionIdA = id;
      _shelfCtrlA.clear();
    });
  }

  void _onSectionBChanged(String? id) {
    setState(() {
      _sectionIdB = id;
      _shelfCtrlB.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shelfA = _shelfCtrlA.text.trim();
    final shelfB = _shelfCtrlB.text.trim();
    final canSubmit = _sectionIdA != null &&
        _sectionIdA!.isNotEmpty &&
        shelfA.isNotEmpty &&
        _sectionIdB != null &&
        _sectionIdB!.isNotEmpty &&
        shelfB.isNotEmpty;

    return ProductLocationModalShell(
      title: 'swapAssignTargetsTitle'.tr,
      confirmLabel: 'continue'.tr,
      confirmEnabled: canSubmit,
      onCancel: () => Navigator.pop(context),
      onConfirm: () {
        Navigator.pop(
          context,
          SwapGroupTargets(
            groupA: SwapGroupLocationTarget(
              sectionId: _sectionIdA!,
              sectionName: _nameFor(_sectionIdA),
              shelfNumber: shelfA,
            ),
            groupB: SwapGroupLocationTarget(
              sectionId: _sectionIdB!,
              sectionName: _nameFor(_sectionIdB),
              shelfNumber: shelfB,
            ),
          ),
        );
      },
      body: ListView(
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
        children: [
          Text(
            'swapAssignTargetsHint'.tr,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.customGreyColor5,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'swapGroupADestination'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.operationalNavy,
            ),
          ),
          SizedBox(height: 8.h),
          _sectionShelfPicker(
            selectedSectionId: _sectionIdA,
            onSectionChanged: _onSectionAChanged,
            shelfCtrl: _shelfCtrlA,
            sections: widget.sections,
            onShelfChanged: _onShelfChanged,
          ),
          SizedBox(height: 16.h),
          Text(
            'swapGroupBDestination'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.operationalNavy,
            ),
          ),
          SizedBox(height: 8.h),
          _sectionShelfPicker(
            selectedSectionId: _sectionIdB,
            onSectionChanged: _onSectionBChanged,
            shelfCtrl: _shelfCtrlB,
            sections: widget.sections,
            onShelfChanged: _onShelfChanged,
          ),
        ],
      ),
    );
  }
}
