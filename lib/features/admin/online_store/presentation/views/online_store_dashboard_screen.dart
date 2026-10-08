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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                      child: Row(children: [
                        const Expanded(
                          child: Text('أدوات الإدارة',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800)),
                        ),
                        _ViewModeButton(
                          tooltip: 'عرض قائمة',
                          icon: Icons.view_list_outlined,
                          selected: !controller.toolsGrid.value,
                          onPressed: () => controller.toolsGrid.value = false,
                        ),
                        const SizedBox(width: 5),
                        _ViewModeButton(
                          tooltip: 'عرض شبكة',
                          icon: Icons.grid_view_outlined,
                          selected: controller.toolsGrid.value,
                          onPressed: () => controller.toolsGrid.value = true,
                        ),
                      ]),
                    ),
                    _managementTools(),
                  ],
                )),
          );
        }),
      );

  Widget _managementTools() {
    final destinations = _destinations();
    if (!controller.toolsGrid.value) {
      return Column(
        children: destinations
            .map((item) => Card(
                  color: OnlineStoreAdminUi.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                    side: const BorderSide(color: OnlineStoreAdminUi.border),
                  ),
                  child: ListTile(
                    dense: true,
                    onTap: () => Get.toNamed(item.route),
                    leading: Icon(item.icon, color: OnlineStoreAdminUi.accent),
                    title: Text(item.label,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ))
            .toList(growable: false),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 420
            ? 3
            : constraints.maxWidth < 760
                ? 4
                : 6;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: destinations.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 108,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final item = destinations[index];
            return Card(
              color: OnlineStoreAdminUi.surface,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: OnlineStoreAdminUi.border),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Get.toNamed(item.route),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon,
                          size: 29, color: OnlineStoreAdminUi.accent),
                      const SizedBox(height: 8),
                      Text(item.label,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<_Destination> _destinations() => [
        if (OnlineStorePermissions.canView)
          const _Destination('إحصائيات المتجر', AppRoutes.ONLINESTORESTATISTICS,
              Icons.query_stats_outlined),
        if (OnlineStorePermissions.canView)
          const _Destination('المنتجات المعروضة', AppRoutes.ONLINESTORELISTINGS,
              Icons.inventory_2_outlined),
        if (OnlineStorePermissions.canManageCategories)
          const _Destination('تصنيفات المتجر', AppRoutes.ONLINESTORECATEGORIES,
              Icons.category_outlined),
        if (OnlineStorePermissions.canManageContent) ...[
          const _Destination('أقسام الصفحة الرئيسية',
              AppRoutes.ONLINESTOREHOMESECTIONS, Icons.view_carousel_outlined),
          const _Destination(
              'البانرات', AppRoutes.ONLINESTOREBANNERS, Icons.image_outlined),
        ],
        if (OnlineStorePermissions.canManagePromotions) ...[
          const _Destination('العروض', AppRoutes.ONLINESTOREPROMOTIONS,
              Icons.local_offer_outlined),
          const _Destination('الكوبونات', AppRoutes.ONLINESTORECOUPONS,
              Icons.confirmation_number_outlined),
        ],
        if (OnlineStorePermissions.canManageSettings) ...[
          const _Destination('حسابات المتجر', AppRoutes.ONLINESTOREACCOUNTS,
              Icons.people_outline),
          const _Destination('إعدادات المتجر', AppRoutes.ONLINESTORESETTINGS,
              Icons.settings_outlined),
        ],
        if (OnlineStorePermissions.canManageReviews)
          const _Destination('المراجعات', AppRoutes.ONLINESTOREREVIEWS,
              Icons.reviews_outlined),
        const _Destination(
            'التقارير', AppRoutes.ONLINESTOREREPORTS, Icons.analytics_outlined),
        if (OnlineStorePermissions.canManageSettings)
          const _Destination('سجل التدقيق', AppRoutes.ONLINESTOREAUDIT,
              Icons.history_outlined),
      ];
}

class _Destination {
  const _Destination(this.label, this.route, this.icon);
  final String label;
  final String route;
  final IconData icon;
}

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: selected
              ? OnlineStoreAdminUi.accent.withValues(alpha: .1)
              : OnlineStoreAdminUi.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: selected
                  ? OnlineStoreAdminUi.accent
                  : OnlineStoreAdminUi.border,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon,
                  size: 20,
                  color: selected
                      ? OnlineStoreAdminUi.accent
                      : OnlineStoreAdminUi.textSecondary),
            ),
          ),
        ),
      );
}
