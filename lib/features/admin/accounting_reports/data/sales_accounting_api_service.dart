import '../../../../core/databases/api/api_consumer.dart';
import '../../../../core/databases/api/end_points.dart';

class SalesAccountingApiService {
  SalesAccountingApiService({required this.api});

  final ApiConsumer api;

  Future<Map<String, dynamic>> load(Map<String, dynamic> filters) async {
    final response = await api.get(
      EndPoints.salesAccountingReport,
      queryParameters: filters,
    );
    final body = response.data;
    if (body is! Map || body['status'] != 'success' || body['data'] is! Map) {
      throw Exception(body is Map
          ? body['message'] ?? 'تعذر تحميل تقرير المبيعات'
          : 'استجابة التقرير غير صالحة');
    }
    return Map<String, dynamic>.from(body['data'] as Map);
  }
}
