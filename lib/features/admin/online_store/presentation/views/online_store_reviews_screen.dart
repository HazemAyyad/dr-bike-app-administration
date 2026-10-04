import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_reviews_controller.dart';
import '../utils/online_store_permissions.dart';
import '../widgets/online_store_state_view.dart';

class OnlineStoreReviewsScreen extends GetView<OnlineStoreReviewsController> {
  const OnlineStoreReviewsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('مراجعات المتجر')),
        body: Obx(() => OnlineStoreStateView(
              loading: controller.loading.value,
              error: controller.error.value,
              isEmpty: controller.items.isEmpty,
              onRetry: controller.load,
              child: ListView.builder(
                itemCount: controller.items.length,
                itemBuilder: (_, i) {
                  final review = controller.items[i];
                  return Card(
                    color: const Color(0xFFF7F7FA),
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
              ),
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
          FilledButton(
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
