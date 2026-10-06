import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../routes/app_routes.dart';
import '../../data/online_store_models.dart';
import '../controllers/online_store_listings_controller.dart';
import '../utils/online_store_permissions.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_state_view.dart';

class OnlineStoreListingsScreen extends GetView<OnlineStoreListingsController> {
  const OnlineStoreListingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OnlineStoreAdminUi.pageBackground,
        appBar: AppBar(
          title: const Text('منتجات المتجر'),
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
                child: CustomScrollView(slivers: [
                  SliverToBoxAdapter(child: _filters()),
                  if (controller.visibleItems.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child:
                          Center(child: Text('لا توجد منتجات مطابقة للبحث.')),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, index) => _listingCard(
                              context, controller.visibleItems[index]),
                          childCount: controller.visibleItems.length,
                        ),
                      ),
                    ),
                ]),
              ),
            )),
      );

  Widget _filters() => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            onChanged: (value) => controller.search.value = value,
            decoration: const InputDecoration(
              hintText: 'ابحث باسم المنتج أو رقمه',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: OnlineStoreAdminUi.surface,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final entry in const {
                'all': 'الكل',
                'draft': 'مسودة',
                'ready': 'جاهز',
                'published': 'منشور',
                'hidden': 'مخفي',
              }.entries)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    selected: controller.status.value == entry.key,
                    label: Text(entry.value),
                    onSelected: (_) {
                      controller.status.value = entry.key;
                      controller.load();
                    },
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 6),
          Text('${controller.visibleItems.length} منتج',
              style: const TextStyle(color: OnlineStoreAdminUi.textSecondary)),
        ]),
      );

  Widget _listingCard(BuildContext context, OnlineStoreListing listing) => Card(
        color: OnlineStoreAdminUi.surface,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: OnlineStoreAdminUi.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.toNamed(
            AppRoutes.ONLINESTORELISTINGEDITOR,
            arguments: listing,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: listing.canPublish
                      ? const Color(0xFFEAF7F0)
                      : const Color(0xFFFFF5E7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  listing.canPublish
                      ? Icons.check_circle_outline
                      : Icons.inventory_2_outlined,
                  color: listing.canPublish
                      ? OnlineStoreAdminUi.success
                      : Colors.orange.shade800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.productName.isEmpty
                        ? 'منتج #${listing.productId}'
                        : listing.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 7),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    _StatusChip(_statusLabel(listing.status),
                        _statusColor(listing.status)),
                    _StatusChip(
                      listing.canPublish
                          ? 'جاهز للنشر'
                          : '${listing.readinessIssues.length} ملاحظات للتجهيز',
                      listing.canPublish
                          ? OnlineStoreAdminUi.success
                          : Colors.orange.shade800,
                    ),
                  ]),
                ],
              )),
              const Icon(Icons.chevron_left,
                  color: OnlineStoreAdminUi.textSecondary),
            ]),
          ),
        ),
      );

  String _statusLabel(String value) =>
      const {
        'draft': 'مسودة',
        'ready': 'جاهز',
        'published': 'منشور',
        'hidden': 'مخفي',
      }[value] ??
      value;

  Color _statusColor(String value) =>
      const {
        'draft': Color(0xFF667085),
        'ready': Color(0xFF1D5D9B),
        'published': OnlineStoreAdminUi.success,
        'hidden': Color(0xFF7A5D00),
      }[value] ??
      OnlineStoreAdminUi.textSecondary;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}
