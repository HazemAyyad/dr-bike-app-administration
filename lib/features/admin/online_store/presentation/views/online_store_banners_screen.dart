import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_banners_controller.dart';
import '../utils/online_store_permissions.dart';
import '../widgets/online_store_resource_screen.dart';
import '../widgets/online_store_banner_editor.dart';
import '../../data/online_store_models.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_network_image.dart';
import '../widgets/online_store_form_widgets.dart';

class OnlineStoreBannersScreen extends GetView<OnlineStoreBannersController> {
  const OnlineStoreBannersScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) =>
      OnlineStoreResourceScreen<OnlineStoreBannersController>(
        title: 'بانرات المتجر',
        icon: Icons.image_outlined,
        canManage: OnlineStorePermissions.canManageContent,
        subtitle: 'محتوى متعدد اللغات وجدولة ووجهة موثقة',
        actions: const {OnlineStoreResourceAction.delete},
        onReorder: controller.reorderBanners,
        showReorderHint: false,
        editor: (context, item) => showOnlineStoreBannerEditor(
          context,
          controller: controller,
          item: item,
        ),
        cardBuilder: _bannerCard,
      );

  Widget _bannerCard(
    BuildContext context,
    OnlineStoreEntity item,
    Widget trailing,
  ) {
    final image = '${item.values['image_path'] ?? ''}';
    final active =
        item.values['is_active'] == true || item.values['is_active'] == 1;
    final starts = '${item.values['starts_at'] ?? ''}';
    final ends = '${item.values['ends_at'] ?? ''}';
    final now = DateTime.now();
    final startDate = DateTime.tryParse(starts)?.toLocal();
    final endDate = DateTime.tryParse(ends)?.toLocal();
    final status = !active
        ? 'متوقف'
        : startDate != null && startDate.isAfter(now)
            ? 'مجدول'
            : endDate != null && endDate.isBefore(now)
                ? 'منتهي'
                : 'نشط الآن';
    return Card(
      color: OnlineStoreAdminUi.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: OnlineStorePermissions.canManageContent
            ? () async {
                final payload = await showOnlineStoreBannerEditor(
                  context,
                  controller: controller,
                  item: item,
                );
                if (payload != null) {
                  await controller.updateItem(item.id, payload);
                }
              }
            : null,
        child: Row(children: [
          SizedBox(
            width: 112,
            height: 86,
            child: image.isEmpty
                ? const ColoredBox(
                    color: OnlineStoreAdminUi.surfaceMuted,
                    child: Icon(Icons.image_not_supported_outlined),
                  )
                : OnlineStoreNetworkImage(path: image),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(status,
                      style: TextStyle(
                        color: status == 'نشط الآن'
                            ? OnlineStoreAdminUi.success
                            : OnlineStoreAdminUi.textSecondary,
                        fontWeight: FontWeight.w700,
                      )),
                  if (starts.isNotEmpty)
                    Text('يبدأ ${onlineStoreFriendlyDate(starts)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            color: OnlineStoreAdminUi.textSecondary)),
                ],
              ),
            ),
          ),
          trailing,
        ]),
      ),
    );
  }
}
