import 'package:doctorbike/core/helpers/show_no_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/custom_dropdown_field.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:doctorbike/core/services/theme_service.dart';
import 'package:doctorbike/core/utils/app_colors.dart';

import '../../domain/entity/all_boxes_logs_entity.dart';
import '../controllers/boxes_controller.dart';
import '../widgets/movements_widget.dart';

class EditBoxesScreen extends StatefulWidget {
  const EditBoxesScreen({Key? key}) : super(key: key);

  @override
  State<EditBoxesScreen> createState() => _EditBoxesScreenState();
}

class _EditBoxesScreenState extends State<EditBoxesScreen> {
  late final BoxesController controller;
  late final String boxId;
  final TextEditingController _movementSearchController =
      TextEditingController();
  String _movementQuery = '';

  @override
  void initState() {
    super.initState();
    controller = Get.find<BoxesController>();
    boxId = Get.arguments?.toString() ?? '';
    if (kDebugMode) {
      debugPrint(
        '[EditBoxesScreen] Get.arguments=${Get.arguments} resolvedBoxId=$boxId',
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.getboxDetails(boxId);
      }
    });
  }

  @override
  void dispose() {
    _movementSearchController.dispose();
    super.dispose();
  }

  List<BoxLog> _filteredLogs(List<BoxLog> logs) {
    final query = _movementQuery.trim().toLowerCase();
    if (query.isEmpty) return logs;

    return logs.where((log) {
      final amount = log.value.toString();
      final amountNoDecimals = log.value.toStringAsFixed(0);
      final formattedAmount = NumberFormat('#,###.##').format(log.value);
      final fields = [
        amount,
        amountNoDecimals,
        formattedAmount,
        log.value.abs().toString(),
        log.description,
        log.note ?? '',
        log.type ?? '',
        log.invoiceNumber ?? '',
        log.paymentMethod ?? '',
        log.box?.name ?? '',
        log.fromBox?.name ?? '',
        log.toBox?.name ?? '',
      ];
      return fields.any((field) => field.toLowerCase().contains(query));
    }).toList();
  }

  String? _appearDropdownValue(String raw) {
    return controller.appears.contains(raw) ? raw : null;
  }

  void _openEditSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          ThemeService.isDark.value ? AppColors.darkColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 16.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              child: Form(
                key: controller.formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: AppColors.primaryColor,
                            size: 22.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'editBox'.tr,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      CustomTextField(
                        isRequired: true,
                        label: 'boxName'.tr,
                        hintText: 'BalanceTransferExample',
                        controller: controller.editBoxNameController,
                      ),
                      SizedBox(height: 10.h),
                      CustomDropdownField(
                        label: 'appear',
                        hint: 'visible',
                        value: _appearDropdownValue(
                          controller.editAppearController.text,
                        ),
                        items: controller.appears,
                        onChanged: (value) {
                          controller.editAppearController.text = value!;
                          setModalState(() {});
                        },
                      ),
                      SizedBox(height: 10.h),
                      _ReadOnlyInfoRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'startBalance'.tr,
                        value: controller.editStartBalanceController.text,
                      ),
                      SizedBox(height: 8.h),
                      _ReadOnlyInfoRow(
                        icon: Icons.payments_outlined,
                        label: 'currencyy'.tr,
                        value: controller.editCurrencyController.text,
                      ),
                      SizedBox(height: 18.h),
                      AppButton(
                        isSafeArea: false,
                        isLoading: controller.isAddBoxLoading,
                        text: 'editBox',
                        widget: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                        onPressed: () {
                          if ((controller.formKey.currentState as FormState)
                              .validate()) {
                            controller.editBox(context: context, boxId: boxId);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ['بروفايل الصندوق', 'سجل الحركات'];
    final isDark = ThemeService.isDark.value;

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'editBox'.tr,
          action: false,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(46.h),
            child: Container(
              color: isDark ? AppColors.darkColor : Colors.white,
              child: TabBar(
                labelColor:
                    isDark ? AppColors.primaryColor : AppColors.secondaryColor,
                unselectedLabelColor: AppColors.customGreyColor5,
                indicatorColor:
                    isDark ? AppColors.primaryColor : AppColors.secondaryColor,
                labelStyle: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
                tabs: tabs.map((tab) => Tab(text: tab)).toList(),
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: _openEditSheet,
              icon: Icon(
                Icons.edit_outlined,
                color:
                    isDark ? AppColors.primaryColor : AppColors.secondaryColor,
                size: 22.sp,
              ),
              label: Text(
                'edit'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.primaryColor
                          : AppColors.secondaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
        body: GetBuilder<BoxesController>(
          builder: (controller) {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.boxDetailsDebugMessage.value.isNotEmpty) {
              return _BoxErrorState(
                message: controller.boxDetailsDebugMessage.value,
                onRetry: () => controller.getboxDetails(boxId),
              );
            }

            return ColoredBox(
              color: isDark ? AppColors.darkColor : const Color(0xFFF4F6FA),
              child: TabBarView(
                children: [
                  _BoxProfileTab(
                    controller: controller,
                    onEdit: _openEditSheet,
                  ),
                  _BoxMovementsTab(
                    logs: _filteredLogs(controller.boxDetailsLogs),
                    searchController: _movementSearchController,
                    onSearchChanged: (value) {
                      setState(() => _movementQuery = value);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BoxProfileTab extends StatelessWidget {
  const _BoxProfileTab({
    required this.controller,
    required this.onEdit,
  });

  final BoxesController controller;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final logs = controller.boxDetailsLogs;
    final deposits = logs.where((log) => log.value > 0).fold<double>(
          0,
          (sum, log) => sum + log.value,
        );
    final withdrawals = logs.where((log) => log.value < 0).fold<double>(
          0,
          (sum, log) => sum + log.value.abs(),
        );
    final transfers = logs.where((log) => log.type == 'transfer').length;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 28.h),
      children: [
        _BoxHeaderCard(
          name: controller.editBoxNameController.text,
          balance: controller.editStartBalanceController.text,
          currency: controller.editCurrencyController.text,
          isShown: controller.editAppearController.text == 'visible',
          onEdit: onEdit,
        ),
        SizedBox(height: 12.h),
        _SummaryGrid(
          items: [
            _SummaryItem(
              icon: Icons.receipt_long_outlined,
              label: 'عدد الحركات',
              value: logs.length.toString(),
              color: AppColors.primaryColor,
            ),
            _SummaryItem(
              icon: Icons.south_west_rounded,
              label: 'إجمالي الإدخال',
              value: _money(deposits),
              color: AppColors.customGreen1,
            ),
            _SummaryItem(
              icon: Icons.north_east_rounded,
              label: 'إجمالي السحب',
              value: _money(withdrawals),
              color: AppColors.redColor,
            ),
            _SummaryItem(
              icon: Icons.swap_horiz_rounded,
              label: 'عمليات النقل',
              value: transfers.toString(),
              color: AppColors.customOrange3,
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _InfoSection(
          title: 'معلومات الصندوق',
          icon: Icons.inventory_2_outlined,
          children: [
            _ReadOnlyInfoRow(
              icon: Icons.badge_outlined,
              label: 'boxName'.tr,
              value: controller.editBoxNameController.text,
            ),
            _ReadOnlyInfoRow(
              icon: Icons.payments_outlined,
              label: 'currencyy'.tr,
              value: controller.editCurrencyController.text,
            ),
            _ReadOnlyInfoRow(
              icon: Icons.visibility_outlined,
              label: 'appear'.tr,
              value: controller.editAppearController.text.tr,
            ),
            _ReadOnlyInfoRow(
              icon: Icons.history_rounded,
              label: 'آخر حركة',
              value: logs.isEmpty
                  ? 'noData'.tr
                  : DateFormat('yyyy-MM-dd  HH:mm').format(logs.last.createdAt),
            ),
          ],
        ),
      ],
    );
  }

  static String _money(double value) => NumberFormat('#,###.##').format(value);
}

class _BoxMovementsTab extends StatelessWidget {
  const _BoxMovementsTab({
    required this.logs,
    required this.searchController,
    required this.onSearchChanged,
  });

  final List<BoxLog> logs;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final reversedLogs = logs.reversed.toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
          child: SearchBar(
            controller: searchController,
            shadowColor: WidgetStateProperty.all(Colors.transparent),
            leading: const Icon(Icons.search_rounded),
            trailing: [
              if (searchController.text.isNotEmpty)
                IconButton(
                  tooltip: 'clear'.tr,
                  onPressed: () {
                    searchController.clear();
                    onSearchChanged('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
            hintText: 'ابحث بالمبلغ أو وصف الحركة',
            onChanged: onSearchChanged,
            backgroundColor: WidgetStateProperty.all(
              ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : Colors.white,
            ),
            textStyle: WidgetStateProperty.all(
              Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13.sp),
            ),
            hintStyle: WidgetStateProperty.all(
              Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.customGreyColor5,
                  ),
            ),
          ),
        ),
        Expanded(
          child: reversedLogs.isEmpty
              ? const Center(child: ShowNoData())
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
                  itemCount: reversedLogs.length,
                  itemBuilder: (context, index) {
                    final log = reversedLogs[index];
                    return _MovementProfileCard(log: log);
                  },
                ),
        ),
      ],
    );
  }
}

class _BoxHeaderCard extends StatelessWidget {
  const _BoxHeaderCard({
    required this.name,
    required this.balance,
    required this.currency,
    required this.isShown,
    required this.onEdit,
  });

  final String name;
  final String balance;
  final String currency;
  final bool isShown;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final textStyle = Theme.of(context).textTheme.bodyMedium!;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.customGreyColor : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withAlpha(28),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primaryColor,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'boxName'.tr : name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    _StatusPill(isShown: isShown),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'edit'.tr,
                onPressed: onEdit,
                icon: Icon(
                  Icons.edit_outlined,
                  color: isDark
                      ? AppColors.primaryColor
                      : AppColors.secondaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Text(
            'الرصيد الحالي',
            style: textStyle.copyWith(
              fontSize: 12.sp,
              color: AppColors.customGreyColor5,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    balance.isEmpty ? '0' : balance,
                    style: textStyle.copyWith(
                      fontSize: 34.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Padding(
                padding: EdgeInsets.only(bottom: 7.h),
                child: Text(
                  currency,
                  style: textStyle.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.items});

  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) => _SummaryTile(item: items[index]),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final textStyle = Theme.of(context).textTheme.bodyMedium!;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.customGreyColor : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: item.color.withAlpha(44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(item.icon, color: item.color, size: 22.sp),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle.copyWith(
              fontSize: 17.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle.copyWith(
              fontSize: 11.sp,
              color: AppColors.customGreyColor5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.customGreyColor : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryColor, size: 21.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ...children,
        ],
      ),
    );
  }
}

class _ReadOnlyInfoRow extends StatelessWidget {
  const _ReadOnlyInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: AppColors.customGreyColor5),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle.copyWith(
                fontSize: 12.sp,
                color: AppColors.customGreyColor5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: Text(
              value.isEmpty ? '—' : value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: textStyle.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isShown});

  final bool isShown;

  @override
  Widget build(BuildContext context) {
    final color = isShown ? AppColors.customGreen1 : AppColors.redColor;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isShown ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: color,
            size: 14.sp,
          ),
          SizedBox(width: 5.w),
          Text(
            isShown ? 'visible'.tr : 'notVisible'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _MovementProfileCard extends StatelessWidget {
  const _MovementProfileCard({required this.log});

  final BoxLog log;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final amountColor = log.type == 'transfer'
        ? AppColors.customOrange3
        : log.value >= 0
            ? AppColors.customGreen1
            : AppColors.redColor;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.customGreyColor : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: amountColor.withAlpha(35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 9.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: 74.h, child: MovementsWidget(box: log)),
          Padding(
            padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 10.h),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 15.sp,
                  color: AppColors.customGreyColor5,
                ),
                SizedBox(width: 5.w),
                Expanded(
                  child: Text(
                    DateFormat('yyyy-MM-dd  HH:mm').format(log.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 10.5.sp,
                          color: AppColors.customGreyColor5,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (log.boxBalanceAfter != null)
                  Text(
                    '${'الرصيد بعد الحركة'}: ${NumberFormat('#,###.##').format(log.boxBalanceAfter)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 10.5.sp,
                          color: AppColors.customGreyColor5,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoxErrorState extends StatelessWidget {
  const _BoxErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.redColor,
              size: 38.sp,
            ),
            SizedBox(height: 10.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.redColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 16.h),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
