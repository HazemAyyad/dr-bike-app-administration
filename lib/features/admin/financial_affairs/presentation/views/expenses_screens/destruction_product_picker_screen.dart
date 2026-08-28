import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/show_no_data.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../stock/presentation/controllers/stock_controller.dart';
import '../../../../stock/data/models/all_stock_products_model.dart';
import '../../../../stock/presentation/widgets/stock_product_grid_layout.dart';
import '../../controllers/expenses_controller.dart';
import '../../widgets/financial_image_cache.dart';

class DestructionProductPickerScreen extends StatefulWidget {
  const DestructionProductPickerScreen({Key? key}) : super(key: key);

  @override
  State<DestructionProductPickerScreen> createState() =>
      _DestructionProductPickerScreenState();
}

class _DestructionProductPickerScreenState
    extends State<DestructionProductPickerScreen> {
  late final StockController stock;
  late final ExpensesController expenses;

  @override
  void initState() {
    super.initState();
    stock = Get.find<StockController>();
    expenses = Get.find<ExpensesController>();
    stock.searchProducts.clear();
    stock.stockSearchQueryController.clear();
    stock.stockSearchActiveQuery.value = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'اختيار منتج للإتلاف', action: false),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
            child: TextField(
              controller: stock.stockSearchQueryController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'ابحث باسم المنتج أو الباركود',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    stock.stockSearchQueryController.clear();
                    stock.onStockSearchQueryChanged('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
                filled: true,
                fillColor: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.customGreyColor7,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide.none),
              ),
              onChanged: (value) {
                stock.onStockSearchQueryChanged(value);
                if (value.trim().length >= 2) {
                  stock.getSearchProducts(name: value.trim());
                }
              },
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  stock.getSearchProducts(name: value.trim());
                }
              },
            ),
          ),
        ),
        GetBuilder<StockController>(builder: (_) {
          if (stock.isSearchLoading.value) {
            return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()));
          }
          if (stock.searchProducts.isEmpty) {
            return const SliverFillRemaining(
                hasScrollBody: false, child: ShowNoData());
          }
          return SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverGrid(
              gridDelegate: StockProductGridLayout.delegate(
                context: context,
                aspectRatio: StockProductGridLayout.aspectRatioForTab(0,
                    context: context),
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _DestructionPickerCard(
                  product: stock.searchProducts[index],
                  onTap: () async {
                    final product = stock.searchProducts[index];
                    expenses.productIdController.text = product.productId;
                    expenses.productNameController.text = product.name;
                    await expenses.addSelectedDestructionProduct();
                    if (context.mounted) Get.back();
                  },
                ),
                childCount: stock.searchProducts.length,
              ),
            ),
          );
        }),
      ]),
    );
  }
}

class _DestructionPickerCard extends StatelessWidget {
  const _DestructionPickerCard({required this.product, required this.onTap});
  final AllStockProductsModel product;
  final VoidCallback onTap;

  String _price(double value) => value == value.roundToDouble()
      ? '${value.toInt()}'
      : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final cost = product.costPrice ?? 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              flex: 5,
              child: Stack(fit: StackFit.expand, children: [
                CachedNetworkImage(
                  cacheManager: FinancialImageCache.instance,
                  imageUrl: product.preferredImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppColors.operationalSurface),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.operationalSurface,
                    child: Icon(Icons.inventory_2_outlined,
                        color: AppColors.operationalPurple, size: 24.sp),
                  ),
                ),
                PositionedDirectional(
                  bottom: 4.h,
                  end: 4.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .68),
                      borderRadius: BorderRadius.circular(7.r),
                    ),
                    child: Text('المتوفر ${product.stock}',
                        style: TextStyle(color: Colors.white, fontSize: 8.sp)),
                  ),
                ),
              ]),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(6.r),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              height: 1.15,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.operationalNavy)),
                      const Spacer(),
                      Text('تكلفة ${cost > 0 ? _price(cost) : '-'} ₪',
                          style: TextStyle(
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.operationalPurple)),
                      Text('بيع ${_price(product.normailPrice)} ₪',
                          style: TextStyle(
                              fontSize: 8.sp,
                              color: AppColors.customGreyColor5)),
                    ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
