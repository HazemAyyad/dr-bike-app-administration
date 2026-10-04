import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_banners_controller.dart';
import '../utils/online_store_permissions.dart';
import '../widgets/online_store_resource_screen.dart';

class OnlineStoreBannersScreen extends GetView<OnlineStoreBannersController> {
  const OnlineStoreBannersScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) =>
      OnlineStoreResourceScreen<OnlineStoreBannersController>(
        title: 'بانرات المتجر',
        icon: Icons.image_outlined,
        canManage: OnlineStorePermissions.canManageContent,
        subtitle: 'محتوى متعدد اللغات وجدولة ووجهة موثقة',
        fields: const [
          OnlineStoreFormField('image_path', 'مسار الصورة'),
          OnlineStoreFormField('title_translations.ar', 'العنوان العربي'),
          OnlineStoreFormField('title_translations.en', 'العنوان الإنجليزي'),
          OnlineStoreFormField('content_translations.ar', 'المحتوى العربي'),
          OnlineStoreFormField('content_translations.en', 'المحتوى الإنجليزي'),
          OnlineStoreFormField('action_type', 'نوع الوجهة',
              options: ['none', 'listing', 'category', 'url']),
          OnlineStoreFormField('action_target_id', 'رقم الوجهة', numeric: true),
          OnlineStoreFormField('action_url', 'الرابط'),
          OnlineStoreFormField('starts_at', 'يبدأ في'),
          OnlineStoreFormField('ends_at', 'ينتهي في'),
          OnlineStoreFormField('is_active', 'نشط', boolean: true),
          OnlineStoreFormField('sort_order', 'الترتيب', numeric: true),
        ],
      );
}
