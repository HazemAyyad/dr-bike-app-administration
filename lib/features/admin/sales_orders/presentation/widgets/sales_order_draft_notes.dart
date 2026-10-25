import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sales_orders_controller.dart';
import 'sales_order_note_media.dart';
import 'sales_order_modal_theme.dart';

class SalesOrderDraftNotes extends GetView<SalesOrdersController> {
  const SalesOrderDraftNotes({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => SalesOrderModalTheme(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
            controller: controller.notesController,
            maxLines: 3,
            maxLength: 2000,
            decoration: const InputDecoration(
                labelText: 'ملاحظات داخلية',
                hintText: 'أضف ملاحظة مع صورة أو فيديو عند الحاجة',
                filled: true,
                fillColor: Color(0xFFF3F4F6),
                border: OutlineInputBorder())),
        Obx(() => Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < controller.draftNoteMedia.length; i++)
                SalesOrderNoteMediaTile(
                    path: controller.draftNoteMedia[i].path,
                    isVideo: controller.draftNoteMedia[i].mediaKind == 'video',
                    local: true,
                    onRemove: controller.isSubmitting.value ||
                            controller.isPickingNoteMedia.value
                        ? null
                        : () => controller.draftNoteMedia.removeAt(i)),
            ])),
        Obx(() => Wrap(spacing: 8, children: [
              TextButton.icon(
                  onPressed: controller.isSubmitting.value ||
                          controller.isPickingNoteMedia.value ||
                          controller.draftNoteMedia.length >= 5
                      ? null
                      : () => controller.pickDraftNoteMedia(camera: true),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('كاميرا / فيديو')),
              TextButton.icon(
                  onPressed: controller.isSubmitting.value ||
                          controller.isPickingNoteMedia.value ||
                          controller.draftNoteMedia.length >= 5
                      ? null
                      : () => controller.pickDraftNoteMedia(camera: false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('المعرض')),
              if (controller.activeEditSalesOrderId.value != null)
                TextButton.icon(
                    onPressed: () => controller.showOrderNotes(
                        controller.activeEditSalesOrderId.value!,
                        scope: 'internal'),
                    icon: const Icon(Icons.history),
                    label: const Text('سجل الملاحظات والمرفقات')),
            ])),
        Obx(() => Text(
            '${controller.draftNoteMedia.length}/5 مرفقات • الصورة 8 MB، الفيديو 50 MB',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)))),
      ]));
}
