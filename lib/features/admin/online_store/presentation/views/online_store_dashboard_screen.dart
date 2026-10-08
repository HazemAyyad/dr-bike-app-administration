import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../routes/app_routes.dart';
import '../controllers/online_store_dashboard_controller.dart';
import '../utils/online_store_permissions.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_state_view.dart';

class OnlineStoreDashboardScreen
    extends GetView<OnlineStoreDashboardController> {
  const OnlineStoreDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OnlineStoreAdminUi.pageBackground,
        appBar: AppBar(title: const Text('إدارة المتجر الإلكتروني')),
        body: Obx(() {
          final summary = controller.summary.value;
          return OnlineStoreStateView(
            loading: controller.loading.value,
            error: controller.error.value,
            isEmpty: summary == null,
            onRetry: controller.load,
            child: RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  children: [
                    Row(children: [
                      Expanded(
                          child: _Summary(
                              'المنشورة',
                              summary?.countPath('listings', 'published') ?? 0,
                              Icons.inventory_2_outlined,
                              const Color(0xFF1D5D9B))),
                      const SizedBox(width: 6),
                      Expanded(
                          child: _Summary(
                              'الطلبات',
                              summary?.countPath('orders', 'store_count') ?? 0,
                              Icons.receipt_long_outlined,
                              OnlineStoreAdminUi.accent)),
                      const SizedBox(width: 6),
                      Expanded(
                          child: _Summary(
                              'العروض',
                              summary?.count('active_promotions') ?? 0,
                              Icons.local_offer_outlined,
                              OnlineStoreAdminUi.success)),
                      const SizedBox(width: 6),
                      Expanded(
                          child: _Summary(
                              'المراجعات',
                              summary?.countPath('pending_reviews', 'value') ??
                                  0,
                              Icons.reviews_outlined,
                              const Color(0xFF9A6700))),
                    ]),
                    const SizedBox(height: 14),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(4, 8, 4, 4),
                      child: Text('أدوات الإدارة',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                    ..._destinations().map((item) => Card(
                          color: OnlineStoreAdminUi.surface,
                          child: ListTile(
                            onTap: () => Get.toNamed(item.route),
                            leading: Icon(item.icon,
                                color: OnlineStoreAdminUi.accent),
                            title: Text(item.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(item.description),
                            trailing: const Icon(Icons.chevron_left),
                          ),
                        )),
                  ],
                )),
          );
        }),
      );

  List<_Destination> _destinations() => [
        if (OnlineStorePermissions.canView)
          const _Destination('المنتجات المعروضة', AppRoutes.ONLINESTORELISTINGS,
              Icons.inventory_2_outlined, 'جهّز المنتجات وانشرها في المتجر'),
        if (OnlineStorePermissions.canManageCategories)
          const _Destination('تصنيفات المتجر', AppRoutes.ONLINESTORECATEGORIES,
              Icons.category_outlined, 'رتّب المنتجات ضمن تصنيفات واضحة'),
        if (OnlineStorePermissions.canManageContent) ...[
          const _Destination(
              'أقسام الصفحة الرئيسية',
              AppRoutes.ONLINESTOREHOMESECTIONS,
              Icons.view_carousel_outlined,
              'حدّد أقسام الصفحة الرئيسية وترتيبها'),
          const _Destination('البانرات', AppRoutes.ONLINESTOREBANNERS,
              Icons.image_outlined, 'صور الواجهة وروابطها ومدة ظهورها'),
        ],
        if (OnlineStorePermissions.canManagePromotions) ...[
          const _Destination('العروض', AppRoutes.ONLINESTOREPROMOTIONS,
              Icons.local_offer_outlined, 'خصومات تلقائية على منتجات محددة'),
          const _Destination('الكوبونات', AppRoutes.ONLINESTORECOUPONS,
              Icons.confirmation_number_outlined, 'رموز خصم يستخدمها العملاء'),
        ],
        if (OnlineStorePermissions.canManageSettings) ...[
          const _Destination(
              'حسابات المتجر',
              AppRoutes.ONLINESTOREACCOUNTS,
              Icons.people_outline,
              'ربط العملاء وحسابات الجملة وسياسة الائتمان'),
          const _Destination('إعدادات المتجر', AppRoutes.ONLINESTORESETTINGS,
              Icons.settings_outlined, 'خيارات التشغيل العامة للمتجر'),
        ],
        if (OnlineStorePermissions.canManageReviews)
          const _Destination('المراجعات', AppRoutes.ONLINESTOREREVIEWS,
              Icons.reviews_outlined, 'مراجعة تقييمات العملاء واعتمادها'),
        const _Destination('التقارير', AppRoutes.ONLINESTOREREPORTS,
            Icons.analytics_outlined, 'متابعة الطلبات والمبيعات حسب الفترة'),
        if (OnlineStorePermissions.canManageSettings)
          const _Destination('سجل التدقيق', AppRoutes.ONLINESTOREAUDIT,
              Icons.history_outlined, 'معرفة من غيّر ماذا ومتى'),
      ];
}

class _Destination {
  const _Destination(this.label, this.route, this.icon, this.description);
  final String label;
  final String route;
  final IconData icon;
  final String description;
}

class _Summary extends StatelessWidget {
  const _Summary(this.label, this.value, this.icon, this.color);
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        decoration: BoxDecoration(
          color: OnlineStoreAdminUi.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE1E1E8)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text('$value',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 9, color: OnlineStoreAdminUi.textSecondary)),
        ]),
      );
}
