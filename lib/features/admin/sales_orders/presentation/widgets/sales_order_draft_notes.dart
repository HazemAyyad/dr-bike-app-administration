import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sales_orders_controller.dart';

class SalesOrderDraftNotes extends GetView<SalesOrdersController> {
  const SalesOrderDraftNotes({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
            controller: controller.notesController,
            maxLines: 3,
            maxLength: 2000,
            decoration: const InputDecoration(
                labelText: 'ملاحظات داخلية', border: OutlineInputBorder())),
        Obx(() => Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < controller.draftNoteImages.length; i++)
                Stack(children: [
                  Image.file(File(controller.draftNoteImages[i].path),
                      width: 76, height: 76, fit: BoxFit.cover),
                  Positioned(
                      top: 0,
                      left: 0,
                      child: IconButton(
                          style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFE5E7EB)),
                          onPressed: controller.isSubmitting.value
                              ? null
                              : () => controller.draftNoteImages.removeAt(i),
                          icon: const Icon(Icons.close,
                              color: Color(0xFF111827)))),
                ]),
            ])),
        Obx(() => Wrap(spacing: 8, children: [
              TextButton.icon(
                  onPressed: controller.isSubmitting.value ||
                          controller.draftNoteImages.length >= 5
                      ? null
                      : () => controller.pickDraftNoteImages(camera: true),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('صورة للملاحظة')),
              TextButton.icon(
                  onPressed: controller.isSubmitting.value ||
                          controller.draftNoteImages.length >= 5
                      ? null
                      : () => controller.pickDraftNoteImages(camera: false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('المعرض')),
              if (controller.activeEditSalesOrderId.value != null)
                TextButton.icon(
                    onPressed: () => controller.showOrderNotes(
                        controller.activeEditSalesOrderId.value!,
                        scope: 'internal'),
                    icon: const Icon(Icons.history),
                    label: const Text('سجل الملاحظات والصور')),
            ])),
      ]);
}
