import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_reports_controller.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_form_widgets.dart';

class OnlineStoreReportsScreen extends GetView<OnlineStoreReportsController> {
  const OnlineStoreReportsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OnlineStoreAdminUi.pageBackground,
        appBar: AppBar(title: const Text('تقارير المتجر')),
        body: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error.value != null) {
            return Center(child: Text(controller.error.value!));
          }
          final entries = controller.data.entries.toList();
          if (entries.isEmpty) {
            return const Center(child: Text('التقرير غير متاح لهذه المرشحات'));
          }
          return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  children: [
                    OnlineStoreFormSection(
                        title: 'تصفية التقرير',
                        description: 'اختر الفترة ونوع الطلبات، ثم اضغط تطبيق.',
                        icon: Icons.filter_alt_outlined,
                        child: Wrap(spacing: 8, runSpacing: 8, children: [
                          SizedBox(
                              width: 180,
                              child: OnlineStoreDateTimeField(
                                controller: controller.fromController,
                                label: 'من تاريخ',
                                includeTime: false,
                              )),
                          SizedBox(
                              width: 180,
                              child: OnlineStoreDateTimeField(
                                controller: controller.toController,
                                label: 'إلى تاريخ',
                                includeTime: false,
                              )),
                          DropdownButton<String>(
                            value: controller.origin.value,
                            items: const [
                              DropdownMenuItem(
                                  value: 'all', child: Text('كل المصادر')),
                              DropdownMenuItem(
                                  value: 'admin', child: Text('الإدارة')),
                              DropdownMenuItem(
                                  value: 'store', child: Text('المتجر')),
                            ],
                            onChanged: (v) =>
                                controller.origin.value = v ?? 'all',
                          ),
                          DropdownButton<String>(
                            value: controller.accountType.value,
                            items: const [
                              DropdownMenuItem(
                                  value: 'all', child: Text('كل الحسابات')),
                              DropdownMenuItem(
                                  value: 'customer', child: Text('تجزئة')),
                              DropdownMenuItem(
                                  value: 'seller', child: Text('جملة')),
                            ],
                            onChanged: (v) =>
                                controller.accountType.value = v ?? 'all',
                          ),
                          DropdownButton<String>(
                            value: controller.status.value,
                            items: const [
                              DropdownMenuItem(
                                  value: 'all', child: Text('كل الحالات')),
                              DropdownMenuItem(
                                  value: 'pending',
                                  child: Text('قيد الانتظار')),
                              DropdownMenuItem(
                                  value: 'processing',
                                  child: Text('قيد التجهيز')),
                              DropdownMenuItem(
                                  value: 'completed', child: Text('مكتمل')),
                              DropdownMenuItem(
                                  value: 'canceled', child: Text('ملغي')),
                            ],
                            onChanged: (v) =>
                                controller.status.value = v ?? 'all',
                          ),
                          OutlinedButton.icon(
                            style: OnlineStoreAdminUi.actionButtonStyle,
                            onPressed: controller.load,
                            icon: const Icon(Icons.filter_alt_outlined),
                            label: const Text('تطبيق'),
                          ),
                        ])),
                    const SizedBox(height: 10),
                    ...entries.map((entry) => Card(
                          color: OnlineStoreAdminUi.surface,
                          child: ListTile(
                              title: Text(_reportLabel(entry.key)),
                              subtitle: Text(_reportValue(entry.value))),
                        )),
                  ]));
        }),
      );

  String _reportLabel(String key) =>
      const {
        'orders': 'الطلبات',
        'sales': 'المبيعات',
        'revenue': 'الإيرادات',
        'discounts': 'الخصومات',
        'average_order_value': 'متوسط قيمة الطلب',
        'customers': 'عملاء التجزئة',
        'sellers': 'عملاء الجملة',
        'by_status': 'الطلبات حسب الحالة',
        'by_origin': 'الطلبات حسب المصدر',
      }[key] ??
      key.replaceAll('_', ' ');

  String _reportValue(dynamic value) {
    if (value is Map) {
      return value.entries
          .map((entry) => '${_reportLabel('${entry.key}')}: ${entry.value}')
          .join('\n');
    }
    if (value is List) return value.join('\n');
    return '$value';
  }
}
