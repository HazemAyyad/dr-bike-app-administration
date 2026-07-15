import 'dart:async';

import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:doctorbike/features/admin/sales/data/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/datasources/stock_datasource.dart';
import '../../data/models/product_assembly_model.dart';
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
  final _noteController = TextEditingController();

  int _modeIndex = 0;
  ProductModel? _targetProduct;
  final List<_AssemblyComponentLine> _components = [];
  List<ProductAssemblyRecipeModel> _recipes = [];
  ProductAssemblyRecipeModel? _selectedRecipe;
  bool _recipesLoading = false;

  int get _runs => int.tryParse(_runsController.text.trim()) ?? 1;

  int get _disassembleQty =>
      int.tryParse(_disassembleQtyController.text.trim()) ?? 1;

  double get _unitCost {
    var total = 0.0;
    for (final line in _components) {
      total += line.product.purchaseCost * line.quantity;
    }
    return total;
  }

  double get _totalCost => _unitCost * _runs;

  @override
  void initState() {
    super.initState();
    _runsController.addListener(_refresh);
    _disassembleQtyController.addListener(_refresh);
    _loadRecipes();
  }

  @override
  void dispose() {
    _runsController.dispose();
    _disassembleQtyController.dispose();
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
    setState(() => _targetProduct = product);
  }

  Future<void> _addComponent() async {
    final product = await _openProductPicker(title: 'اختيار مكوّن');
    if (product == null) return;
    final qty = await _askQuantity(title: product.nameAr);
    if (qty == null || qty < 1) return;

    final index =
        _components.indexWhere((line) => line.product.id == product.id);
    setState(() {
      if (index >= 0) {
        _components[index].quantity += qty;
      } else {
        _components
            .add(_AssemblyComponentLine(product: product, quantity: qty));
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
        quantity: _runs,
        note: _noteController.text,
        components: _components
            .map((line) => {
                  'product_id': line.product.id,
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
        for (final line in _components) {
          line.dispose();
        }
        _components.clear();
        _runsController.text = '1';
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
      appBar: const CustomAppBar(
        title: 'newProductComposition',
        action: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.build_circle_outlined),
                  label: Text('تركيب'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.undo_outlined),
                  label: Text('فك تركيب'),
                ),
              ],
              selected: {_modeIndex},
              onSelectionChanged: (value) {
                setState(() => _modeIndex = value.first);
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 18.h),
              child: _modeIndex == 0 ? _buildAssembly() : _buildDisassembly(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        child: AppButton(
          text: _modeIndex == 0 ? 'تنفيذ التركيب' : 'تنفيذ فك التركيب',
          isLoading: _isSubmitting,
          isSafeArea: false,
          onPressed: _modeIndex == 0 ? _executeAssembly : _executeDisassembly,
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
          actionText: _targetProduct == null ? 'اختيار' : 'تغيير',
          onAction: _selectTarget,
        ),
        _ProductSummaryTile(product: _targetProduct),
        SizedBox(height: 14.h),
        _NumberField(
          label: 'عدد مرات التركيب',
          controller: _runsController,
        ),
        SizedBox(height: 14.h),
        _SectionTitle(
          title: 'المكونات',
          actionText: 'إضافة مكوّن',
          onAction: _addComponent,
        ),
        if (_components.isEmpty)
          const _EmptyHint(text: 'أضف المنتجات التي سيتم خصمها من المخزون.')
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
            items: _recipes
                .map(
                  (recipe) => DropdownMenuItem<int>(
                    value: recipe.id,
                    child: Text(
                      recipe.targetProductName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
              border: OutlineInputBorder(),
            ),
          ),
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
      builder: (_) => _AssemblyProductPicker(
        title: title,
        datasource: _datasource,
      ),
    );
  }

  Future<int?> _askQuantity({required String title}) async {
    final controller = TextEditingController(text: '1');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'الكمية',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, int.tryParse(controller.text.trim()) ?? 1);
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
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
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
          child: Column(
            children: [
              Text(
                widget.title,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'بحث عن منتج...',
                  border: OutlineInputBorder(),
                ),
                onChanged: _onSearch,
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        controller: scrollController,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.8,
                          crossAxisSpacing: 8.w,
                          mainAxisSpacing: 8.h,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return InkWell(
                            onTap: () => Navigator.pop(context, product),
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    product.nameAr,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Text(
                                    'المخزون: ${product.stock} | التكلفة: ${_money(product.purchaseCost)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      color: Colors.grey.shade700,
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
      },
    );
  }
}

class _AssemblyComponentLine {
  _AssemblyComponentLine({
    required this.product,
    required int quantity,
  }) : quantityController = TextEditingController(text: quantity.toString());

  final ProductModel product;
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

class _ProductSummaryTile extends StatelessWidget {
  const _ProductSummaryTile({required this.product});

  final ProductModel? product;

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return const _EmptyHint(text: 'اختر المنتج الذي ستزيد كميته بعد التركيب.');
    }
    return _PlainTile(
      title: product!.nameAr,
      subtitle: 'المخزون الحالي: ${product!.stock}',
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
              subtitle:
                  'المخزون: ${line.product.stock} | تكلفة الوحدة: ${_money(line.product.purchaseCost)}',
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
    required this.unitCost,
    required this.totalCost,
    required this.runs,
  });

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlainTile(
          title: recipe.targetProductName,
          subtitle: 'سيتم خصم $quantity من المنتج المركّب',
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
              subtitle:
                  'لكل قطعة: ${_qty(item.quantityPerUnit)} | الراجع: ${_qty(item.quantityPerUnit * quantity)}',
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
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
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

String _qty(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(3);
}
