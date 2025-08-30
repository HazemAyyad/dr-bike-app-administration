import 'package:get/get.dart';

class Product {
  final String id;
  final String name;
  final String? imageUrl;
  final int quantity;
  final double price;
  final String category;

  Product({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.quantity,
    required this.price,
    required this.category,
  });
}

class StockController extends GetxController {
  final tabs = ['products', 'clearance', 'productComposition'].obs;

  final currentTab = 0.obs;

  void changeTab(int index) {
    currentTab.value = index;
  }

  // State variables
  final RxList<Product> _products = <Product>[].obs;
  final RxList<String> categories = <String>[
    'الكل',
    'قطع غيار',
    'إطارات',
    'زيوت',
    'إكسسوارات',
  ].obs;

  final RxInt selectedCategoryIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  // Getters
  List<Product> get products => _products;

  @override
  void onInit() {
    super.onInit();
    // Load initial data
    loadProducts();
  }

  // Load products from repository/API
  Future<void> loadProducts() async {
    try {
      isLoading.value = true;
      // TODO: Replace with actual API call
      await Future.delayed(
          const Duration(seconds: 1)); // Simulate network delay

      // Mock data - replace with actual data from your data source
      _products.assignAll([
        Product(
          id: '1',
          name: 'إطار دراجة هوائية',
          quantity: 15,
          price: 199.99,
          category: 'إطارات',
          imageUrl: 'https://example.com/tire.jpg',
        ),
        Product(
          id: '2',
          name: 'زيت محرك دراجة',
          quantity: 30,
          price: 49.99,
          category: 'زيوت',
        ),
        // Add more mock products as needed
      ]);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحميل المنتجات');
    } finally {
      isLoading.value = false;
    }
  }

  // Filter products by selected category
  List<Product> get filteredProducts {
    if (selectedCategoryIndex.value == 0) {
      return _products;
    }
    final selectedCategory = categories[selectedCategoryIndex.value];
    return _products
        .where((product) => product.category == selectedCategory)
        .toList();
  }

  // Search products
  List<Product> get searchedProducts {
    if (searchQuery.value.isEmpty) return filteredProducts;
    return filteredProducts
        .where((product) => product.name
            .toLowerCase()
            .contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  // Category selection
  void selectCategory(int index) {
    selectedCategoryIndex.value = index;
  }

  // Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  // Add new product
  Future<void> addProduct(Product product) async {
    try {
      // TODO: Implement add product to API
      _products.add(product);
      Get.back(); // Close add product dialog
      Get.snackbar('نجاح', 'تمت إضافة المنتج بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إضافة المنتج');
    }
  }

  // Update product
  Future<void> updateProduct(Product updatedProduct) async {
    try {
      // TODO: Implement update product in API
      final index = _products.indexWhere((p) => p.id == updatedProduct.id);
      if (index != -1) {
        _products[index] = updatedProduct;
        _products.refresh();
        Get.back(); // Close edit dialog
        Get.snackbar('نجاح', 'تم تحديث المنتج بنجاح');
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحديث المنتج');
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      // TODO: Implement delete product from API
      _products.removeWhere((p) => p.id == productId);
      Get.snackbar('نجاح', 'تم حذف المنتج بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حذف المنتج');
    }
  }
}
