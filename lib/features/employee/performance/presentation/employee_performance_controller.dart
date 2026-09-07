import 'package:get/get.dart';

import '../../../../core/databases/api/dio_consumer.dart';
import '../data/employee_performance_model.dart';

class EmployeePerformanceController extends GetxController {
  EmployeePerformanceController(this.api);

  final DioConsumer api;
  final loading = false.obs;
  final period = 'monthly'.obs;
  final performance = Rxn<EmployeePerformanceModel>();
  final error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> selectPeriod(String value) async {
    if (period.value == value) return;
    period.value = value;
    await load();
  }

  Future<void> load() async {
    if (loading.value) return;
    loading.value = true;
    error.value = '';
    try {
      final response = await api.get(
        'employee/performance',
        queryParameters: {'period': period.value},
      );
      final root = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final raw = root['performance'];
      if (raw is! Map) throw const FormatException('بيانات الأداء غير مكتملة');
      performance.value = EmployeePerformanceModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
    } catch (_) {
      error.value = 'تعذر تحميل مؤشر الأداء. اسحب للأسفل للمحاولة مجددًا.';
    } finally {
      loading.value = false;
    }
  }
}
