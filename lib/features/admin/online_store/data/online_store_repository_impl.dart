import '../../../../core/databases/api/end_points.dart';
import '../domain/online_store_repository.dart';
import 'online_store_datasource.dart';
import 'online_store_models.dart';

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

  Map<String, dynamic> _data(Map<String, dynamic> json) =>
      onlineStoreMap(json['data']).isEmpty
          ? json
          : onlineStoreMap(json['data']);
}
