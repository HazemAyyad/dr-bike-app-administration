import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_reviews_controller.dart';
import '../utils/online_store_permissions.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_state_view.dart';

class OnlineStoreReviewsScreen extends GetView<OnlineStoreReviewsController> {
  const OnlineStoreReviewsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OnlineStoreAdminUi.pageBackground,
        appBar: AppBar(title: const Text('مراجعات المتجر')),
        body: Obx(() => OnlineStoreStateView(
              loading: controller.loading.value,
              error: controller.error.value,
              isEmpty: controller.items.isEmpty,
              onRetry: controller.load,
              child: RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: controller.items.length,
                    itemBuilder: (_, i) {
                      final review = controller.items[i];
                      return Card(
                        color: OnlineStoreAdminUi.surface,
                        child: ListTile(
                          title: Text(review.label),
                          subtitle: Text(
                              '${review.status}${controller.verifiedPurchase(review) ? ' • شراء موثّق' : ''}'),
                          trailing: OnlineStorePermissions.canManageReviews
                              ? PopupMenuButton<String>(
                                  onSelected: (status) =>
                                      _moderate(review.id, status),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                        value: 'published', child: Text('نشر')),
                                    PopupMenuItem(
                                        value: 'rejected',
                                        child: Text('رفض مع سبب')),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  )),
            )),
      );

  Future<void> _moderate(int id, String status) async {
    String? reason;
    if (status == 'rejected') {
      final field = TextEditingController();
      reason = await Get.dialog<String>(AlertDialog(
        title: const Text('سبب رفض المراجعة'),
        content: TextField(
          controller: field,
          maxLines: 3,
          decoration:
              const InputDecoration(hintText: 'أدخل سببًا واضحًا للمراجعة'),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('إلغاء')),
          OutlinedButton(
              style: OnlineStoreAdminUi.actionButtonStyle,
              onPressed: () => Get.back(result: field.text.trim()),
              child: const Text('رفض')),
        ],
      ));
      field.dispose();
      if (reason == null || reason.isEmpty) return;
    }
    await controller.moderate(id, status, reason: reason);
  }
}
