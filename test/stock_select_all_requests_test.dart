import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctorbike/features/admin/stock/presentation/controllers/stock_controller.dart';
import 'package:doctorbike/features/admin/stock/data/datasources/stock_datasource.dart';
import 'package:doctorbike/features/admin/stock/data/models/all_stock_products_model.dart';
import 'package:doctorbike/features/admin/stock/domain/stock_location_interactor.dart';
import 'package:doctorbike/features/admin/stock/domain/usecases/get_all_stock_usecase.dart';
import 'package:doctorbike/features/admin/stock/domain/usecases/get_product_details_usecase.dart';
import 'package:doctorbike/features/admin/stock/domain/usecases/move_to_archive_usecase.dart';
import 'package:doctorbike/features/admin/stock/domain/usecases/get_archived_usecase.dart';
import 'package:doctorbike/features/admin/stock/domain/usecases/get_categories_usecase.dart';
import 'package:doctorbike/features/admin/stock/domain/usecases/get_main_categories_usecase.dart';
import 'package:doctorbike/features/admin/stock/domain/usecases/search_products_usecase.dart';
import 'package:doctorbike/features/admin/stock/domain/usecases/add_combination_usecase.dart';
import 'package:doctorbike/features/admin/stock/domain/usecases/save_product_full_usecase.dart';
import 'package:doctorbike/features/admin/stock/domain/usecases/get_product_size_options_usecase.dart';

class _GetAllStockUsecase extends Fake implements GetAllStockUsecase {}

class _GetProductDetailsUsecase extends Fake
    implements GetProductDetailsUsecase {}

class _MoveToArchiveUsecase extends Fake implements MoveToArchiveUsecase {}

class _GetArchivedUsecase extends Fake implements GetArchivedUsecase {}

class _GetCategoriesUsecase extends Fake implements GetCategoriesUsecase {}

class _GetMainCategoriesUsecase extends Fake
    implements GetMainCategoriesUsecase {}

class _SearchProductsUsecase extends Fake implements SearchProductsUsecase {}

class _AddCombinationUsecase extends Fake implements AddCombinationUsecase {}

class _SaveProductFullUsecase extends Fake implements SaveProductFullUsecase {}

class _GetProductSizeOptionsUsecase extends Fake
    implements GetProductSizeOptionsUsecase {}

class _StockDatasource extends Fake implements StockDatasource {}

class _StockLocationInteractor extends Fake
    implements StockLocationInteractor {}

class _Controller extends StockController {
  _Controller()
      : super(
          getAllStockUsecase: _GetAllStockUsecase(),
          getProductDetailsUsecase: _GetProductDetailsUsecase(),
          moveToArchiveUsecase: _MoveToArchiveUsecase(),
          getArchivedUsecase: _GetArchivedUsecase(),
          getCategoriesUsecase: _GetCategoriesUsecase(),
          getMainCategoriesUsecase: _GetMainCategoriesUsecase(),
          searchProductsUsecase: _SearchProductsUsecase(),
          addCombinationUsecase: _AddCombinationUsecase(),
          saveProductFullUsecase: _SaveProductFullUsecase(),
          getProductSizeOptionsUsecase: _GetProductSizeOptionsUsecase(),
          stockLocationInteractor: _StockLocationInteractor(),
          stockDatasource: _StockDatasource(),
        ) {
    currentTab.value = 3;
    deleteSelectionActive.value = true;
    selectedLocationSectionId.value = 'room';
    locationFilterProducts
        .add(AllStockProductsModel.fromJson({'product_id': 1}));
    locationProductsLastPage = 3;
  }

  int calls = 0;
  bool fail = false;
  Completer<void>? pending;
  @override
  Future<void> loadMoreLocationFilterProducts() async {
    calls++;
    if (pending != null) await pending!.future;
    if (fail) {
      return; // Real loader absorbs the request error without advancing.
    }
    locationProductsPage++;
    locationFilterProducts.add(AllStockProductsModel.fromJson({
      'product_id': locationProductsPage,
    }));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('select all stops after a failed page without selecting a partial list',
      () async {
    final controller = _Controller()..fail = true;
    controller.selectedProductIds.add('1');
    await controller.toggleAllLocationDeleteProducts();
    expect(controller.calls, 1);
    expect(controller.selectedProductIds, ['1']);
    // The user can retry; all pages are loaded and selected normally.
    controller.fail = false;
    await controller.toggleAllLocationDeleteProducts();
    expect(controller.calls, 3);
    expect(controller.selectedProductIds.toSet(), {'1', '2', '3'});
    await controller.toggleAllLocationDeleteProducts();
    expect(controller.selectedProductIds, isEmpty);
  });

  test('repeated taps do not start duplicate pagination', () async {
    final controller = _Controller()..pending = Completer<void>();
    final first = controller.toggleAllLocationDeleteProducts();
    await controller.toggleAllLocationDeleteProducts();
    expect(controller.calls, 1);
    controller.pending!.complete();
    await first;
    expect(controller.calls, 2);
    expect(controller.selectedProductIds.toSet(), {'1', '2', '3'});
  });

  test('changing the location cancels the old select-all operation', () async {
    final controller = _Controller()..pending = Completer<void>();
    final first = controller.toggleAllLocationDeleteProducts();
    controller.selectedLocationSectionId.value = 'other';
    controller.pending!.complete();
    await first;
    expect(controller.calls, 1);
    expect(controller.selectedProductIds, isEmpty);
  });
}
