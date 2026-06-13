import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/outline_input_style.dart';
import '../../../stock/data/datasources/stock_datasource.dart';
import '../../../stock/data/models/store_section_model.dart';
import '../../../stock/presentation/controllers/stock_controller.dart';

class StoreSectionsSettingsScreen extends StatefulWidget {
  const StoreSectionsSettingsScreen({Key? key}) : super(key: key);

  @override
  State<StoreSectionsSettingsScreen> createState() =>
      _StoreSectionsSettingsScreenState();
}

class _StoreSectionsSettingsScreenState
    extends State<StoreSectionsSettingsScreen> {
  final List<StoreSectionModel> _sections = [];
  bool _loading = true;

  StockDatasource get _ds => Get.find<StockDatasource>();

  Future<void> _notifyStockProductsRefresh() async {
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
      final list = await _ds.getStoreSections(includeInactive: true);
      _sections
        ..clear()
        ..addAll(list);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showSectionDialog({StoreSectionModel? section}) async {
    final isEdit = section != null;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _StoreSectionFormDialog(
        title: isEdit ? 'editStoreSection'.tr : 'newStoreSection'.tr,
        initialName: section?.name ?? '',
        initialDescription: section?.description ?? '',
      ),
    );
    if (!mounted || result == null) return;

    final name = result['name']?.trim() ?? '';
    final description = result['description']?.trim() ?? '';
    if (name.isEmpty) {
      Get.snackbar('error'.tr, 'storeSectionName'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      if (isEdit) {
        await _ds.updateStoreSection(
          id: section!.id,
          name: name,
          description: description,
        );
      } else {
        await _ds.createStoreSection(
          name: name,
          description: description,
        );
      }
      await _load();
      await _notifyStockProductsRefresh();
      Get.snackbar('success'.tr, 'settingsUpdated'.tr,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _confirmDelete(StoreSectionModel section) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminUiColors.cardBackground(ctx),
        title: Text('deleteStoreSection'.tr),
        content: Text('deleteStoreSectionConfirm'.tr),
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
      await _ds.deleteStoreSection(id: section.id);
      await _load();
      await _notifyStockProductsRefresh();
      Get.snackbar('success'.tr, 'OK', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminUiColors.scaffoldBackground(context),
      appBar: CustomAppBar(
        title: 'storeSectionsSetting',
        action: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSectionDialog(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sections.isEmpty
              ? Center(
                  child: Text(
                    'noStoreSectionsYet'.tr,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 88.h),
                  itemCount: _sections.length,
                  separatorBuilder: (_, __) => SizedBox(height: 6.h),
                  itemBuilder: (context, index) {
                    final section = _sections[index];
                    final desc = section.description?.trim() ?? '';
                    return Material(
                      color: AdminUiColors.cardBackground(context),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 8.h,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32.w,
                                height: 32.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0369A1)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.place_outlined,
                                  color: const Color(0xFF0369A1),
                                  size: 17.sp,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      section.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5.sp,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 3.h),
                                    Wrap(
                                      spacing: 4.w,
                                      runSpacing: 2.h,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        _SectionStatChip(
                                          icon: Icons.inventory_2_outlined,
                                          label:
                                              'sectionStatProducts'.trParams({
                                            'count':
                                                section.productCount.toString(),
                                          }),
                                        ),
                                        if (!section.isActive)
                                          Text(
                                            'inactive'.tr,
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (desc.isNotEmpty) ...[
                                      SizedBox(height: 2.h),
                                      Text(
                                        desc,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.55),
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              _SectionActionIcon(
                                tooltip: 'edit'.tr,
                                icon: Icons.edit_outlined,
                                onPressed: () =>
                                    _showSectionDialog(section: section),
                              ),
                              _SectionActionIcon(
                                tooltip: 'delete'.tr,
                                icon: Icons.delete_outline,
                                color: Colors.red.shade700,
                                onPressed: () => _confirmDelete(section),
                              ),
                            ],
                          ),
                        ),
                    );
                  },
                ),
    );
  }
}

class _SectionActionIcon extends StatelessWidget {
  const _SectionActionIcon({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.w),
      iconSize: 18.sp,
      icon: Icon(icon, color: color),
    );
  }
}

class _SectionStatChip extends StatelessWidget {
  const _SectionStatChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0369A1).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: const Color(0xFF0369A1)),
          SizedBox(width: 3.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0369A1),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreSectionFormDialog extends StatefulWidget {
  const _StoreSectionFormDialog({
    required this.title,
    required this.initialName,
    required this.initialDescription,
  });

  final String title;
  final String initialName;
  final String initialDescription;

  @override
  State<_StoreSectionFormDialog> createState() =>
      _StoreSectionFormDialogState();
}

class _StoreSectionFormDialogState extends State<_StoreSectionFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _descCtrl = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AdminUiColors.cardBackground(context),
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: OutlineInputStyle.merge(
                context,
                labelText: 'storeSectionName'.tr,
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: OutlineInputStyle.merge(
                context,
                labelText: 'storeSectionDescription'.tr,
                hintText: 'storeSectionDescriptionHint'.tr,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('cancel'.tr),
        ),
        FilledButton(
          onPressed: () => Get.back(result: {
            'name': _nameCtrl.text,
            'description': _descCtrl.text,
          }),
          child: Text('save'.tr),
        ),
      ],
    );
  }
}
