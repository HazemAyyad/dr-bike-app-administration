import 'all_stock_products_model.dart';
import 'store_section_model.dart';

class ProductsByLocationResult {
  final StoreSectionModel? section;
  final List<AllStockProductsModel> products;
  final int currentPage;
  final int lastPage;
  final int total;

  ProductsByLocationResult({
    required this.section,
    required this.products,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}
