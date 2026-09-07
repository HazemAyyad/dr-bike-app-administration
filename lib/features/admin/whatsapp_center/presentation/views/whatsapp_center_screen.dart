import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:typed_data';

import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/widgets/skeleton_loading.dart';
import '../../../../../features/bottom_nav_bar/controllers/bottom_nav_bar_controller.dart';
import '../../../../../features/bottom_nav_bar/widgets/custom_bottom_nav_bar.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/whatsapp_models.dart';
import '../controllers/whatsapp_center_controller.dart';
import '../utils/social_datetime_formatters.dart';

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
            backgroundColor: Colors.white,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Obx(() {
                final showingDashboard = controller.tabIndex.value == 0;
                final showingSettings = controller.tabIndex.value == 3;
                final selectedChannel = controller.selectedChannel.value;
                final channelColor = _channelColor(selectedChannel);
                return AppBar(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF111B21),
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  title: Text(
                    showingDashboard
                        ? 'إحصائيات مركز التواصل'
                        : showingSettings
                            ? 'إعدادات ${_channelLabel(selectedChannel)}'
                            : selectedChannel == 'all'
                                ? 'جميع المحادثات'
                                : _channelLabel(selectedChannel),
                    style: TextStyle(
                      color: channelColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  actions: [
                    if (!showingSettings && !showingDashboard)
                      IconButton(
                        tooltip: 'فلترة المحادثات',
                        onPressed: () =>
                            _showConversationFilters(context, controller),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    IconButton(
                      tooltip: showingDashboard
                          ? 'العودة إلى المحادثات'
                          : 'إحصائيات مركز التواصل',
                      onPressed: controller.toggleDashboard,
                      icon: Icon(showingDashboard
                          ? Icons.forum_outlined
                          : Icons.analytics_outlined),
                    ),
                    IconButton(
                      tooltip: showingSettings
                          ? 'العودة إلى المحادثات'
                          : 'إعدادات ${_channelLabel(selectedChannel)}',
                      onPressed: controller.toggleSettings,
                      icon: Icon(showingSettings
                          ? Icons.forum_outlined
                          : Icons.settings_outlined),
                    ),
                  ],
                );
              }),
            ),
            body: Column(children: [
              _SocialChannelBar(controller: controller),
              Expanded(child: Obx(() {
                if (controller.loading.value) {
                  return _CenterSkeleton(tabIndex: controller.tabIndex.value);
                }
                if (controller.error.value != null) {
                  return _StateMessage(
                    icon: Icons.cloud_off,
                    text: controller.error.value!,
                    action: controller.refreshCurrent,
                  );
                }
                return RefreshIndicator(
                  onRefresh: controller.refreshCurrent,
                  child: controller.tabIndex.value == 0
                      ? _DashboardTab(controller: controller)
                      : controller.tabIndex.value == 3
                          ? _SettingsTab(controller: controller)
                          : _ConversationsTab(controller: controller),
                );
              })),
            ]),
            bottomNavigationBar: Listener(
              onPointerUp: (_) {
                if (Get.isRegistered<BottomNavBarController>()) {
                  Future<void>.delayed(Duration.zero, () {
                    Get.offAllNamed(AppRoutes.BOTTOMNAVBARSCREEN);
                  });
                }
              },
              child: const CustomBottomNavigationBar(),
            ),
          )),
    );
  }
}

class _CenterSkeleton extends StatelessWidget {
  const _CenterSkeleton({required this.tabIndex});

  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    if (tabIndex == 1) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          const SkeletonBlock(width: double.infinity, height: 48, radius: 24),
          const SizedBox(height: 12),
          const Row(children: [
            SkeletonBlock(width: 58, height: 34, radius: 18),
            SizedBox(width: 8),
            SkeletonBlock(width: 92, height: 34, radius: 18),
            SizedBox(width: 8),
            SkeletonBlock(width: 82, height: 34, radius: 18),
          ]),
          const SizedBox(height: 12),
          ...List.generate(7, (_) => const _ConversationSkeletonRow()),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SkeletonBlock(width: double.infinity, height: 145, radius: 22),
        SizedBox(height: 14),
        Row(children: [
          Expanded(child: SkeletonBlock(width: 100, height: 84, radius: 14)),
          SizedBox(width: 9),
          Expanded(child: SkeletonBlock(width: 100, height: 84, radius: 14)),
          SizedBox(width: 9),
          Expanded(child: SkeletonBlock(width: 100, height: 84, radius: 14)),
        ]),
        SizedBox(height: 18),
        SkeletonBlock(width: 130, height: 20),
        SizedBox(height: 10),
        SkeletonBlock(width: double.infinity, height: 150, radius: 16),
      ],
    );
  }
}

class _ConversationSkeletonRow extends StatelessWidget {
  const _ConversationSkeletonRow();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          SkeletonCircle(size: 54),
          SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SkeletonBlock(width: 150, height: 15),
              SizedBox(height: 9),
              SkeletonBlock(width: double.infinity, height: 12),
            ]),
          ),
          SizedBox(width: 12),
          SkeletonBlock(width: 42, height: 11),
        ]),
      );
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF075E54), Color(0xFF128C7E)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              CircleAvatar(
                backgroundColor: Color(0x24FFFFFF),
                foregroundColor: Colors.white,
                child: Icon(Icons.all_inbox_rounded),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('صندوق التواصل الموحد',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              _HeroMetric(label: 'غير مقروءة', value: d.unreadConversations),
              const _HeroDivider(),
              _HeroMetric(label: 'مفتوحة', value: d.openConversations),
              const _HeroDivider(),
              _HeroMetric(label: 'كل المحادثات', value: d.totalConversations),
            ]),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => controller.selectTab(1),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF075E54),
              ),
              icon: const Icon(Icons.forum_outlined),
              label: const Text('فتح المحادثات'),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: _CompactMetric(
              icon: Icons.contacts_outlined,
              label: 'جهات الاتصال',
              value: d.totalContacts,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _CompactMetric(
              icon: Icons.today_outlined,
              label: 'رسائل اليوم',
              value: d.messagesToday,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _CompactMetric(
              icon: Icons.error_outline,
              label: 'فاشلة اليوم',
              value: d.failedMessagesToday,
              alert: d.failedMessagesToday > 0,
            ),
          ),
        ]),
        if (d.channelStats.isNotEmpty) ...[
          const SizedBox(height: 22),
          const Text('القنوات',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          SizedBox(
            height: 158,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: d.channelStats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => SizedBox(
                width: 270,
                child: _ChannelStatsCard(stats: d.channelStats[i]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text('$value',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          Text(label,
              maxLines: 1,
              style: const TextStyle(color: Color(0xFFD9F3ED), fontSize: 10)),
        ]),
      );
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 38,
        color: const Color(0x45FFFFFF),
      );
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.alert = false,
  });

  final IconData icon;
  final String label;
  final int value;
  final bool alert;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 11),
        decoration: BoxDecoration(
          color: alert ? const Color(0xFFFFF1F0) : const Color(0xFFF5F8F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Icon(icon,
              color: alert ? Colors.red : const Color(0xFF008069), size: 21),
          const SizedBox(height: 5),
          Text('$value',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF667781), fontSize: 9)),
        ]),
      );
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
    const allChannels = [
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
    final channels = userType == 'admin'
        ? allChannels
        : allChannels.where((channel) {
            if (channel.id == 'all') return true;
            const permissions = {
              'whatsapp': 'Social Center WhatsApp',
              'facebook': 'Social Center Facebook',
              'instagram': 'Social Center Instagram',
            };
            return employeePermissionNames.contains(permissions[channel.id]);
          }).toList(growable: false);

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
  Widget build(BuildContext context) => CustomScrollView(
        controller: controller.conversationsScrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 8),
            sliver: SliverToBoxAdapter(
              child: _ConversationSearch(controller: controller),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
              child: _ConversationFilters(controller: controller)),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          Obx(() {
            if (controller.conversations.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: _StateMessage(
                  icon: Icons.chat_bubble_outline,
                  text: 'لا توجد محادثات تطابق الفلاتر الحالية',
                ),
              );
            }
            final extraRows = controller.loadingMoreConversations.value
                ? 2
                : controller.hasMoreConversations.value
                    ? 1
                    : 0;
            return SliverPadding(
              padding: const EdgeInsets.only(bottom: 88),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < controller.conversations.length) {
                      return _ConversationCard(
                        item: controller.conversations[index],
                        controller: controller,
                      );
                    }
                    if (controller.loadingMoreConversations.value) {
                      return const _ConversationSkeletonRow();
                    }
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('انزل لعرض محادثات إضافية',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF8696A0), fontSize: 11)),
                    );
                  },
                  childCount: controller.conversations.length + extraRows,
                ),
              ),
            );
          }),
        ],
      );
}

class _ConversationSearch extends StatelessWidget {
  final WhatsAppCenterController controller;
  const _ConversationSearch({required this.controller});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SizedBox(
          height: 48,
          child: SearchBar(
            controller: controller.searchController,
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: const WidgetStatePropertyAll(Color(0xFFF0F2F5)),
            hintText: 'بحث...',
            leading: const Icon(Icons.search, color: Color(0xFF54656F)),
            trailing: [
              IconButton(
                tooltip: 'فلاتر إضافية',
                onPressed: () => _showConversationFilters(context, controller),
                icon: const Icon(Icons.tune, color: Color(0xFF54656F)),
              ),
              IconButton(
                tooltip: 'مسح البحث والفلاتر',
                onPressed: controller.clearConversationFilters,
                icon: const Icon(Icons.close, color: Color(0xFF54656F)),
              ),
            ],
            onSubmitted: (_) => controller.loadConversations(),
          ),
        ),
      );
}

class _ConversationFilters extends StatelessWidget {
  final WhatsAppCenterController controller;
  const _ConversationFilters({required this.controller});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: Obx(() => ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: const <Map<String, String>>[
                {'id': 'all', 'label': 'الكل'},
                {'id': 'unread', 'label': 'غير مقروء'},
                {'id': 'needs_reply', 'label': 'تحتاج رد'},
                {'id': 'assigned_me', 'label': 'مسندة لي'},
              ]
                  .map((item) => Padding(
                        padding: const EdgeInsetsDirectional.only(end: 7),
                        child: FilterChip(
                          label: Text(item['label']!),
                          selected: controller.selectedQuickFilter.value ==
                              item['id'],
                          showCheckmark: false,
                          selectedColor: const Color(0xFFD8FDD2),
                          side: BorderSide(
                            color: controller.selectedQuickFilter.value ==
                                    item['id']
                                ? const Color(0xFF9AD69B)
                                : const Color(0xFFD5D9DC),
                          ),
                          labelStyle: TextStyle(
                            color: controller.selectedQuickFilter.value ==
                                    item['id']
                                ? const Color(0xFF008069)
                                : const Color(0xFF3B4A54),
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) =>
                              controller.selectQuickFilter(item['id']!),
                        ),
                      ))
                  .toList(),
            )),
      );
}

Future<void> _showConversationFilters(
    BuildContext context, WhatsAppCenterController controller) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('حالة المحادثة',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                    spacing: 7,
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
              const SizedBox(height: 14),
              const Text('متابعة العمل',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              Obx(() => Column(children: [
                    ListTile(
                      selected:
                          controller.selectedQuickFilter.value == 'failed',
                      title: const Text('رسائل فاشلة'),
                      leading:
                          const Icon(Icons.error_outline, color: Colors.red),
                      trailing: controller.selectedQuickFilter.value == 'failed'
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF00A884))
                          : null,
                      onTap: () => controller.selectQuickFilter('failed'),
                    ),
                    ListTile(
                      selected:
                          controller.selectedQuickFilter.value == 'linked',
                      title: const Text('مربوطة بزبون أو تاجر'),
                      leading: const Icon(Icons.verified_user_outlined,
                          color: Color(0xFF1D9BF0)),
                      trailing: controller.selectedQuickFilter.value == 'linked'
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF00A884))
                          : null,
                      onTap: () => controller.selectQuickFilter('linked'),
                    ),
                  ])),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await controller.clearConversationFilters();
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('مسح جميع الفلاتر'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
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
    final preview = _conversationPreview(item);
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => Get.toNamed(
          '/WhatsAppConversation/${item.id}',
          parameters: {'channel': item.channel},
        ),
        onLongPress: () => _showContactProfile(context, item),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 9, 10, 0),
          child: Row(
            children: [
              Stack(clipBehavior: Clip.none, children: [
                _ContactAvatar(
                    name: displayName,
                    imageUrl: item.contact?.profilePictureUrl),
                if (controller.selectedChannel.value == 'all')
                  PositionedDirectional(
                    end: -3,
                    bottom: -2,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.white,
                      child: Icon(_channelIcon(item.channel),
                          size: 13, color: color),
                    ),
                  ),
                if (linked)
                  const PositionedDirectional(
                      start: -3, bottom: -2, child: _LinkedBadge()),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsetsDirectional.only(bottom: 12),
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Color(0xFFE9EDEF))),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: const Color(0xFF111B21),
                                    fontSize: 16,
                                    fontWeight: item.unreadCount > 0
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  )),
                            ),
                            if (item.needsReply)
                              const Padding(
                                padding: EdgeInsetsDirectional.only(start: 5),
                                child: Icon(Icons.priority_high_rounded,
                                    size: 17, color: Color(0xFFE65100)),
                              ),
                          ]),
                          const SizedBox(height: 5),
                          Row(children: [
                            if (item.lastMessageDirection == 'outbound') ...[
                              Icon(
                                  _conversationStatusIcon(
                                      item.lastMessageStatus),
                                  size: 17,
                                  color: _conversationStatusColor(
                                      item.lastMessageStatus)),
                              const SizedBox(width: 4),
                            ],
                            if (item.lastMessageType != null &&
                                item.lastMessageType != 'text') ...[
                              Icon(_messageTypeIcon(item.lastMessageType),
                                  size: 17, color: const Color(0xFF667781)),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: item.channel == 'whatsapp' &&
                                      item.lastMessageType == 'audio'
                                  ? _ConversationAudioLabel(
                                      item: item, controller: controller)
                                  : Text(preview,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Color(0xFF667781),
                                          fontSize: 14)),
                            ),
                          ]),
                          if (item.assignedEmployee != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'يتابعها ${item.assignedEmployee!.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Color(0xFF8696A0), fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (item.channel == 'whatsapp' &&
                        item.lastMessageId != null &&
                        (item.lastMessageType == 'image' ||
                            item.lastMessageType == 'video')) ...[
                      const SizedBox(width: 7),
                      _ConversationMediaThumbnail(
                          item: item, controller: controller),
                    ],
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 58,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_shortDate(item.lastMessageAt),
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 11,
                                color: item.unreadCount > 0
                                    ? const Color(0xFF1FA855)
                                    : const Color(0xFF667781),
                              )),
                          const SizedBox(height: 7),
                          if (item.unreadCount > 0)
                            Container(
                              constraints: const BoxConstraints(minWidth: 20),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: const BoxDecoration(
                                  color: Color(0xFF25D366),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20))),
                              child: Text('${item.unreadCount}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            )
                          else if (item.failedCount > 0)
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 18)
                          else if (item.tags.isNotEmpty)
                            const Icon(Icons.sell_rounded,
                                color: Color(0xFF8696A0), size: 16),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationMediaThumbnail extends StatelessWidget {
  const _ConversationMediaThumbnail({
    required this.item,
    required this.controller,
  });

  final WhatsAppConversation item;
  final WhatsAppCenterController controller;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: SizedBox.square(
          dimension: 52,
          child: FutureBuilder<Uint8List?>(
            future: controller.conversationThumbnail(item),
            builder: (_, snapshot) {
              final bytes = snapshot.data;
              return Stack(fit: StackFit.expand, children: [
                if (bytes != null)
                  Image.memory(bytes, fit: BoxFit.cover)
                else
                  const ColoredBox(
                    color: Color(0xFFE9EDEF),
                    child: Icon(Icons.photo_outlined, color: Color(0xFF8696A0)),
                  ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const ColoredBox(
                    color: Color(0x33000000),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 15,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                  ),
                if (item.lastMessageType == 'video')
                  const Center(
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
              ]);
            },
          ),
        ),
      );
}

class _ConversationAudioLabel extends StatelessWidget {
  const _ConversationAudioLabel({required this.item, required this.controller});

  final WhatsAppConversation item;
  final WhatsAppCenterController controller;

  @override
  Widget build(BuildContext context) => FutureBuilder<Duration?>(
        future: controller.conversationAudioDuration(item),
        builder: (_, snapshot) {
          final duration = snapshot.data;
          final label = duration == null
              ? 'رسالة صوتية'
              : 'رسالة صوتية (${_shortDuration(duration)})';
          return Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF667781), fontSize: 14));
        },
      );
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

// Kept for a possible WhatsApp templates entry from the settings screen.
// ignore: unused_element
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
        if (!controller.canManageWhatsAppEmployees.value ||
            controller.selectedChannel.value != 'all') {
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
                    final channels =
                        controller.selectedEmployeeChannelAccess[employee.id] ??
                            const <String>{};
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Column(children: [
                        CheckboxListTile(
                          value: channels.contains('main'),
                          activeColor: const Color(0xFF00A884),
                          title: Text(employee.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text([
                            if (employee.jobTitle?.isNotEmpty == true)
                              employee.jobTitle!,
                            if (employee.phone?.isNotEmpty == true)
                              employee.phone!,
                          ].join(' • ')),
                          secondary: CircleAvatar(
                            backgroundColor: const Color(0xFFD9EEE8),
                            child: Text(employee.name.characters.first),
                          ),
                          onChanged: (value) =>
                              controller.toggleSocialCenterEmployee(
                                  employee.id, value == true),
                        ),
                        if (channels.contains('main'))
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 52, 8),
                            child: Column(
                              children: const <Map<String, dynamic>>[
                                {
                                  'id': 'whatsapp',
                                  'label': 'واتساب',
                                  'icon': Icons.chat,
                                },
                                {
                                  'id': 'facebook',
                                  'label': 'فيسبوك',
                                  'icon': Icons.facebook,
                                },
                                {
                                  'id': 'instagram',
                                  'label': 'إنستغرام',
                                  'icon': Icons.camera_alt,
                                },
                              ].map((item) {
                                final channel = item['id']! as String;
                                return CheckboxListTile(
                                  dense: true,
                                  value: channels.contains(channel),
                                  title: Text(item['label']! as String),
                                  secondary:
                                      Icon(item['icon']! as IconData, size: 20),
                                  onChanged: (value) =>
                                      controller.toggleEmployeeChannel(
                                          employee.id, channel, value == true),
                                );
                              }).toList(),
                            ),
                          ),
                      ]),
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
      Obx(() {
        if (controller.selectedChannel.value != 'whatsapp') {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _WhatsAppAccountPicker(controller: controller),
            const SizedBox(height: 12),
            Text('رسالة تجربة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextField(
                controller: controller.testPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'رقم الهاتف الدولي',
                    border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
                controller: controller.testMessageController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                    labelText: 'نص التجربة', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: controller.actionLoading.value
                  ? null
                  : () => controller.sendDirect(
                      controller.testPhoneController.text,
                      controller.testMessageController.text,
                      test: true),
              icon: const Icon(Icons.send),
              label: const Text('إرسال رسالة تجربة'),
            ),
            const Divider(height: 28),
            Text('QR واتساب دكتور بايك',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            controller.qrBytes.value == null
                ? const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()))
                : Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    height: 230,
                    child: SvgPicture.memory(controller.qrBytes.value!),
                  ),
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
          ],
        );
      }),
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
  Widget build(BuildContext context) => Obx(() {
        final selected = controller.selectedWhatsAppAccountId.value;
        final channels = controller.whatsAppAccountChannels;
        if (channels.isEmpty) return const SizedBox.shrink();

        return DropdownButtonFormField<int>(
          initialValue: selected,
          isDense: true,
          isExpanded: true,
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
      });
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
      radius: 27,
      backgroundColor: const Color(0xFFF8E7B5),
      foregroundColor: const Color(0xFF66562E),
      backgroundImage: hasImage ? NetworkImage(imageUrl!.trim()) : null,
      child: hasImage ? null : Text(_avatarInitial(name)),
    );
  }
}

String _shortDate(DateTime? date) {
  return formatSocialConversationStamp(date);
}

String _shortDuration(Duration duration) {
  final minutes = duration.inMinutes.toString();
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

IconData _conversationStatusIcon(String? status) {
  if (status == 'read' || status == 'delivered') return Icons.done_all;
  if (status == 'sent') return Icons.done;
  if (status == 'failed') return Icons.error_outline;
  return Icons.schedule;
}

Color _conversationStatusColor(String? status) {
  if (status == 'read') return const Color(0xFF53BDEB);
  if (status == 'failed') return Colors.red;
  return const Color(0xFF8696A0);
}

IconData _messageTypeIcon(String? type) =>
    const {
      'image': Icons.photo_outlined,
      'audio': Icons.mic_outlined,
      'video': Icons.videocam_outlined,
      'document': Icons.description_outlined,
      'interactive': Icons.shopping_bag_outlined,
      'template': Icons.article_outlined,
      'location': Icons.location_on_outlined,
    }[type] ??
    Icons.chat_bubble_outline;

String _messageTypeLabel(String? type) =>
    const {
      'image': 'صورة',
      'audio': 'رسالة صوتية',
      'video': 'فيديو',
      'document': 'مستند',
      'sticker': 'ملصق',
      'location': 'موقع',
      'system': 'رسالة غير مدعومة',
      'interactive': 'منتجات',
      'template': 'قالب',
    }[type] ??
    'لا توجد رسائل';

String _conversationPreview(WhatsAppConversation conversation) {
  final type = conversation.lastMessageType?.toLowerCase();
  final body = conversation.lastMessage?.trim();
  if (body == null || body.isEmpty) return _messageTypeLabel(type);

  final normalized = body.toLowerCase();
  const internalMediaPlaceholders = {
    '[image]',
    '[video]',
    '[audio]',
    '[document]',
    '[sticker]',
    '[system]',
  };
  if (internalMediaPlaceholders.contains(normalized) ||
      (type != null && normalized == '[$type]')) {
    return _messageTypeLabel(type);
  }
  return body;
}

String _statusLabel(String status) =>
    const {
      'open': 'مفتوحة',
      'pending': 'معلقة',
      'closed': 'مغلقة',
    }[status] ??
    status;
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
