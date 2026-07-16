import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:doctorbike/features/admin/sales/data/models/product_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/product_variant_model.dart';
import 'package:doctorbike/features/admin/sales/presentation/widgets/new_instant_sale/instant_sale_qty_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/datasources/stock_datasource.dart';
import '../../data/models/product_assembly_model.dart';
import '../widgets/product_location_badge.dart';
import '../controllers/stock_controller.dart';

class AddCombinationScreen extends StatefulWidget {
  const AddCombinationScreen({Key? key}) : super(key: key);

  @override
  State<AddCombinationScreen> createState() => _AddCombinationScreenState();
}

class _AddCombinationScreenState extends State<AddCombinationScreen> {
  final StockDatasource _datasource = Get.find<StockDatasource>();
  final StockController _stock = Get.find<StockController>();
  final RxBool _isSubmitting = false.obs;
  final _runsController = TextEditingController(text: '1');
  final _disassembleQtyController = TextEditingController(text: '1');
  final _additionalCostController = TextEditingController(text: '0');
  final _noteController = TextEditingController();

  int _modeIndex = 0;
  ProductModel? _targetProduct;
  _AssemblyVariantChoice? _targetVariant;
  final List<_AssemblyComponentLine> _components = [];
  List<ProductAssemblyRecipeModel> _recipes = [];
  ProductAssemblyRecipeModel? _selectedRecipe;
  bool _recipesLoading = false;

  int get _runs => int.tryParse(_runsController.text.trim()) ?? 1;

  int get _disassembleQty =>
      int.tryParse(_disassembleQtyController.text.trim()) ?? 1;

  double get _additionalCost =>
      double.tryParse(_additionalCostController.text.trim()) ?? 0;

  double get _componentsUnitCost {
    var total = 0.0;
    for (final line in _components) {
      total += line.product.purchaseCost * line.quantity;
    }
    return total;
  }

  double get _unitCost => _componentsUnitCost + _additionalCost;

  double get _totalCost => _unitCost * _runs;

  @override
  void initState() {
    super.initState();
    _runsController.addListener(_refresh);
    _disassembleQtyController.addListener(_refresh);
    _additionalCostController.addListener(_refresh);
    _loadRecipes();
  }

  @override
  void dispose() {
    _runsController.dispose();
    _disassembleQtyController.dispose();
    _additionalCostController.dispose();
    _noteController.dispose();
    for (final line in _components) {
      line.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRecipes() async {
    setState(() => _recipesLoading = true);
    try {
      final recipes = await _datasource.getAssemblyRecipes();
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        if (_selectedRecipe == null && recipes.isNotEmpty) {
          _selectedRecipe = recipes.first;
        } else if (_selectedRecipe != null) {
          _selectedRecipe = recipes.firstWhereOrNull(
                (recipe) => recipe.id == _selectedRecipe!.id,
              ) ??
              (recipes.isEmpty ? null : recipes.first);
        }
      });
    } catch (e) {
      Get.snackbar('error'.tr, _errorText(e));
    } finally {
      if (mounted) setState(() => _recipesLoading = false);
    }
  }

  Future<void> _selectTarget() async {
    final product = await _openProductPicker(title: 'اختيار المنتج الناتج');
    if (product == null) return;
    final variant = await _pickVariantIfNeeded(product);
    if (product.hasVariants && variant == null) return;
    setState(() {
      _targetProduct = product;
      _targetVariant = variant;
    });
  }

  Future<void> _addComponent() async {
    final picks = await _openComponentPicker();
    if (picks == null || picks.isEmpty) return;

    final resolvedPicks = <_AssemblyComponentPick>[];
    for (final pick in picks) {
      var resolvedPick = pick;
      if (pick.product.hasVariants && pick.sizeColorId == null) {
        final variant = await _pickVariantIfNeeded(pick.product);
        if (variant == null) continue;
        resolvedPick = pick.copyWith(variant: variant);
      }
      resolvedPicks.add(resolvedPick);
    }
    if (resolvedPicks.isEmpty) return;

    setState(() {
      for (final pick in resolvedPicks) {
        final index = _components.indexWhere(
          (line) =>
              line.product.id == pick.product.id &&
              line.sizeColorId == pick.sizeColorId,
        );
        if (index >= 0) {
          _components[index].quantity = pick.quantity;
        } else {
          _components.add(
            _AssemblyComponentLine(
              product: pick.product,
              quantity: pick.quantity,
              sizeColorId: pick.sizeColorId,
              variantLabel: pick.variantLabel,
            ),
          );
        }
      }
    });
  }

  Future<void> _executeAssembly() async {
    final target = _targetProduct;
    if (target == null) {
      Get.snackbar('error'.tr, 'اختر المنتج الناتج أولاً.');
      return;
    }
    if (_components.isEmpty) {
      Get.snackbar('error'.tr, 'أضف مكوّناً واحداً على الأقل.');
      return;
    }
    if (_runs < 1) {
      Get.snackbar('error'.tr, 'عدد مرات التركيب يجب أن يكون أكبر من صفر.');
      return;
    }

    _isSubmitting(true);
    try {
      final operation = await _datasource.executeAssembly(
        targetProductId: target.id,
        targetSizeColorId: _targetVariant?.sizeColorId,
        quantity: _runs,
        additionalCost: _additionalCost,
        note: _noteController.text,
        components: _components
            .map((line) => {
                  'product_id': line.product.id,
                  if (line.sizeColorId != null)
                    'size_color_id': line.sizeColorId,
                  'quantity': line.quantity,
                })
            .toList(),
      );
      Get.snackbar(
        'success'.tr,
        'تم تركيب ${operation.quantity} من ${operation.targetProductName}.',
      );
      await _stock.getAllProducts();
      await _loadRecipes();
      setState(() {
        _targetProduct = null;
        _targetVariant = null;
        for (final line in _components) {
          line.dispose();
        }
        _components.clear();
        _runsController.text = '1';
        _additionalCostController.text = '0';
        _noteController.clear();
      });
    } catch (e) {
      Get.snackbar('error'.tr, _errorText(e));
    } finally {
      _isSubmitting(false);
    }
  }

  Future<void> _executeDisassembly() async {
    final recipe = _selectedRecipe;
    if (recipe == null) {
      Get.snackbar('error'.tr, 'اختر وصفة تركيب لفكها.');
      return;
    }
    if (_disassembleQty < 1) {
      Get.snackbar('error'.tr, 'كمية الفك يجب أن تكون أكبر من صفر.');
      return;
    }

    _isSubmitting(true);
    try {
      final operation = await _datasource.disassembleAssembly(
        recipeId: recipe.id,
        quantity: _disassembleQty,
        note: _noteController.text,
      );
      Get.snackbar(
        'success'.tr,
        'تم فك ${operation.quantity} من ${operation.targetProductName}.',
      );
      await _stock.getAllProducts();
      await _loadRecipes();
      setState(() {
        _disassembleQtyController.text = '1';
        _noteController.clear();
      });
    } catch (e) {
      Get.snackbar('error'.tr, _errorText(e));
    } finally {
      _isSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'newProductComposition',
        action: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 18.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ModeSwitch(
                selectedIndex: _modeIndex,
                onChanged: (value) {
                  setState(() => _modeIndex = value);
                },
              ),
              SizedBox(height: 12.h),
              _modeIndex == 0 ? _buildAssembly() : _buildDisassembly(),
              SizedBox(height: 18.h),
              AppButton(
                text: _modeIndex == 0 ? 'تنفيذ التركيب' : 'تنفيذ فك التركيب',
                isLoading: _isSubmitting,
                isSafeArea: false,
                onPressed:
                    _modeIndex == 0 ? _executeAssembly : _executeDisassembly,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssembly() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'المنتج الناتج',
          actionText: _targetProduct == null ? 'اختيار المنتج الناتج' : 'تغيير',
          onAction: _selectTarget,
        ),
        InkWell(
          onTap: _selectTarget,
          borderRadius: BorderRadius.circular(8.r),
          child: _ProductSummaryTile(
            product: _targetProduct,
            variantLabel: _targetVariant?.label,
          ),
        ),
        SizedBox(height: 14.h),
        _NumberField(
          label: 'عدد مرات التركيب',
          controller: _runsController,
        ),
        SizedBox(height: 14.h),
        _NumberField(
          label: 'تكلفة إضافية للقطعة',
          controller: _additionalCostController,
          allowDecimal: true,
        ),
        SizedBox(height: 14.h),
        _SectionTitle(
          title: 'المكونات',
          actionText: 'إضافة مكوّن من المخزون',
          onAction: _addComponent,
        ),
        if (_components.isEmpty)
          InkWell(
            onTap: _addComponent,
            borderRadius: BorderRadius.circular(8.r),
            child: const _EmptyHint(
              text: 'اضغط هنا لإضافة المنتجات التي سيتم خصمها من المخزون.',
            ),
          )
        else
          ...List.generate(_components.length, (index) {
            final line = _components[index];
            return _ComponentTile(
              line: line,
              onChanged: _refresh,
              onRemove: () {
                setState(() {
                  final removed = _components.removeAt(index);
                  removed.dispose();
                });
              },
            );
          }),
        SizedBox(height: 14.h),
        _CostPanel(
          componentsCost: _componentsUnitCost,
          additionalCost: _additionalCost,
          unitCost: _unitCost,
          totalCost: _totalCost,
          runs: _runs,
        ),
        SizedBox(height: 14.h),
        _NoteField(controller: _noteController),
      ],
    );
  }

  Widget _buildDisassembly() {
    final recipe = _selectedRecipe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'وصفة التركيب',
          actionText: 'تحديث',
          onAction: _loadRecipes,
        ),
        if (_recipesLoading)
          const Center(child: CircularProgressIndicator())
        else if (_recipes.isEmpty)
          const _EmptyHint(text: 'لا توجد وصفات تركيب محفوظة حتى الآن.')
        else
          DropdownButtonFormField<int>(
            initialValue: recipe?.id,
            selectedItemBuilder: (context) => _recipes
                .map(
                  (recipe) => Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      _recipeSelectedLabel(recipe),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            items: _recipes
                .map(
                  (recipe) => DropdownMenuItem<int>(
                    value: recipe.id,
                    child: _RecipeDropdownItem(recipe: recipe),
                  ),
                )
                .toList(),
            onChanged: (id) {
              setState(() {
                _selectedRecipe =
                    _recipes.firstWhereOrNull((recipe) => recipe.id == id);
              });
            },
            decoration: const InputDecoration(
              labelText: 'اختر وصفة التركيب',
              border: OutlineInputBorder(),
            ),
            isExpanded: true,
          ),
        if (recipe != null) ...[
          SizedBox(height: 8.h),
          _PlainTile(
            title: _recipeSelectedLabel(recipe),
            subtitle: _recipeDetailsLabel(recipe),
            trailing: '${recipe.items.length} مكوّن',
          ),
        ],
        SizedBox(height: 14.h),
        _NumberField(
          label: 'عدد القطع المراد فكها',
          controller: _disassembleQtyController,
        ),
        SizedBox(height: 14.h),
        if (recipe != null) ...[
          _RecipePreview(recipe: recipe, quantity: _disassembleQty),
          SizedBox(height: 14.h),
        ],
        _NoteField(controller: _noteController),
      ],
    );
  }

  Future<ProductModel?> _openProductPicker({required String title}) async {
    return showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssemblyProductPicker(
        title: title,
        datasource: _datasource,
      ),
    );
  }

  Future<_AssemblyVariantChoice?> _pickVariantIfNeeded(
      ProductModel product) async {
    if (!product.hasVariants || product.sizes.isEmpty) return null;
    return showDialog<_AssemblyVariantChoice>(
      context: context,
      builder: (ctx) => _AssemblyVariantDialog(product: product),
    );
  }

  Future<List<_AssemblyComponentPick>?> _openComponentPicker() async {
    return showModalBottomSheet<List<_AssemblyComponentPick>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssemblyComponentPicker(
        datasource: _datasource,
        initialComponents: _components,
      ),
    );
  }

  String _errorText(Object e) {
    final text = e.toString();
    final marker = 'message:';
    if (text.contains(marker)) {
      return text.split(marker).last.trim();
    }
    return text.replaceFirst('Exception:', '').trim();
  }
}

class _RecipeDropdownItem extends StatelessWidget {
  const _RecipeDropdownItem({required this.recipe});

  final ProductAssemblyRecipeModel recipe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _recipeSelectedLabel(recipe),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            _recipeDetailsLabel(recipe),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssemblyComponentPick {
  const _AssemblyComponentPick({
    required this.product,
    required this.quantity,
    this.sizeColorId,
    this.variantLabel,
  });

  final ProductModel product;
  final int quantity;
  final String? sizeColorId;
  final String? variantLabel;

  _AssemblyComponentPick copyWith({
    int? quantity,
    _AssemblyVariantChoice? variant,
  }) {
    return _AssemblyComponentPick(
      product: product,
      quantity: quantity ?? this.quantity,
      sizeColorId: variant?.sizeColorId ?? sizeColorId,
      variantLabel: variant?.label ?? variantLabel,
    );
  }
}

class _AssemblyVariantChoice {
  const _AssemblyVariantChoice({
    required this.sizeColorId,
    required this.label,
  });

  final String sizeColorId;
  final String label;
}

class _AssemblyVariantDialog extends StatefulWidget {
  const _AssemblyVariantDialog({required this.product});

  final ProductModel product;

  @override
  State<_AssemblyVariantDialog> createState() => _AssemblyVariantDialogState();
}

class _AssemblyVariantDialogState extends State<_AssemblyVariantDialog> {
  ProductSizeVariant? _size;
  ProductColorVariant? _color;

  @override
  void initState() {
    super.initState();
    if (widget.product.sizes.isNotEmpty) {
      _size = widget.product.sizes.first;
      final colors = _size!.colorSizes;
      if (colors.isNotEmpty) {
        _color = colors.firstWhere(
          (color) => color.stock > 0,
          orElse: () => colors.first,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _size?.colorSizes ?? const <ProductColorVariant>[];
    return AlertDialog(
      title: Text(widget.product.nameAr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<ProductSizeVariant>(
            initialValue: _size,
            items: widget.product.sizes
                .map(
                  (size) => DropdownMenuItem(
                    value: size,
                    child: Text(size.size),
                  ),
                )
                .toList(),
            onChanged: (size) {
              setState(() {
                _size = size;
                final nextColors = size?.colorSizes ?? [];
                _color = nextColors.isEmpty
                    ? null
                    : nextColors.firstWhere(
                        (color) => color.stock > 0,
                        orElse: () => nextColors.first,
                      );
              });
            },
            decoration: const InputDecoration(
              labelText: 'المقاس',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 12.h),
          DropdownButtonFormField<ProductColorVariant>(
            initialValue: _color,
            items: colors
                .map(
                  (color) => DropdownMenuItem(
                    value: color,
                    child: Text('${color.colorAr} - المخزون ${color.stock}'),
                  ),
                )
                .toList(),
            onChanged: (color) => setState(() => _color = color),
            decoration: const InputDecoration(
              labelText: 'اللون',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            final size = _size;
            final color = _color;
            if (size == null || color == null) {
              Get.snackbar('error'.tr, 'اختر المقاس واللون.');
              return;
            }
            Navigator.pop(
              context,
              _AssemblyVariantChoice(
                sizeColorId: color.id,
                label: '${size.size} / ${color.colorAr}',
              ),
            );
          },
          child: const Text('موافقة'),
        ),
      ],
    );
  }
}

class _AssemblyProductPicker extends StatefulWidget {
  const _AssemblyProductPicker({
    required this.title,
    required this.datasource,
  });

  final String title;
  final StockDatasource datasource;

  @override
  State<_AssemblyProductPicker> createState() => _AssemblyProductPickerState();
}

class _AssemblyProductPickerState extends State<_AssemblyProductPicker> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<ProductModel> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final products = await widget.datasource.getAssemblyProductPicker(
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() => _products = products);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _load);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Material(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            child: Column(
              children: [
                Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.grey.shade900,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.grey.shade900),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade700),
                    hintText: 'بحث عن منتج...',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onChanged: _onSearch,
                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          controller: scrollController,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.74,
                            crossAxisSpacing: 8.w,
                            mainAxisSpacing: 8.h,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return _AssemblyPickerProductCard(
                              product: product,
                              quantity: 0,
                              onTap: () => Navigator.pop(context, product),
                              onQuantityTap: () {},
                              onIncrement: () =>
                                  Navigator.pop(context, product),
                              onDecrement: null,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AssemblyComponentPicker extends StatefulWidget {
  const _AssemblyComponentPicker({
    required this.datasource,
    required this.initialComponents,
  });

  final StockDatasource datasource;
  final List<_AssemblyComponentLine> initialComponents;

  @override
  State<_AssemblyComponentPicker> createState() =>
      _AssemblyComponentPickerState();
}

class _AssemblyComponentPickerState extends State<_AssemblyComponentPicker> {
  final _searchController = TextEditingController();
  final Map<String, ProductModel> _selectedProducts = {};
  final Map<String, TextEditingController> _quantityControllers = {};
  final List<TextEditingController> _retiredQuantityControllers = [];
  Timer? _debounce;
  List<ProductModel> _products = [];
  bool _loading = true;

  static const int _maxRows = 4;
  static const int _minRows = 2;
  static const int _visibleColumns = 4;

  @override
  void initState() {
    super.initState();
    for (final line in widget.initialComponents) {
      _selectedProducts[line.product.id] = line.product;
      _quantityControllers[line.product.id] =
          TextEditingController(text: line.quantity.toString());
    }
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (final controller in _retiredQuantityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final products = await widget.datasource.getAssemblyProductPicker(
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() => _products = products);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _load);
  }

  void _remove(ProductModel product) {
    _selectedProducts.remove(product.id);
    final controller = _quantityControllers.remove(product.id);
    if (controller != null) {
      _retiredQuantityControllers.add(controller);
    }
  }

  int _quantityFor(ProductModel product) {
    if (!_selectedProducts.containsKey(product.id)) return 0;
    final controller = _quantityControllers[product.id];
    return int.tryParse(controller?.text.trim() ?? '') ?? 0;
  }

  void _setQuantity(ProductModel product, int quantity) {
    if (quantity < 1) {
      _remove(product);
      return;
    }
    _debugSelectedComponentCost(product, quantity);
    _selectedProducts[product.id] = product;
    final controller = _quantityControllers[product.id];
    if (controller == null) {
      _quantityControllers[product.id] =
          TextEditingController(text: quantity.toString());
    } else {
      controller.text = quantity.toString();
    }
  }

  void _increment(ProductModel product) {
    setState(() => _setQuantity(product, _quantityFor(product) + 1));
  }

  void _decrement(ProductModel product) {
    setState(() => _setQuantity(product, _quantityFor(product) - 1));
  }

  Future<void> _promptQuantity(ProductModel product) async {
    final qty = await showDialog<int>(
      context: context,
      builder: (ctx) => _AssemblyQuantityDialog(
        title: product.nameAr,
        initialQuantity:
            (_quantityFor(product) > 0 ? _quantityFor(product) : 1),
      ),
    );
    if (qty == null) return;
    setState(() => _setQuantity(product, qty));
  }

  int get _selectedLines => _selectedProducts.length;

  int get _selectedPieces {
    var total = 0;
    for (final product in _selectedProducts.values) {
      total += _quantityFor(product);
    }
    return total;
  }

  double get _selectedCost {
    var total = 0.0;
    for (final product in _selectedProducts.values) {
      total += product.purchaseCost * _quantityFor(product);
    }
    return total;
  }

  void _confirm() {
    final picks = <_AssemblyComponentPick>[];
    for (final product in _selectedProducts.values) {
      final controller = _quantityControllers[product.id];
      final quantity = int.tryParse(controller?.text.trim() ?? '') ?? 0;
      if (quantity < 1) {
        Get.snackbar(
            'error'.tr, 'كمية ${product.nameAr} يجب أن تكون أكبر من صفر.');
        return;
      }
      debugPrint(
        '[AssemblyCostDebug] confirm component '
        'id=${product.id} name=${product.nameAr} '
        'quantity=$quantity purchaseCost=${product.purchaseCost} '
        'lineTotal=${product.purchaseCost * quantity}',
      );
      picks.add(_AssemblyComponentPick(product: product, quantity: quantity));
    }
    Navigator.pop(context, picks);
  }

  void _debugSelectedComponentCost(ProductModel product, int quantity) {
    debugPrint(
      '[AssemblyCostDebug] select/update component '
      'id=${product.id} name=${product.nameAr} '
      'quantity=$quantity purchaseCost=${product.purchaseCost} '
      'stock=${product.stock} unitPrice=${product.unitPrice} '
      'productCode=${product.productCode} '
      'storeSection=${product.storeSectionName}',
    );
  }

  Future<void> _showCartSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComponentCartSheet(
        products: _selectedProducts.values.toList(),
        quantityControllers: _quantityControllers,
        onChanged: () => setState(() {}),
        onRemove: (product) => setState(() => _remove(product)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.94,
      maxChildSize: 0.98,
      minChildSize: 0.72,
      builder: (context, scrollController) {
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
                child: Column(
                  children: [
                    Container(
                      width: 42.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'اختيار المكونات',
                            style: TextStyle(
                              color: Colors.grey.shade900,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '$_selectedLines محدد',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _searchController,
                      style: TextStyle(color: Colors.grey.shade900),
                      decoration: InputDecoration(
                        prefixIcon:
                            Icon(Icons.search, color: Colors.grey.shade700),
                        hintText: 'instantSaleSearchProductsAndPackages'.tr,
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                      ),
                      onChanged: _onSearch,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final hGap = 6.w;
                          final vGap = 6.h;
                          final padH = 10.w;
                          final gridW = constraints.maxWidth - padH * 2;
                          final gridH = constraints.maxHeight;
                          final minCellH = 82.h;
                          final rows = ((gridH + vGap) / (minCellH + vGap))
                              .floor()
                              .clamp(_minRows, _maxRows);
                          final cellW = (gridW - hGap * (_visibleColumns - 1)) /
                              _visibleColumns;
                          final cellH = (gridH - vGap * (rows - 1)) / rows;
                          final aspectRatio = cellH / cellW;

                          return GridView.builder(
                            key: ValueKey(
                              'assembly_picker_grid_${_searchController.text}_${_products.length}',
                            ),
                            controller: scrollController,
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: padH),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: rows,
                              mainAxisSpacing: hGap,
                              crossAxisSpacing: vGap,
                              childAspectRatio: aspectRatio,
                            ),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              final qty = _quantityFor(product);
                              return _AssemblyPickerProductCard(
                                product: product,
                                quantity: qty,
                                onTap: () => qty > 0
                                    ? _promptQuantity(product)
                                    : _increment(product),
                                onQuantityTap: () => _promptQuantity(product),
                                onIncrement: () => _increment(product),
                                onDecrement:
                                    qty > 0 ? () => _decrement(product) : null,
                              );
                            },
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap:
                            _selectedProducts.isEmpty ? null : _showCartSheet,
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                color: AppColors.primaryColor,
                                size: 28.sp,
                              ),
                              if (_selectedLines > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    padding: EdgeInsets.all(4.w),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 18.w,
                                      minHeight: 18.w,
                                    ),
                                    child: Text(
                                      '$_selectedLines',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'سلة المكونات ($_selectedLines)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                              ),
                            ),
                            Text(
                              '$_selectedPieces قطعة | تكلفة ${_money(_selectedCost)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      SizedBox(
                        height: 46.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed:
                              _selectedProducts.isEmpty ? null : _confirm,
                          child: Text(
                            'موافقة',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AssemblyQuantityDialog extends StatefulWidget {
  const _AssemblyQuantityDialog({
    required this.title,
    required this.initialQuantity,
  });

  final String title;
  final int initialQuantity;

  @override
  State<_AssemblyQuantityDialog> createState() =>
      _AssemblyQuantityDialogState();
}

class _AssemblyQuantityDialogState extends State<_AssemblyQuantityDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialQuantity.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF3F4F6),
      surfaceTintColor: const Color(0xFFF3F4F6),
      title: Text(
        widget.title,
        style: TextStyle(
          color: Colors.grey.shade900,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: TextStyle(color: Colors.grey.shade900),
        decoration: InputDecoration(
          labelText: 'كمية',
          labelStyle: TextStyle(color: Colors.grey.shade700),
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              int.tryParse(_controller.text.trim()) ?? 1,
            );
          },
          child: Text('save'.tr),
        ),
      ],
    );
  }
}

class _ComponentCartSheet extends StatefulWidget {
  const _ComponentCartSheet({
    required this.products,
    required this.quantityControllers,
    required this.onChanged,
    required this.onRemove,
  });

  final List<ProductModel> products;
  final Map<String, TextEditingController> quantityControllers;
  final VoidCallback onChanged;
  final ValueChanged<ProductModel> onRemove;

  @override
  State<_ComponentCartSheet> createState() => _ComponentCartSheetState();
}

class _ComponentCartSheetState extends State<_ComponentCartSheet> {
  late final List<ProductModel> _products;

  @override
  void initState() {
    super.initState();
    _products = List<ProductModel>.from(widget.products);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.58,
      maxChildSize: 0.9,
      minChildSize: 0.32,
      builder: (context, scrollController) {
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'سلة المكونات',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey.shade900,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.all(12.w),
                  itemCount: _products.length,
                  separatorBuilder: (_, __) => Divider(height: 12.h),
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final controller = widget.quantityControllers[product.id];
                    final qty =
                        int.tryParse(controller?.text.trim() ?? '') ?? 0;
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.nameAr,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                'تكلفة الوحدة: ${_money(product.purchaseCost)} | المجموع: ${_money(product.purchaseCost * qty)}',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        SizedBox(
                          width: 76.w,
                          height: 36.h,
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onChanged: (_) {
                              setState(() {});
                              widget.onChanged();
                            },
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: 'كمية',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setState(() => _products.removeAt(index));
                            widget.onRemove(product);
                          },
                          icon: const Icon(Icons.close, color: Colors.red),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AssemblyPickerProductCard extends StatelessWidget {
  const _AssemblyPickerProductCard({
    required this.product,
    required this.quantity,
    required this.onTap,
    required this.onQuantityTap,
    required this.onIncrement,
    required this.onDecrement,
  });

  final ProductModel product;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onQuantityTap;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final image = product.preferredImageUrl;
    final url = ShowNetImage.getThumbnailPhoto(image);
    final hasImage = url.isNotEmpty && image != 'no image';
    final stock = int.tryParse(product.stock) ?? 0;
    final selected = quantity > 0;
    final locationCodeLabel = ProductLocationLabel.withProductCode(
      sectionName: product.storeSectionName,
      productCode: product.displayProductCode,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10.r),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.primaryColor : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: InkWell(
                onTap: onTap,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImage
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                          )
                        : ColoredBox(
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 22.sp,
                              color: Colors.grey.shade400,
                            ),
                          ),
                    Positioned(
                      bottom: 3.h,
                      right: 3.w,
                      child: _PickerStockBadge(stock: stock),
                    ),
                    if (locationCodeLabel != null)
                      Positioned(
                        top: 3.h,
                        left: 3.w,
                        right: 3.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.62),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            locationCodeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 6.5.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ),
                    if (selected)
                      Positioned(
                        top: locationCodeLabel != null ? 18.h : 3.h,
                        left: 3.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '$quantity',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onTap,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return ClipRect(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.center,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        product.nameAr,
                                        maxLines: 2,
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.w600,
                                          height: 1.05,
                                        ),
                                      ),
                                      Text(
                                        'تكلفة ${_money(product.purchaseCost)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 7.sp,
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w600,
                                          height: 1.05,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20.h,
                      child: Center(
                        child: InstantSaleQtyStepper(
                          compact: true,
                          quantity: quantity,
                          canDecrement: selected,
                          canIncrement: true,
                          onQuantityTap: selected ? onQuantityTap : null,
                          onDecrement: onDecrement,
                          onIncrement: onIncrement,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerStockBadge extends StatelessWidget {
  const _PickerStockBadge({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final out = stock < 1;
    final low = !out && stock <= 3;
    final color = out
        ? Colors.red.shade700
        : low
            ? Colors.orange.shade700
            : const Color(0xFF15803D);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        '$stock',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AssemblyComponentLine {
  _AssemblyComponentLine({
    required this.product,
    required int quantity,
    this.sizeColorId,
    this.variantLabel,
  }) : quantityController = TextEditingController(text: quantity.toString());

  final ProductModel product;
  final String? sizeColorId;
  final String? variantLabel;
  final TextEditingController quantityController;

  int get quantity => int.tryParse(quantityController.text.trim()) ?? 1;

  set quantity(int value) => quantityController.text = value.toString();

  double get totalCost => product.purchaseCost * quantity;

  void dispose() => quantityController.dispose();
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  final String title;
  final String actionText;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
          ),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add),
          label: Text(actionText),
        ),
      ],
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'تركيب',
              icon: Icons.build_circle_outlined,
              selected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: _ModeButton(
              label: 'فك تركيب',
              icon: Icons.undo_outlined,
              selected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primaryColor : Colors.white;
    final fg = selected ? Colors.white : AppColors.primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7.r),
      child: Container(
        height: 42.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18.sp, color: fg),
            SizedBox(width: 5.w),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSummaryTile extends StatelessWidget {
  const _ProductSummaryTile({required this.product, this.variantLabel});

  final ProductModel? product;
  final String? variantLabel;

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return const _EmptyHint(
          text: 'اختر المنتج الذي ستزيد كميته بعد التركيب.');
    }
    return _PlainTile(
      title: product!.nameAr,
      subtitle: [
        'المخزون الحالي: ${product!.stock}',
        if (variantLabel != null && variantLabel!.trim().isNotEmpty)
          variantLabel!,
      ].join(' | '),
      trailing: product!.displayProductCode,
    );
  }
}

class _ComponentTile extends StatelessWidget {
  const _ComponentTile({
    required this.line,
    required this.onChanged,
    required this.onRemove,
  });

  final _AssemblyComponentLine line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Expanded(
            child: _PlainTile(
              title: line.product.nameAr,
              subtitle: [
                'المخزون: ${line.product.stock}',
                if (line.variantLabel != null &&
                    line.variantLabel!.trim().isNotEmpty)
                  line.variantLabel!,
                'تكلفة الوحدة: ${_money(line.product.purchaseCost)}',
              ].join(' | '),
              trailing: 'المجموع: ${_money(line.totalCost)}',
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            width: 72.w,
            child: TextField(
              controller: line.quantityController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'كمية',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class _CostPanel extends StatelessWidget {
  const _CostPanel({
    required this.componentsCost,
    required this.additionalCost,
    required this.unitCost,
    required this.totalCost,
    required this.runs,
  });

  final double componentsCost;
  final double additionalCost;
  final double unitCost;
  final double totalCost;
  final int runs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryRow(label: 'تكلفة المكونات', value: _money(componentsCost)),
          SizedBox(height: 6.h),
          _SummaryRow(
              label: 'تكلفة إضافية للقطعة', value: _money(additionalCost)),
          SizedBox(height: 6.h),
          _SummaryRow(label: 'تكلفة القطعة الواحدة', value: _money(unitCost)),
          SizedBox(height: 6.h),
          _SummaryRow(label: 'عدد القطع الناتجة', value: '$runs'),
          SizedBox(height: 6.h),
          _SummaryRow(label: 'إجمالي تكلفة العملية', value: _money(totalCost)),
        ],
      ),
    );
  }
}

class _RecipePreview extends StatelessWidget {
  const _RecipePreview({
    required this.recipe,
    required this.quantity,
  });

  final ProductAssemblyRecipeModel recipe;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final targetVariant = [recipe.targetSize, recipe.targetColorAr]
        .where((value) => value != null && value.trim().isNotEmpty)
        .join(' / ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlainTile(
          title: recipe.targetProductName,
          subtitle: targetVariant.isEmpty
              ? 'سيتم خصم $quantity من المنتج المركّب'
              : 'سيتم خصم $quantity من المنتج المركّب | $targetVariant',
          trailing: 'تكلفة: ${_money(recipe.unitCost * quantity)}',
        ),
        SizedBox(height: 10.h),
        Text(
          'المكونات التي سترجع للمخزون',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8.h),
        ...recipe.items.map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: _PlainTile(
              title: item.componentProductName,
              subtitle: [
                'لكل قطعة: ${_qty(item.quantityPerUnit)}',
                'الراجع: ${_qty(item.quantityPerUnit * quantity)}',
                [item.componentSize, item.componentColorAr]
                    .where((value) => value != null && value.trim().isNotEmpty)
                    .join(' / '),
              ].where((value) => value.isNotEmpty).join(' | '),
              trailing: _money(item.unitCost * item.quantityPerUnit * quantity),
            ),
          ),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    this.allowDecimal = false,
  });

  final String label;
  final TextEditingController controller;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'ملاحظة',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _PlainTile extends StatelessWidget {
  const _PlainTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 10.sp, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            trailing,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }
}

String _money(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(2);
}

String _recipeSelectedLabel(ProductAssemblyRecipeModel recipe) {
  return '${recipe.targetProductName} - وصفة #${recipe.id}';
}

String _recipeDetailsLabel(ProductAssemblyRecipeModel recipe) {
  final variant = [recipe.targetSize, recipe.targetColorAr]
      .where((value) => value != null && value.trim().isNotEmpty)
      .join(' / ');
  final parts = <String>[
    if (variant.isNotEmpty) variant,
    'تكلفة ${_money(recipe.unitCost)}',
    if (recipe.additionalCost > 0) 'إضافي ${_money(recipe.additionalCost)}',
    '${recipe.items.length} مكوّن',
    if ((recipe.createdAt ?? '').trim().isNotEmpty) recipe.createdAt!.trim(),
  ];
  return parts.join(' | ');
}

String _qty(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(3);
}
