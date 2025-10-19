
class StockServices {
  int page = 1;

  // final RxList<AllStockProductsModel> allProducts =
  //     <AllStockProductsModel>[].obs;

  // final RxList<AllStockProductsModel> allClearances =
  //     <AllStockProductsModel>[].obs;

  // final RxList<AllStockProductsModel> allCombinations =
  //     <AllStockProductsModel>[].obs;

  // singleton pattern
  static final StockServices _instance = StockServices._internal();
  factory StockServices() => _instance;
  StockServices._internal();
}
