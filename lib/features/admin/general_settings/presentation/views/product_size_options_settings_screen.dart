import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/outline_input_style.dart';
import '../../../stock/data/datasources/stock_datasource.dart';

/// Admin CRUD for product size dropdown presets.
class ProductSizeOptionsSettingsScreen extends StatefulWidget {
  const ProductSizeOptionsSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ProductSizeOptionsSettingsScreen> createState() =>
      _ProductSizeOptionsSettingsScreenState();
}

class _ProductSizeOptionsSettingsScreenState
    extends State<ProductSizeOptionsSettingsScreen> {
  final List<String> _sizes = [];
  bool _loading = true;
  bool _saving = false;

  StockDatasource get _ds => Get.find<StockDatasource>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _ds.getSizeOptionPresets();
      _sizes
        ..clear()
        ..addAll(list);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persist() async {
    setState(() => _saving = true);
    try {
      final saved = await _ds.saveSizeOptionPresets(List<String>.from(_sizes));
      _sizes
        ..clear()
        ..addAll(saved);
      Get.snackbar('success'.tr, 'settingsUpdated'.tr,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showSizeDialog({String? initial, int? editIndex}) async {
    final isEdit = editIndex != null;

    final value = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _SizeOptionFormDialog(
        title: isEdit ? 'editSizeOption'.tr : 'addSizeOption'.tr,
        initial: initial ?? '',
      ),
    );

    if (!mounted || value == null) {
      return;
    }

    if (value.isEmpty) {
      Get.snackbar('error'.tr, 'sizeRequired'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final duplicate = _sizes.asMap().entries.any(
          (e) =>
              e.key != editIndex &&
              e.value.trim().toLowerCase() == value.toLowerCase(),
        );
    if (duplicate) {
      Get.snackbar('error'.tr, 'sizeOptionDuplicate'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() {
      if (isEdit && editIndex != null) {
        _sizes[editIndex] = value;
      } else {
        _sizes.add(value);
      }
    });
    await _persist();
  }

  Future<void> _confirmDelete(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _neutralAlertDialog(
        context: ctx,
        title: Text(
          'delete'.tr,
          style: _dialogTitleStyle(ctx),
        ),
        content: Text(
          'deleteSizeOptionConfirm'.tr,
          style: _dialogBodyStyle(ctx),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _dialogActionMuted(ctx),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFEE2E2),
              foregroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _sizes.removeAt(index));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminUiColors.scaffoldBackground(context),
      appBar: CustomAppBar(
        title: 'productSizeOptionsSetting',
        action: false,
      ),
      floatingActionButton: _loading || _saving
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showSizeDialog(),
              icon: const Icon(Icons.add),
              label: Text('addSizeOption'.tr),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sizes.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Text(
                      'noSizeOptionsYet'.tr,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 88.h),
                  itemCount: _sizes.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final label = _sizes[index];
                    return Material(
                      color: AdminUiColors.cardBackground(context),
                      borderRadius: BorderRadius.circular(12.r),
                      child: ListTile(
                        leading: Icon(
                          Icons.straighten,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: _saving
                                  ? null
                                  : () => _showSizeDialog(
                                        initial: label,
                                        editIndex: index,
                                      ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: _saving
                                  ? null
                                  : () => _confirmDelete(index),
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

/// Owns [TextEditingController] lifecycle so dispose runs after the route closes.
class _SizeOptionFormDialog extends StatefulWidget {
  const _SizeOptionFormDialog({
    required this.title,
    required this.initial,
  });

  final String title;
  final String initial;

  @override
  State<_SizeOptionFormDialog> createState() => _SizeOptionFormDialogState();
}

class _SizeOptionFormDialogState extends State<_SizeOptionFormDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _neutralAlertDialog(
      context: context,
      title: Text(
        widget.title,
        style: _dialogTitleStyle(context),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: TextStyle(color: _dialogFieldText(context)),
        cursorColor: _dialogFieldText(context),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: OutlineInputStyle.merge(
          context,
          labelText: 'size'.tr,
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: _dialogActionMuted(context),
          ),
          onPressed: _cancel,
          child: Text('cancel'.tr),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: _dialogActionPrimary(context),
          ),
          onPressed: _submit,
          child: Text(
            'save'.tr,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

AlertDialog _neutralAlertDialog({
  required BuildContext context,
  required Widget title,
  required Widget content,
  required List<Widget> actions,
}) {
  return AlertDialog(
    backgroundColor: AdminUiColors.cardBackground(context),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
    title: title,
    content: content,
    actions: actions,
  );
}

TextStyle _dialogTitleStyle(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return TextStyle(
    fontWeight: FontWeight.w700,
    color: isDark
        ? Theme.of(context).colorScheme.onSurface
        : const Color(0xFF111827),
  );
}

TextStyle _dialogBodyStyle(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return TextStyle(
    color: isDark
        ? Theme.of(context).colorScheme.onSurface
        : const Color(0xFF374151),
    height: 1.4,
  );
}

Color _dialogFieldText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).colorScheme.onSurface
      : const Color(0xFF111827);
}

Color _dialogActionMuted(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).colorScheme.onSurfaceVariant
      : const Color(0xFF374151);
}

Color _dialogActionPrimary(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).colorScheme.onSurface
      : const Color(0xFF111827);
}
