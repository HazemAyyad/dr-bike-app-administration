import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../routes/app_routes.dart';
import '../controllers/online_store_listings_controller.dart';
import '../utils/online_store_permissions.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_state_view.dart';

class OnlineStoreListingsScreen extends GetView<OnlineStoreListingsController> {
  const OnlineStoreListingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('قوائم منتجات المتجر'),
          actions: [
            Obx(() => DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.status.value,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('الكل')),
                      DropdownMenuItem(value: 'draft', child: Text('مسودة')),
                      DropdownMenuItem(value: 'ready', child: Text('جاهز')),
                      DropdownMenuItem(
                          value: 'published', child: Text('منشور')),
                      DropdownMenuItem(value: 'hidden', child: Text('مخفي')),
                    ],
                    onChanged: (value) {
                      controller.status.value = value ?? 'all';
                      controller.load();
                    },
                  ),
                )),
          ],
        ),
        floatingActionButton: OnlineStorePermissions.canManageProducts
            ? FloatingActionButton.extended(
                onPressed: () =>
                    Get.toNamed(AppRoutes.ONLINESTOREPRODUCTPICKER),
                icon: const Icon(Icons.add),
                label: const Text('إضافة منتج'),
              )
            : null,
        body: Obx(() => OnlineStoreStateView(
              loading: controller.loading.value,
              error: controller.error.value,
              isEmpty: controller.items.isEmpty,
              onRetry: controller.load,
              child: RefreshIndicator(
                onRefresh: controller.load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.items.length,
                  itemBuilder: (_, index) {
                    final listing = controller.items[index];
                    return Card(
                      color: OnlineStoreAdminUi.surface,
                      child: ListTile(
                        onTap: () => Get.toNamed(
                          AppRoutes.ONLINESTORELISTINGEDITOR,
                          arguments: listing,
                        ),
                        title: Text(
                          listing.productName.isEmpty
                              ? 'منتج #${listing.productId}'
                              : listing.productName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                            '${listing.status} • ${listing.readinessState}'),
                        leading: Icon(
                          listing.canPublish
                              ? Icons.check_circle
                              : Icons.pending_outlined,
                          color:
                              listing.canPublish ? Colors.green : Colors.orange,
                        ),
                        trailing: const Icon(Icons.chevron_left),
                      ),
                    );
                  },
                ),
              ),
            )),
      );
}
