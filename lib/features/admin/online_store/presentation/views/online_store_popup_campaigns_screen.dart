import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/online_store_models.dart';
import '../controllers/online_store_popup_campaigns_controller.dart';
import '../utils/online_store_admin_ui.dart';
import '../utils/online_store_permissions.dart';
import '../widgets/online_store_form_widgets.dart';
import '../widgets/online_store_network_image.dart';
import '../widgets/online_store_popup_campaign_editor.dart';
import '../widgets/online_store_resource_screen.dart';

class OnlineStorePopupCampaignsScreen
    extends GetView<OnlineStorePopupCampaignsController> {
  const OnlineStorePopupCampaignsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      OnlineStoreResourceScreen<OnlineStorePopupCampaignsController>(
        title: 'الإعلانات المنبثقة',
        icon: Icons.campaign_outlined,
        canManage: OnlineStorePermissions.canManageContent,
        actions: const {
          OnlineStoreResourceAction.activate,
          OnlineStoreResourceAction.deactivate,
          OnlineStoreResourceAction.delete,
        },
        editor: (context, item) => showOnlineStorePopupCampaignEditor(
          context,
          controller: controller,
          item: item,
        ),
        cardBuilder: _card,
      );

  Widget _card(BuildContext context, OnlineStoreEntity item, Widget trailing) {
    final values = item.values;
    final image = '${values['image_path'] ?? ''}';
    final active = values['is_active'] == true || values['is_active'] == 1;
    final impressions =
        int.tryParse('${values['impressions_count'] ?? 0}') ?? 0;
    final clicks = int.tryParse('${values['clicks_count'] ?? 0}') ?? 0;
    final dismisses = int.tryParse('${values['dismisses_count'] ?? 0}') ?? 0;
    final audience = const {
          'all': 'الجميع',
          'guests': 'الزوار',
          'registered': 'المسجلون',
          'new_users': 'المستخدمون الجدد',
          'no_orders': 'بدون طلبات',
          'customers': 'عملاء سابقون',
        }['${values['audience_type']}'] ??
        '${values['audience_type'] ?? ''}';
    final ctr = impressions == 0 ? 0.0 : clicks * 100 / impressions;
    return Card(
      color: OnlineStoreAdminUi.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: OnlineStorePermissions.canManageContent
            ? () async {
                final payload = await showOnlineStorePopupCampaignEditor(
                    context,
                    controller: controller,
                    item: item);
                if (payload != null) {
                  await controller.updateItem(item.id, payload);
                }
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                  width: 92,
                  height: 92,
                  child: image.isEmpty
                      ? const ColoredBox(
                          color: OnlineStoreAdminUi.surfaceMuted,
                          child: Icon(Icons.campaign_outlined))
                      : OnlineStoreNetworkImage(path: image)),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text(item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800))),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: (active
                                    ? OnlineStoreAdminUi.success
                                    : OnlineStoreAdminUi.textSecondary)
                                .withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(active ? 'نشط' : 'متوقف',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: active
                                    ? OnlineStoreAdminUi.success
                                    : OnlineStoreAdminUi.textSecondary))),
                  ]),
                  const SizedBox(height: 5),
                  Text('الجمهور: $audience',
                      style: const TextStyle(
                          fontSize: 12,
                          color: OnlineStoreAdminUi.textSecondary)),
                  if ('${values['starts_at'] ?? ''}'.isNotEmpty)
                    Text('يبدأ ${onlineStoreFriendlyDate(values['starts_at'])}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            color: OnlineStoreAdminUi.textSecondary)),
                  const SizedBox(height: 7),
                  Wrap(spacing: 6, runSpacing: 5, children: [
                    _metric(Icons.visibility_outlined, '$impressions مشاهدة'),
                    _metric(Icons.ads_click_outlined, '$clicks ضغطة'),
                    _metric(Icons.visibility_off_outlined, '$dismisses إخفاء'),
                    _metric(Icons.query_stats_outlined,
                        '${ctr.toStringAsFixed(1)}% تفاعل'),
                  ]),
                ])),
            trailing,
          ]),
        ),
      ),
    );
  }

  Widget _metric(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
            color: OnlineStoreAdminUi.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: OnlineStoreAdminUi.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: OnlineStoreAdminUi.accent),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))
        ]),
      );
}
