import '../../../../../core/helpers/product_image_utils.dart';
import '../../../sales/data/models/product_model.dart';
import 'product_development_model.dart';

class ProductManagementListItem {
  final ProductModel product;
  final ProductDevelopmentModel? development;

  const ProductManagementListItem({
    required this.product,
    this.development,
  });

  bool get hasDevelopment => development != null;

  int? get developmentId => development?.id;

  String get productId => product.id;

  String get productName => product.nameAr;

  String get displayStep => development?.currentStep ?? '0';

  int get stepValue => int.tryParse(displayStep) ?? 0;

  String get productImage {
    final urls = productImageUrls;
    return urls.isEmpty ? '' : urls.first;
  }

  List<String> get productImageUrls {
    final fromProduct = product.allImageUrlsInPriority;
    if (fromProduct.isNotEmpty) {
      return fromProduct;
    }

    final devImage = development?.productImage;
    if (ProductImageUtils.isValidUrl(devImage)) {
      return [devImage!.trim()];
    }
    return const [];
  }

  String? get developmentDate =>
      development?.updatedAt.isNotEmpty == true
          ? development!.updatedAt
          : development?.createdAt;
}
