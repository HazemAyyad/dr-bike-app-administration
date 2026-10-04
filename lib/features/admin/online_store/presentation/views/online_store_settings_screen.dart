import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_settings_controller.dart';

class OnlineStoreSettingsScreen extends GetView<OnlineStoreSettingsController> {
  const OnlineStoreSettingsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('إعدادات المتجر')),
        body: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(padding: const EdgeInsets.all(14), children: [
            Card(
              color: const Color(0xFFF2F2F5),
              child: ListTile(
                leading: const Icon(Icons.power_settings_new),
                title: const Text('الحالة التشغيلية الفعلية'),
                subtitle: Text(controller.operatingState.value.isEmpty
                    ? controller.effectiveOperatingState
                    : controller.operatingState.value),
              ),
            ),
            SwitchListTile(
              title: const Text('المتجر مفتوح'),
              value: controller.values['store_enabled'] != false,
              onChanged: (v) => controller.values['store_enabled'] = v,
            ),
            SwitchListTile(
              title: const Text('وضع الصيانة (له الأولوية)'),
              value: controller.values['maintenance_mode'] == true,
              onChanged: (v) => controller.values['maintenance_mode'] = v,
            ),
            SwitchListTile(
              title: const Text('تفعيل إتمام الطلب'),
              value: controller.values['checkout_enabled'] != false,
              onChanged: (v) => controller.values['checkout_enabled'] = v,
            ),
            SwitchListTile(
              title: const Text('الدفع عند الاستلام'),
              value: controller.values['cod_enabled'] != false,
              onChanged: (v) => controller.values['cod_enabled'] = v,
            ),
            SwitchListTile(
              title: const Text('تصفح الزوار'),
              value: controller.values['guest_browsing_enabled'] != false,
              onChanged: (v) => controller.values['guest_browsing_enabled'] = v,
            ),
            TextFormField(
              initialValue: '${controller.values['minimum_order'] ?? 0}',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الحد الأدنى للطلب'),
              onChanged: (v) =>
                  controller.values['minimum_order'] = double.tryParse(v) ?? 0,
            ),
            TextFormField(
              initialValue: '${controller.values['support_phone'] ?? ''}',
              decoration: const InputDecoration(labelText: 'هاتف الدعم'),
              onChanged: (v) => controller.values['support_phone'] = v,
            ),
            TextFormField(
              initialValue: '${controller.values['whatsapp'] ?? ''}',
              decoration: const InputDecoration(labelText: 'واتساب'),
              onChanged: (v) => controller.values['whatsapp'] = v,
            ),
            const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('السعر الأساسي والمخزون غير قابلين للتعديل هنا'),
              subtitle: Text('تتم إدارتهما فقط من نظام المخزون'),
            ),
            FilledButton.icon(
              onPressed: controller.saving.value ? null : controller.save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ الإعدادات'),
            ),
          ]);
        }),
      );
}
