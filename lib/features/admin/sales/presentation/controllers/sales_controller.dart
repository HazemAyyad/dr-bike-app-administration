import 'package:doctorbike/features/admin/sales/data/models/product_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/profit_sale_model.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/add_instant_sales_usecase.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/get_instant_sales_usecase.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../domain/usecases/add_profit_sale.dart';
import '../../domain/usecases/get_all_products_usecase.dart';
import '../../domain/usecases/get_profit_sales_usecase.dart';
import 'sales_service.dart';

class SalesController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final AddProfitSaleUsecase addProfitSaleUsecase;
  final GetProfitSalesUsecase getProfitSalesUsecase;
  final GetInstantSalesUsecase getInstantSalesUsecase;
  final GetAllProductsUsecase getAllProductsUsecase;
  final AddInstantSalesUsecase addInstantSalesUsecase;
  final SalesService salesService;

  SalesController({
    required this.salesService,
    required this.addProfitSaleUsecase,
    required this.getProfitSalesUsecase,
    required this.getInstantSalesUsecase,
    required this.getAllProductsUsecase,
    required this.addInstantSalesUsecase,
  });

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  final TextEditingController discountController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController totalCostController = TextEditingController();

  // filters
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController employeeNameController = TextEditingController();

  final currentTab = 0.obs;
  List<String> tabs = ['spotSale', 'cashProfit'];

  final targets = <Map<String, dynamic>>[].obs;

  final isLoading = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
  }

  final items = <ItemModel>[ItemModel()].obs;

  void addItem() {
    items.add(ItemModel());
    listKey.currentState?.insertItem(
      items.length - 1,
      duration: const Duration(milliseconds: 300),
    );
  }

  void removeItem(int index) {
    if (items.length > 1) {
      items.removeAt(index);
    }
  }

  // متغير للتحكم في قائمة الإضافة
  final RxBool isAddMenuOpen = false.obs;

  late AnimationController animController;
  late Animation<double> opacityAnimation;
  late Animation<double> sizeAnimation;

  void toggleAddMenu() {
    isAddMenuOpen.value = !isAddMenuOpen.value;
  }

  List<Map<String, String>> addList = [
    {
      'title': 'newInstantSale',
      'icon': AssetsManger.invoiceIcon,
      'route': AppRoutes.NEWINSTANTSALESCREEN
    },
    {
      'title': 'newCashProfit',
      'icon': AssetsManger.moneyIcon,
      'route': AppRoutes.NEWCASHPROFITSCREEN,
    },
    {
      'title': 'receiveMaintenance',
      'icon': AssetsManger.userIcon,
      'route': AppRoutes.NEWMAINTENANCESCREEN,
    },
  ];

  // add profit sale
  Future<void> addProfitSale({required BuildContext context}) async {
    if (formKey.currentState!.validate()) {
      isLoading(true);
      final result = await addProfitSaleUsecase.call(
        notes: noteController.text,
        totalCost: totalCostController.text,
      );
      result.fold(
        (failure) {
          String errorMessages = '';
          bool permissionsAdded = false;
          final errors = failure.data?['errors'] as Map<String, dynamic>?;
          if (errors != null) {
            errors.forEach((key, value) {
              if (key.startsWith('permissions')) {
                if (!permissionsAdded) {
                  errorMessages += "Permissions: ${value.first}\n";
                  permissionsAdded = true;
                }
              } else {
                for (var msg in value) {
                  errorMessages += "- $key: $msg\n";
                }
              }
            });
          } else {
            errorMessages = failure.data?['message'] ?? failure.errMessage;
          }
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: errorMessages,
          );
        },
        (success) {
          noteController.clear();
          totalCostController.clear();
          Get.back();
          Future.delayed(
            Duration(milliseconds: 1500),
            () {
              getProfitSales();
              Get.back();
            },
          );
          Helpers.showCustomDialogSuccess(
            context: context,
            title: 'success'.tr,
            message: success,
          );
        },
      );
    }
    isLoading(false);
  }

  // add instant sale
  Future<void> addInstantSale({required BuildContext context}) async {
    if (formKey.currentState!.validate()) {
      isLoading(true);
      final result = await addInstantSalesUsecase.call(
        productId: items.first.selectedItem.value,
        quantity: items.first.quantityController.text,
        cost: items.first.priceController.text,
        discount: discountController.text,
        totalCost: totalController.text,
        note: noteController.text,
        type: 'normal',
        projectId: '',
        otherProducts: items,
      );
      result.fold(
        (failure) {
          String errorMessages = '';
          bool permissionsAdded = false;
          final errors = failure.data?['errors'] as Map<String, dynamic>?;
          if (errors != null) {
            errors.forEach((key, value) {
              if (key.startsWith('permissions')) {
                if (!permissionsAdded) {
                  errorMessages += "Permissions: ${value.first}\n";
                  permissionsAdded = true;
                }
              } else {
                for (var msg in value) {
                  errorMessages += "- $key: $msg\n";
                }
              }
            });
          } else {
            errorMessages = failure.data?['message'] ?? failure.errMessage;
          }
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: errorMessages,
          );
        },
        (success) async {
          noteController.clear();
          totalCostController.clear();
          items.map((e) => e.quantityController.clear());
          items.map((e) => e.priceController.clear());
          items.map((e) => e.selectedItem.value = '');
          discountController.clear();
          totalController.clear();
          Future.delayed(
            Duration(milliseconds: 1500),
            () {
              getInstantSales();
              Get.back();
              Get.back();
            },
          );
          Helpers.showCustomDialogSuccess(
            context: context,
            title: 'success'.tr,
            message: success,
          );
        },
      );
    }
    isLoading(false);
  }

  // get profit sales
  final Map<String, List<ProfitSale>> profitSalesTasks = {};

  void getProfitSales() async {
    isLoading(true);
    profitSalesTasks.clear();
    for (var profitSale in await getProfitSalesUsecase.call()) {
      String dateKey =
          "${profitSale.createdAt.year}-${profitSale.createdAt.month}";
      if (profitSalesTasks.containsKey(dateKey)) {
        if (!profitSalesTasks[dateKey]!.any((a) => a.id == profitSale.id)) {
          profitSalesTasks[dateKey]!.add(profitSale);
        }
      } else {
        profitSalesTasks[dateKey] = [profitSale];
      }
    }
    isLoading(false);
  }

  // get instant sales
  // final Map<String, List<InstantSalesModel>> instantSalesTasks = {};

  void getInstantSales() async {
    isLoading(true);
    final result = await getInstantSalesUsecase.call();
    salesService.instantSalesTasks.assignAll(result);
    isLoading(false);
  }

  // get all products
  final List<ProductModel> products = [];
  void getAllProducts() async {
    final result = await getAllProductsUsecase.call();
    products.assignAll(result);
  }

  @override
  void onInit() {
    super.onInit();
    getProfitSales();
    getInstantSales();
    getAllProducts();
    animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    opacityAnimation = Tween<double>(begin: 0, end: 1).animate(animController);
    sizeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: animController, curve: Curves.fastOutSlowIn),
    );

    ever(isAddMenuOpen, (bool open) {
      if (open) {
        animController.forward();
      } else {
        animController.reverse();
      }
    });
  }

  @override
  void dispose() {
    animController.dispose();
    discountController.dispose();
    totalController.dispose();
    noteController.dispose();
    totalCostController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    employeeNameController.dispose();
    for (var item in items) {
      item.quantityController.dispose();
      item.priceController.dispose();
    }
    super.dispose();
  }
}

class ItemModel {
  RxString selectedItem = ''.obs;
  TextEditingController quantityController = TextEditingController();
  TextEditingController priceController = TextEditingController();
}
