import '../data/online_store_models.dart';

abstract class OnlineStoreRepository {
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query});
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data});
  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? data});
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? data});
  Future<Map<String, dynamic>> delete(String path,
      {Map<String, dynamic>? data});

  Future<OnlineStorePage<OnlineStoreListing>> listings({String? status});
  Future<OnlineStoreListing> listing(int id);
  Future<OnlineStoreListing> createListing(int productId);
  Future<OnlineStoreListing> updateListing(
      int id, Map<String, dynamic> payload);
  Future<OnlineStoreListing> transitionListing(int id, String status,
      {String? updatedAt});
  Future<OnlineStoreDashboardSummary> dashboard();
  Future<List<OnlineStoreAccount>> accounts({String? search});
}
