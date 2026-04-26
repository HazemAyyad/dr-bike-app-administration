import '../data/datasources/stock_datasource.dart';
import '../data/models/product_tag_model.dart';
import '../data/models/products_by_tag_result.dart';

class StockTagsInteractor {
  StockTagsInteractor(this._ds);

  final StockDatasource _ds;

  Future<List<ProductTagModel>> loadTags({bool includeInactive = false}) =>
      _ds.getProductTags(includeInactive: includeInactive);

  Future<ProductsByTagResult> loadProductsByTag({
    required String tagId,
    required int page,
  }) =>
      _ds.getProductsByTag(tagId: tagId, page: page);

  Future<ProductTagModel> createTag({
    required String name,
    required String color,
  }) =>
      _ds.createProductTag(name: name, color: color);

  Future<void> updateTag({
    required String id,
    String? name,
    String? color,
  }) =>
      _ds.updateProductTag(id: id, name: name, color: color);

  Future<void> deactivateTag(String id) =>
      _ds.deactivateProductTag(id: id);
}
