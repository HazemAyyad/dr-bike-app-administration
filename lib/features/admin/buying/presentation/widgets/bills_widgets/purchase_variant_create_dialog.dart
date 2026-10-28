import 'package:flutter/material.dart';

import '../../../../sales/data/models/product_variant_model.dart';

typedef CreatePurchaseVariant = Future<PurchaseVariantOption> Function({
  required String size,
  required String color,
  required double retailPrice,
});

class PurchaseVariantCreateDialog extends StatefulWidget {
  const PurchaseVariantCreateDialog({
    Key? key,
    required this.sizes,
    required this.defaultRetailPrice,
    required this.onCreate,
  }) : super(key: key);

  final List<String> sizes;
  final double defaultRetailPrice;
  final CreatePurchaseVariant onCreate;

  @override
  State<PurchaseVariantCreateDialog> createState() =>
      _PurchaseVariantCreateDialogState();
}

class _PurchaseVariantCreateDialogState
    extends State<PurchaseVariantCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _color = TextEditingController();
  late final _price = TextEditingController(
    text: widget.defaultRetailPrice.toStringAsFixed(2),
  );
  String _size = '';
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _color.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final option = await widget.onCreate(
        size: _size.trim(),
        color: _color.text.trim(),
        retailPrice: double.parse(_price.text.trim()),
      );
      if (mounted) Navigator.pop(context, option);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'تعذر إضافة اللون والحجم. $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: const Text('إضافة لون أو حجم'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Autocomplete<String>(
                    optionsBuilder: (value) => widget.sizes.where(
                      (size) => size
                          .toLowerCase()
                          .contains(value.text.trim().toLowerCase()),
                    ),
                    onSelected: (value) => _size = value,
                    fieldViewBuilder:
                        (context, controller, focusNode, onSubmit) =>
                            TextFormField(
                      key: const Key('purchase_variant_size'),
                      controller: controller,
                      focusNode: focusNode,
                      enabled: !_saving,
                      maxLength: 50,
                      onChanged: (value) => _size = value,
                      decoration: const InputDecoration(
                        labelText: 'الحجم',
                        helperText: 'اختر حجمًا موجودًا أو اكتب حجمًا جديدًا',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'أدخل الحجم'
                              : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('purchase_variant_color'),
                    controller: _color,
                    enabled: !_saving,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'اللون',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'أدخل اللون'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('purchase_variant_retail_price'),
                    controller: _price,
                    enabled: !_saving,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'سعر البيع',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final price = double.tryParse(value?.trim() ?? '');
                      return price == null || !price.isFinite || price < 0
                          ? 'أدخل سعر بيع صحيحًا'
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                      'يُحفظ اللون والحجم للمنتج مباشرة. حدد الكمية وسعر الشراء في القائمة؛ يُضاف المخزون عند الاستلام.'),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('حفظ واختيار'),
          ),
        ],
      ),
    );
  }
}
