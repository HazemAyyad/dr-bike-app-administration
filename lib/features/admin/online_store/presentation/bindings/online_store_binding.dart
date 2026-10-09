import 'package:get/get.dart';

import '../../../../../../core/databases/api/dio_consumer.dart';
import '../../data/online_store_datasource.dart';
import '../../data/online_store_repository_impl.dart';
import '../../domain/online_store_repository.dart';
import '../controllers/online_store_accounts_controller.dart';
import '../controllers/online_store_audit_controller.dart';
import '../controllers/online_store_banners_controller.dart';
import '../controllers/online_store_categories_controller.dart';
import '../controllers/online_store_coupons_controller.dart';
import '../controllers/online_store_credit_controller.dart';
import '../controllers/online_store_dashboard_controller.dart';
import '../controllers/online_store_home_sections_controller.dart';
import '../controllers/online_store_listings_controller.dart';
import '../controllers/online_store_media_controller.dart';
import '../controllers/online_store_promotions_controller.dart';
import '../controllers/online_store_popup_campaigns_controller.dart';
import '../controllers/online_store_notification_broadcasts_controller.dart';
import '../controllers/online_store_reports_controller.dart';
import '../controllers/online_store_reviews_controller.dart';
import '../controllers/online_store_settings_controller.dart';

class OnlineStoreBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => OnlineStoreDatasource(api: Get.find<DioConsumer>()),
      fenix: true,
    );
    Get.lazyPut<OnlineStoreRepository>(
      () => OnlineStoreRepositoryImpl(Get.find()),
      fenix: true,
    );
    Get.lazyPut(() => OnlineStoreDashboardController(Get.find()), fenix: true);
    Get.lazyPut(() => OnlineStoreListingsController(Get.find()), fenix: true);
    Get.lazyPut(() => OnlineStoreMediaController(Get.find()), fenix: true);
    Get.lazyPut(() => OnlineStoreCategoriesController(Get.find()), fenix: true);
    Get.lazyPut(() => OnlineStoreHomeSectionsController(Get.find()),
        fenix: true);
    Get.lazyPut(() => OnlineStoreBannersController(Get.find()), fenix: true);
    Get.lazyPut(() => OnlineStorePromotionsController(Get.find()), fenix: true);
    Get.lazyPut(() => OnlineStorePopupCampaignsController(Get.find()),
        fenix: true);
    Get.lazyPut(() => OnlineStoreNotificationBroadcastsController(Get.find()),
        fenix: true);
    Get.lazyPut(() => OnlineStoreCouponsController(Get.find()), fenix: true);
    Get.lazyPut(() => OnlineStoreAccountsController(Get.find()), fenix: true);
    Get.lazyPut(() => OnlineStoreCreditController(Get.find()), fenix: true);
    Get.lazyPut(() => OnlineStoreReviewsController(Get.find()), fenix: true);
    Get.lazyPut(() => OnlineStoreSettingsController(Get.find()), fenix: true);
    Get.lazyPut(() => OnlineStoreAuditController(Get.find()), fenix: true);
    Get.lazyPut(() => OnlineStoreReportsController(Get.find()), fenix: true);
  }
}
