import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../data/datasources/stock_datasource.dart';
import '../../data/models/product_assembly_model.dart';

class ProductAssemblyOperationsArgs {
  const ProductAssemblyOperationsArgs({
    required this.productId,
    required this.productName,
  });

  final String productId;
  final String productName;

  factory ProductAssemblyOperationsArgs.fromDynamic(dynamic raw) {
    if (raw is ProductAssemblyOperationsArgs) return raw;
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      return ProductAssemblyOperationsArgs(
        productId: '${m['productId'] ?? ''}',
        productName: '${m['productName'] ?? ''}',
      );
    }
    return const ProductAssemblyOperationsArgs(productId: '', productName: '');
  }
}

class ProductAssemblyOperationsScreen extends StatefulWidget {
  const ProductAssemblyOperationsScreen({Key? key}) : super(key: key);

  @override
  State<ProductAssemblyOperationsScreen> createState() =>
      _ProductAssemblyOperationsScreenState();
}

class _ProductAssemblyOperationsScreenState
    extends State<ProductAssemblyOperationsScreen> {
  late final ProductAssemblyOperationsArgs args;
  List<ProductAssemblyOperationModel> operations = [];
  var loading = true;

  StockDatasource get _datasource => Get.find<StockDatasource>();

  @override
  void initState() {
    super.initState();
    args = ProductAssemblyOperationsArgs.fromDynamic(Get.arguments);
    _load();
  }

  Future<void> _load() async {
    if (args.productId.isEmpty) {
      setState(() => loading = false);
      return;
    }
    setState(() => loading = true);
    final rows = await _datasource.getAssemblyOperationsForProduct(
      productId: args.productId,
    );
    if (!mounted) return;
    setState(() {
      operations = rows;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminUiColors.scaffoldBackground(context),
      appBar: CustomAppBar(
        title: 'سجل التركيب',
        action: false,
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : operations.isEmpty
              ? const Center(child: ShowNoData())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                    children: [
                      if (args.productName.trim().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: Text(
                            args.productName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      _AssemblyOperationsSummary(operations: operations),
                      SizedBox(height: 12.h),
                      ...operations.map(
                        (operation) => _AssemblyOperationCard(
                          operation: operation,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _AssemblyOperationsSummary extends StatelessWidget {
  const _AssemblyOperationsSummary({required this.operations});

  final List<ProductAssemblyOperationModel> operations;

  @override
  Widget build(BuildContext context) {
    final totalQty = operations.fold<int>(0, (sum, op) => sum + op.quantity);
    final totalCost =
        operations.fold<double>(0, (sum, op) => sum + op.totalCost);
    final totalComponents = operations.fold<int>(
      0,
      (sum, op) => sum + op.items.length,
    );

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          _AssemblyInfoChip(label: 'العمليات', value: '${operations.length}'),
          _AssemblyInfoChip(label: 'الكمية المركبة', value: '$totalQty'),
          _AssemblyInfoChip(label: 'المكونات', value: '$totalComponents'),
          _AssemblyInfoChip(label: 'إجمالي التكلفة', value: _money(totalCost)),
        ],
      ),
    );
  }
}

class _AssemblyOperationCard extends StatelessWidget {
  const _AssemblyOperationCard({required this.operation});

  final ProductAssemblyOperationModel operation;

  @override
  Widget build(BuildContext context) {
    final variant = [operation.targetSize, operation.targetColorAr]
        .where((value) => value != null && value.trim().isNotEmpty)
        .join(' / ');

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.precision_manufacturing_outlined,
                  size: 19.sp, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'عملية تركيب #${operation.id}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                operation.createdAt ?? '',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              _AssemblyInfoChip(label: 'العدد', value: '${operation.quantity}'),
              _AssemblyInfoChip(
                label: 'تكلفة الوحدة',
                value: _money(operation.unitCost),
              ),
              _AssemblyInfoChip(
                label: 'الإجمالي',
                value: _money(operation.totalCost),
              ),
              if (operation.additionalCost > 0)
                _AssemblyInfoChip(
                  label: 'تكلفة إضافية',
                  value: _money(operation.additionalCost),
                ),
              if (variant.isNotEmpty)
                _AssemblyInfoChip(label: 'المقاس/اللون', value: variant),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'المكونات المستخدمة',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6.h),
          ...operation.items.map(
            (item) => _AssemblyOperationItemTile(item: item),
          ),
        ],
      ),
    );
  }
}

class _AssemblyOperationItemTile extends StatelessWidget {
  const _AssemblyOperationItemTile({required this.item});

  final ProductAssemblyOperationItemModel item;

  @override
  Widget build(BuildContext context) {
    final variant = [item.componentSize, item.componentColorAr]
        .where((value) => value != null && value.trim().isNotEmpty)
        .join(' / ');

    return Container(
      margin: EdgeInsets.only(top: 6.h),
      padding: EdgeInsets.all(9.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(7.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.remove_circle_outline,
              size: 16.sp, color: Colors.red.shade600),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.componentProductName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  [
                    'لكل قطعة ${_qty(item.quantityPerUnit)}',
                    'المستخدم ${_qty(item.totalQuantity)}',
                    'تكلفة الوحدة ${_money(item.unitCost)}',
                    'الإجمالي ${_money(item.totalCost)}',
                    if (variant.isNotEmpty) variant,
                  ].join(' | '),
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    color: Colors.grey.shade700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssemblyInfoChip extends StatelessWidget {
  const _AssemblyInfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _money(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

String _qty(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(3);
}
