import 'package:dio/dio.dart';
import '../../../../core/databases/api/dio_consumer.dart';
import '../../../../core/databases/api/end_points.dart';
import 'sales_return_models.dart';

class SalesReturnsApiService {
  SalesReturnsApiService(this._api);
  final DioConsumer _api;

  Future<List<SalesReturnPerson>> people({String? search}) async {
    final Response response = await _api.get(EndPoints.salesReturnPeople,
        queryParameters: {
          if (search?.trim().isNotEmpty == true) 'search': search!.trim()
        });
    final map = _map(response.data);
    _ensureSuccess(map);
    return (map['people'] as List? ?? const [])
        .whereType<Map>()
        .map(
            (row) => SalesReturnPerson.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<SalesReturnAvailableItem>> availableItems(
      SalesReturnPerson person) async {
    final Response response = await _api.get(
        EndPoints.salesReturnAvailableItems,
        queryParameters: {'person_type': person.type, 'person_id': person.id});
    final map = _map(response.data);
    _ensureSuccess(map);
    return (map['items'] as List? ?? const [])
        .whereType<Map>()
        .map((row) =>
            SalesReturnAvailableItem.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final Response response =
        await _api.post(EndPoints.salesReturn, data: payload);
    final map = _map(response.data);
    _ensureSuccess(map);
    return map;
  }

  Future<Map<String, dynamic>> update(Map<String, dynamic> payload) async {
    final Response response =
        await _api.put(EndPoints.salesReturn, data: payload);
    final map = _map(response.data);
    _ensureSuccess(map);
    return map;
  }

  Future<void> cancel({required int id, required String reason}) async {
    final Response response = await _api.post(
      EndPoints.salesReturnCancel,
      data: {'sales_return_id': id, 'reason': reason},
    );
    _ensureSuccess(_map(response.data));
  }

  Future<List<SalesReturnRecord>> list({required String date}) async {
    final Response response = await _api.get(
      EndPoints.salesReturns,
      queryParameters: {'date': date, 'per_page': 100},
    );
    final map = _map(response.data);
    _ensureSuccess(map);
    final payload = map['sales_returns'];
    final rows = payload is Map ? payload['data'] : payload;
    return (rows as List? ?? const [])
        .whereType<Map>()
        .map(
            (row) => SalesReturnRecord.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<SalesReturnRecord> show(int id) async {
    final Response response = await _api.get(
      EndPoints.salesReturn,
      queryParameters: {'sales_return_id': id},
    );
    final map = _map(response.data);
    _ensureSuccess(map);
    return SalesReturnRecord.fromJson(
      Map<String, dynamic>.from(map['sales_return'] as Map),
    );
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};
  void _ensureSuccess(Map<String, dynamic> map) {
    if (map['status'] != 'success') {
      throw Exception('${map['message'] ?? 'تعذر تنفيذ العملية.'}');
    }
  }
}
