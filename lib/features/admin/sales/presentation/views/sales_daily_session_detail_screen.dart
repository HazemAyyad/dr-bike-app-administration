import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../data/datasources/sales_datasources.dart';
import '../../data/models/daily_session_model.dart';
import '../../../../../routes/app_routes.dart';
import '../widgets/sales_daily_session_orders_log.dart';
import '../widgets/sales_daily_session_sales_log.dart';
import '../widgets/sales_daily_ui_widgets.dart';
import '../widgets/sales_skeleton_widgets.dart';

class SalesDailySessionDetailScreen extends StatefulWidget {
  const SalesDailySessionDetailScreen({Key? key}) : super(key: key);

  @override
  State<SalesDailySessionDetailScreen> createState() =>
      _SalesDailySessionDetailScreenState();
}

class _SalesDailySessionDetailScreenState
    extends State<SalesDailySessionDetailScreen> {
  bool _loading = true;
  String? _error;
  DailySessionDetailModel? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final args = Get.arguments;
    if (args is DailySessionDetailModel) {
      setState(() {
        _detail = args;
        _loading = false;
      });
      return;
    }

    final sessionId = args is int ? args : int.tryParse('$args');
    if (sessionId == null) {
      setState(() {
        _loading = false;
        _error = 'error'.tr;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      AppDependencyRegistry.ensureSales();
      final ds = Get.find<SalesDatasource>();
      final detail = await ds.getDailySessionDetail(sessionId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'salesDailySessionDetail', action: false),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SalesDailySessionDetailSkeleton();
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              SizedBox(height: 16.h),
              AppButton(text: 'tryAgain'.tr, onPressed: _load),
            ],
          ),
        ),
      );
    }

    final detail = _detail;
    if (detail == null) {
      return Center(child: Text('noData'.tr));
    }

    final session = detail.session;

    return ListView(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 16.h),
      children: [
        SalesDailyDetailHeader(
          session: session,
          instantCount: detail.instantSalesCount,
          profitCount: detail.profitSalesCount,
        ),
        if (session.canRequestClosing) ...[
          SizedBox(height: 10.h),
          AppButton(
            text: 'salesDailyCloseDay'.tr,
            onPressed: () => Get.toNamed(
              AppRoutes.SALESDAILYCLOSESCREEN,
              arguments: session.id,
            ),
          ),
        ],
        SalesDailySectionTitle(title: 'salesDailyBoxesSection'.tr),
        SalesDailyCurrencyTable(currencies: detail.currencies),
        SalesDailySectionTitle(title: 'salesDailyOrdersSection'.tr),
        SalesDailySessionOrdersLog(orders: detail.salesOrders),
        SalesDailySectionTitle(title: 'salesDailySalesLog'.tr),
        SalesDailySessionSalesLog(
          instantSales: detail.instantSales,
          profitSales: detail.profitSales,
        ),
        if (detail.closingRequests.isNotEmpty) ...[
          SalesDailySectionTitle(title: 'salesDailyClosingHistory'.tr),
          ...detail.closingRequests.map(
            (request) => SalesDailyClosingTile(request: request),
          ),
        ],
      ],
    );
  }
}
