import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_banners_controller.dart';
import '../utils/online_store_permissions.dart';
import '../widgets/online_store_resource_screen.dart';
import '../widgets/online_store_banner_editor.dart';

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
        editor: (context, item) => showOnlineStoreBannerEditor(
          context,
          controller: controller,
          item: item,
        ),
      );
}
