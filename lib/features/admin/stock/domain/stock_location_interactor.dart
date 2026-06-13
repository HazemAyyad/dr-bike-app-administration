import '../data/datasources/stock_datasource.dart';
import 'product_location_utils.dart';
import '../data/models/products_by_location_result.dart';
import '../data/models/store_section_model.dart';

class StockLocationInteractor {
  StockLocationInteractor(this._ds);

  final StockDatasource _ds;

  Future<List<StoreSectionModel>> loadSections({
    bool includeInactive = false,
  }) =>
      _ds.getStoreSections(includeInactive: includeInactive);

  Future<ProductsByLocationResult> loadProductsByLocation({
    required String sectionId,
    required int page,
  }) =>
      _ds.getProductsByLocation(
        sectionId: sectionId,
        page: page,
      );

  Future<StoreSectionModel> createSection({
    required String name,
    int sortOrder = 0,
  }) =>
      _ds.createStoreSection(name: name, sortOrder: sortOrder);

  Future<void> deactivateSection(String id) =>
      _ds.deactivateStoreSection(id: id);

  Future<int> moveProducts({
    required List<int> productIds,
    required String sectionId,
  }) =>
      _ds.moveProductsLocation(
        productIds: productIds,
        sectionId: sectionId,
      );

  Future<int> swapProductGroups({
    required List<int> groupA,
    required List<int> groupB,
    required SwapGroupLocationTarget groupATarget,
    required SwapGroupLocationTarget groupBTarget,
  }) =>
      _ds.swapProductsLocation(
        groupA: groupA,
        groupB: groupB,
        groupATarget: groupATarget,
        groupBTarget: groupBTarget,
      );
}
