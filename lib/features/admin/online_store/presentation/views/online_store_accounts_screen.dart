import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../routes/app_routes.dart';
import '../controllers/online_store_accounts_controller.dart';
import '../widgets/online_store_state_view.dart';

class OnlineStoreAccountsScreen extends GetView<OnlineStoreAccountsController> {
  const OnlineStoreAccountsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('حسابات المتجر المرتبطة')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: controller.search,
              onSubmitted: (_) => controller.load(),
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو البريد أو الهاتف',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                    onPressed: controller.load,
                    icon: const Icon(Icons.arrow_back)),
              ),
            ),
          ),
          Expanded(
              child: Obx(() => OnlineStoreStateView(
                    loading: controller.loading.value,
                    error: controller.error.value,
                    isEmpty: controller.accounts.isEmpty,
                    onRetry: controller.load,
                    child: ListView.builder(
                      itemCount: controller.accounts.length,
                      itemBuilder: (_, i) {
                        final account = controller.accounts[i];
                        return Card(
                          color: const Color(0xFFF7F7FA),
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
                              if (account.isBlocked) 'محظور وغير قابل للربط',
                            ].join(' • ')),
                            children: [
                              if (account.links.isEmpty)
                                const ListTile(
                                    title: Text('لا توجد روابط بعد')),
                              ...account.links.map((link) => ListTile(
                                    title: Text(
                                        '${link.role} • ${link.partyName ?? '#${link.partyId}'}'),
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
                    ),
                  ))),
        ]),
      );

  Future<void> _showLinkDialog(int userId) async {
    final partyId = TextEditingController();
    var role = 'customer';
    final confirmed = await Get.dialog<bool>(StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('إنشاء ربط صريح'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            initialValue: role,
            items: const [
              DropdownMenuItem(value: 'customer', child: Text('عميل')),
              DropdownMenuItem(value: 'seller', child: Text('مورد')),
            ],
            onChanged: (value) => setState(() => role = value ?? 'customer'),
          ),
          TextField(
            controller: partyId,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'رقم الطرف'),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Get.back(result: true),
              child: const Text('ربط')),
        ],
      ),
    ));
    final id = int.tryParse(partyId.text);
    partyId.dispose();
    if (confirmed == true && id != null) {
      await controller.link(userId: userId, role: role, partyId: id);
    }
  }
}
