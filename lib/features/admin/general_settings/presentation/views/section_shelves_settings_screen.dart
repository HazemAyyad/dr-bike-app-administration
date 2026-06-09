import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/outline_input_style.dart';
import '../../../stock/data/datasources/stock_datasource.dart';
import '../../../stock/data/models/store_section_model.dart';
import '../../../stock/data/models/store_section_shelf_model.dart';
import '../../../stock/presentation/controllers/stock_controller.dart';

class SectionShelvesSettingsScreen extends StatefulWidget {
  const SectionShelvesSettingsScreen({
    Key? key,
    required this.section,
  }) : super(key: key);

  final StoreSectionModel section;

  @override
  State<SectionShelvesSettingsScreen> createState() =>
      _SectionShelvesSettingsScreenState();
}

class _SectionShelvesSettingsScreenState
    extends State<SectionShelvesSettingsScreen> {
  final List<StoreSectionShelfModel> _shelves = [];
  bool _loading = true;

  StockDatasource get _ds => Get.find<StockDatasource>();

  Future<void> _notifyStockRefresh() async {
    if (Get.isRegistered<StockController>()) {
      await Get.find<StockController>().refreshAfterStoreSectionsChanged();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list =
          await _ds.getSectionShelvesDetailed(sectionId: widget.section.id);
      _shelves
        ..clear()
        ..addAll(list);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showShelfDialog({StoreSectionShelfModel? shelf}) async {
    final isEdit = shelf != null;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _ShelfFormDialog(
        title: isEdit ? 'editShelf'.tr : 'newShelf'.tr,
        initialNumber: shelf?.shelfNumber ?? '',
      ),
    );
    if (!mounted || result == null) return;

    final number = result.trim();
    if (number.isEmpty) {
      Get.snackbar('error'.tr, 'shelfNumberRequired'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      if (isEdit) {
        await _ds.updateSectionShelf(
          shelfId: shelf!.id,
          shelfNumber: number,
        );
      } else {
        await _ds.createSectionShelf(
          sectionId: widget.section.id,
          shelfNumber: number,
        );
      }
      await _load();
      await _notifyStockRefresh();
      Get.snackbar('success'.tr, 'settingsUpdated'.tr,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _confirmDelete(StoreSectionShelfModel shelf) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminUiColors.cardBackground(ctx),
        title: Text('deleteShelf'.tr),
        content: Text(
          shelf.productCount > 0
              ? 'deleteShelfWithProductsConfirm'.trParams({
                  'count': shelf.productCount.toString(),
                })
              : 'deleteShelfConfirm'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await _ds.deleteSectionShelf(shelfId: shelf.id);
      await _load();
      await _notifyStockRefresh();
      Get.snackbar('success'.tr, 'OK', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminUiColors.scaffoldBackground(context),
      appBar: CustomAppBar(
        title: widget.section.name,
        action: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showShelfDialog(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            child: Text(
              'sectionShelvesSubtitle'.tr,
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _shelves.isEmpty
                    ? Center(
                        child: Text(
                          'noShelvesYet'.tr,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 88.h),
                        itemCount: _shelves.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (context, index) {
                          final shelf = _shelves[index];
                          return Material(
                            color: AdminUiColors.cardBackground(context),
                            borderRadius: BorderRadius.circular(12.r),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              leading: Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0369A1)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  Icons.view_week_outlined,
                                  color: const Color(0xFF0369A1),
                                  size: 20.sp,
                                ),
                              ),
                              title: Text(
                                shelf.shelfNumber,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.sp,
                                ),
                              ),
                              subtitle: shelf.productCount > 0
                                  ? Text(
                                      'shelfProductCount'.trParams({
                                        'count':
                                            shelf.productCount.toString(),
                                      }),
                                    )
                                  : Text('shelfEmpty'.tr),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'edit'.tr,
                                    onPressed: () =>
                                        _showShelfDialog(shelf: shelf),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'delete'.tr,
                                    onPressed: () => _confirmDelete(shelf),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ShelfFormDialog extends StatefulWidget {
  const _ShelfFormDialog({
    required this.title,
    required this.initialNumber,
  });

  final String title;
  final String initialNumber;

  @override
  State<_ShelfFormDialog> createState() => _ShelfFormDialogState();
}

class _ShelfFormDialogState extends State<_ShelfFormDialog> {
  late final TextEditingController _numberCtrl;

  @override
  void initState() {
    super.initState();
    _numberCtrl = TextEditingController(text: widget.initialNumber);
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final dialogBg = Theme.of(context).brightness == Brightness.dark
        ? AdminUiColors.cardBackground(context)
        : Colors.grey.shade100;
    final actionBg = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade300;

    return AlertDialog(
      backgroundColor: dialogBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide.none,
      ),
      title: Text(
        widget.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
      ),
      content: TextField(
        controller: _numberCtrl,
        autofocus: true,
        style: TextStyle(color: onSurface),
        decoration: OutlineInputStyle.merge(
          context,
          labelText: 'shelfNumberRequired'.tr,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(foregroundColor: onSurface),
          child: Text('cancel'.tr),
        ),
        FilledButton(
          onPressed: () => Get.back(result: _numberCtrl.text),
          style: FilledButton.styleFrom(
            backgroundColor: actionBg,
            foregroundColor: onSurface,
            elevation: 0,
          ),
          child: Text('save'.tr),
        ),
      ],
    );
  }
}
