import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/databases/api/end_points.dart';
import '../../data/online_store_models.dart';
import '../controllers/online_store_notification_broadcasts_controller.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_form_widgets.dart';
import '../widgets/online_store_state_view.dart';
import '../widgets/online_store_target_picker.dart';

class OnlineStoreNotificationBroadcastsScreen
    extends GetView<OnlineStoreNotificationBroadcastsController> {
  const OnlineStoreNotificationBroadcastsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OnlineStoreAdminUi.pageBackground,
        appBar: AppBar(
          title: const Text('إشعارات عملاء المتجر'),
          actions: [
            Obx(() => IconButton(
                  tooltip: controller.searchOpen.value ? 'إغلاق البحث' : 'بحث',
                  onPressed: controller.toggleSearch,
                  icon: Icon(
                      controller.searchOpen.value ? Icons.close : Icons.search),
                )),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(54),
            child: Obx(() => controller.searchOpen.value
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: TextField(
                      controller: controller.search,
                      autofocus: true,
                      onChanged: (value) =>
                          controller.searchQuery.value = value,
                      decoration: const InputDecoration(
                        hintText: 'ابحث في سجل الإرسال...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _compose(context),
          icon: const Icon(Icons.send_outlined),
          label: const Text('إرسال جماعي'),
        ),
        body: Obx(() => OnlineStoreStateView(
              loading: controller.loading.value,
              error: controller.error.value,
              isEmpty: controller.visibleItems.isEmpty,
              onRetry: controller.load,
              child: RefreshIndicator(
                onRefresh: controller.load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.visibleItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) =>
                      _broadcastCard(controller.visibleItems[index]),
                ),
              ),
            )),
      );

  Widget _broadcastCard(OnlineStoreEntity item) {
    final values = item.values;
    final titles = onlineStoreMap(values['title_translations']);
    final audience = const {
          'all': 'جميع المستخدمين',
          'new_users': 'المستخدمون الجدد',
          'no_orders': 'من لم يطلبوا بعد',
          'customers': 'أصحاب الطلبات',
          'guests': 'الزوار - لا يوجد Push',
        }['${values['audience_type']}'] ??
        '${values['audience_type'] ?? ''}';
    return Card(
      color: OnlineStoreAdminUi.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: OnlineStoreAdminUi.accent.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_outlined,
                color: OnlineStoreAdminUi.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${titles['ar'] ?? item.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(audience,
                  style: const TextStyle(
                      fontSize: 12, color: OnlineStoreAdminUi.textSecondary)),
              const SizedBox(height: 7),
              Wrap(spacing: 6, runSpacing: 5, children: [
                _metric(Icons.people_outline,
                    '${values['recipient_count'] ?? 0} مستهدف'),
                _metric(Icons.mark_email_read_outlined,
                    '${values['sent_count'] ?? 0} داخل التطبيق'),
                _metric(Icons.phone_android_outlined,
                    '${values['push_count'] ?? 0} جهاز FCM'),
              ]),
              if (values['sent_at'] != null) ...[
                const SizedBox(height: 6),
                Text('أرسل ${onlineStoreFriendlyDate(values['sent_at'])}',
                    style: const TextStyle(
                        fontSize: 11, color: OnlineStoreAdminUi.textSecondary)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _metric(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: OnlineStoreAdminUi.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: OnlineStoreAdminUi.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: OnlineStoreAdminUi.accent),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      );

  Future<void> _compose(BuildContext context) async {
    final listings = await controller.repository.allListings();
    final categories = await controller.repository
        .allEntities(EndPoints.onlineStoreCategories);
    if (!context.mounted) return;
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _BroadcastDialog(options: [
        ...listings.map((item) => OnlineStoreTargetOption(
              type: 'listing',
              id: item.id,
              label: item.productName,
              subtitle: 'منتج معروض',
            )),
        ...categories.map((item) => OnlineStoreTargetOption(
              type: 'category',
              id: item.id,
              label: item.label,
              subtitle: 'تصنيف متجر',
            )),
      ]),
    );
    if (payload == null || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الإرسال الجماعي'),
        content: const Text(
            'سيُحفظ الإشعار داخل التطبيق ويُرسل Push فوراً لكل مستخدم ينطبق عليه الجمهور. لا يمكن التراجع بعد الإرسال.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء')),
          FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.send_outlined),
              label: const Text('إرسال الآن')),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await controller.create(payload);
    if (success) {
      Get.snackbar(
          'تم الإرسال', 'تم حفظ الإشعار وإرساله للمستخدمين المستهدفين.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}

class _BroadcastDialog extends StatefulWidget {
  const _BroadcastDialog({required this.options});
  final List<OnlineStoreTargetOption> options;

  @override
  State<_BroadcastDialog> createState() => _BroadcastDialogState();
}

class _BroadcastDialogState extends State<_BroadcastDialog> {
  final locales = const ['ar', 'en', 'he'];
  final titles = <String, TextEditingController>{};
  final bodies = <String, TextEditingController>{};
  final days = TextEditingController(text: '14');
  final url = TextEditingController();
  String audience = 'all';
  String destination = 'home';
  int? destinationId;
  String? error;

  @override
  void initState() {
    super.initState();
    for (final locale in locales) {
      titles[locale] = TextEditingController();
      bodies[locale] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in [...titles.values, ...bodies.values, days, url]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTarget() async {
    final selected = await showOnlineStoreTargetPicker(
      context,
      title: 'اختيار وجهة الإشعار',
      options:
          widget.options.where((option) => option.type == destination).toList(),
      selectedKeys:
          destinationId == null ? const [] : ['$destination:$destinationId'],
      multiple: false,
    );
    if (selected != null && mounted) {
      setState(
          () => destinationId = selected.isEmpty ? null : selected.single.id);
    }
  }

  void _submit() {
    if (titles['ar']!.text.trim().isEmpty ||
        bodies['ar']!.text.trim().isEmpty) {
      setState(() => error = 'العنوان والنص العربيان مطلوبان.');
      return;
    }
    if ({'listing', 'category'}.contains(destination) &&
        destinationId == null) {
      setState(() => error = 'اختر وجهة الإشعار.');
      return;
    }
    if (destination == 'url') {
      final uri = Uri.tryParse(url.text.trim());
      if (uri == null || !{'http', 'https'}.contains(uri.scheme)) {
        setState(() => error = 'أدخل رابطاً صحيحاً يبدأ بـ http أو https.');
        return;
      }
    }
    Navigator.pop(context, {
      'title_translations': {
        for (final locale in locales) locale: titles[locale]!.text.trim()
      },
      'body_translations': {
        for (final locale in locales) locale: bodies[locale]!.text.trim()
      },
      'audience_type': audience,
      'audience_days':
          audience == 'new_users' ? int.tryParse(days.text) ?? 14 : null,
      'destination_type': destination,
      'destination_id':
          {'listing', 'category'}.contains(destination) ? destinationId : null,
      'destination_url': destination == 'url' ? url.text.trim() : null,
    });
  }

  @override
  Widget build(BuildContext context) => OnlineStoreDialog(
        icon: Icons.campaign_outlined,
        title: const Text('إنشاء إشعار جماعي'),
        content: OnlineStoreDialogBody(
          maxWidth: OnlineStoreAdminUi.dialogWideMaxWidth,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DefaultTabController(
              length: 3,
              child: Column(children: [
                const TabBar(tabs: [
                  Tab(text: 'العربية'),
                  Tab(text: 'English'),
                  Tab(text: 'עברית'),
                ]),
                SizedBox(
                  height: 185,
                  child: TabBarView(
                    children: locales
                        .map((locale) => Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(children: [
                                TextField(
                                    controller: titles[locale],
                                    decoration: const InputDecoration(
                                        labelText: 'عنوان الإشعار')),
                                const SizedBox(height: 10),
                                TextField(
                                    controller: bodies[locale],
                                    minLines: 3,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                        labelText: 'نص الإشعار')),
                              ]),
                            ))
                        .toList(),
                  ),
                ),
              ]),
            ),
            DropdownButtonFormField<String>(
              initialValue: audience,
              decoration: const InputDecoration(labelText: 'الجمهور'),
              items: const [
                DropdownMenuItem(
                    value: 'all', child: Text('جميع مستخدمي المتجر')),
                DropdownMenuItem(
                    value: 'new_users', child: Text('المستخدمون الجدد')),
                DropdownMenuItem(
                    value: 'no_orders', child: Text('من لم يطلبوا بعد')),
                DropdownMenuItem(
                    value: 'customers', child: Text('من لديهم طلبات')),
              ],
              onChanged: (value) => setState(() => audience = value ?? 'all'),
            ),
            if (audience == 'new_users')
              TextField(
                  controller: days,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'مسجل خلال آخر عدد أيام')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: destination,
              decoration:
                  const InputDecoration(labelText: 'عند الضغط على الإشعار'),
              items: const [
                DropdownMenuItem(value: 'home', child: Text('فتح المتجر')),
                DropdownMenuItem(value: 'listing', child: Text('فتح منتج')),
                DropdownMenuItem(value: 'category', child: Text('فتح تصنيف')),
                DropdownMenuItem(value: 'url', child: Text('فتح رابط خارجي')),
                DropdownMenuItem(value: 'none', child: Text('بدون إجراء')),
              ],
              onChanged: (value) => setState(() {
                destination = value ?? 'home';
                destinationId = null;
              }),
            ),
            if ({'listing', 'category'}.contains(destination))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(destinationId == null
                    ? 'اختيار الوجهة'
                    : 'تم اختيار الوجهة #$destinationId'),
                trailing: const Icon(Icons.chevron_left),
                onTap: _pickTarget,
              ),
            if (destination == 'url')
              TextField(
                  controller: url,
                  keyboardType: TextInputType.url,
                  decoration:
                      const InputDecoration(labelText: 'الرابط الخارجي')),
            if (error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child:
                      Text(error!, style: const TextStyle(color: Colors.red))),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('متابعة')),
        ],
      );
}
