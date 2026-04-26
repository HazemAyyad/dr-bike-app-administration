import 'all_stock_products_model.dart';
import 'product_tag_model.dart';

class ProductsByTagResult {
  final ProductTagModel? tag;
  final List<AllStockProductsModel> products;
  final int currentPage;
  final int lastPage;
  final int total;

  ProductsByTagResult({
    required this.tag,
    required this.products,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}
