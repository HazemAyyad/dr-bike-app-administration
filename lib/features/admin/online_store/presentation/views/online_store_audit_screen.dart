import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/online_store_audit_controller.dart';
import '../widgets/online_store_state_view.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_form_widgets.dart';

class OnlineStoreAuditScreen extends GetView<OnlineStoreAuditController> {
  const OnlineStoreAuditScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OnlineStoreAdminUi.pageBackground,
        appBar: AppBar(title: const Text('سجل تدقيق المتجر')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              Obx(() => DropdownButton<String>(
                    value: controller.entityType.value,
                    items: const [
                      'all',
                      'listing',
                      'promotion',
                      'coupon',
                      'settings',
                      'account_link',
                      'credit_policy',
                      'review',
                      'pricing'
                    ]
                        .map((v) => DropdownMenuItem(
                            value: v, child: Text(_entityLabel(v))))
                        .toList(),
                    onChanged: (v) => controller.entityType.value = v ?? 'all',
                  )),
              Obx(() => DropdownButton<String>(
                    value: controller.actionFilter.value,
                    items: const [
                      'all',
                      'created',
                      'updated',
                      'linked',
                      'approved',
                      'suspended',
                      'activated',
                      'deactivated',
                      'published',
                      'hidden',
                      'status_changed',
                      'moderated',
                      'previewed'
                    ]
                        .map((v) => DropdownMenuItem(
                            value: v, child: Text(_actionLabel(v))))
                        .toList(),
                    onChanged: (v) =>
                        controller.actionFilter.value = v ?? 'all',
                  )),
              SizedBox(
                width: 110,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'رقم المنفذ'),
                  onChanged: (v) => controller.actorUserId.value = v,
                ),
              ),
              SizedBox(
                  width: 170,
                  child: OnlineStoreDateTimeField(
                    controller: controller.fromController,
                    label: 'من تاريخ',
                    includeTime: false,
                  )),
              SizedBox(
                  width: 170,
                  child: OnlineStoreDateTimeField(
                    controller: controller.toController,
                    label: 'إلى تاريخ',
                    includeTime: false,
                  )),
              OutlinedButton.icon(
                style: OnlineStoreAdminUi.actionButtonStyle,
                onPressed: controller.applyFilters,
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('تطبيق'),
              ),
            ]),
          ),
          Expanded(
              child: Obx(() => OnlineStoreStateView(
                    loading: controller.loading.value,
                    error: controller.error.value,
                    isEmpty: controller.items.isEmpty,
                    onRetry: controller.applyFilters,
                    child: RefreshIndicator(
                        onRefresh: controller.applyFilters,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: controller.items.length,
                          itemBuilder: (_, index) {
                            final event = controller.items[index].values;
                            return ExpansionTile(
                              title: Text(
                                  '${_actionLabel('${event['action'] ?? ''}')} • ${_entityLabel('${event['entity_type'] ?? ''}')} #${event['entity_id'] ?? '—'}'),
                              subtitle: Text('${event['occurred_at'] ?? ''}'),
                              children: [
                                ListTile(
                                    title: const Text('قبل (منقح)'),
                                    subtitle: Text(
                                        '${event['before_values'] ?? {}}')),
                                ListTile(
                                    title: const Text('بعد (منقح)'),
                                    subtitle:
                                        Text('${event['after_values'] ?? {}}')),
                              ],
                            );
                          },
                        )),
                  ))),
        ]),
      );

  static String _entityLabel(String value) =>
      const {
        'all': 'كل أنواع السجلات',
        'listing': 'منتج معروض',
        'promotion': 'عرض ترويجي',
        'coupon': 'كوبون',
        'settings': 'إعدادات المتجر',
        'account_link': 'حساب متجر',
        'credit_policy': 'سياسة ائتمان',
        'review': 'مراجعة عميل',
        'pricing': 'احتساب سعر',
      }[value] ??
      value;

  static String _actionLabel(String value) =>
      const {
        'all': 'كل العمليات',
        'created': 'تمت الإضافة',
        'updated': 'تم التعديل',
        'linked': 'تم ربط الحساب',
        'approved': 'تمت الموافقة',
        'suspended': 'تم التعليق',
        'activated': 'تم التفعيل',
        'deactivated': 'تم الإيقاف',
        'published': 'تم النشر',
        'hidden': 'تم الإخفاء',
        'status_changed': 'تغيّرت الحالة',
        'moderated': 'تمت مراجعة المحتوى',
        'previewed': 'تمت معاينة السعر',
      }[value] ??
      (value.isEmpty ? 'عملية' : value);
}
