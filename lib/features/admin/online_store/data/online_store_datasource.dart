import 'package:dio/dio.dart';

import '../../../../core/databases/api/api_consumer.dart';
import '../../../../core/databases/api/end_points.dart';
import 'online_store_models.dart';

class OnlineStoreDatasource {
  const OnlineStoreDatasource({required this.api});
  final ApiConsumer api;

  Future<Map<String, dynamic>> get(String path,
          {Map<String, dynamic>? query}) async =>
      _unwrap(await api.get(path, queryParameters: query));
  Future<Map<String, dynamic>> post(String path,
          {Map<String, dynamic>? data}) async =>
      _unwrap(await api.post(path, data: data ?? const {}));
  Future<Map<String, dynamic>> patch(String path,
          {Map<String, dynamic>? data}) async =>
      _unwrap(await api.patch(path, data: data ?? const {}));
  Future<Map<String, dynamic>> put(String path,
          {Map<String, dynamic>? data}) async =>
      _unwrap(await api.put(path, data: data ?? const {}));
  Future<Map<String, dynamic>> delete(String path,
          {Map<String, dynamic>? data}) async =>
      _unwrap(await api.delete(path, data: data));

  Future<Map<String, dynamic>> listings({String? status}) => get(
        EndPoints.onlineStoreListings,
        query: {if (status != null && status != 'all') 'status': status},
      );
  Future<Map<String, dynamic>> listing(int id) =>
      get('${EndPoints.onlineStoreListings}/$id');
  Future<Map<String, dynamic>> createListing(int productId) =>
      post(EndPoints.onlineStoreListings, data: {'product_id': productId});
  Future<Map<String, dynamic>> transitionListing(int id, String status,
          {String? updatedAt}) =>
      post('${EndPoints.onlineStoreListings}/$id/transition', data: {
        'status': status,
        if (updatedAt != null) 'updated_at': updatedAt,
      });

  Map<String, dynamic> _unwrap(dynamic response) {
    final value = response is Response ? response.data : response;
    return onlineStoreMap(value);
  }
}
