import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/expentions.dart';
import '../../data/models/all_stock_products_model.dart';
import '../../domain/stock_product_filters.dart';
import '../controllers/stock_controller.dart';
import 'product_card.dart';
import 'stock_product_grid_layout.dart';

class SaleBlockedProductsTab extends StatefulWidget {
  const SaleBlockedProductsTab({Key? key}) : super(key: key);

  @override
  State<SaleBlockedProductsTab> createState() => _SaleBlockedProductsTabState();
}

class _SaleBlockedProductsTabState extends State<SaleBlockedProductsTab> {
  final _search = TextEditingController();
  final _rows = <AllStockProductsModel>[];
  Timer? _debounce;
  int _ticket = 0;
  int _page = 0;
  int _total = 0;
  bool _loading = true;
  bool _hasMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _ticket++;
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load({bool more = false}) async {
    final ticket = ++_ticket;
    setState(() {
      _loading = true;
      _error = null;
      if (!more) _rows.clear();
    });
    try {
      final result =
          await Get.find<StockController>().stockDatasource.getAllStock(
                page: more ? _page + 1 : 1,
                perPage: 30,
                ifCombinations: false,
                ifCloseouts: false,
                filters: StockProductFilters(
                  search: _search.text.trim(),
                  saleStatus: 'blocked',
                ),
              );
      if (!mounted || ticket != _ticket) return;
      setState(() {
        _rows.addAll(result.products);
        _total = result.total;
        _page = result.currentPage;
        _hasMore = result.currentPage < result.lastPage;
      });
    } on ServerException catch (e) {
      if (mounted && ticket == _ticket) {
        setState(() => _error = e.errorModel.errorMessage);
      }
    } catch (_) {
      if (mounted && ticket == _ticket) {
        setState(() => _error = 'تعذر تحميل المنتجات');
      }
    } finally {
      if (mounted && ticket == _ticket) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _search,
            onChanged: _onSearch,
            decoration: const InputDecoration(
              labelText: 'البحث في الممنوع من البيع',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text('الممنوع من البيع: $_total منتج')),
            IconButton(
              tooltip: 'تحديث',
              onPressed: _loading ? null : () => _load(),
              icon: const Icon(Icons.refresh),
            ),
          ]),
          if (_error != null) ...[
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            TextButton(
                onPressed: () => _load(), child: const Text('إعادة المحاولة')),
          ] else if (!_loading && _rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('لا توجد منتجات ممنوعة من البيع',
                  textAlign: TextAlign.center),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: StockProductGridLayout.delegate(
              context: context,
              aspectRatio:
                  StockProductGridLayout.aspectRatioForTab(0, context: context),
            ),
            itemCount: _rows.length,
            itemBuilder: (_, index) =>
                BuildProductCard(product: _rows[index], isCloseouts: false),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasMore)
            TextButton(
                onPressed: () => _load(more: true),
                child: const Text('تحميل المزيد')),
          const SizedBox(height: 72),
        ],
      ),
    );
  }
}
