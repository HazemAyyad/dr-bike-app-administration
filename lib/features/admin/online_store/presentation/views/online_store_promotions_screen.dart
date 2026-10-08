import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_promotions_controller.dart';
import '../utils/online_store_permissions.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_resource_screen.dart';
import '../widgets/online_store_discount_editor.dart';
import '../widgets/online_store_target_picker.dart';
import '../../data/online_store_models.dart';

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
        actions: const {
          OnlineStoreResourceAction.activate,
          OnlineStoreResourceAction.deactivate,
          OnlineStoreResourceAction.delete,
        },
        editor: (context, item) => showOnlineStoreDiscountEditor(
          context,
          controller: controller,
          kind: OnlineStoreDiscountKind.promotion,
          item: item,
        ),
      );

  Future<void> _preview() async {
    final accounts = (await controller.repository.accounts())
        .where((account) => account.links.any((link) =>
            link.status == 'active' &&
            {'customer', 'seller'}.contains(link.role)))
        .toList(growable: false);
    final listings = await controller.repository.allListings();
    OnlineStoreAccount? account;
    OnlineStoreListing? listing;
    final quantity = TextEditingController(text: '1');
    String? role;
    final accepted = await Get.dialog<bool>(StatefulBuilder(
      builder: (context, setState) => OnlineStoreDialog(
        icon: Icons.calculate_outlined,
        title: const Text('معاينة تسعير للقراءة فقط'),
        content: OnlineStoreDialogBody(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<OnlineStoreAccount>(
              initialValue: account,
              decoration: const InputDecoration(labelText: 'حساب المتجر'),
              items: accounts
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value.name)))
                  .toList(growable: false),
              onChanged: (value) => setState(() {
                account = value;
                final roles = value?.links
                        .where((link) => link.status == 'active')
                        .map((link) => link.role)
                        .toSet() ??
                    const <String>{};
                role = roles.contains(role)
                    ? role
                    : (roles.isEmpty ? null : roles.first);
              }),
            ),
            if (account != null)
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'نوع الحساب'),
                items: account!.links
                    .where((link) => link.status == 'active')
                    .map((link) => link.role)
                    .toSet()
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value == 'seller' ? 'جملة' : 'تجزئة'),
                        ))
                    .toList(growable: false),
                onChanged: (value) => setState(() => role = value),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(listing?.productName.isNotEmpty == true
                  ? listing!.productName
                  : 'اختيار قائمة منتج'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () async {
                final selected = await showOnlineStoreTargetPicker(
                  context,
                  title: 'اختيار قائمة المنتج',
                  options: listings
                      .map((value) => OnlineStoreTargetOption(
                            type: 'listing',
                            id: value.id,
                            label: value.productName.isEmpty
                                ? 'قائمة #${value.id}'
                                : value.productName,
                          ))
                      .toList(growable: false),
                  selectedKeys:
                      listing == null ? const [] : ['listing:${listing!.id}'],
                  multiple: false,
                );
                if (selected != null && selected.isNotEmpty) {
                  setState(() => listing = listings
                      .firstWhere((value) => value.id == selected.single.id));
                }
              },
            ),
            TextField(
                controller: quantity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الكمية')),
          ]),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('إلغاء')),
          OutlinedButton(
              style: OnlineStoreAdminUi.actionButtonStyle,
              onPressed: account == null || role == null || listing == null
                  ? null
                  : () => Get.back(result: true),
              child: const Text('معاينة')),
        ],
      ),
    ));
    if (accepted == true) {
      final result = await controller.preview({
        'user_id': account!.id,
        'account_role': role,
        'items': [
          {
            'listing_id': listing!.id,
            'quantity': int.tryParse(quantity.text) ?? 1,
          }
        ],
      });
      await Get.dialog(OnlineStoreDialog(
        icon: Icons.receipt_long_outlined,
        title: const Text('نتيجة المعاينة'),
        content:
            SingleChildScrollView(child: Text('${result['data'] ?? result}')),
        actions: [TextButton(onPressed: Get.back, child: const Text('إغلاق'))],
      ));
    }
    quantity.dispose();
  }
}
