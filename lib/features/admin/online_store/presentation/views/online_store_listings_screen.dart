import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../routes/app_routes.dart';
import '../../data/online_store_models.dart';
import '../controllers/online_store_listings_controller.dart';
import '../utils/online_store_permissions.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_state_view.dart';
import '../widgets/online_store_network_image.dart';

class OnlineStoreListingsScreen extends GetView<OnlineStoreListingsController> {
  const OnlineStoreListingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OnlineStoreAdminUi.pageBackground,
        appBar: AppBar(
          title: Obx(() => controller.searchOpen.value
              ? TextField(
                  autofocus: true,
                  onChanged: (value) => controller.search.value = value,
                  decoration: const InputDecoration(
                    hintText: 'ابحث باسم المنتج أو رقمه',
                    border: InputBorder.none,
                  ),
                )
              : const Text('منتجات المتجر')),
          actions: [
            Obx(() => IconButton(
                  tooltip: controller.searchOpen.value ? 'إغلاق البحث' : 'بحث',
                  onPressed: () {
                    controller.searchOpen.toggle();
                    if (!controller.searchOpen.value) {
                      controller.search.value = '';
                    }
                  },
                  icon: Icon(
                      controller.searchOpen.value ? Icons.close : Icons.search),
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
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 90),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          final columns = width < 700
                              ? 3
                              : width < 900
                                  ? 4
                                  : width < 1200
                                      ? 5
                                      : (width / 220).floor().clamp(6, 8);
                          return SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisExtent: 218,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (_, index) => _listingCard(
                                  context, controller.visibleItems[index]),
                              childCount: controller.visibleItems.length,
                            ),
                          );
                        },
                      ),
                    ),
                ]),
              ),
            )),
      );

  Widget _filters() => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: controller.focusListingId.value == listing.id
                ? OnlineStoreAdminUi.accent
                : OnlineStoreAdminUi.border,
            width: controller.focusListingId.value == listing.id ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Get.toNamed(
            AppRoutes.ONLINESTORELISTINGEDITOR,
            arguments: listing,
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _ListingMedia(listing: listing)),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    listing.productName.isEmpty
                        ? 'منتج #${listing.productId}'
                        : listing.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1.25),
                  ),
                  if (listing.productCode.isNotEmpty)
                    Text(listing.productCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            color: OnlineStoreAdminUi.textSecondary)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Expanded(
                        child: Text('${listing.retailPrice} ₪',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w800))),
                    const SizedBox(width: 3),
                    const Icon(Icons.inventory_2_outlined,
                        size: 14, color: OnlineStoreAdminUi.textSecondary),
                    const SizedBox(width: 3),
                    Text('${listing.availableQuantity}',
                        style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 5),
                    const Icon(Icons.perm_media_outlined,
                        size: 14, color: OnlineStoreAdminUi.textSecondary),
                    const SizedBox(width: 3),
                    Text('${listing.media.length}',
                        style: const TextStyle(fontSize: 11)),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    _StatusChip(_statusLabel(listing.status),
                        _statusColor(listing.status)),
                    const Spacer(),
                    Icon(
                      listing.canPublish
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_rounded,
                      size: 15,
                      color: listing.canPublish
                          ? OnlineStoreAdminUi.success
                          : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        listing.canPublish
                            ? 'جاهز'
                            : '${listing.readinessIssues.length} ملاحظات',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: listing.canPublish
                              ? OnlineStoreAdminUi.success
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      );
}

class _ListingMedia extends StatelessWidget {
  const _ListingMedia({required this.listing});

  final OnlineStoreListing listing;

  @override
  Widget build(BuildContext context) {
    final available = listing.media.where(
      (item) => item.isVisible && item.url.trim().isNotEmpty,
    );
    final media = available.isEmpty
        ? null
        : available.firstWhere((item) => item.isMain,
            orElse: () => available.first);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(fit: StackFit.expand, children: [
          ColoredBox(
            color: OnlineStoreAdminUi.surfaceMuted,
            child: media == null
                ? const Icon(Icons.inventory_2_outlined,
                    color: OnlineStoreAdminUi.textSecondary)
                : media.mediaType == 'video'
                    ? const Stack(fit: StackFit.expand, children: [
                        Icon(Icons.video_library_outlined,
                            color: OnlineStoreAdminUi.accent, size: 34),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child:
                                Text('فيديو', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                      ])
                    : OnlineStoreNetworkImage(path: media.url),
          ),
          PositionedDirectional(
            top: 6,
            end: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .68),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.visibility_outlined,
                    size: 12, color: Colors.white),
                const SizedBox(width: 3),
                Text('${listing.viewCount}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
