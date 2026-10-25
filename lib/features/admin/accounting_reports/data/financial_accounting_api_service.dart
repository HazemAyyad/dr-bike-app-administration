import '../../../../core/databases/api/api_consumer.dart';
import '../../../../core/databases/api/end_points.dart';

class FinancialAccountingApiService {
  FinancialAccountingApiService({required this.api});
  final ApiConsumer api;

  Future<Map<String, dynamic>> load(
          String type, Map<String, dynamic> filters) =>
      _get('${EndPoints.financialAccountingReports}/$type', filters);

  Future<Map<String, dynamic>> detail(String key) {
    final parts = key.split(':');
    if (parts.length != 2 || int.tryParse(parts[1]) == null) {
      throw Exception('مرجع الحركة غير صالح');
    }
    return _get(
        '${EndPoints.financialAccountingReports}/movement/${parts[0]}/${parts[1]}',
        {});
  }

  Future<Map<String, dynamic>> _get(
      String path, Map<String, dynamic> filters) async {
    final response = await api.get(path, queryParameters: filters);
    final body = response.data;
    if (body is! Map || body['status'] != 'success' || body['data'] is! Map) {
      throw Exception(body is Map
          ? body['message'] ?? 'تعذر تحميل التقرير'
          : 'استجابة التقرير غير صالحة');
    }
    return Map<String, dynamic>.from(body['data'] as Map);
  }
}
