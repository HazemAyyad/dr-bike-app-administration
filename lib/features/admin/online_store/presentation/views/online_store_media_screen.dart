import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/online_store_media_controller.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_network_image.dart';

class OnlineStoreMediaScreen extends GetView<OnlineStoreMediaController> {
  const OnlineStoreMediaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final listingId = Get.arguments as int;
    if (controller.listingId != listingId) {
      controller.load(listingId);
    }
    return Scaffold(
      backgroundColor: OnlineStoreAdminUi.pageBackground,
      appBar: AppBar(
        title: const Text('صور المنتج في المتجر'),
        actions: [
          Obx(() => IconButton(
              tooltip: 'حفظ التغييرات',
              onPressed: controller.saving.value ? null : controller.save,
              icon: const Icon(Icons.save_outlined)))
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: OnlineStoreAdminUi.surface,
        foregroundColor: OnlineStoreAdminUi.textPrimary,
        onPressed: () async {
          final file =
              await ImagePicker().pickImage(source: ImageSource.gallery);
          if (file != null) await controller.addStoreImage(file);
        },
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('إضافة صورة'),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null && controller.items.isEmpty) {
          return Center(child: Text(controller.error.value!));
        }
        return Column(children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OnlineStoreAdminUi.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(children: [
              Icon(Icons.touch_app_outlined, color: OnlineStoreAdminUi.accent),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                'اسحب الصور لترتيبها، اختر نجمة للصورة الرئيسية، أو أضف صورة خاصة بالمتجر.',
              )),
            ]),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: () => controller.load(listingId),
            child: ReorderableListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: controller.items.length,
              onReorder: controller.reorder,
              itemBuilder: (_, index) {
                final media = controller.items[index];
                return Card(
                  key: ValueKey(media.sourceMediaId),
                  color: OnlineStoreAdminUi.surface,
                  child: ListTile(
                    leading: media.url.isEmpty
                        ? const Icon(Icons.image_outlined)
                        : SizedBox.square(
                            dimension: 48,
                            child: OnlineStoreNetworkImage(path: media.url),
                          ),
                    title: Text(media.isMain
                        ? 'الصورة الرئيسية'
                        : 'وسيط #${media.sourceMediaId}'),
                    subtitle: Text(media.sourceType == 'store_specific'
                        ? 'صورة خاصة بالمتجر • الموضع ${media.sortOrder + 1}'
                        : 'من صور المنتج الأصلية • الموضع ${media.sortOrder + 1}'),
                    trailing: Wrap(children: [
                      IconButton(
                        tooltip: 'تحديد كرئيسية',
                        onPressed: () =>
                            controller.selectMain(media.sourceMediaId),
                        icon:
                            Icon(media.isMain ? Icons.star : Icons.star_border),
                      ),
                      IconButton(
                        tooltip: media.isVisible ? 'إخفاء' : 'إظهار',
                        onPressed: () =>
                            controller.toggleVisible(media.sourceMediaId),
                        icon: Icon(media.isVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                      ),
                      IconButton(
                        tooltip: 'إزالة من المتجر',
                        onPressed: () => controller.remove(media.sourceMediaId),
                        icon: const Icon(Icons.delete_outline,
                            color: OnlineStoreAdminUi.danger),
                      ),
                    ]),
                  ),
                );
              },
            ),
          )),
        ]);
      }),
    );
  }
}
