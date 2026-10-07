import '../data/online_store_models.dart';
import 'package:image_picker/image_picker.dart';

abstract class OnlineStoreRepository {
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query});
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data});
  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? data});
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? data});
  Future<Map<String, dynamic>> delete(String path,
      {Map<String, dynamic>? data});

  Future<OnlineStorePage<OnlineStoreListing>> listings({String? status});
  Future<List<OnlineStoreListing>> allListings();
  Future<List<OnlineStoreEntity>> allEntities(String path);
  Future<OnlineStoreListing> listing(int id);
  Future<OnlineStoreListing> createListing(int productId);
  Future<OnlineStoreListing> updateListing(
      int id, Map<String, dynamic> payload);
  Future<OnlineStoreListing> transitionListing(int id, String status,
      {String? updatedAt});
  Future<OnlineStoreDashboardSummary> dashboard();
  Future<List<OnlineStoreAccount>> accounts({String? search});
  Future<void> reorderCategories(List<int> categoryIds);
  Future<void> reorderHomeSections(List<int> sectionIds);
  Future<void> reorderBanners(List<int> bannerIds);
  Future<String> uploadContentImage(XFile file);
  Future<String> uploadProductImage(XFile file);
  Future<Map<String, dynamic>> uploadProductMedia(XFile file);
  Future<List<OnlineStoreParty>> parties(String role);
  Future<List<OnlineStoreProductCandidate>> productCandidates({String? search});
}
