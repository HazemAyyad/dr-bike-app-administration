import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../routes/app_routes.dart';
import '../../../widgets/unified_partner_selector.dart';
import '../../data/online_store_models.dart';
import '../controllers/online_store_accounts_controller.dart';
import '../widgets/online_store_state_view.dart';
import '../utils/online_store_admin_ui.dart';

class OnlineStoreAccountsScreen extends GetView<OnlineStoreAccountsController> {
  const OnlineStoreAccountsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OnlineStoreAdminUi.pageBackground,
        appBar: AppBar(
          title: Obx(() => controller.searchOpen.value
              ? TextField(
                  controller: controller.search,
                  autofocus: true,
                  onChanged: controller.onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'الاسم أو البريد أو الهاتف',
                    border: InputBorder.none,
                  ),
                )
              : const Text('حسابات المتجر المرتبطة')),
          actions: [
            Obx(() => IconButton(
                  onPressed: controller.toggleSearch,
                  tooltip: controller.searchOpen.value ? 'إغلاق البحث' : 'بحث',
                  icon: Icon(
                      controller.searchOpen.value ? Icons.close : Icons.search),
                )),
          ],
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: OnlineStoreAdminUi.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: OnlineStoreAdminUi.border),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: OnlineStoreAdminUi.accent),
                SizedBox(width: 10),
                Expanded(
                    child: Text(
                  'هذا القسم يربط حساب تسجيل الدخول في تطبيق المتجر بسجل العميل أو المورد داخل النظام، ليستخدم الأسعار والرصيد وسياسة الائتمان الصحيحة.',
                  style: TextStyle(color: OnlineStoreAdminUi.textSecondary),
                )),
              ]),
            ),
          ),
          Expanded(
              child: Obx(() => OnlineStoreStateView(
                    loading: controller.loading.value,
                    error: controller.error.value,
                    isEmpty: controller.accounts.isEmpty,
                    onRetry: controller.load,
                    child: RefreshIndicator(
                        onRefresh: controller.load,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: controller.accounts.length,
                          itemBuilder: (_, i) {
                            final account = controller.accounts[i];
                            return Card(
                              color: OnlineStoreAdminUi.surface,
                              child: ExpansionTile(
                                leading: Icon(
                                  account.isBlocked
                                      ? Icons.block
                                      : Icons.person_outline,
                                  color: account.isBlocked ? Colors.red : null,
                                ),
                                title: Text(account.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                                subtitle: Text([
                                  if (account.email != null) account.email!,
                                  if (account.phone != null) account.phone!,
                                  if (account.isBlocked)
                                    'محظور وغير قابل للربط',
                                ].join(' • ')),
                                children: [
                                  if (account.links.isEmpty)
                                    const ListTile(
                                        title: Text('لا توجد روابط بعد')),
                                  ...account.links.map((link) => ListTile(
                                        title: Text(
                                            '${link.role == 'seller' ? 'مورد' : 'عميل'} • ${controller.partyName(link)}'),
                                        subtitle: Text(link.status),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (action) {
                                            if (action == 'credit') {
                                              Get.toNamed(
                                                  AppRoutes.ONLINESTORECREDIT,
                                                  arguments: link.id);
                                            } else {
                                              controller.setLinkStatus(
                                                  link.id, action);
                                            }
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                                value: 'credit',
                                                child: Text('سياسة الائتمان')),
                                            PopupMenuItem(
                                                value: 'active',
                                                child: Text('تفعيل الربط')),
                                            PopupMenuItem(
                                                value: 'suspended',
                                                child: Text('تعليق الربط')),
                                          ],
                                        ),
                                      )),
                                  if (account.isLinkable)
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _showLinkDialog(account.id),
                                        icon: const Icon(Icons.link),
                                        label: const Text('ربط عميل أو مورد'),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        )),
                  ))),
        ]),
      );

  Future<void> _showLinkDialog(int userId) async {
    var role = 'customer';
    OnlineStoreParty? selected;
    await controller.loadParties(role);
    final confirmed = await Get.dialog<bool>(StatefulBuilder(
      builder: (context, setState) => OnlineStoreDialog(
        icon: Icons.link,
        title: const Text('إنشاء ربط صريح'),
        content: SizedBox(
            width: OnlineStoreAdminUi.dialogWidth(context),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: role,
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text('عميل')),
                  DropdownMenuItem(value: 'seller', child: Text('مورد')),
                ],
                onChanged: (value) async {
                  role = value ?? 'customer';
                  selected = null;
                  await controller.loadParties(role);
                  if (context.mounted) setState(() {});
                },
              ),
              const SizedBox(height: 12),
              if (controller.partiesLoading.value)
                const LinearProgressIndicator()
              else
                UnifiedPartnerSelector<OnlineStoreParty>(
                  customers: role == 'customer' ? controller.parties : const [],
                  sellers: role == 'seller' ? controller.parties : const [],
                  selected: selected,
                  selectedIsSeller: role == 'seller',
                  idOf: (party) => party.id,
                  nameOf: (party) => party.name,
                  phoneOf: (party) => party.phone,
                  onSelected: (party, _) => setState(() => selected = party),
                  onCleared: () => setState(() => selected = null),
                  title: role == 'customer' ? 'اختيار العميل' : 'اختيار المورد',
                  hintText: 'ابحث بالاسم أو الهاتف',
                  requiredSelection: true,
                  compact: true,
                ),
              if (controller.error.value != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(controller.error.value!,
                      style: const TextStyle(color: Colors.red)),
                ),
            ])),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('إلغاء')),
          OutlinedButton(
              style: OnlineStoreAdminUi.actionButtonStyle,
              onPressed: selected == null ? null : () => Get.back(result: true),
              child: const Text('ربط')),
        ],
      ),
    ));
    if (confirmed == true && selected != null) {
      await controller.link(userId: userId, role: role, partyId: selected!.id);
    }
  }
}
