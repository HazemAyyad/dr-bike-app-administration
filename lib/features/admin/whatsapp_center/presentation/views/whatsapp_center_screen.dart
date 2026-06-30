import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/whatsapp_models.dart';
import '../controllers/whatsapp_center_controller.dart';

class WhatsAppCenterScreen extends GetView<WhatsAppCenterController> {
  const WhatsAppCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مركز واتساب')),
        body: Column(children: [
          Obx(() => NavigationBar(
                selectedIndex: controller.tabIndex.value,
                onDestinationSelected: controller.selectTab,
                destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      label: 'لوحة التحكم'),
                  NavigationDestination(
                      icon: Icon(Icons.forum_outlined), label: 'المحادثات'),
                  NavigationDestination(
                      icon: Icon(Icons.description_outlined), label: 'القوالب'),
                  NavigationDestination(
                      icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
                ],
              )),
          Expanded(child: Obx(() {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.error.value != null) {
              return _StateMessage(
                icon: Icons.cloud_off,
                text: controller.error.value!,
                action: controller.refreshCurrent,
              );
            }
            final children = <Widget>[
              _DashboardTab(controller: controller),
              _ConversationsTab(controller: controller),
              _TemplatesTab(controller: controller),
              _SettingsTab(controller: controller),
            ];
            return RefreshIndicator(
              onRefresh: controller.refreshCurrent,
              child: children[controller.tabIndex.value],
            );
          })),
        ]),
        floatingActionButton: Obx(() => controller.tabIndex.value == 1
            ? FloatingActionButton.extended(
                onPressed: () => _showDirectMessage(context),
                icon: const Icon(Icons.send),
                label: const Text('إرسال رسالة'))
            : const SizedBox.shrink()),
      ),
    );
  }

  Future<void> _showDirectMessage(BuildContext context) async {
    final phone = TextEditingController();
    final message = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إرسال رسالة مباشرة'),
        content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'رقم الهاتف الدولي',
                      hintText: '9705XXXXXXXX')),
              const SizedBox(height: 12),
              TextField(
                  controller: message,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'الرسالة')),
            ])),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('إلغاء')),
          Obx(() => FilledButton.icon(
                onPressed: controller.actionLoading.value
                    ? null
                    : () async {
                        if (await controller.sendDirect(
                            phone.text, message.text)) {
                          Get.back();
                        }
                      },
                icon: controller.actionLoading.value
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: const Text('إرسال'),
              )),
        ],
      ),
    );
    phone.dispose();
    message.dispose();
  }
}

class _DashboardTab extends StatelessWidget {
  final WhatsAppCenterController controller;
  const _DashboardTab({required this.controller});
  @override
  Widget build(BuildContext context) {
    final d = controller.dashboard.value;
    if (d == null) {
      return const _StateMessage(
          icon: Icons.analytics_outlined, text: 'لا توجد بيانات');
    }
    final items = <Map<String, dynamic>>[
      {
        'label': 'إجمالي جهات الاتصال',
        'value': d.totalContacts,
        'icon': Icons.contacts_outlined
      },
      {
        'label': 'إجمالي المحادثات',
        'value': d.totalConversations,
        'icon': Icons.forum_outlined
      },
      {
        'label': 'المحادثات المفتوحة',
        'value': d.openConversations,
        'icon': Icons.mark_chat_unread_outlined
      },
      {
        'label': 'محادثات غير مقروءة',
        'value': d.unreadConversations,
        'icon': Icons.notifications_active_outlined
      },
      {
        'label': 'رسائل اليوم',
        'value': d.messagesToday,
        'icon': Icons.today_outlined
      },
      {
        'label': 'رسائل فاشلة اليوم',
        'value': d.failedMessagesToday,
        'icon': Icons.error_outline
      },
    ];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('نظرة عامة', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        final count = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 520
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: count,
              childAspectRatio: 2.35,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12),
          itemCount: items.length,
          itemBuilder: (_, i) => Card(
              child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              CircleAvatar(child: Icon(items[i]['icon'] as IconData)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Text('${items[i]['value']}',
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text(items[i]['label'].toString(), maxLines: 2),
                  ])),
            ]),
          )),
        );
      }),
    ]);
  }
}

class _ConversationsTab extends StatelessWidget {
  final WhatsAppCenterController controller;
  const _ConversationsTab({required this.controller});
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(12), children: [
        SearchBar(
          controller: controller.searchController,
          hintText: 'بحث بالاسم أو الرقم أو الرسالة',
          leading: const Icon(Icons.search),
          trailing: [
            IconButton(
                onPressed: controller.loadConversations,
                icon: const Icon(Icons.arrow_forward))
          ],
          onSubmitted: (_) => controller.loadConversations(),
        ),
        const SizedBox(height: 10),
        Obx(() => Wrap(
            spacing: 8,
            children: const <Map<String, String>>[
              {'id': 'all', 'label': 'الكل'},
              {'id': 'open', 'label': 'مفتوحة'},
              {'id': 'pending', 'label': 'معلقة'},
              {'id': 'closed', 'label': 'مغلقة'},
            ]
                .map((item) => ChoiceChip(
                      label: Text(item['label']!),
                      selected: controller.selectedStatus.value == item['id'],
                      onSelected: (_) {
                        controller.selectedStatus.value = item['id']!;
                        controller.loadConversations();
                      },
                    ))
                .toList())),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.conversations.isEmpty) {
            return const SizedBox(
                height: 350,
                child: _StateMessage(
                    icon: Icons.chat_bubble_outline, text: 'لا توجد محادثات'));
          }
          return Column(
              children: controller.conversations
                  .map((item) => Card(
                        child: ListTile(
                          onTap: () =>
                              Get.toNamed('/WhatsAppConversation/${item.id}'),
                          leading: CircleAvatar(
                              child: Text((item.contact?.name ?? item.phone)
                                  .characters
                                  .first)),
                          title: Text(item.contact?.name?.isNotEmpty == true
                              ? item.contact!.name!
                              : item.phone),
                          subtitle: Text(item.lastMessage ?? 'لا توجد رسائل',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_shortDate(item.lastMessageAt),
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                if (item.unreadCount > 0)
                                  Badge(label: Text('${item.unreadCount}')),
                                Text(_statusLabel(item.status),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: _statusColor(item.status))),
                              ]),
                        ),
                      ))
                  .toList());
        }),
        const SizedBox(height: 80),
      ]);
}

class _TemplatesTab extends StatelessWidget {
  final WhatsAppCenterController controller;
  const _TemplatesTab({required this.controller});
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(12), children: [
        Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
                onPressed: () => _edit(context),
                icon: const Icon(Icons.add),
                label: const Text('إضافة قالب'))),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
                'قوالب محلية للصياغة. إرسال قالب عبر Meta يتطلب اعتماده في WhatsApp Manager.')),
        Obx(() => controller.templates.isEmpty
            ? const SizedBox(
                height: 300,
                child: _StateMessage(
                    icon: Icons.description_outlined, text: 'لا توجد قوالب'))
            : Column(
                children: controller.templates
                    .map((t) => Card(
                            child: ListTile(
                          leading: Icon(
                              t.isActive
                                  ? Icons.check_circle
                                  : Icons.pause_circle_outline,
                              color: t.isActive ? Colors.green : Colors.grey),
                          title: Text(t.name),
                          subtitle: Text(
                              '${t.category ?? 'بدون تصنيف'} • ${t.language}\n${t.body}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis),
                          isThreeLine: true,
                          onTap: () => _edit(context, t),
                          trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final yes = await Get.dialog<bool>(AlertDialog(
                                    title: const Text('حذف القالب؟'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Get.back(result: false),
                                          child: const Text('إلغاء')),
                                      FilledButton(
                                          onPressed: () =>
                                              Get.back(result: true),
                                          child: const Text('حذف'))
                                    ]));
                                if (yes == true) {
                                  controller.deleteTemplate(t.id);
                                }
                              }),
                        )))
                    .toList())),
      ]);

  Future<void> _edit(BuildContext context, [WhatsAppTemplate? template]) async {
    final name = TextEditingController(text: template?.name);
    final category = TextEditingController(text: template?.category);
    final language = TextEditingController(text: template?.language ?? 'ar');
    final body = TextEditingController(text: template?.body);
    final variables =
        TextEditingController(text: template?.variables.join(', '));
    var active = template?.isActive ?? true;
    await showDialog<void>(
        context: context,
        builder: (_) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: Text(template == null ? 'إضافة قالب' : 'تعديل القالب'),
                content: SingleChildScrollView(
                    child: SizedBox(
                        width: 460,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          TextField(
                              controller: name,
                              decoration:
                                  const InputDecoration(labelText: 'الاسم')),
                          TextField(
                              controller: category,
                              decoration:
                                  const InputDecoration(labelText: 'التصنيف')),
                          TextField(
                              controller: language,
                              decoration:
                                  const InputDecoration(labelText: 'اللغة')),
                          TextField(
                              controller: body,
                              minLines: 4,
                              maxLines: 8,
                              decoration:
                                  const InputDecoration(labelText: 'النص')),
                          TextField(
                              controller: variables,
                              decoration: const InputDecoration(
                                  labelText: 'المتغيرات مفصولة بفاصلة')),
                          SwitchListTile(
                              value: active,
                              onChanged: (v) => setState(() => active = v),
                              title: const Text('نشط')),
                        ]))),
                actions: [
                  TextButton(onPressed: Get.back, child: const Text('إلغاء')),
                  FilledButton(
                      onPressed: () async {
                        final ok = await controller.saveTemplate({
                          'name': name.text.trim(),
                          'category': category.text.trim(),
                          'language': language.text.trim(),
                          'body': body.text.trim(),
                          'variables': variables.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList(),
                          'is_active': active,
                        }, id: template?.id);
                        if (ok) Get.back();
                      },
                      child: const Text('حفظ')),
                ],
              ),
            ));
    name.dispose();
    category.dispose();
    language.dispose();
    body.dispose();
    variables.dispose();
  }
}

class _SettingsTab extends StatelessWidget {
  final WhatsAppCenterController controller;
  const _SettingsTab({required this.controller});
  @override
  Widget build(BuildContext context) {
    final settings = controller.settings.value;
    if (settings == null) {
      return const _StateMessage(
          icon: Icons.settings_outlined, text: 'لا توجد إعدادات');
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(
          child: ListTile(
        leading: Icon(settings.configured ? Icons.cloud_done : Icons.cloud_off,
            color: settings.configured ? Colors.green : Colors.red),
        title: Text(settings.configured ? 'الاتصال مهيأ' : 'الاتصال غير مكتمل'),
        subtitle: Text(
            '${settings.message}\nPhone number ID: ${settings.phoneNumberId ?? '—'}'),
        isThreeLine: true,
      )),
      const SizedBox(height: 16),
      Text('رسالة تجربة', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 10),
      TextField(
          controller: controller.testPhoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
              labelText: 'رقم الهاتف الدولي', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(
          controller: controller.testMessageController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
              labelText: 'نص التجربة', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      Obx(() => FilledButton.icon(
            onPressed: controller.actionLoading.value
                ? null
                : () => controller.sendDirect(
                    controller.testPhoneController.text,
                    controller.testMessageController.text,
                    test: true),
            icon: const Icon(Icons.send),
            label: const Text('إرسال رسالة تجربة'),
          )),
      const SizedBox(height: 12),
      const Text(
          'رمز الوصول محفوظ في Laravel .env ولا يتم عرضه أو تخزينه داخل التطبيق.'),
    ]);
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Future<void> Function()? action;
  const _StateMessage({required this.icon, required this.text, this.action});
  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
              height: 320,
              child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 52, color: Colors.grey),
                const SizedBox(height: 12),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(text, textAlign: TextAlign.center)),
                if (action != null)
                  TextButton.icon(
                      onPressed: action,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة')),
              ])))
        ],
      );
}

String _shortDate(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  return '${local.day}/${local.month} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _statusLabel(String status) =>
    const {
      'open': 'مفتوحة',
      'pending': 'معلقة',
      'closed': 'مغلقة',
    }[status] ??
    status;
Color _statusColor(String status) => status == 'open'
    ? Colors.green
    : status == 'pending'
        ? Colors.orange
        : Colors.grey;
