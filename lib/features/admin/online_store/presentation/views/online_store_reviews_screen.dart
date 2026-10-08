import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_reviews_controller.dart';
import '../utils/online_store_permissions.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_state_view.dart';
import '../widgets/online_store_form_widgets.dart';
import '../../data/online_store_models.dart';

class OnlineStoreReviewsScreen extends GetView<OnlineStoreReviewsController> {
  const OnlineStoreReviewsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OnlineStoreAdminUi.pageBackground,
        appBar: AppBar(
          title: Obx(() => controller.searchOpen.value
              ? TextField(
                  controller: controller.search,
                  autofocus: true,
                  onChanged: (value) => controller.searchQuery.value = value,
                  decoration: const InputDecoration(
                      hintText: 'اسم العميل أو المنتج',
                      border: InputBorder.none),
                )
              : const Text('مراجعات المتجر')),
          actions: [
            Obx(() => IconButton(
                  onPressed: controller.toggleSearch,
                  icon: Icon(
                      controller.searchOpen.value ? Icons.close : Icons.search),
                )),
          ],
        ),
        body: Obx(() => OnlineStoreStateView(
              loading: controller.loading.value,
              error: controller.error.value,
              isEmpty: controller.visibleItems.isEmpty,
              onRetry: controller.load,
              child: Column(children: [
                SizedBox(
                  height: 50,
                  child: ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    scrollDirection: Axis.horizontal,
                    children: const {
                      'all': 'الكل',
                      'pending': 'بانتظار المراجعة',
                      'published': 'منشورة',
                      'rejected': 'مرفوضة',
                    }
                        .entries
                        .map((entry) => Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: ChoiceChip(
                                selected: controller.selectedStatus.value ==
                                    entry.key,
                                label: Text(entry.value),
                                onSelected: (_) =>
                                    controller.changeStatus(entry.key),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                      onRefresh: controller.load,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: controller.visibleItems.length,
                        itemBuilder: (_, i) {
                          final review = controller.visibleItems[i];
                          return _reviewCard(review);
                        },
                      )),
                ),
              ]),
            )),
      );

  Widget _reviewCard(OnlineStoreEntity review) {
    final values = review.values;
    final customer =
        '${values['customer_name'] ?? 'عميل #${values['customer_id'] ?? '—'}'}';
    final product =
        '${values['product_name'] ?? 'منتج #${values['product_id'] ?? '—'}'}';
    final rating = int.tryParse('${values['rating'] ?? 0}') ?? 0;
    final comment = '${values['comment'] ?? ''}'.trim();
    return Card(
      color: OnlineStoreAdminUi.surface,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(child: Icon(Icons.person_outline)),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(customer,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(product,
                      style: const TextStyle(
                          color: OnlineStoreAdminUi.textSecondary)),
                ])),
            if (OnlineStorePermissions.canManageReviews)
              PopupMenuButton<String>(
                onSelected: (status) => _moderate(review.id, status),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'published', child: Text('نشر')),
                  PopupMenuItem(value: 'rejected', child: Text('رفض مع سبب')),
                ],
              ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            ...List.generate(
                5,
                (index) => Icon(
                      index < rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 19,
                      color: const Color(0xFFE0A100),
                    )),
            const SizedBox(width: 8),
            Text('$rating/5',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(_statusLabel(review.status),
                style:
                    const TextStyle(color: OnlineStoreAdminUi.textSecondary)),
          ]),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment),
          ],
          const SizedBox(height: 8),
          Text(
            '${controller.verifiedPurchase(review) ? 'شراء موثّق • ' : ''}${onlineStoreFriendlyDate(values['created_at'])}',
            style: const TextStyle(
                fontSize: 11, color: OnlineStoreAdminUi.textSecondary),
          ),
        ]),
      ),
    );
  }

  String _statusLabel(String status) =>
      const {
        'pending': 'بانتظار المراجعة',
        'published': 'منشورة',
        'rejected': 'مرفوضة',
      }[status] ??
      status;

  Future<void> _moderate(int id, String status) async {
    String? reason;
    if (status == 'rejected') {
      final field = TextEditingController();
      reason = await Get.dialog<String>(OnlineStoreDialog(
        icon: Icons.rate_review_outlined,
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
