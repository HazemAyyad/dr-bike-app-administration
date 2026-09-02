import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/sales_order_model.dart';
import '../controllers/sales_orders_controller.dart';
import 'sales_order_status_ui.dart';

/// عرض الطلبيات كبطاقات تشغيلية مضغوطة، بنفس لغة قسم الصيانة.
class SalesOrdersTable extends GetView<SalesOrdersController> {
  const SalesOrdersTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final groups = controller.statusFilter.value == 'all'
          ? _groupOperationally(controller.orders)
          : _groupByDate(controller.orders);
      if (groups.isEmpty) {
        return Padding(
          padding: EdgeInsets.only(top: 30.h),
          child: Column(
            children: [
              const ShowNoData(),
              if (controller.statusFilter.value == 'archived')
                Text(
                  'لا توجد طلبيات مؤرشفة',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
            ],
          ),
        );
      }
      final bulk =
          controller.bulkMode.value && controller.canBulkSelectCurrentTab;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final group in groups) ...[
            _DateHeader(
              label: group.label,
              count: group.orders.length,
              color: group.color,
              icon: group.icon,
              formatAsDate: group.formatAsDate,
            ),
            ...group.orders.map(
              (order) => _SwipeOrderCard(
                enabled: !bulk,
                onCall: () => _showRecipientContact(context, order),
                onOptions: () => _showOrderOptions(context, order),
                child: _OrderCard(
                  order: order,
                  bulk: bulk,
                  selected: controller.selectedOrderIds.contains(order.id),
                  onSelect: (value) =>
                      controller.toggleOrderSelection(order.id, value),
                  onTap: () {
                    if (bulk) {
                      controller.toggleOrderSelection(
                        order.id,
                        !controller.selectedOrderIds.contains(order.id),
                      );
                      return;
                    }
                    Get.toNamed(
                      AppRoutes.SALESORDERDETAILSCREEN,
                      arguments: order.id,
                    );
                  },
                  onLongPress: order.status == 'unconfirmed' && !bulk
                      ? () => controller.confirmOrder(order.id)
                      : null,
                ),
              ),
            ),
            SizedBox(height: 7.h),
          ],
        ],
      );
    });
  }

  Future<void> _showRecipientContact(
    BuildContext context,
    SalesOrderListItemModel order,
  ) async {
    final phone = (order.customerPhone ?? '').trim();
    if (phone.isEmpty) {
      Get.snackbar('لا يوجد رقم للمستلم', 'أضف رقم المستلم من تفاصيل الطلبية');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 18.h),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(order.customerName ?? 'المستلم',
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 3.h),
            Text(phone, style: TextStyle(color: Colors.grey.shade600)),
            SizedBox(height: 14.h),
            _ContactAction(
              icon: Icons.phone_outlined,
              label: 'اتصال عادي',
              onTap: () => _launchPhone(phone),
            ),
            for (final candidate in _whatsAppNumbers(phone))
              _ContactAction(
                icon: Icons.chat_outlined,
                label: 'واتساب +${candidate.substring(0, 3)}',
                onTap: () => _launchWhatsApp(candidate),
              ),
            _ContactAction(
              icon: Icons.copy_rounded,
              label: 'نسخ الرقم',
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: phone));
                Get.back();
                Get.snackbar('تم النسخ', phone);
              },
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _showOrderOptions(
    BuildContext context,
    SalesOrderListItemModel order,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 16.h),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              title: Text(order.customerName ?? 'الطلبية',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(order.serialNumber ?? '#${order.id}'),
              trailing: Icon(Icons.circle,
                  size: 13.sp,
                  color: SalesOrderStatusUi.statusColor(order.status)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('فتح تفاصيل الطلبية'),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.SALESORDERDETAILSCREEN,
                    arguments: order.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('الاتصال بالمستلم'),
              onTap: () {
                Get.back();
                _showRecipientContact(context, order);
              },
            ),
            if (order.status == 'unconfirmed')
              ListTile(
                leading:
                    const Icon(Icons.fact_check_outlined, color: Colors.green),
                title: const Text('تأكيد الطلبية'),
                onTap: () => _runQuickAction(
                  context,
                  title: 'تأكيد الطلبية؟',
                  action: () => controller.confirmOrder(order.id),
                ),
              ),
            if (order.status == 'confirmed')
              ListTile(
                leading:
                    const Icon(Icons.inventory_2_outlined, color: Colors.green),
                title: const Text('تحديد كجاهزة'),
                onTap: () => _runQuickAction(
                  context,
                  title: 'تحديد الطلبية كجاهزة؟',
                  action: () => controller.markReady(order.id),
                ),
              ),
            const ListTile(
              dense: true,
              leading: Icon(Icons.info_outline_rounded),
              title: Text(
                  'بقية الإجراءات تظهر داخل الطلبية حسب حالتها ومتطلباتها'),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _runQuickAction(
    BuildContext context, {
    required String title,
    required Future<void> Function() action,
  }) async {
    Get.back();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: const Text('سيتم تحديث حالة الطلبية مباشرة.'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('رجوع')),
          FilledButton(
              onPressed: () => Get.back(result: true),
              child: const Text('تأكيد')),
        ],
      ),
    );
    if (confirmed == true) await action();
  }

  Future<void> _launchPhone(String phone) async {
    Get.back();
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      Get.snackbar('تعذر الاتصال', 'لا يوجد تطبيق اتصال متاح');
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    Get.back();
    final uri = Uri.parse('https://wa.me/$phone');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('تعذر فتح واتساب', 'تأكد من تثبيت واتساب على الجهاز');
    }
  }

  List<String> _whatsAppNumbers(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('970') || digits.startsWith('972')) {
      return [digits];
    }
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.isEmpty) return const [];
    return ['970$digits', '972$digits'];
  }

  List<_OrderGroup> _groupByDate(List<SalesOrderListItemModel> orders) {
    final grouped = <String, List<SalesOrderListItemModel>>{};
    for (final order in orders) {
      final raw = order.createdAt ?? '';
      final parsed = DateTime.tryParse(raw);
      final key = parsed == null
          ? (raw.length >= 10 ? raw.substring(0, 10) : '—')
          : DateFormat('yyyy-MM-dd').format(parsed);
      grouped.putIfAbsent(key, () => []).add(order);
    }
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return keys
        .map((key) => _OrderGroup(
              key,
              grouped[key]!,
              color: AppColors.primaryColor,
              icon: Icons.calendar_today_outlined,
              formatAsDate: true,
            ))
        .toList();
  }

  List<_OrderGroup> _groupOperationally(
    List<SalesOrderListItemModel> orders,
  ) {
    const statuses = [
      'unconfirmed',
      'confirmed',
      'ready',
      'with_delivery',
      'review',
      'partial_delivered',
      'partial_return',
      'alternative_return',
      'returned',
      'stuck',
      'delivered',
      'canceled',
      'postponed',
    ];
    final known = statuses.where(
      (status) => orders.any((order) => order.status == status),
    );
    final unknown = orders
        .map((order) => order.status)
        .where((status) => !statuses.contains(status))
        .toSet();
    return [...known, ...unknown].map((status) {
      final rows = orders.where((order) => order.status == status).toList();
      return _OrderGroup(
        controller.statusLabel(status),
        rows,
        color: SalesOrderStatusUi.statusColor(status),
        icon: _statusIcon(status),
      );
    }).toList();
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'unconfirmed':
        return Icons.fiber_new_rounded;
      case 'confirmed':
        return Icons.fact_check_outlined;
      case 'ready':
        return Icons.inventory_2_outlined;
      case 'with_delivery':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.check_circle_outline_rounded;
      case 'archived':
        return Icons.archive_outlined;
      case 'canceled':
      case 'returned':
        return Icons.keyboard_return_rounded;
      case 'postponed':
        return Icons.schedule_outlined;
      case 'stuck':
        return Icons.report_problem_outlined;
      default:
        return Icons.sync_alt_rounded;
    }
  }
}

class _OrderGroup {
  const _OrderGroup(
    this.label,
    this.orders, {
    required this.color,
    required this.icon,
    this.formatAsDate = false,
  });
  final String label;
  final List<SalesOrderListItemModel> orders;
  final Color color;
  final IconData icon;
  final bool formatAsDate;
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.formatAsDate,
  });
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool formatAsDate;

  @override
  Widget build(BuildContext context) {
    final date = formatAsDate ? DateTime.tryParse(label) : null;
    final text = !formatAsDate || date == null
        ? label
        : DateFormat('EEEE d MMMM', Get.locale?.languageCode ?? 'ar')
            .format(date);
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 4.h),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 18.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(width: 7.w),
          Icon(icon, size: 17.sp, color: color),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text('$count', style: TextStyle(fontSize: 10.sp)),
          ),
        ],
      ),
    );
  }
}

class _SwipeOrderCard extends StatefulWidget {
  const _SwipeOrderCard({
    required this.child,
    required this.enabled,
    required this.onCall,
    required this.onOptions,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback onCall;
  final VoidCallback onOptions;

  @override
  State<_SwipeOrderCard> createState() => _SwipeOrderCardState();
}

class _SwipeOrderCardState extends State<_SwipeOrderCard> {
  double offset = 0;
  static const double revealWidth = 146;

  @override
  void didUpdateWidget(covariant _SwipeOrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled && offset != 0) {
      offset = 0;
    }
  }

  void _update(DragUpdateDetails details) {
    if (!widget.enabled) return;
    setState(() => offset = (offset + details.delta.dx).clamp(0, revealWidth));
  }

  void _finish(DragEndDetails details) {
    if (!widget.enabled) return;
    final shouldOpen =
        offset > revealWidth * .34 || (details.primaryVelocity ?? 0) > 350;
    setState(() => offset = shouldOpen ? revealWidth : 0);
  }

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (widget.enabled)
            Positioned(
              left: 12.w,
              child: Row(children: [
                _SwipeAction(
                  icon: Icons.phone_outlined,
                  label: 'اتصال',
                  color: const Color(0xFF0F766E),
                  onTap: () {
                    setState(() => offset = 0);
                    widget.onCall();
                  },
                ),
                SizedBox(width: 5.w),
                _SwipeAction(
                  icon: Icons.more_horiz_rounded,
                  label: 'الخيارات',
                  color: AppColors.primaryColor,
                  onTap: () {
                    setState(() => offset = 0);
                    widget.onOptions();
                  },
                ),
              ]),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(offset, 0, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: widget.enabled ? _update : null,
              onHorizontalDragEnd: widget.enabled ? _finish : null,
              child: widget.child,
            ),
          ),
        ],
      );
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(11.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11.r),
          child: SizedBox(
            width: 66.w,
            height: 66.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20.sp),
                SizedBox(height: 3.h),
                Text(label,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
}

class _ContactAction extends StatelessWidget {
  const _ContactAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: onTap,
            icon: Icon(icon),
            label: Text(label),
          ),
        ),
      );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.bulk,
    required this.selected,
    required this.onSelect,
    required this.onTap,
    this.onLongPress,
  });

  final SalesOrderListItemModel order;
  final bool bulk;
  final bool selected;
  final ValueChanged<bool> onSelect;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final dark = ThemeService.isDark.value;
    final statusColor = SalesOrderStatusUi.statusColor(order.status);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryColor.withValues(alpha: 0.08)
                : dark
                    ? AppColors.customGreyColor
                    : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.operationalCardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (bulk)
                Checkbox(
                  value: selected,
                  onChanged: (value) => onSelect(value ?? false),
                  visualDensity: VisualDensity.compact,
                )
              else
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    color: statusColor,
                    size: 19.sp,
                  ),
                ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.customerName ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          order.serialNumber ?? '#${order.id}',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        _Meta(
                          icon: Icons.location_on_outlined,
                          text: order.cityName ?? '—',
                        ),
                        SizedBox(width: 8.w),
                        _Meta(
                          icon: Icons.payments_outlined,
                          text: '${order.total.toStringAsFixed(2)} ₪',
                          strong: true,
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            Get.find<SalesOrdersController>()
                                .statusLabel(order.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (order.customerDebtBalance > 0.009 ||
                        order.carrierReceivableBalance > 0.009) ...[
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 13.sp,
                            color: const Color(0xFFB45309),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              _settlementLabel(order),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: const Color(0xFFB45309),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!order.reservesStock) ...[
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 13.sp, color: Colors.orange.shade800),
                          SizedBox(width: 3.w),
                          Text(
                            'الكمية غير محجوزة',
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(
                          Icons.delivery_dining_outlined,
                          size: 13.sp,
                          color: statusColor,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            'وسيلة التوصيل: ${_deliveryLabel(order)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: SalesOrdersController.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 3.w),
              Icon(Icons.chevron_left_rounded, size: 19.sp, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _deliveryLabel(SalesOrderListItemModel order) {
    final name = order.deliveryCompanyName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (order.status == 'unconfirmed' ||
        order.status == 'confirmed' ||
        order.status == 'ready' ||
        order.status == 'postponed') {
      return 'لم تُحدد بعد';
    }
    return 'غير مسجلة';
  }

  String _settlementLabel(SalesOrderListItemModel order) {
    final parts = <String>[];
    if (order.carrierReceivableBalance > 0.009) {
      parts.add(
        'مستحق شركة التوصيل ${order.carrierReceivableBalance.toStringAsFixed(2)} ₪',
      );
    }
    if (order.customerDebtBalance > 0.009) {
      parts.add(
        'دين الزبون ${order.customerDebtBalance.toStringAsFixed(2)} ₪',
      );
    }
    return parts.join(' • ');
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.strong = false});
  final IconData icon;
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.sp, color: Colors.grey.shade600),
        SizedBox(width: 2.w),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
            color: strong ? AppColors.primaryColor : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
