import 'quick_edit_product_model.dart';

class QuickEditProductsPageResult {
  final List<QuickEditProductModel> products;
  final int currentPage;
  final int lastPage;
  final int total;

  QuickEditProductsPageResult({
    required this.products,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}
