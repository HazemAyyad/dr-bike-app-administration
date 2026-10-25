import 'package:get/get.dart';

import '../../../../../core/helpers/app_failure_notice.dart';
import '../../data/datasources/sales_datasources.dart';
import '../../data/models/daily_session_model.dart';
import '../controllers/sales_controller.dart';
import '../controllers/sales_daily_admin_controller.dart';
import '../views/sales_daily_admin_screen.dart';
import '../widgets/sales_daily_status_bar.dart';
import 'daily_drawer_access_flow.dart';

Future<DailySessionPayload?> prepareSaleDrawer(
  SalesController sales, {
  bool salesOrders = false,
}) async {
  try {
    return await prepareDailyDrawer(
      loadPayload: () async {
        if (salesOrders) return sales.loadSalesOrdersDailySession();
        await sales.loadDailySession();
        return sales.dailySessionPayload.value;
      },
      reviewClosing: (requestId) async {
        final requests =
            await Get.find<SalesDatasource>().getPendingDailyClosing();
        final type = salesOrders ? 'sales_orders' : 'instant_sales';
        final request = requests.firstWhereOrNull(
          (item) => item.id == requestId && item.sessionType == type,
        );
        if (request == null) return false;
        if (!Get.isRegistered<SalesDailyAdminController>()) {
          SalesDailyAdminBinding().dependencies();
        }
        final admin = Get.find<SalesDailyAdminController>();
        await admin.loadAll();
        final context = Get.context;
        if (context == null || !context.mounted) return false;
        return await SalesDailyClosingRequestsList.showClosingSheet(
              context,
              admin,
              request,
              continueAfterApproval: true,
            ) ==
            true;
      },
      openDrawer: () async {
        final context = Get.context;
        if (context == null || !context.mounted) return false;
        var opened = false;
        await SalesDailyStatusBar(
          salesOrders: salesOrders,
          onOpened: () async => opened = true,
        ).openDrawer(context);
        return opened;
      },
    );
  } catch (e) {
    AppFailureNotice.show(title: 'error'.tr, message: e.toString());
    return null;
  }
}
