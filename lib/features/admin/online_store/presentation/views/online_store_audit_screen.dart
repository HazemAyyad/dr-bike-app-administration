import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/online_store_models.dart';
import '../controllers/online_store_audit_controller.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_form_widgets.dart';
import '../widgets/online_store_state_view.dart';

class OnlineStoreAuditScreen extends GetView<OnlineStoreAuditController> {
  const OnlineStoreAuditScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OnlineStoreAdminUi.pageBackground,
        appBar: AppBar(
          title: const Text('سجل تدقيق المتجر'),
          actions: [
            IconButton(
              tooltip: 'تصفية السجل',
              onPressed: () => _showFilters(context),
              icon: const Icon(Icons.filter_alt_outlined),
            ),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: Obx(() => OnlineStoreStateView(
                  loading: controller.loading.value,
                  error: controller.error.value,
                  isEmpty: controller.items.isEmpty,
                  onRetry: controller.applyFilters,
                  child: RefreshIndicator(
                    onRefresh: controller.applyFilters,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: controller.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) =>
                          _eventCard(controller.items[index].values),
                    ),
                  ),
                )),
          ),
        ]),
      );

  Future<void> _showFilters(BuildContext context) => showOnlineStoreBottomSheet(
        context,
        child: Obx(() => _filters(onApplied: () {
              Navigator.pop(context);
              controller.applyFilters();
            })),
      );

  Widget _filters({required VoidCallback onApplied}) => OnlineStoreFormSection(
        title: 'تصفية السجل',
        icon: Icons.filter_alt_outlined,
        child: SingleChildScrollView(
            child: Column(children: [
          Row(children: [
            Expanded(
                child: DropdownButtonFormField<String>(
              initialValue: controller.entityType.value,
              isDense: true,
              decoration: const InputDecoration(labelText: 'نوع السجل'),
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
                  .map((value) => DropdownMenuItem(
                      value: value, child: Text(_entityLabel(value))))
                  .toList(),
              onChanged: (value) =>
                  controller.entityType.value = value ?? 'all',
            )),
            const SizedBox(width: 8),
            Expanded(
                child: DropdownButtonFormField<String>(
              initialValue: controller.actionFilter.value,
              isDense: true,
              decoration: const InputDecoration(labelText: 'نوع العملية'),
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
                  .map((value) => DropdownMenuItem(
                      value: value, child: Text(_actionLabel(value))))
                  .toList(),
              onChanged: (value) =>
                  controller.actionFilter.value = value ?? 'all',
            )),
          ]),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'رقم الموظف (اختياري)',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              onChanged: (value) => controller.actorUserId.value = value,
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: OnlineStoreDateTimeField(
              controller: controller.fromController,
              label: 'من تاريخ',
              includeTime: false,
            )),
            const SizedBox(width: 8),
            Expanded(
                child: OnlineStoreDateTimeField(
              controller: controller.toController,
              label: 'إلى تاريخ',
              includeTime: false,
            )),
          ]),
          const SizedBox(height: 10),
          SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OnlineStoreAdminUi.actionButtonStyle,
                onPressed: onApplied,
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('تطبيق المرشحات'),
              )),
        ])),
      );

  Widget _eventCard(Map<String, dynamic> event) {
    final before = onlineStoreMap(event['before_values']);
    final after = onlineStoreMap(event['after_values']);
    final actor = onlineStoreMap(event['actor']);
    final keys = <String>{...before.keys, ...after.keys}
      ..removeWhere((key) => const {
            'created_at',
            'updated_at',
            'created_by',
            'updated_by',
          }.contains(key));
    final changed = keys
        .where((key) => '${before[key]}' != '${after[key]}')
        .toList(growable: false);
    final action = _actionLabel('${event['action'] ?? ''}');
    final entity = _entityLabel('${event['entity_type'] ?? ''}');

    return Card(
      color: OnlineStoreAdminUi.surface,
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: const BoxDecoration(
            color: OnlineStoreAdminUi.surfaceMuted,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.history_rounded,
              color: OnlineStoreAdminUi.accent),
        ),
        title: Text('$action — $entity',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          '${actor['name'] ?? 'موظف #${event['actor_user_id'] ?? '—'}'} • '
          '${onlineStoreFriendlyDate(event['occurred_at'])}\n'
          'رقم السجل: ${event['entity_id'] ?? '—'}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          if (changed.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('لا توجد تفاصيل إضافية قابلة للعرض.'),
            )
          else
            ...changed.map((key) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: OnlineStoreAdminUi.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_fieldLabel(key),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      if (before.containsKey(key))
                        Text('قبل: ${_value(before[key])}',
                            style: const TextStyle(
                                color: OnlineStoreAdminUi.textSecondary)),
                      if (after.containsKey(key))
                        Text('بعد: ${_value(after[key])}'),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  static String _entityLabel(String value) =>
      const {
        'all': 'كل أنواع السجلات',
        'listing': 'منتج المتجر',
        'promotion': 'عرض ترويجي',
        'coupon': 'كوبون',
        'settings': 'إعدادات المتجر',
        'account_link': 'حساب متجر',
        'credit_policy': 'سياسة ائتمان',
        'review': 'مراجعة عميل',
        'pricing': 'احتساب سعر',
      }[value] ??
      'سجل متجر';

  static String _actionLabel(String value) =>
      const {
        'all': 'كل العمليات',
        'created': 'إضافة',
        'updated': 'تعديل',
        'linked': 'ربط حساب',
        'approved': 'موافقة',
        'suspended': 'تعليق',
        'activated': 'تفعيل',
        'deactivated': 'إيقاف',
        'published': 'نشر',
        'hidden': 'إخفاء',
        'status_changed': 'تغيير الحالة',
        'moderated': 'مراجعة محتوى',
        'previewed': 'معاينة سعر',
      }[value] ??
      'عملية';

  String _fieldLabel(String value) =>
      const {
        'code': 'الرمز',
        'status': 'الحالة',
        'is_active': 'نشط',
        'is_featured': 'مميز',
        'is_new': 'جديد',
        'show_on_home': 'يظهر في الرئيسية',
        'show_as_offer': 'يظهر كعرض',
        'sort_order': 'ترتيب العرض',
        'readiness_state': 'حالة الجاهزية',
        'readiness_issues': 'ملاحظات الجاهزية',
        'published_at': 'وقت النشر',
        'hidden_at': 'وقت الإخفاء',
        'name_translations': 'الاسم',
        'title_translations': 'العنوان',
        'description_translations': 'الوصف',
        'discount_type': 'نوع الخصم',
        'discount_value': 'قيمة الخصم',
        'minimum_order': 'الحد الأدنى للطلب',
        'total_usage_limit': 'حد الاستخدام الكلي',
        'per_user_usage_limit': 'حد الاستخدام لكل مستخدم',
        'eligible_account_type': 'نوع الحساب المؤهل',
        'applies_to': 'نوع السعر',
        'scope': 'نطاق التطبيق',
        'starts_at': 'يبدأ في',
        'ends_at': 'ينتهي في',
        'role': 'نوع الحساب',
        'credit_limit': 'حد الائتمان',
        'payment_terms_days': 'مهلة السداد بالأيام',
        'is_eligible': 'مؤهل للائتمان',
        'approved_at': 'وقت الموافقة',
        'expires_at': 'انتهاء الموافقة',
        'currency': 'العملة',
        'store_enabled': 'المتجر مفعّل',
        'maintenance_mode': 'وضع الصيانة',
        'checkout_enabled': 'إتمام الطلبات مفعّل',
        'cod_enabled': 'الدفع عند الاستلام مفعّل',
        'guest_browsing_enabled': 'تصفح الزوار مفعّل',
        'enabled_languages': 'اللغات المفعّلة',
        'out_of_stock_behavior': 'سلوك نفاد المخزون',
        'low_stock_threshold': 'حد المخزون المنخفض',
        'account_source': 'مصدر الحساب',
        'verified_at': 'وقت التحقق',
        'rating': 'التقييم',
        'is_verified_purchase': 'عملية شراء موثقة',
        'moderated_by': 'راجعه الموظف',
        'moderated_at': 'وقت المراجعة',
        'moderation_reason': 'سبب المراجعة',
        'reason': 'السبب',
        'targets': 'الأهداف',
      }[value] ??
      value.replaceAll('_', ' ');

  String _value(dynamic value) {
    if (value == null) return 'غير محدد';
    if (value is bool) return value ? 'نعم' : 'لا';
    if (value is List) {
      if (value.isEmpty) return 'لا يوجد';
      return value.map(_value).join('، ');
    }
    if (value is Map) {
      final map = onlineStoreMap(value);
      if ('${map['ar'] ?? ''}'.trim().isNotEmpty) return '${map['ar']}';
      return map.entries
          .map((entry) => '${_fieldLabel(entry.key)}: ${_value(entry.value)}')
          .join('، ');
    }
    final raw = '$value';
    if (DateTime.tryParse(raw) != null) return onlineStoreFriendlyDate(raw);
    return const {
          'draft': 'مسودة',
          'ready': 'جاهز',
          'published': 'منشور',
          'hidden': 'مخفي',
          'pending': 'قيد الانتظار',
          'approved': 'مقبول',
          'rejected': 'مرفوض',
          'percentage': 'نسبة مئوية',
          'fixed': 'مبلغ ثابت',
          'customer': 'تجزئة',
          'seller': 'جملة',
          'both': 'الجميع',
          'retail': 'سعر التجزئة',
          'wholesale': 'سعر الجملة',
          'global': 'كل المتجر',
          'targeted': 'عناصر محددة',
          'active': 'نشط',
          'inactive': 'غير نشط',
        }['$value'] ??
        '$value';
  }
}
