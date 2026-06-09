import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/outline_input_style.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/datasources/stock_datasource.dart';

/// Shelf dropdown for a section + inline "add new shelf".
class SectionShelfPickerField extends StatefulWidget {
  const SectionShelfPickerField({
    Key? key,
    required this.sectionId,
    this.controller,
    this.onChanged,
    this.label,
    this.required = true,
    this.useOutlineStyle = false,
  }) : super(key: key);

  final String? sectionId;
  final TextEditingController? controller;
  final ValueChanged<String?>? onChanged;
  final String? label;
  final bool required;
  final bool useOutlineStyle;

  @override
  State<SectionShelfPickerField> createState() =>
      _SectionShelfPickerFieldState();
}

class _SectionShelfPickerFieldState extends State<SectionShelfPickerField> {
  List<String> _shelves = [];
  bool _loading = false;
  String? _selected;

  StockDatasource get _ds => Get.find<StockDatasource>();

  @override
  void initState() {
    super.initState();
    _selected = _normalize(widget.controller?.text);
    widget.controller?.addListener(_syncFromController);
    _loadShelves();
  }

  @override
  void didUpdateWidget(SectionShelfPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sectionId != widget.sectionId) {
      _selected = _normalize(widget.controller?.text);
      _loadShelves();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_syncFromController);
    super.dispose();
  }

  void _syncFromController() {
    final v = _normalize(widget.controller?.text);
    if (v == _selected) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final next = _normalize(widget.controller?.text);
      if (next != _selected) {
        setState(() => _selected = next);
      }
    });
  }

  String? _normalize(String? raw) {
    final t = raw?.trim() ?? '';
    return t.isEmpty ? null : t;
  }

  void _emit(String? shelf) {
    final v = _normalize(shelf);
    setState(() => _selected = v);
    if (widget.controller != null) {
      widget.controller!.text = v ?? '';
    }
    widget.onChanged?.call(v);
  }

  Future<void> _loadShelves() async {
    final sectionId = widget.sectionId;
    if (sectionId == null || sectionId.isEmpty) {
      setState(() {
        _shelves = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final list = await _ds.getSectionShelves(sectionId: sectionId);
      if (!mounted) return;
      setState(() {
        _shelves = list;
        _loading = false;
        if (_selected != null && !_shelves.contains(_selected)) {
          _shelves = [..._shelves, _selected!]..sort();
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _shelves = [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _addNewShelf() async {
    final sectionId = widget.sectionId;
    if (sectionId == null || sectionId.isEmpty) return;

    final number = await showDialog<String>(
      context: context,
      builder: (ctx) => const _AddShelfDialog(),
    );

    if (number == null || number.isEmpty || !mounted) return;

    try {
      await _ds.createSectionShelf(
        sectionId: sectionId,
        shelfNumber: number,
      );
      await _loadShelves();
      _emit(number);
      Get.snackbar('success'.tr, 'settingsUpdated'.tr,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  InputDecoration _decoration(BuildContext context) {
    final label = widget.label ?? 'selectTargetShelf'.tr;
    if (widget.useOutlineStyle) {
      return OutlineInputStyle.merge(context, labelText: label);
    }
    return InputDecoration(
      labelText: label,
      labelStyle:
          TextStyle(color: AppColors.customGreyColor5, fontSize: 12.sp),
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.operationalCardBorder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSection =
        widget.sectionId != null && widget.sectionId!.isNotEmpty;

    if (!hasSection) {
      return InputDecorator(
        decoration: _decoration(context),
        child: Text(
          'selectSectionForShelf'.tr,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.customGreyColor5,
          ),
        ),
      );
    }

    if (_loading) {
      return Column(
        children: [
          InputDecorator(
            decoration: _decoration(context),
            child: const SizedBox(
              height: 20,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ],
      );
    }

    final items = <DropdownMenuItem<String?>>[
      if (!widget.required)
        DropdownMenuItem<String?>(
          value: null,
          child: Text('all'.tr),
        ),
      ..._shelves.map(
        (s) => DropdownMenuItem<String?>(
          value: s,
          child: Text(s),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String?>(
          value: _selected,
          decoration: _decoration(context),
          hint: Text('selectShelfFirst'.tr),
          items: items,
          onChanged: _emit,
        ),
        SizedBox(height: 8.h),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _addNewShelf,
            icon: Icon(Icons.add, size: 18.sp),
            label: Text('addNewShelf'.tr),
          ),
        ),
      ],
    );
  }
}

class _AddShelfDialog extends StatefulWidget {
  const _AddShelfDialog();

  @override
  State<_AddShelfDialog> createState() => _AddShelfDialogState();
}

class _AddShelfDialogState extends State<_AddShelfDialog> {
  late final TextEditingController _numberCtrl;

  @override
  void initState() {
    super.initState();
    _numberCtrl = TextEditingController();
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
        'newShelf'.tr,
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
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: onSurface),
          child: Text('cancel'.tr),
        ),
        FilledButton(
          onPressed: () {
            final value = _numberCtrl.text.trim();
            if (value.isEmpty) return;
            Navigator.pop(context, value);
          },
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
