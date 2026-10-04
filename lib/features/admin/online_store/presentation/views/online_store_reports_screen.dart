import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_reports_controller.dart';

class OnlineStoreReportsScreen extends GetView<OnlineStoreReportsController> {
  const OnlineStoreReportsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
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
          return ListView(padding: const EdgeInsets.all(12), children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              SizedBox(
                  width: 130,
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'من'),
                    onChanged: (v) => controller.from.value = v,
                  )),
              SizedBox(
                  width: 130,
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'إلى'),
                    onChanged: (v) => controller.to.value = v,
                  )),
              DropdownButton<String>(
                value: controller.origin.value,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('كل المصادر')),
                  DropdownMenuItem(value: 'admin', child: Text('الإدارة')),
                  DropdownMenuItem(value: 'store', child: Text('المتجر')),
                ],
                onChanged: (v) => controller.origin.value = v ?? 'all',
              ),
              DropdownButton<String>(
                value: controller.accountType.value,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('كل الحسابات')),
                  DropdownMenuItem(value: 'customer', child: Text('تجزئة')),
                  DropdownMenuItem(value: 'seller', child: Text('جملة')),
                ],
                onChanged: (v) => controller.accountType.value = v ?? 'all',
              ),
              FilledButton.icon(
                onPressed: controller.load,
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('تطبيق'),
              ),
            ]),
            const SizedBox(height: 10),
            ...entries.map((entry) => Card(
                  color: const Color(0xFFF7F7FA),
                  child: ListTile(
                      title: Text(entry.key), subtitle: Text('${entry.value}')),
                )),
          ]);
        }),
      );
}
