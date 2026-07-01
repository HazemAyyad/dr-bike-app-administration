import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:typed_data';

import '../controllers/whatsapp_conversation_controller.dart';

class WhatsAppConversationScreen
    extends GetView<WhatsAppConversationController> {
  const WhatsAppConversationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF075E54),
                brightness: Theme.of(context).brightness,
              ),
            ),
            child: Scaffold(
              appBar: AppBar(
                  title: Obx(() {
                    final c = controller.conversation.value;
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c?.contact?.name?.isNotEmpty == true
                              ? c!.contact!.name!
                              : c?.phone ?? 'المحادثة'),
                          if (c != null)
                            Text(c.phone, style: const TextStyle(fontSize: 12)),
                        ]);
                  }),
                  actions: [
                    Obx(() {
                      final contact = controller.conversation.value?.contact;
                      final linked = contact?.customerId != null ||
                          contact?.supplierId != null;
                      return linked
                          ? const SizedBox.shrink()
                          : IconButton(
                              tooltip: 'إضافة للنظام',
                              icon: const Icon(Icons.person_add_alt_1),
                              onPressed: () => _showAddPerson(context),
                            );
                    }),
                  ]),
              body: Column(children: [
                Expanded(child: Obx(() {
                  if (controller.loading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.error.value != null) {
                    return Center(
                        child: Text(controller.error.value!,
                            textAlign: TextAlign.center));
                  }
                  if (controller.messages.isEmpty) {
                    return const Center(child: Text('لا توجد رسائل بعد'));
                  }
                  return RefreshIndicator(
                    onRefresh: controller.load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: controller.messages.length,
                      itemBuilder: (_, index) {
                        final message = controller.messages[index];
                        final outbound = message.direction == 'outbound';
                        return Align(
                          alignment: outbound
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * .78),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
                            decoration: BoxDecoration(
                              color: outbound
                                  ? const Color(0xFFD9FDD3)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x18000000), blurRadius: 4)
                              ],
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (message.mediaUrl != null &&
                                      message.type == 'image')
                                    GestureDetector(
                                      onTap: () =>
                                          controller.showMedia(message),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: FutureBuilder<Uint8List>(
                                          future:
                                              controller.getMediaBytes(message),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              return Image.memory(
                                                snapshot.data!,
                                                width: 230,
                                                height: 180,
                                                fit: BoxFit.cover,
                                              );
                                            }
                                            if (snapshot.hasError) {
                                              return const SizedBox(
                                                width: 230,
                                                height: 90,
                                                child: Center(
                                                    child: Icon(Icons
                                                        .broken_image_outlined)),
                                              );
                                            }
                                            return const SizedBox(
                                              width: 230,
                                              height: 150,
                                              child: Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  if (message.mediaUrl != null &&
                                      message.type != 'image')
                                    InkWell(
                                      onTap: () =>
                                          controller.showMedia(message),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        margin:
                                            const EdgeInsets.only(bottom: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(0xFFB8CBC6)),
                                        ),
                                        child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.attach_file,
                                                  color: Color(0xFF075E54)),
                                              SizedBox(width: 6),
                                              Text('فتح المرفق'),
                                            ]),
                                      ),
                                    ),
                                  if (message.body != null) Text(message.body!),
                                  const SizedBox(height: 4),
                                  Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(_time(message.createdAt),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey)),
                                        if (outbound) ...[
                                          const SizedBox(width: 5),
                                          Icon(_statusIcon(message.status),
                                              size: 15,
                                              color: message.status == 'failed'
                                                  ? Colors.red
                                                  : Colors.blueGrey),
                                        ],
                                      ]),
                                  if (message.status == 'failed' &&
                                      message.errorMessage != null)
                                    Text(message.errorMessage!,
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.red)),
                                ]),
                          ),
                        );
                      },
                    ),
                  );
                })),
                SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                      child: Row(children: [
                        IconButton(
                          tooltip: 'صورة أو مرفق',
                          onPressed: controller.pickAndSendAttachment,
                          icon: const Icon(Icons.attach_file,
                              color: Color(0xFF075E54)),
                        ),
                        Expanded(
                            child: TextField(
                          controller: controller.input,
                          minLines: 1,
                          maxLines: 5,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: 'اكتب رسالة...',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24)),
                          ),
                        )),
                        const SizedBox(width: 8),
                        Obx(() => IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF075E54),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: controller.sending.value
                                  ? null
                                  : controller.send,
                              icon: controller.sending.value
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.send),
                            )),
                      ]),
                    )),
              ]),
            )),
      );

  Future<void> _showAddPerson(BuildContext context) async {
    final name = TextEditingController(
        text: controller.conversation.value?.contact?.name);
    var type = 'customer';
    await showDialog<void>(
        context: context,
        builder: (_) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: const Text('إضافة الرقم إلى النظام'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(controller.conversation.value?.phone ?? '',
                      textDirection: TextDirection.ltr),
                  TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'الاسم')),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'customer',
                          label: Text('زبون'),
                          icon: Icon(Icons.person_outline)),
                      ButtonSegment(
                          value: 'seller',
                          label: Text('تاجر'),
                          icon: Icon(Icons.store_outlined)),
                    ],
                    selected: {type},
                    onSelectionChanged: (value) =>
                        setState(() => type = value.first),
                  ),
                ]),
                actions: [
                  TextButton(onPressed: Get.back, child: const Text('إلغاء')),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF075E54)),
                    onPressed: () async {
                      if (await controller.addAsPerson(
                          type, name.text.trim())) {
                        Get.back();
                      }
                    },
                    child: const Text('إضافة'),
                  ),
                ],
              ),
            ));
    name.dispose();
  }
}

IconData _statusIcon(String status) {
  if (status == 'read' || status == 'delivered') return Icons.done_all;
  if (status == 'sent') return Icons.done;
  if (status == 'failed') return Icons.error_outline;
  return Icons.schedule;
}

String _time(DateTime? date) {
  if (date == null) return '';
  final d = date.toLocal();
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
