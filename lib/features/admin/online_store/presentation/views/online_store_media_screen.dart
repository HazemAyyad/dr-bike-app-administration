import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/online_store_media_controller.dart';

class OnlineStoreMediaScreen extends GetView<OnlineStoreMediaController> {
  const OnlineStoreMediaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final listingId = Get.arguments as int;
    if (controller.listingId != listingId) {
      controller.load(listingId);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('وسائط المتجر'),
        actions: [
          IconButton(
              onPressed: controller.save, icon: const Icon(Icons.save_outlined))
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ReorderableListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.items.length,
          onReorder: controller.reorder,
          itemBuilder: (_, index) {
            final media = controller.items[index];
            return Card(
              key: ValueKey(media.sourceMediaId),
              color: const Color(0xFFF7F7FA),
              child: ListTile(
                leading: media.url.isEmpty
                    ? const Icon(Icons.image_outlined)
                    : Image.network(media.url,
                        width: 48, height: 48, fit: BoxFit.cover),
                title: Text(media.isMain
                    ? 'الصورة الرئيسية'
                    : 'وسيط #${media.sourceMediaId}'),
                subtitle:
                    Text('${media.sourceType} • ترتيب ${media.sortOrder + 1}'),
                trailing: Wrap(children: [
                  IconButton(
                    tooltip: 'تحديد كرئيسية',
                    onPressed: () => controller.selectMain(media.sourceMediaId),
                    icon: Icon(media.isMain ? Icons.star : Icons.star_border),
                  ),
                  IconButton(
                    tooltip: media.isVisible ? 'إخفاء' : 'إظهار',
                    onPressed: () =>
                        controller.toggleVisible(media.sourceMediaId),
                    icon: Icon(media.isVisible
                        ? Icons.visibility
                        : Icons.visibility_off),
                  ),
                ]),
              ),
            );
          },
        );
      }),
    );
  }
}
