import 'all_stock_products_model.dart';

class StockProductsPageResult {
  final List<AllStockProductsModel> products;
  final int currentPage;
  final int lastPage;
  final int total;

  StockProductsPageResult({
    required this.products,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}
