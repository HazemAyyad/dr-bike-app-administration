import 'package:doctorbike/features/admin/online_store/data/online_store_models.dart';
import 'package:doctorbike/features/admin/online_store/domain/online_store_repository.dart';

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
}
