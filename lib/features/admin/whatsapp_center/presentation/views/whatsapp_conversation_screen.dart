import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/whatsapp_conversation_controller.dart';

class WhatsAppConversationScreen
    extends GetView<WhatsAppConversationController> {
  const WhatsAppConversationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: Obx(() {
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
          })),
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
                            maxWidth: MediaQuery.sizeOf(context).width * .78),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
                        decoration: BoxDecoration(
                          color: outbound
                              ? const Color(0xFFD9FDD3)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Color(0x18000000), blurRadius: 4)
                          ],
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message.body ?? '[${message.type}]'),
                              const SizedBox(height: 4),
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Text(_time(message.createdAt),
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey)),
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
                          onPressed:
                              controller.sending.value ? null : controller.send,
                          icon: controller.sending.value
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send),
                        )),
                  ]),
                )),
          ]),
        ),
      );
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
