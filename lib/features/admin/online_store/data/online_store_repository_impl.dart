import '../../../../core/databases/api/end_points.dart';
import '../domain/online_store_repository.dart';
import 'online_store_datasource.dart';
import 'online_store_models.dart';
import 'package:image_picker/image_picker.dart';

class OnlineStoreRepositoryImpl implements OnlineStoreRepository {
  const OnlineStoreRepositoryImpl(this.datasource);
  final OnlineStoreDatasource datasource;

  @override
  Future<Map<String, dynamic>> get(String path,
          {Map<String, dynamic>? query}) =>
      datasource.get(path, query: query);
  @override
  Future<Map<String, dynamic>> post(String path,
          {Map<String, dynamic>? data}) =>
      datasource.post(path, data: data);
  @override
  Future<Map<String, dynamic>> patch(String path,
          {Map<String, dynamic>? data}) =>
      datasource.patch(path, data: data);
  @override
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? data}) =>
      datasource.put(path, data: data);
  @override
  Future<Map<String, dynamic>> delete(String path,
          {Map<String, dynamic>? data}) =>
      datasource.delete(path, data: data);

  @override
  Future<OnlineStorePage<OnlineStoreListing>> listings(
          {String? status}) async =>
      OnlineStorePage.fromJson(
        await datasource.listings(status: status),
        (json) => OnlineStoreListing.fromJson(json),
      );

  @override
  Future<List<OnlineStoreListing>> allListings() async {
    final result = <OnlineStoreListing>[];
    var page = 1;
    var lastPage = 1;
    do {
      final json = await datasource.get(
        EndPoints.onlineStoreListings,
        query: {'page': page},
      );
      result.addAll(onlineStoreRows(json['data'])
          .map((row) => OnlineStoreListing.fromJson(row)));
      final meta = onlineStoreMap(json['meta']);
      lastPage = (meta['last_page'] as num?)?.toInt() ??
          int.tryParse('${meta['last_page'] ?? 1}') ??
          1;
      page++;
    } while (page <= lastPage);
    return result;
  }

  @override
  Future<List<OnlineStoreEntity>> allEntities(String path) async {
    final result = <OnlineStoreEntity>[];
    var page = 1;
    var lastPage = 1;
    do {
      final json = await datasource.get(path, query: {'page': page});
      result.addAll(onlineStoreRows(json['data'])
          .map((row) => OnlineStoreEntity.fromJson(row)));
      final meta = onlineStoreMap(json['meta']);
      final lastPageValue = meta['last_page'] ?? json['last_page'];
      lastPage = (lastPageValue as num?)?.toInt() ??
          int.tryParse('${lastPageValue ?? 1}') ??
          1;
      page++;
    } while (page <= lastPage);
    return result;
  }

  @override
  Future<OnlineStoreListing> listing(int id) async =>
      OnlineStoreListing.fromJson(_data(await datasource.listing(id)));

  @override
  Future<OnlineStoreListing> createListing(int productId) async =>
      OnlineStoreListing.fromJson(
          _data(await datasource.createListing(productId)));

  @override
  Future<OnlineStoreListing> updateListing(
          int id, Map<String, dynamic> payload) async =>
      OnlineStoreListing.fromJson(_data(
          await patch('${EndPoints.onlineStoreListings}/$id', data: payload)));

  @override
  Future<OnlineStoreListing> transitionListing(int id, String status,
          {String? updatedAt}) async =>
      OnlineStoreListing.fromJson(_data(await datasource.transitionListing(
        id,
        status,
        updatedAt: updatedAt,
      )));

  @override
  Future<OnlineStoreDashboardSummary> dashboard() async =>
      OnlineStoreDashboardSummary.fromJson(
          await get(EndPoints.onlineStoreDashboard));

  @override
  Future<List<OnlineStoreAccount>> accounts({String? search}) async {
    final json = await get(EndPoints.onlineStoreAccounts, query: {
      if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
    });
    return onlineStoreRows(json['data'])
        .map((json) => OnlineStoreAccount.fromJson(json))
        .toList(growable: false);
  }

  @override
  Future<void> reorderCategories(List<int> categoryIds) async {
    await datasource.reorderCategories(categoryIds);
  }

  @override
  Future<void> reorderHomeSections(List<int> sectionIds) async {
    await datasource.reorderHomeSections(sectionIds);
  }

  @override
  Future<void> reorderBanners(List<int> bannerIds) async {
    await datasource.reorderBanners(bannerIds);
  }

  @override
  Future<String> uploadContentImage(XFile file) async {
    final json = await datasource.uploadContentImage(file);
    final path = '${onlineStoreMap(json['data'])['image_path'] ?? ''}';
    if (path.isEmpty) {
      throw const FormatException('لم يرجع الخادم مسار الصورة.');
    }
    return path;
  }

  @override
  Future<List<OnlineStoreParty>> parties(String role) async {
    final endpoint =
        role == 'seller' ? EndPoints.all_sellers : EndPoints.all_customers;
    final json = await datasource.get(endpoint);
    final key = endpoint.replaceAll('/', '_');
    return onlineStoreRows(json[key])
        .map((json) => OnlineStoreParty.fromJson(json))
        .toList(growable: false);
  }

  Map<String, dynamic> _data(Map<String, dynamic> json) =>
      onlineStoreMap(json['data']).isEmpty
          ? json
          : onlineStoreMap(json['data']);
}
