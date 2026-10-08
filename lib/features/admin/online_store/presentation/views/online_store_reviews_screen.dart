import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_reviews_controller.dart';
import '../utils/online_store_permissions.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_state_view.dart';
import '../widgets/online_store_form_widgets.dart';
import '../../data/online_store_models.dart';
import '../../../../../../routes/app_routes.dart';

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
      margin: const EdgeInsets.fromLTRB(10, 3, 10, 5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(
                radius: 16, child: Icon(Icons.person_outline, size: 18)),
            const SizedBox(width: 8),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(customer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                  Text(product,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          color: OnlineStoreAdminUi.textSecondary)),
                ])),
            IconButton(
              tooltip: 'فتح المنتج',
              visualDensity: VisualDensity.compact,
              onPressed: int.tryParse('${values['product_id']}') == null
                  ? null
                  : () => Get.toNamed(
                        AppRoutes.PRODUCTDETAILSSCREEN,
                        arguments: int.parse('${values['product_id']}'),
                      ),
              icon: const Icon(Icons.open_in_new, size: 19),
            ),
            if (OnlineStorePermissions.canManageReviews)
              PopupMenuButton<String>(
                onSelected: (status) => _moderate(review.id, status),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'published', child: Text('نشر')),
                  PopupMenuItem(value: 'rejected', child: Text('رفض مع سبب')),
                ],
              ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.star_rounded, size: 17, color: Color(0xFFE0A100)),
            const SizedBox(width: 3),
            Text('$rating/5',
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(_statusLabel(review.status),
                style:
                    const TextStyle(color: OnlineStoreAdminUi.textSecondary)),
          ]),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(comment,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
          ],
          const SizedBox(height: 4),
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
