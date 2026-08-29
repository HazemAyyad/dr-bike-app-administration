import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/show_no_data.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/assets_controller.dart';
import '../../controllers/finacial_service.dart';
import '../../widgets/financial_skeletons.dart';

class AssetsLogScreen extends StatefulWidget {
  const AssetsLogScreen({Key? key}) : super(key: key);

  @override
  State<AssetsLogScreen> createState() => _AssetsLogScreenState();
}

class _AssetsLogScreenState extends State<AssetsLogScreen> {
  final AssetsController controller = Get.find<AssetsController>();
  final TextEditingController searchController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'سجل إهلاك الأصول',
        actions: [
          IconButton(
            tooltip: 'فلترة الفترة',
            onPressed: _showPeriodFilter,
            icon: const Icon(Icons.tune_rounded, color: AppColors.primaryColor),
          ),
          IconButton(
            tooltip: 'تنزيل PDF',
            onPressed: () => controller.downloadReport(),
            icon: const Icon(Icons.picture_as_pdf_outlined,
                color: AppColors.primaryColor),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: GetBuilder<AssetsController>(builder: (_) {
        if (controller.isLoadingDepreciate.value &&
            FinacialService().assetsLogs.isEmpty) {
          return const CustomScrollView(
            slivers: [FinancialListSkeletonSliver()],
          );
        }
        final logs = FinacialService()
            .assetsLogs
            .where((log) =>
                query.isEmpty ||
                log.assetName.toLowerCase().contains(query.toLowerCase()) ||
                log.depreciationPeriod.contains(query))
            .toList()
          ..sort((a, b) => b.depreciationDate.compareTo(a.depreciationDate));
        final total =
            logs.fold<double>(0, (sum, log) => sum + log.depreciationAmount);
        final assetsCount = logs.map((log) => log.assetId).toSet().length;

        return RefreshIndicator(
          onRefresh: () async => controller.getAssetsLogs(),
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 8.h),
                child: Column(children: [
                  Container(
                    padding: EdgeInsets.all(15.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withValues(alpha: .72),
                      ]),
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Column(children: [
                      Row(children: [
                        const Icon(Icons.auto_graph_rounded,
                            color: Colors.white),
                        SizedBox(width: 8.w),
                        const Expanded(
                          child: Text('ملخص حركة الإهلاك',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Obx(() => Text(
                              controller.assetLogPeriodFilter.value.isEmpty
                                  ? 'كل الفترات'
                                  : controller.assetLogPeriodFilter.value,
                              style: const TextStyle(color: Colors.white70),
                            )),
                      ]),
                      SizedBox(height: 14.h),
                      Row(children: [
                        _SummaryValue(
                            label: 'الحركات', value: '${logs.length}'),
                        _SummaryValue(label: 'الأصول', value: '$assetsCount'),
                        _SummaryValue(
                          label: 'إجمالي الإهلاك',
                          value: NumberFormat('#,##0.00').format(total),
                        ),
                      ]),
                    ]),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: searchController,
                    onChanged: (value) => setState(() => query = value.trim()),
                    decoration: InputDecoration(
                      hintText: 'ابحث باسم الأصل أو فترة الإهلاك',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                searchController.clear();
                                setState(() => query = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            if (logs.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: ShowNoData(),
              )
            else
              SliverList.builder(
                itemCount: logs.length,
                itemBuilder: (_, index) {
                  final log = logs[index];
                  final before = log.valueBefore;
                  final after = double.tryParse(log.total) ??
                      (before - log.depreciationAmount);
                  return Container(
                    margin: EdgeInsets.fromLTRB(18.w, 5.h, 18.w, 5.h),
                    padding: EdgeInsets.all(13.r),
                    decoration: BoxDecoration(
                      color: ThemeService.isDark.value
                          ? AppColors.customGreyColor
                          : AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(15.r),
                      border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: .13),
                      ),
                    ),
                    child: Column(children: [
                      Row(children: [
                        CircleAvatar(
                          backgroundColor:
                              AppColors.primaryColor.withValues(alpha: .12),
                          child: const Icon(Icons.precision_manufacturing,
                              color: AppColors.primaryColor),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.assetName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(
                                DateFormat('yyyy-MM-dd • HH:mm')
                                    .format(log.depreciationDate),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 9.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: .11),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            log.type == 'create' ? 'إنشاء الأصل' : 'تم الإهلاك',
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]),
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: .055),
                          borderRadius: BorderRadius.circular(11.r),
                        ),
                        child: Row(children: [
                          _LogValue(label: 'قبل', value: before),
                          const Icon(Icons.arrow_back_rounded,
                              color: AppColors.primaryColor),
                          _LogValue(
                              label: 'الإهلاك',
                              value: log.depreciationAmount,
                              negative: true),
                          const Icon(Icons.arrow_back_rounded,
                              color: AppColors.primaryColor),
                          _LogValue(label: 'بعد', value: after),
                        ]),
                      ),
                      SizedBox(height: 8.h),
                      Row(children: [
                        const Icon(Icons.calendar_month_outlined, size: 17),
                        SizedBox(width: 5.w),
                        Text(log.depreciationPeriod.isEmpty
                            ? DateFormat('yyyy-MM').format(log.depreciationDate)
                            : log.depreciationPeriod),
                        const Spacer(),
                        Text('نسبة الإهلاك ${log.depreciationRate}%'),
                      ]),
                    ]),
                  );
                },
              ),
            SliverToBoxAdapter(child: SizedBox(height: 35.h)),
          ]),
        );
      }),
    );
  }

  void _showPeriodFilter() {
    final current = DateFormat('yyyy-MM').format(DateTime.now());
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const ListTile(
              leading: Icon(Icons.tune_rounded),
              title: Text('فلترة سجل الإهلاك',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive_rounded),
              title: const Text('كل الفترات'),
              onTap: () {
                Get.back();
                controller.setAssetLogPeriodFilter('');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('الشهر الحالي'),
              subtitle: Text(current),
              onTap: () {
                Get.back();
                controller.setAssetLogPeriodFilter(current);
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ]),
      );
}

class _LogValue extends StatelessWidget {
  const _LogValue({
    required this.label,
    required this.value,
    this.negative = false,
  });
  final String label;
  final double value;
  final bool negative;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            '${negative ? '-' : ''}${NumberFormat('#,##0.00').format(value)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: negative ? Colors.redAccent : null,
            ),
          ),
        ]),
      );
}
