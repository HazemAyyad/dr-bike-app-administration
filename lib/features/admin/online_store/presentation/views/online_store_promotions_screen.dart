import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_promotions_controller.dart';
import '../utils/online_store_permissions.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_resource_screen.dart';
import '../widgets/online_store_discount_editor.dart';
import '../widgets/online_store_target_picker.dart';
import '../widgets/online_store_form_widgets.dart';
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
        cardBuilder: _promotionCard,
      );

  Widget _promotionCard(
    BuildContext context,
    OnlineStoreEntity item,
    Widget trailing,
  ) {
    final active =
        item.values['is_active'] == true || item.values['is_active'] == 1;
    final type = '${item.values['discount_type'] ?? ''}';
    final value = item.values['discount_value'] ?? 0;
    final uses = int.tryParse('${item.values['redemptions_count'] ?? 0}') ?? 0;
    final discountTotal = item.values['discount_total'] ?? 0;
    return Card(
      color: OnlineStoreAdminUi.surface,
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -3),
        contentPadding: const EdgeInsetsDirectional.fromSTEB(10, 2, 4, 2),
        onTap: OnlineStorePermissions.canManagePromotions
            ? () async {
                final payload = await showOnlineStoreDiscountEditor(
                  context,
                  controller: controller,
                  kind: OnlineStoreDiscountKind.promotion,
                  item: item,
                );
                if (payload != null) {
                  await controller.updateItem(item.id, payload);
                }
              }
            : null,
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: const BoxDecoration(
            color: OnlineStoreAdminUi.surfaceMuted,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.local_offer_outlined,
              color: OnlineStoreAdminUi.accent),
        ),
        title: Row(children: [
          Expanded(
            child: Text(item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          _badge(
              active ? 'نشط' : 'متوقف',
              active
                  ? OnlineStoreAdminUi.success
                  : OnlineStoreAdminUi.textSecondary),
        ]),
        subtitle: Text(
          '${type == 'percentage' ? '$value%' : '$value ₪'}  •  $uses استخدام  •  وفر $discountTotal ₪',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            tooltip: 'سجل المستفيدين والإحصاءات',
            onPressed: () => Get.to(() => OnlineStorePromotionHistoryScreen(
                  promotion: item,
                  controller: controller,
                )),
            icon: const Icon(Icons.history_rounded,
                color: OnlineStoreAdminUi.accent),
          ),
          trailing,
        ]),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: .25)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w700)),
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

class OnlineStorePromotionHistoryScreen extends StatelessWidget {
  const OnlineStorePromotionHistoryScreen({
    Key? key,
    required this.promotion,
    required this.controller,
  }) : super(key: key);

  final OnlineStoreEntity promotion;
  final OnlineStorePromotionsController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OnlineStoreAdminUi.pageBackground,
        appBar: AppBar(title: Text('مستفيدو ${promotion.label}')),
        body: FutureBuilder<OnlineStorePromotionHistory>(
          future: controller.redemptions(promotion.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('تعذر تحميل السجل: ${snapshot.error}'));
            }
            final history = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    _PromotionStat(
                        'مرات الاستفادة', history.summary['uses'] ?? 0),
                    _PromotionStat(
                        'المستخدمون', history.summary['unique_users'] ?? 0),
                    _PromotionStat('القطع', history.summary['quantity'] ?? 0),
                    _PromotionStat('إجمالي التوفير',
                        '${history.summary['discount_total'] ?? 0} ₪'),
                  ],
                ),
                const SizedBox(height: 12),
                if (history.rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child:
                        Center(child: Text('لم يستفد أحد من هذا العرض بعد.')),
                  )
                else
                  ...history.rows.map((row) => _PromotionHistoryRow(row)),
              ],
            );
          },
        ),
      );
}

class _PromotionStat extends StatelessWidget {
  const _PromotionStat(this.label, this.value);
  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OnlineStoreAdminUi.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OnlineStoreAdminUi.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: OnlineStoreAdminUi.textSecondary)),
          Text('$value',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _PromotionHistoryRow extends StatelessWidget {
  const _PromotionHistoryRow(this.row);
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final user = onlineStoreMap(row['user']);
    final customer = onlineStoreMap(row['customer']);
    final seller = onlineStoreMap(row['seller']);
    final order = onlineStoreMap(row['sales_order']);
    final party = customer.isNotEmpty ? customer : seller;
    final name =
        '${party['name'] ?? party['nameAr'] ?? party['name_ar'] ?? user['name'] ?? 'مستخدم #${row['user_id'] ?? '—'}'}';
    return Card(
      color: OnlineStoreAdminUi.surface,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          'الطلب: ${order['serial_number'] ?? row['sales_order_id'] ?? '—'} • ${row['quantity'] ?? 0} قطعة\n${onlineStoreFriendlyDate(row['used_at'] ?? row['created_at'])}',
        ),
        isThreeLine: true,
        trailing: Text('${row['discount_amount'] ?? 0} ₪',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
