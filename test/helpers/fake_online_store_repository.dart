import 'package:doctorbike/features/admin/online_store/data/online_store_models.dart';
import 'package:doctorbike/features/admin/online_store/domain/online_store_repository.dart';
import 'package:image_picker/image_picker.dart';

class FakeOnlineStoreRepository implements OnlineStoreRepository {
  final responses = <String, Map<String, dynamic>>{};
  final calls = <String>[];
  Map<String, dynamic>? lastData;
  Map<String, dynamic>? lastQuery;

  @override
  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? query}) async {
    calls.add('GET $path');
    lastQuery = query;
    return responses['GET $path'] ?? <String, dynamic>{'data': []};
  }

  @override
  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? data}) async {
    calls.add('POST $path');
    lastData = data;
    return responses['POST $path'] ?? <String, dynamic>{'data': {}};
  }

  @override
  Future<Map<String, dynamic>> patch(String path,
      {Map<String, dynamic>? data}) async {
    calls.add('PATCH $path');
    lastData = data;
    return responses['PATCH $path'] ?? <String, dynamic>{'data': {}};
  }

  @override
  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? data}) async {
    calls.add('PUT $path');
    lastData = data;
    return responses['PUT $path'] ?? <String, dynamic>{'data': {}};
  }

  @override
  Future<Map<String, dynamic>> delete(String path,
      {Map<String, dynamic>? data}) async {
    calls.add('DELETE $path');
    lastData = data;
    return responses['DELETE $path'] ?? <String, dynamic>{'data': {}};
  }

  @override
  Future<List<OnlineStoreAccount>> accounts({String? search}) async {
    lastQuery = {'search': search};
    return onlineStoreRows(responses['accounts']?['data'])
        .map((row) => OnlineStoreAccount.fromJson(row))
        .toList();
  }

  @override
  Future<OnlineStoreDashboardSummary> dashboard() async =>
      OnlineStoreDashboardSummary.fromJson(
          responses['dashboard'] ?? <String, dynamic>{});

  @override
  Future<OnlineStoreListing> createListing(int productId) async {
    lastData = {'product_id': productId};
    return OnlineStoreListing.fromJson(responses['create'] ??
        {
          'id': 1,
          'product_id': productId,
          'status': 'draft',
        });
  }

  @override
  Future<OnlineStoreListing> listing(int id) async =>
      OnlineStoreListing.fromJson(responses['listing'] ?? {'id': id});

  @override
  Future<OnlineStorePage<OnlineStoreListing>> listings(
          {String? status}) async =>
      OnlineStorePage.fromJson(
        responses['listings'] ?? <String, dynamic>{'data': []},
        (row) => OnlineStoreListing.fromJson(row),
      );

  @override
  Future<List<OnlineStoreListing>> allListings() async {
    calls.add('GET ALL online-store/listings');
    return (await listings()).items;
  }

  @override
  Future<List<OnlineStoreEntity>> allEntities(String path) async =>
      onlineStoreRows(responses['GET $path']?['data'])
          .map((row) => OnlineStoreEntity.fromJson(row))
          .toList(growable: false);

  @override
  Future<OnlineStoreListing> transitionListing(int id, String status,
      {String? updatedAt}) async {
    lastData = {'status': status, 'updated_at': updatedAt};
    return OnlineStoreListing.fromJson(responses['transition'] ??
        {
          'id': id,
          'product_id': 1,
          'status': status,
          'updated_at': updatedAt,
        });
  }

  @override
  Future<OnlineStoreListing> updateListing(
      int id, Map<String, dynamic> payload) async {
    lastData = payload;
    return OnlineStoreListing.fromJson(responses['update'] ??
        {
          'id': id,
          'product_id': 1,
          'status': 'draft',
          ...payload,
        });
  }

  @override
  Future<void> reorderCategories(List<int> categoryIds) async {
    calls.add('POST online-store/categories/reorder');
    lastData = {'category_ids': categoryIds};
  }

  @override
  Future<void> reorderHomeSections(List<int> sectionIds) async {
    calls.add('POST online-store/home-sections/reorder');
    lastData = {'section_ids': sectionIds};
  }

  @override
  Future<void> reorderBanners(List<int> bannerIds) async {
    calls.add('POST online-store/banners/reorder');
    lastData = {'banner_ids': bannerIds};
  }

  @override
  Future<String> uploadContentImage(XFile file) async {
    calls.add('POST online-store/content-images');
    lastData = {'file': file.path};
    return responses['upload']?['image_path'] ??
        'public/OnlineStore/Content/banner.jpg';
  }

  @override
  Future<String> uploadProductImage(XFile file) async {
    calls.add('POST online-store/product-images');
    lastData = {'file': file.path};
    return responses['product-upload']?['image_path'] ??
        'public/OnlineStore/Products/product.jpg';
  }

  @override
  Future<List<OnlineStoreParty>> parties(String role) async {
    calls.add('GET ${role == 'seller' ? 'all/sellers' : 'all/customers'}');
    return onlineStoreRows(responses['parties:$role']?['data'])
        .map((json) => OnlineStoreParty.fromJson(json))
        .toList(growable: false);
  }

  @override
  Future<List<OnlineStoreProductCandidate>> productCandidates(
      {String? search}) async {
    calls.add('GET all/products');
    lastQuery = {
      if (search?.trim().isNotEmpty == true) 'search': search!.trim()
    };
    return onlineStoreRows(responses['products']?['products'])
        .map((row) => OnlineStoreProductCandidate.fromJson(row))
        .toList(growable: false);
  }
}
