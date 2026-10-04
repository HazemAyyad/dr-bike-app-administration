import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_promotions_controller.dart';
import '../utils/online_store_permissions.dart';
import '../widgets/online_store_resource_screen.dart';

class OnlineStorePromotionsScreen
    extends GetView<OnlineStorePromotionsController> {
  const OnlineStorePromotionsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) =>
      OnlineStoreResourceScreen<OnlineStorePromotionsController>(
        title: 'عروض المتجر',
        icon: Icons.local_offer_outlined,
        canManage: OnlineStorePermissions.canManagePromotions,
        subtitle: 'عالمي أو مستهدف • أولوية وجدولة • معاينة سعر للقراءة فقط',
        inspectLabel: 'معاينة التسعير',
        onInspect: (_) => _preview(),
        fields: const [
          OnlineStoreFormField('name', 'اسم العرض'),
          OnlineStoreFormField('discount_type', 'نوع الخصم',
              options: ['percentage', 'fixed']),
          OnlineStoreFormField('discount_value', 'قيمة الخصم', numeric: true),
          OnlineStoreFormField('applies_to', 'السعر المستهدف',
              options: ['retail', 'wholesale', 'both']),
          OnlineStoreFormField('scope', 'النطاق',
              options: ['global', 'targeted']),
          OnlineStoreFormField('targets', 'الأهداف JSON', json: true),
          OnlineStoreFormField('starts_at', 'يبدأ في'),
          OnlineStoreFormField('ends_at', 'ينتهي في'),
          OnlineStoreFormField('priority', 'الأولوية', numeric: true),
          OnlineStoreFormField('is_active', 'نشط', boolean: true),
        ],
      );

  Future<void> _preview() async {
    final userId = TextEditingController();
    final listingId = TextEditingController();
    final quantity = TextEditingController(text: '1');
    var role = 'customer';
    final accepted = await Get.dialog<bool>(StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('معاينة تسعير للقراءة فقط'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: userId,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'رقم المستخدم')),
          DropdownButtonFormField<String>(
            initialValue: role,
            items: const [
              DropdownMenuItem(value: 'customer', child: Text('تجزئة')),
              DropdownMenuItem(value: 'seller', child: Text('جملة')),
            ],
            onChanged: (v) => setState(() => role = v ?? 'customer'),
          ),
          TextField(
              controller: listingId,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'رقم القائمة')),
          TextField(
              controller: quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الكمية')),
        ]),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Get.back(result: true),
              child: const Text('معاينة')),
        ],
      ),
    ));
    if (accepted == true) {
      final result = await controller.preview({
        'user_id': int.tryParse(userId.text),
        'account_role': role,
        'items': [
          {
            'listing_id': int.tryParse(listingId.text),
            'quantity': int.tryParse(quantity.text) ?? 1,
          }
        ],
      });
      await Get.dialog(AlertDialog(
        title: const Text('نتيجة المعاينة'),
        content:
            SingleChildScrollView(child: Text('${result['data'] ?? result}')),
        actions: [TextButton(onPressed: Get.back, child: const Text('إغلاق'))],
      ));
    }
    userId.dispose();
    listingId.dispose();
    quantity.dispose();
  }
}
