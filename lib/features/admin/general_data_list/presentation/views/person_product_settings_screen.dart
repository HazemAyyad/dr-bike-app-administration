import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';
import 'package:doctorbike/features/admin/sales/data/models/product_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PersonProductSettingsScreen extends StatefulWidget {
  const PersonProductSettingsScreen({
    Key? key,
    required this.personName,
    this.customerId,
    this.sellerId,
  }) : super(key: key);

  final String personName;
  final String? customerId;
  final String? sellerId;

  @override
  State<PersonProductSettingsScreen> createState() =>
      _PersonProductSettingsScreenState();
}

class _PersonProductSettingsScreenState
    extends State<PersonProductSettingsScreen> {
  final _api = Get.find<DioConsumer>();
  final List<ProductModel> _products = [];
  final Map<String, Map<String, dynamic>> _settings = {};
  bool _loading = true;

  Map<String, dynamic> get _personQuery => {
        if (widget.customerId != null) 'customer_id': widget.customerId,
        if (widget.sellerId != null) 'seller_id': widget.sellerId,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, dynamic> _body(dynamic response) {
    final data = response?.data ?? response;
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final responses = await Future.wait([
        _api.get(EndPoints.allProducts),
        _api.get(
          EndPoints.personProductSettings,
          queryParameters: _personQuery,
        ),
      ]);
      final productsBody = _body(responses[0]);
      final settingsBody = _body(responses[1]);
      _products
        ..clear()
        ..addAll(
          ((productsBody['products'] as List?) ?? const [])
              .whereType<Map>()
              .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e))),
        );
      _settings
        ..clear()
        ..addEntries(
          ((settingsBody['settings'] as List?) ?? const [])
              .whereType<Map>()
              .map((raw) {
            final item = Map<String, dynamic>.from(raw);
            return MapEntry(item['product_id'].toString(), item);
          }),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(ProductModel product) async {
    final current = _settings[product.id];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ProductSettingDialog(
        product: product,
        current: current,
        isSeller: widget.sellerId != null,
      ),
    );
    if (result == null) return;

    setState(() => _loading = true);
    try {
      if (result['delete'] == true) {
        await _api.post(
          EndPoints.deletePersonProductSetting,
          data: {..._personQuery, 'product_id': product.id},
        );
      } else {
        final priceText = result['custom_price']?.toString() ?? '';
        final tiers = (result['price_tiers'] as List?) ?? const [];
        if (priceText.isEmpty && result['is_hidden'] != true && tiers.isEmpty) {
          Get.snackbar(
            'تنبيه',
            'أدخل سعراً خاصاً أو أضف شرائح أسعار أو فعّل إخفاء المنتج.',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        await _api.post(
          EndPoints.personProductSettings,
          data: {
            ..._personQuery,
            'product_id': product.id,
            'custom_price': priceText.isEmpty ? null : priceText,
            'is_hidden': result['is_hidden'] == true,
            'price_tiers': tiers,
          },
        );
      }
      await _load();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openProductPicker() async {
    final product = await Navigator.of(context).push<ProductModel>(
      MaterialPageRoute(
        builder: (_) => _PersonProductPickerScreen(products: _products),
      ),
    );
    if (product != null && mounted) {
      await _edit(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _products
        .where((product) => _settings.containsKey(product.id))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('أسعار ومنتجات ${widget.personName}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              leading: const Icon(Icons.search),
              hintText: 'اضغط لاختيار المنتج',
              keyboardType: TextInputType.none,
              onTap: _openProductPicker,
            ),
          ),
          if (!_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'المنتجات المعدّلة (${_settings.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد أسعار أو منتجات مخفية لهذا الحساب',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = list[index];
                          final setting = _settings[product.id];
                          final hidden = setting?['is_hidden'] == true ||
                              setting?['is_hidden']?.toString() == '1';
                          return ListTile(
                            leading: Icon(
                              hidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.price_change_outlined,
                              color: hidden ? Colors.red : Colors.green,
                            ),
                            title: Text(product.nameAr),
                            subtitle: Text(
                              setting == null
                                  ? 'السعر العام: ${widget.sellerId != null ? product.wholesalePrice : product.unitPrice} ₪'
                                  : [
                                      if (setting['custom_price'] != null)
                                        'السعر الخاص: ${setting['custom_price']} ₪',
                                      if (((setting['price_tiers'] as List?) ??
                                              const [])
                                          .isNotEmpty)
                                        'شرائح جملة: ${((setting['price_tiers'] as List?) ?? const []).length}',
                                      if (hidden) 'مخفي',
                                    ].join(' • '),
                            ),
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () => _edit(product),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProductSettingDialog extends StatefulWidget {
  const _ProductSettingDialog({
    required this.product,
    required this.current,
    required this.isSeller,
  });

  final ProductModel product;
  final Map<String, dynamic>? current;
  final bool isSeller;

  @override
  State<_ProductSettingDialog> createState() => _ProductSettingDialogState();
}

class _ProductSettingDialogState extends State<_ProductSettingDialog> {
  late final TextEditingController _price;
  late final List<_TierDraft> _tiers;
  late bool _hidden;

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(
      text: widget.current?['custom_price']?.toString() ?? '',
    );
    _tiers = (((widget.current?['price_tiers'] as List?) ?? const [])
        .whereType<Map>()
        .map((raw) => _TierDraft.fromJson(Map<String, dynamic>.from(raw)))
        .toList());
    _hidden = widget.current?['is_hidden'] == true ||
        widget.current?['is_hidden']?.toString() == '1';
  }

  @override
  void dispose() {
    _price.dispose();
    for (final tier in _tiers) {
      tier.dispose();
    }
    super.dispose();
  }

  void _addTier() {
    setState(() => _tiers.add(_TierDraft()));
  }

  void _removeTier(int index) {
    final tier = _tiers.removeAt(index);
    tier.dispose();
    setState(() {});
  }

  List<Map<String, dynamic>>? _collectTiers() {
    final rows = <Map<String, dynamic>>[];
    for (final tier in _tiers) {
      final minText = tier.min.text.trim();
      final maxText = tier.max.text.trim();
      final priceText = tier.price.text.trim();
      if (minText.isEmpty && maxText.isEmpty && priceText.isEmpty) continue;
      final min = int.tryParse(minText);
      final max = maxText.isEmpty ? null : int.tryParse(maxText);
      final price = double.tryParse(priceText);
      if (min == null ||
          min < 1 ||
          (maxText.isNotEmpty && max == null) ||
          (max != null && max < min) ||
          price == null ||
          price <= 0) {
        Get.snackbar(
          'تنبيه',
          'تأكد من شرائح الكمية: من، إلى، والسعر.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }
      rows.add({
        'min_qty': min,
        'max_qty': max,
        'unit_price': priceText,
      });
    }

    rows.sort((a, b) => (a['min_qty'] as int).compareTo(b['min_qty'] as int));
    var previousMax = 0;
    var openEndedSeen = false;
    for (var i = 0; i < rows.length; i++) {
      final min = rows[i]['min_qty'] as int;
      final max = rows[i]['max_qty'] as int?;
      if (openEndedSeen || min <= previousMax) {
        Get.snackbar(
          'تنبيه',
          'شرائح الكميات لا يمكن أن تتداخل.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }
      if (max == null) {
        openEndedSeen = true;
        if (i != rows.length - 1) {
          Get.snackbar(
            'تنبيه',
            'الشريحة المفتوحة يجب أن تكون آخر شريحة.',
            snackPosition: SnackPosition.BOTTOM,
          );
          return null;
        }
      } else {
        previousMax = max;
      }
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    const darkText = Color(0xFF202124);
    const lightGrey = Color(0xFFF1F3F4);
    final publicPrice = widget.isSeller
        ? widget.product.wholesalePrice
        : widget.product.unitPrice;

    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: lightGrey,
        dialogTheme: const DialogThemeData(backgroundColor: lightGrey),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
          surface: lightGrey,
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: darkText,
              displayColor: darkText,
            ),
      ),
      child: AlertDialog(
        backgroundColor: lightGrey,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: darkText,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(color: darkText),
        title: Text(widget.product.nameAr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _price,
                style: const TextStyle(color: darkText),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'السعر الخاص',
                  labelStyle: const TextStyle(color: Color(0xFF5F6368)),
                  hintText: 'اتركه فارغاً لاستخدام السعر العام',
                  hintStyle: const TextStyle(color: Color(0xFF80868B)),
                  suffixText: '₪',
                  suffixStyle: const TextStyle(color: darkText),
                  border: const OutlineInputBorder(),
                  helperText: 'السعر العام: $publicPrice',
                  helperStyle: const TextStyle(color: Color(0xFF5F6368)),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'إخفاء المنتج عن هذا الحساب',
                  style: TextStyle(color: darkText),
                ),
                value: _hidden,
                onChanged: (value) => setState(() => _hidden = value),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'أسعار جملة حسب الكمية',
                      style: TextStyle(
                        color: darkText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'إضافة شريحة',
                    onPressed: _addTier,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              if (_tiers.isEmpty)
                const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'مثال: من 1 إلى 3 بسعر، ومن 4 إلى 9 بسعر آخر.',
                    style: TextStyle(color: Color(0xFF5F6368), fontSize: 12),
                  ),
                ),
              for (var i = 0; i < _tiers.length; i++)
                _TierEditor(
                  key: ValueKey(_tiers[i]),
                  tier: _tiers[i],
                  onRemove: () => _removeTier(i),
                ),
            ],
          ),
        ),
        actions: [
          if (widget.current != null)
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, <String, dynamic>{'delete': true}),
              child: const Text(
                'إلغاء التخصيص',
                style: TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'رجوع',
              style: TextStyle(color: darkText),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD7E8FF),
              foregroundColor: const Color(0xFF0D47A1),
            ),
            onPressed: () {
              final tiers = _collectTiers();
              if (tiers == null) return;
              Navigator.pop(context, <String, dynamic>{
                'custom_price': _price.text.trim(),
                'is_hidden': _hidden,
                'price_tiers': tiers,
              });
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _TierDraft {
  _TierDraft({
    String min = '',
    String max = '',
    String price = '',
  })  : min = TextEditingController(text: min),
        max = TextEditingController(text: max),
        price = TextEditingController(text: price);

  factory _TierDraft.fromJson(Map<String, dynamic> json) {
    return _TierDraft(
      min: json['min_qty']?.toString() ?? '',
      max: json['max_qty']?.toString() ?? '',
      price: json['unit_price']?.toString() ?? '',
    );
  }

  final TextEditingController min;
  final TextEditingController max;
  final TextEditingController price;

  void dispose() {
    min.dispose();
    max.dispose();
    price.dispose();
  }
}

class _TierEditor extends StatelessWidget {
  const _TierEditor({
    Key? key,
    required this.tier,
    required this.onRemove,
  }) : super(key: key);

  final _TierDraft tier;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: tier.min,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'من',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: tier.max,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'إلى',
                hintText: 'وأكثر',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: tier.price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'السعر',
                suffixText: '₪',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'حذف الشريحة',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class _PersonProductPickerScreen extends StatefulWidget {
  const _PersonProductPickerScreen({required this.products});

  final List<ProductModel> products;

  @override
  State<_PersonProductPickerScreen> createState() =>
      _PersonProductPickerScreenState();
}

class _PersonProductPickerScreenState
    extends State<_PersonProductPickerScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ProductModel> get _filtered {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return widget.products;
    return widget.products.where((product) {
      return product.nameAr.toLowerCase().contains(query) ||
          product.displayProductCode.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('اختيار المنتج'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'ابحث باسم المنتج أو الكود',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text('لا توجد نتائج'))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: .72,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final imageUrl = ShowNetImage.getThumbnailPhoto(
                        product.preferredImageUrl,
                      );
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.pop(context, product),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: imageUrl.isEmpty
                                    ? const ColoredBox(
                                        color: Color(0xFFEEEEEE),
                                        child: Icon(
                                          Icons.inventory_2_outlined,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => const Icon(
                                          Icons.inventory_2_outlined,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(7),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      product.nameAr,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF202124),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      product.displayProductCode,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF5F6368),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
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
