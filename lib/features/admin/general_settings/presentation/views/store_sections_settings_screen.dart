import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/outline_input_style.dart';
import '../../../stock/data/datasources/stock_datasource.dart';
import '../../../stock/data/models/store_section_model.dart';
import '../../../stock/presentation/controllers/stock_controller.dart';
import 'section_shelves_settings_screen.dart';

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
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 88.h),
                  itemCount: _sections.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final section = _sections[index];
                    final desc = section.description?.trim() ?? '';
                    return Material(
                      color: AdminUiColors.cardBackground(context),
                      borderRadius: BorderRadius.circular(14.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14.r),
                        onTap: () => Get.to(
                          () => SectionShelvesSettingsScreen(section: section),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(14.w),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44.w,
                                height: 44.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0369A1)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.place_outlined,
                                  color: const Color(0xFF0369A1),
                                  size: 22.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      section.name,
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (desc.isNotEmpty) ...[
                                      SizedBox(height: 4.h),
                                      Text(
                                        desc,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.65),
                                          height: 1.35,
                                        ),
                                      ),
                                    ] else ...[
                                      SizedBox(height: 4.h),
                                      Text(
                                        'storeSectionNoDescription'.tr,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: 6.h),
                                    Row(
                                      children: [
                                        _SectionStatChip(
                                          icon: Icons.inventory_2_outlined,
                                          label: 'sectionStatProducts'.trParams({
                                            'count':
                                                section.productCount.toString(),
                                          }),
                                        ),
                                        SizedBox(width: 6.w),
                                        _SectionStatChip(
                                          icon: Icons.view_week_outlined,
                                          label: 'sectionStatShelves'.trParams({
                                            'count':
                                                section.shelfCount.toString(),
                                          }),
                                        ),
                                      ],
                                    ),
                                    if (!section.isActive) ...[
                                      SizedBox(height: 4.h),
                                      Text(
                                        'inactive'.tr,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'manageShelves'.tr,
                                onPressed: () => Get.to(
                                  () => SectionShelvesSettingsScreen(
                                    section: section,
                                  ),
                                ),
                                icon: const Icon(Icons.view_week_outlined),
                              ),
                              IconButton(
                                tooltip: 'edit'.tr,
                                onPressed: () =>
                                    _showSectionDialog(section: section),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'delete'.tr,
                                onPressed: () => _confirmDelete(section),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0369A1).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: const Color(0xFF0369A1)),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0369A1),
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
