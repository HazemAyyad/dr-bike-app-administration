import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../../../../core/databases/api/dio_consumer.dart';

class MetaCatalogApiService {
  DioConsumer get _api => Get.find<DioConsumer>();
  static const _base = '/meta/catalog';

  Future<Map<String, dynamic>> getAccounts() => _get('$_base/accounts');
  Future<Map<String, dynamic>> getSyncSources() => _get('$_base/sync-sources');
  Future<Map<String, dynamic>> getStatus({int? accountId}) =>
      _get('$_base/status', query: _accountQuery(accountId));
  Future<Map<String, dynamic>> getProducts(
          {int page = 1, String? search, String? status, int? accountId}) =>
      _get('$_base/products', query: {
        'page': page,
        ..._accountQuery(accountId),
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        if (status != null && status != 'all') 'status': status,
      });
  Future<Map<String, dynamic>> getLogs(
          {int page = 1, String? status, String? action, int? accountId}) =>
      _get('$_base/sync-log', query: {
        'page': page,
        ..._accountQuery(accountId),
        if (status != null && status != 'all') 'status': status,
        if (action != null && action != 'all') 'action': action,
      });
  Future<Map<String, dynamic>> getProductSets(
          {int page = 1,
          String? search,
          String? status,
          String? type,
          int? accountId}) =>
      _get('$_base/product-sets', query: {
        'page': page,
        ..._accountQuery(accountId),
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        if (status != null && status != 'all') 'status': status,
        if (type != null && type != 'all') 'type': type,
      });
  Future<Map<String, dynamic>> syncHierarchy({int? accountId}) =>
      _post('$_base/sync-hierarchy', _accountQuery(accountId));
  Future<Map<String, dynamic>> syncProduct(int id, {int? accountId}) =>
      _post('$_base/products/$id/sync', _accountQuery(accountId));
  Future<Map<String, dynamic>> resyncProduct(int id, {int? accountId}) =>
      _post('$_base/products/$id/resync', _accountQuery(accountId));
  Future<Map<String, dynamic>> disableProduct(int id, {int? accountId}) =>
      _post('$_base/products/$id/disable', _accountQuery(accountId));
  Future<Map<String, dynamic>> bulkSync({
    int? accountId,
    String sourceType = 'all',
    int? sourceId,
  }) =>
      _post('$_base/bulk-sync', {
        ..._accountQuery(accountId),
        'source_type': sourceType,
        if (sourceId != null) 'source_id': sourceId,
      });
  Future<Map<String, dynamic>> testProduct(int id, {int? accountId}) =>
      _post('$_base/test-product', {
        'product_id': id,
        ..._accountQuery(accountId),
      });
  Future<Map<String, dynamic>> getSettings() => _get('$_base/settings');
  Future<Map<String, dynamic>> saveSettings(Map<String, dynamic> data) =>
      _post('$_base/settings', data);

  Future<Map<String, dynamic>> _get(String path,
      {Map<String, dynamic>? query}) async {
    final Response response = await _api.get(path, queryParameters: query);
    return _map(response.data);
  }

  Future<Map<String, dynamic>> _post(String path,
      [Map<String, dynamic>? data]) async {
    final Response response = await _api.post(path, data: data ?? {});
    return _map(response.data);
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};

  Map<String, dynamic> _accountQuery(int? accountId) => {
        if (accountId != null && accountId > 0)
          'whatsapp_account_id': accountId,
      };
}
