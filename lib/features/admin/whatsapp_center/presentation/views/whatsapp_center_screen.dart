import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/whatsapp_models.dart';
import '../controllers/whatsapp_center_controller.dart';

class WhatsAppCenterScreen extends GetView<WhatsAppCenterController> {
  const WhatsAppCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF075E54),
              brightness: Theme.of(context).brightness,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFFF7FAF9),
              surfaceTintColor: Colors.transparent,
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Color(0xFFF7FAF9),
              surfaceTintColor: Colors.transparent,
            ),
          ),
          child: Scaffold(
            appBar: AppBar(title: const Text('مركز التواصل الاجتماعي')),
            body: Column(children: [
              _SocialChannelBar(controller: controller),
              Obx(() => Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    child: Row(
                      children: const [
                        [Icons.dashboard_outlined, 'الرئيسية'],
                        [Icons.forum_outlined, 'المحادثات'],
                        [Icons.description_outlined, 'القوالب'],
                        [Icons.settings_outlined, 'الإعدادات'],
                      ].asMap().entries.map((entry) {
                        final selected = controller.tabIndex.value == entry.key;
                        return Expanded(
                            child: InkWell(
                          onTap: () => controller.selectTab(entry.key),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF075E54)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFDDE5E3)),
                            ),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(entry.value[0] as IconData,
                                      size: 20,
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF075E54)),
                                  Text(entry.value[1] as String,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: selected
                                              ? Colors.white
                                              : const Color(0xFF263B37))),
                                ]),
                          ),
                        ));
                      }).toList(),
                    ),
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
                    backgroundColor: const Color(0xFF075E54),
                    foregroundColor: Colors.white,
                    onPressed: () => _showDirectMessage(context),
                    icon: const Icon(Icons.send),
                    label: const Text('إرسال رسالة'))
                : const SizedBox.shrink()),
          )),
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
              Obx(() => _WhatsAppAccountPicker(controller: controller)),
              const SizedBox(height: 12),
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
      Text('نظرة عامة على مركز التواصل',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        final count = constraints.maxWidth >= 900 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: count,
              childAspectRatio: constraints.maxWidth < 520 ? 1.55 : 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8),
          itemCount: items.length,
          itemBuilder: (_, i) => Card(
            elevation: 0,
            color: const Color(0xFFF0F7F5),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFD5E8E2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                CircleAvatar(
                    backgroundColor: const Color(0xFFD9EEE8),
                    child: Icon(items[i]['icon'] as IconData,
                        color: const Color(0xFF075E54))),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Text(
                        '${items[i]['value']}',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: const Color(0xFF102A25),
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      Text(
                        items[i]['label'].toString(),
                        maxLines: 2,
                        style: const TextStyle(
                          color: Color(0xFF425E58),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ])),
              ]),
            ),
          ),
        );
      }),
      if (d.channelStats.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('أداء القنوات', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final count = constraints.maxWidth >= 900 ? 3 : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: count,
              childAspectRatio: constraints.maxWidth < 520 ? 2.15 : 2.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: d.channelStats.length,
            itemBuilder: (_, i) => _ChannelStatsCard(stats: d.channelStats[i]),
          );
        }),
      ],
    ]);
  }
}

class _ChannelStatsCard extends StatelessWidget {
  final SocialChannelStats stats;
  const _ChannelStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final color = _channelColor(stats.channel);
    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: .25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(_channelIcon(stats.channel), color: color),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _channelLabel(stats.channel),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(stats.messagesToday.toString(),
                  style: TextStyle(
                      color: color, fontSize: 24, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _MetricPill(label: 'محادثات', value: stats.conversations),
                _MetricPill(label: 'مفتوحة', value: stats.open),
                _MetricPill(label: 'غير مقروء', value: stats.unread),
                if (stats.failedToday > 0)
                  _MetricPill(
                    label: 'فاشلة',
                    value: stats.failedToday,
                    color: Colors.red,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MetricPill({
    required this.label,
    required this.value,
    this.color = const Color(0xFF52635F),
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label $value',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _SocialChannelBar extends StatelessWidget {
  final WhatsAppCenterController controller;
  const _SocialChannelBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    const channels = [
      _SocialChannel(
        id: 'all',
        icon: Icons.all_inbox_outlined,
        label: 'الكل',
        color: Color(0xFF455A64),
      ),
      _SocialChannel(
        id: 'whatsapp',
        icon: Icons.chat,
        label: 'واتساب',
        color: Color(0xFF075E54),
      ),
      _SocialChannel(
        id: 'facebook',
        icon: Icons.facebook,
        label: 'فيسبوك',
        color: Color(0xFF1877F2),
      ),
      _SocialChannel(
        id: 'instagram',
        icon: Icons.camera_alt_outlined,
        label: 'إنستغرام',
        color: Color(0xFFE4405F),
      ),
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFFF7FAF9),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
      child: Obx(() => Row(
            children: channels
                .map((channel) => Expanded(
                      child: _ChannelChip(
                        channel: channel,
                        active: controller.selectedChannel.value == channel.id,
                        onTap: () => controller.selectChannel(channel.id),
                      ),
                    ))
                .toList(),
          )),
    );
  }
}

class _SocialChannel {
  final String id;
  final IconData icon;
  final String label;
  final Color color;

  const _SocialChannel({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
  });
}

class _ChannelChip extends StatelessWidget {
  final _SocialChannel channel;
  final bool active;
  final VoidCallback onTap;
  const _ChannelChip({
    required this.channel,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: active ? channel.color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? channel.color : const Color(0xFFDDE5E3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              channel.icon,
              size: 18,
              color: active ? Colors.white : channel.color,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                channel.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : const Color(0xFF263B37),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationsTab extends StatelessWidget {
  final WhatsAppCenterController controller;
  const _ConversationsTab({required this.controller});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 70),
        children: [
          _ConversationSearch(controller: controller),
          const SizedBox(height: 8),
          _ConversationFilters(controller: controller),
          const SizedBox(height: 8),
          Obx(() {
            if (controller.conversations.isEmpty) {
              return const SizedBox(
                height: 350,
                child: _StateMessage(
                  icon: Icons.chat_bubble_outline,
                  text: 'لا توجد محادثات تطابق الفلاتر الحالية',
                ),
              );
            }
            return Column(
              children: controller.conversations
                  .map((item) => _ConversationCard(
                        item: item,
                        controller: controller,
                      ))
                  .toList(),
            );
          }),
        ],
      );
}

class _ConversationSearch extends StatelessWidget {
  final WhatsAppCenterController controller;
  const _ConversationSearch({required this.controller});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: SearchBar(
          controller: controller.searchController,
          hintText: 'بحث بالاسم أو الرقم أو الرسالة',
          leading: const Icon(Icons.search),
          trailing: [
            IconButton(
              tooltip: 'مسح الفلاتر',
              onPressed: controller.clearConversationFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
            ),
            IconButton(
              tooltip: 'بحث',
              onPressed: controller.loadConversations,
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
          onSubmitted: (_) => controller.loadConversations(),
        ),
      );
}

class _ConversationFilters extends StatelessWidget {
  final WhatsAppCenterController controller;
  const _ConversationFilters({required this.controller});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Wrap(
                spacing: 6,
                runSpacing: 6,
                children: const <Map<String, String>>[
                  {'id': 'all', 'label': 'كل الحالات'},
                  {'id': 'open', 'label': 'مفتوحة'},
                  {'id': 'pending', 'label': 'معلقة'},
                  {'id': 'closed', 'label': 'مغلقة'},
                ]
                    .map((item) => ChoiceChip(
                          label: Text(item['label']!),
                          selected:
                              controller.selectedStatus.value == item['id'],
                          onSelected: (_) =>
                              controller.selectStatus(item['id']!),
                        ))
                    .toList(),
              )),
          const SizedBox(height: 6),
          Obx(() => Wrap(
                spacing: 6,
                runSpacing: 6,
                children: const <Map<String, dynamic>>[
                  {'id': 'all', 'label': 'الكل', 'icon': Icons.all_inbox},
                  {
                    'id': 'unread',
                    'label': 'غير مقروء',
                    'icon': Icons.mark_chat_unread_outlined
                  },
                  {
                    'id': 'failed',
                    'label': 'فاشلة',
                    'icon': Icons.error_outline
                  },
                  {
                    'id': 'needs_reply',
                    'label': 'تحتاج رد',
                    'icon': Icons.priority_high_outlined
                  },
                  {
                    'id': 'linked',
                    'label': 'مربوطة',
                    'icon': Icons.verified_user_outlined
                  },
                ]
                    .map((item) => FilterChip(
                          avatar: Icon(item['icon'] as IconData, size: 17),
                          label: Text(item['label'] as String),
                          selected: controller.selectedQuickFilter.value ==
                              item['id'],
                          onSelected: (_) => controller
                              .selectQuickFilter(item['id'] as String),
                        ))
                    .toList(),
              )),
        ],
      );
}

class _ConversationCard extends StatelessWidget {
  final WhatsAppConversation item;
  final WhatsAppCenterController controller;
  const _ConversationCard({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final displayName = item.contact?.name?.isNotEmpty == true
        ? item.contact!.name!
        : item.phone;
    final linked =
        item.contact?.customerId != null || item.contact?.supplierId != null;
    final color = _channelColor(item.channel);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      elevation: item.unreadCount > 0 ? 1 : 0,
      color: item.unreadCount > 0 ? color.withValues(alpha: .06) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: item.failedCount > 0
              ? const Color(0xFFFFB4AB)
              : item.unreadCount > 0
                  ? color.withValues(alpha: .35)
                  : const Color(0xFFE3ECE9),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        onTap: () => Get.toNamed(
          '/WhatsAppConversation/${item.id}',
          parameters: {'channel': item.channel},
        ),
        leading: GestureDetector(
          onTap: () => _showContactProfile(context, item),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _ContactAvatar(
                name: displayName,
                imageUrl: item.contact?.profilePictureUrl,
              ),
              Positioned(
                right: -4,
                bottom: -3,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.white,
                  child: Icon(_channelIcon(item.channel),
                      size: 13, color: _channelColor(item.channel)),
                ),
              ),
              if (linked)
                const Positioned(
                  left: -3,
                  bottom: -2,
                  child: _LinkedBadge(),
                ),
            ],
          ),
        ),
        title: Row(children: [
          Expanded(
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight:
                    item.unreadCount > 0 ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
          if (item.failedCount > 0)
            const Icon(Icons.error_outline, color: Colors.red, size: 18),
          if (item.needsReply) ...[
            const SizedBox(width: 4),
            const Icon(Icons.priority_high_outlined,
                color: Color(0xFFE65100), size: 18),
          ],
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.lastMessage ?? _messageTypeLabel(item.lastMessageType),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Wrap(
              spacing: 5,
              runSpacing: 3,
              children: [
                _TinyBadge(
                  label: _channelLabel(item.channel),
                  color: color,
                  icon: _channelIcon(item.channel),
                ),
                _TinyBadge(
                  label: _statusLabel(item.status),
                  color: _statusColor(item.status),
                  icon: Icons.radio_button_checked,
                ),
                if (linked)
                  const _TinyBadge(
                    label: 'مربوط',
                    color: Color(0xFF1D9BF0),
                    icon: Icons.verified_user_outlined,
                  ),
                if (item.needsReply)
                  const _TinyBadge(
                    label: 'تحتاج رد',
                    color: Color(0xFFE65100),
                    icon: Icons.priority_high_outlined,
                  ),
                if (item.assignedEmployee != null)
                  _TinyBadge(
                    label: item.assignedEmployee!.name,
                    color: const Color(0xFF6D4C41),
                    icon: Icons.support_agent,
                  ),
                ...item.tags.take(2).map(
                      (tag) => _TinyBadge(
                        label: tag.name,
                        color:
                            _parseColor(tag.color) ?? const Color(0xFF52635F),
                        icon: Icons.sell_outlined,
                      ),
                    ),
              ],
            ),
          ],
        ),
        trailing: SizedBox(
          width: 66,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _shortDate(item.lastMessageAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              if (item.unreadCount > 0)
                Badge(label: Text('${item.unreadCount}'))
              else
                Tooltip(
                  message: 'عرض البروفايل',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showContactProfile(context, item),
                    child: const SizedBox.square(
                      dimension: 26,
                      child: Icon(Icons.info_outline, size: 19),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _TinyBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

void _showContactProfile(BuildContext context, WhatsAppConversation item) {
  final contact = item.contact;
  final displayName =
      contact?.name?.isNotEmpty == true ? contact!.name! : item.phone;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _ContactAvatar(
                name: displayName,
                imageUrl: contact?.profilePictureUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text('${_channelLabel(item.channel)} • ${item.phone}',
                        textDirection: TextDirection.ltr),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 14),
            _ProfileRow(
                icon: Icons.forum_outlined,
                label: 'حالة المحادثة',
                value: _statusLabel(item.status)),
            _ProfileRow(
                icon: Icons.schedule,
                label: 'آخر رسالة',
                value: _shortDate(item.lastMessageAt).isEmpty
                    ? 'غير متاح'
                    : _shortDate(item.lastMessageAt)),
            _ProfileRow(
                icon: Icons.notifications_active_outlined,
                label: 'غير مقروء',
                value: '${item.unreadCount}'),
            _ProfileRow(
                icon: Icons.error_outline,
                label: 'رسائل فاشلة',
                value: '${item.failedCount}'),
            _ProfileRow(
                icon: Icons.priority_high_outlined,
                label: 'تحتاج رد',
                value: item.needsReply ? 'نعم' : 'لا'),
            _ProfileRow(
                icon: Icons.assignment_ind_outlined,
                label: 'الموظف المسؤول',
                value: item.assignedEmployee?.name ?? 'غير معين'),
            _ProfileRow(
              icon: Icons.link,
              label: 'الربط',
              value: contact?.customerId != null
                  ? 'زبون #${contact!.customerId}'
                  : contact?.supplierId != null
                      ? 'تاجر #${contact!.supplierId}'
                      : 'غير مربوط',
            ),
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: item.tags
                    .map((tag) => _TinyBadge(
                          label: tag.name,
                          color:
                              _parseColor(tag.color) ?? const Color(0xFF52635F),
                          icon: Icons.sell_outlined,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Get.toNamed('/WhatsAppConversation/${item.id}',
                      parameters: {'channel': item.channel});
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('فتح المحادثة'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(icon, size: 18, color: const Color(0xFF52635F)),
          const SizedBox(width: 8),
          SizedBox(
            width: 105,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF52635F), fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, textDirection: TextDirection.rtl)),
        ]),
      );
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
      if (settings.metaAppStatus != null && !settings.metaAppStatus!.published)
        _MetaSettingsBanner(status: settings.metaAppStatus!),
      Obx(() {
        final selectedChannel = controller.selectedChannel.value;
        final visibleChannels = selectedChannel == 'all'
            ? settings.channels
            : settings.channels
                .where(
                    (channel) => _sameChannelGroup(channel.id, selectedChannel))
                .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  selectedChannel == 'all'
                      ? 'قنوات التواصل'
                      : 'إعدادات ${_channelLabel(selectedChannel)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (selectedChannel != 'all')
                TextButton.icon(
                  onPressed: () => controller.selectChannel('all'),
                  icon: const Icon(Icons.all_inbox_outlined, size: 18),
                  label: const Text('عرض الكل'),
                ),
            ]),
            const SizedBox(height: 8),
            if (settings.channels.isEmpty)
              Card(
                  child: ListTile(
                leading: Icon(
                    settings.configured ? Icons.cloud_done : Icons.cloud_off,
                    color: settings.configured ? Colors.green : Colors.red),
                title: Text(
                    settings.configured ? 'الاتصال مهيأ' : 'الاتصال غير مكتمل'),
                subtitle: Text(
                    '${settings.message}\nPhone number ID: ${settings.phoneNumberId ?? '—'}'),
                isThreeLine: true,
              ))
            else
              ...visibleChannels.map(
                (channel) => _SocialChannelSettingsCard(
                  channel: channel,
                  controller: controller,
                ),
              ),
          ],
        );
      }),
      const SizedBox(height: 8),
      const Text(
        'رموز الوصول محفوظة في Laravel .env ولا يتم عرضها أو تخزينها داخل التطبيق.',
        style: TextStyle(fontSize: 12, color: Color(0xFF52635F)),
      ),
      Obx(() {
        if (!controller.canManageWhatsAppEmployees.value) {
          return const SizedBox.shrink();
        }
        return Card(
          margin: const EdgeInsets.only(top: 12),
          color: const Color(0xFFF0F7F5),
          surfaceTintColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.manage_accounts, color: Color(0xFF075E54)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الموظفون المخولون بمركز التواصل',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ]),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'هذا الاختيار يستخدم نفس صلاحية مركز التواصل الموجودة في إضافة وتعديل الموظف.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF52635F)),
                  ),
                ),
                if (controller.whatsAppEmployees.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: Text('لا يوجد موظفون')),
                  )
                else
                  ...controller.whatsAppEmployees.map((employee) {
                    final selected = controller.selectedWhatsAppEmployeeIds
                        .contains(employee.id);
                    return CheckboxListTile(
                      value: selected,
                      activeColor: const Color(0xFF00A884),
                      contentPadding: EdgeInsets.zero,
                      title: Text(employee.name),
                      subtitle: Text([
                        if (employee.jobTitle?.isNotEmpty == true)
                          employee.jobTitle!,
                        if (employee.phone?.isNotEmpty == true) employee.phone!,
                      ].join(' • ')),
                      secondary: CircleAvatar(
                        backgroundColor: const Color(0xFFD9EEE8),
                        child: Text(employee.name.characters.first),
                      ),
                      onChanged: (value) => controller.toggleWhatsAppEmployee(
                          employee.id, value == true),
                    );
                  }),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF075E54)),
                    onPressed: controller.actionLoading.value
                        ? null
                        : controller.saveWhatsAppEmployees,
                    icon: controller.actionLoading.value
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: const Text('حفظ صلاحيات مركز التواصل'),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      const SizedBox(height: 16),
      Obx(() => _WhatsAppAccountPicker(controller: controller)),
      const SizedBox(height: 12),
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
      const Divider(height: 28),
      Text('QR واتساب دكتور بايك',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Obx(() => controller.qrBytes.value == null
          ? const SizedBox(
              height: 180, child: Center(child: CircularProgressIndicator()))
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              height: 230,
              child: SvgPicture.memory(controller.qrBytes.value!),
            )),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(
            onPressed: controller.printQrA4,
            icon: const Icon(Icons.print),
            label: const Text('طباعة A4')),
        OutlinedButton.icon(
            onPressed: controller.downloadQrA4,
            icon: const Icon(Icons.download),
            label: const Text('تنزيل')),
        OutlinedButton.icon(
            onPressed: controller.shareQrA4,
            icon: const Icon(Icons.share),
            label: const Text('مشاركة')),
      ]),
    ]);
  }
}

class _SocialChannelSettingsCard extends StatelessWidget {
  final SocialChannelSetting channel;
  final WhatsAppCenterController controller;
  const _SocialChannelSettingsCard({
    required this.channel,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final color = _channelColor(channel.id);
    final details = channel.details.entries
        .where((entry) => entry.value?.toString().isNotEmpty == true)
        .map((entry) => '${_detailLabel(entry.key)}: ${entry.value}')
        .join('\n');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                foregroundColor: color,
                child: Icon(_channelIcon(channel.id)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          channel.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Icon(
                        channel.configured
                            ? Icons.check_circle
                            : Icons.error_outline,
                        size: 18,
                        color: channel.configured ? Colors.green : Colors.red,
                      ),
                    ]),
                    Text(
                      channel.displayName.isNotEmpty
                          ? channel.displayName
                          : 'غير محدد',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF263B37),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            if (channel.identifier?.isNotEmpty == true || details.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  [
                    if (channel.identifier?.isNotEmpty == true)
                      'ID: ${channel.identifier}',
                    if (details.isNotEmpty) details,
                  ].join('\n'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF52635F),
                  ),
                ),
              ),
            if (channel.health.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: channel.health.entries
                    .map((entry) => _HealthChip(
                          label: _healthLabel(entry.key),
                          ok: entry.value,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: channel.url?.isNotEmpty == true
                      ? () => controller.openChannel(channel)
                      : null,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('فتح'),
                ),
                OutlinedButton.icon(
                  onPressed: channel.url?.isNotEmpty == true
                      ? () => controller.shareChannel(channel)
                      : null,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('مشاركة'),
                ),
                IconButton.outlined(
                  tooltip: 'نسخ الرابط',
                  onPressed: channel.url?.isNotEmpty == true
                      ? () => controller.copyChannelLink(channel)
                      : null,
                  icon: const Icon(Icons.copy, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsAppAccountPicker extends StatelessWidget {
  final WhatsAppCenterController controller;
  const _WhatsAppAccountPicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    final channels = controller.whatsAppAccountChannels;
    if (channels.isEmpty) return const SizedBox.shrink();

    return DropdownButtonFormField<int>(
      initialValue: controller.selectedWhatsAppAccountId.value,
      isDense: true,
      decoration: const InputDecoration(
        labelText: 'الإرسال من رقم واتساب',
        border: OutlineInputBorder(),
      ),
      items: channels
          .map((channel) => DropdownMenuItem<int>(
                value: _channelAccountId(channel),
                child: Text(
                  '${channel.displayName} • ${channel.identifier ?? ''}',
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .where((item) => item.value != null)
          .toList(),
      onChanged: controller.selectWhatsAppAccount,
    );
  }
}

class _HealthChip extends StatelessWidget {
  final String label;
  final bool ok;
  const _HealthChip({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: ok ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ok ? const Color(0xFFA5D6A7) : const Color(0xFFFFCDD2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.error_outline,
              size: 14,
              color: ok ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ok ? Colors.green.shade800 : Colors.red.shade800)),
          ],
        ),
      );
}

class _MetaSettingsBanner extends StatelessWidget {
  final MetaAppStatus status;
  const _MetaSettingsBanner({required this.status});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: const Color(0xFFFFF3CD),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFFFD76A)),
        ),
        child: ListTile(
          leading: const Icon(Icons.science_outlined, color: Color(0xFF8A5A00)),
          title: const Text('Meta في وضع اختبار'),
          subtitle: Text(status.message),
          trailing: Text(
            status.mode,
            style: const TextStyle(
              color: Color(0xFF8A5A00),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
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

class _LinkedBadge extends StatelessWidget {
  const _LinkedBadge();

  @override
  Widget build(BuildContext context) => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: const Color(0xFF1D9BF0),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 11),
      );
}

class _ContactAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  const _ContactAvatar({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl?.trim().isNotEmpty == true;
    return CircleAvatar(
      backgroundColor: const Color(0xFFF8E7B5),
      foregroundColor: const Color(0xFF66562E),
      backgroundImage: hasImage ? NetworkImage(imageUrl!.trim()) : null,
      child: hasImage ? null : Text(_avatarInitial(name)),
    );
  }
}

String _shortDate(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  return '${local.day}/${local.month} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _messageTypeLabel(String? type) =>
    const {
      'image': 'صورة',
      'audio': 'رسالة صوتية',
      'video': 'فيديو',
      'document': 'مستند',
      'interactive': 'منتجات',
      'template': 'قالب',
    }[type] ??
    'لا توجد رسائل';

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

String _channelLabel(String channel) => channel.startsWith('whatsapp:')
    ? 'واتساب'
    : const {
          'whatsapp': 'واتساب',
          'facebook': 'فيسبوك',
          'instagram': 'إنستغرام',
        }[channel] ??
        channel;

IconData _channelIcon(String channel) => channel.startsWith('whatsapp:')
    ? Icons.chat
    : const {
          'whatsapp': Icons.chat,
          'facebook': Icons.facebook,
          'instagram': Icons.camera_alt_outlined,
        }[channel] ??
        Icons.forum_outlined;

Color _channelColor(String channel) => channel.startsWith('whatsapp:')
    ? const Color(0xFF075E54)
    : const {
          'whatsapp': Color(0xFF075E54),
          'facebook': Color(0xFF1877F2),
          'instagram': Color(0xFFE4405F),
        }[channel] ??
        const Color(0xFF455A64);

String _avatarInitial(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed.characters.first;
}

Color? _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final normalized = hex.replaceFirst('#', '');
  final value = int.tryParse('FF$normalized', radix: 16);
  return value == null ? null : Color(value);
}

String _healthLabel(String key) =>
    const {
      'token': 'التوكن',
      'identity': 'الهوية',
      'webhook': 'Webhook',
      'profile': 'البروفايل',
      'public_url': 'الرابط العام',
      'catalog': 'الكتالوج',
    }[key] ??
    key;

String _detailLabel(String key) =>
    const {
      'phone_number_id': 'Phone number ID',
      'business_account_id': 'Business account ID',
      'account_id': 'Account ID',
      'catalog_id': 'Catalog ID',
      'page_id': 'Page ID',
      'instagram_business_account_id': 'Instagram business ID',
    }[key] ??
    key;

bool _sameChannelGroup(String id, String selected) {
  if (selected == 'whatsapp') {
    return id == 'whatsapp' || id.startsWith('whatsapp:');
  }
  return id == selected;
}

int? _channelAccountId(SocialChannelSetting channel) =>
    int.tryParse(channel.details['account_id']?.toString() ?? '');
