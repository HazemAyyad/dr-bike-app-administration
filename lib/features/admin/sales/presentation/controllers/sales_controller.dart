import 'package:doctorbike/core/databases/api/api_consumer.dart';
import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/features/admin/sales/data/models/product_model.dart';
import 'package:doctorbike/features/admin/sales/data/models/profit_sale_model.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/add_instant_sales_usecase.dart';
import 'package:doctorbike/features/admin/sales/domain/usecases/get_instant_sales_usecase.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/instant_sales_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/ongoing_project_model.dart';
import '../../domain/usecases/add_profit_sale.dart';
import '../../domain/usecases/get_all_products_usecase.dart';
import '../../domain/usecases/get_profit_sales_usecase.dart';
import '../../domain/usecases/invoice_model_usecase.dart';
import 'sales_service.dart';

class SalesController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final AddProfitSaleUsecase addProfitSaleUsecase;
  final GetProfitSalesUsecase getProfitSalesUsecase;
  final GetInstantSalesUsecase getInstantSalesUsecase;
  final GetAllProductsUsecase getAllProductsUsecase;
  final AddInstantSalesUsecase addInstantSalesUsecase;
  final InvoiceModelUsecase invoiceModelUsecase;
  final SalesService salesService;

  SalesController({
    required this.salesService,
    required this.addProfitSaleUsecase,
    required this.getProfitSalesUsecase,
    required this.getInstantSalesUsecase,
    required this.getAllProductsUsecase,
    required this.addInstantSalesUsecase,
    required this.invoiceModelUsecase,
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

  final currentTab = 0.obs;
  List<String> tabs = ['spotSale', 'cashProfit'];

  final targets = <Map<String, dynamic>>[].obs;

  final isLoading = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
  }

  final items = <ItemModel>[ItemModel()].obs;

  void addItem() {
    ItemModel newItem = ItemModel();
    newItem.total.listen((_) => calculateGrandTotal());
    items.add(newItem);
    listKey.currentState?.insertItem(
      items.length - 1,
      duration: const Duration(milliseconds: 300),
    );
  }

  void removeItem(int index) {
    if (items.length > 1) {
      items.removeAt(index);
    }
    calculateGrandTotal();
  }

  final RxInt totalCost = 0.obs;
  void calculateGrandTotal() {
    int total = 0;
    for (ItemModel item in items) {
      (total += item.total.value);
    }
    final discount = int.tryParse(discountController.text.trim()) ?? 0;

    totalCost.value = total - discount;
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
      'icon': AssetsManager.invoiceIcon,
      'route': AppRoutes.NEWINSTANTSALESCREEN
    },
    {
      'title': 'newCashProfit',
      'icon': AssetsManager.moneyIcon,
      'route': AppRoutes.NEWCASHPROFITSCREEN,
    },
  ];

  // add profit sale
  Future<bool> addProfitSale(BuildContext context) async {
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
          return false;
        },
        (success) {
          noteController.clear();
          totalCostController.clear();
          Get.back();
          Future.delayed(
            const Duration(milliseconds: 500),
            () {
              getProfitSales(loding: true);
            },
          );
          Future.delayed(
            const Duration(milliseconds: 1000),
            () {
              Get.back();
            },
          );
          Helpers.showCustomDialogSuccess(
            context: context,
            title: 'success'.tr,
            message: success,
          );
          return true;
        },
      );
    }
    isLoading(false);
    return false;
  }

  // add instant sale
  Future<void> addInstantSale(BuildContext context) async {
    isLoading(true);
    final result = await addInstantSalesUsecase.call(
      productId: items.first.selectedItem.value,
      quantity: items.first.quantityController.text,
      cost: items.first.priceController.text,
      discount: discountController.text.isEmpty ? '0' : discountController.text,
      totalCost: totalCost.value.toString(),
      note: noteController.text,
      type: items.first.selectedCustomersSellers.value ? 'project' : 'normal',
      projectId: items.first.selectedCustomersSellers.value
          ? items.first.selectedValue.value!
          : '',
      otherProducts: items,
    );
    result.fold(
      (failure) {
        String errorMessages = '';
        bool permissionsAdded = false;
        final errors = failure.data?['errors'] as Map<String, dynamic>?;
        if (errors != null) {
          errors.forEach(
            (key, value) {
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
            },
          );
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
          const Duration(milliseconds: 500),
          () {
            getInstantSales(loding: true);
            getProfitSales(loding: true);
          },
        );
        Future.delayed(
          const Duration(milliseconds: 1000),
          () {
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

    isLoading(false);
  }

  // get profit sales
  void getProfitSales({bool loding = false}) async {
    salesService.filterProfitSalesTasks.isEmpty ? isLoading(true) : null;
    loding ? isLoading(true) : null;
    // salesService.profitSalesTasks.clear();
    for (var profitSale in await getProfitSalesUsecase.call()) {
      String dateKey =
          "${profitSale.createdAt.year}-${profitSale.createdAt.month}-${profitSale.createdAt.day}";
      if (salesService.profitSalesTasks.containsKey(dateKey)) {
        if (!salesService.profitSalesTasks[dateKey]!
            .any((a) => a.id == profitSale.id)) {
          salesService.profitSalesTasks[dateKey]!.add(profitSale);
          salesService.filterProfitSalesTasks.assignAll(
            salesService.profitSalesTasks,
          );
        }
      } else {
        salesService.profitSalesTasks[dateKey] = [profitSale];
        salesService.filterProfitSalesTasks.assignAll(
          salesService.profitSalesTasks,
        );
      }
    }
    loding ? isLoading(false) : null;
  }

  // get instant sales
  void getInstantSales({bool loding = false}) async {
    salesService.filterInstantSalesTasks.isNotEmpty
        ? isLoading(false)
        : isLoading(true);
    loding ? isLoading(true) : null;
    for (var instantSale in await getInstantSalesUsecase.call()) {
      String dateKey =
          "${instantSale.date.year}-${instantSale.date.month}-${instantSale.date.day}";
      if (salesService.instantSalesTasks.containsKey(dateKey)) {
        if (!salesService.instantSalesTasks[dateKey]!
            .any((a) => a.id == instantSale.id)) {
          salesService.instantSalesTasks[dateKey]!.add(instantSale);
          salesService.filterInstantSalesTasks
              .assignAll(salesService.instantSalesTasks);
        }
      } else {
        salesService.instantSalesTasks[dateKey] = [instantSale];
        salesService.filterInstantSalesTasks
            .assignAll(salesService.instantSalesTasks);
      }
    }
    isLoading(false);
  }

  InvoiceModel? invoiceModel;
  // get invoice
  void getInvoice({required String invoiceId}) async {
    if (invoiceModel != null) {
      invoiceId == invoiceModel!.id.toString()
          ? isLoading(false)
          : isLoading(true);
      update();
    } else {
      isLoading(true);
      update();
    }
    final invoice = await invoiceModelUsecase.call(invoiceId: invoiceId);
    invoiceModel = invoice;
    isLoading(false);
    update();
  }

  // بيانات العرض بعد الفلترة
  void filterLists(bool isFilter) {
    isLoading(true);
    final from = DateTime.tryParse(fromDateController.text);
    final to = DateTime.tryParse(toDateController.text);

    if (from == null && to == null) {
      salesService.filterProfitSalesTasks.assignAll(
        salesService.profitSalesTasks,
      );
      salesService.filterInstantSalesTasks
          .assignAll(salesService.instantSalesTasks);
      isFilter ? Get.back() : null;
      isLoading(false);
      return;
    }

    final Map<String, List<ProfitSale>> newMap = Map.fromEntries(
      salesService.profitSalesTasks.entries.map((entry) {
        final list = entry.value.where((task) {
          final start = task.createdAt;
          final end = task.updatedAt;
          // لو فيه from فقط
          if (from != null && to == null) {
            return start.isAtSameMomentAs(from) || start.isAfter(from);
          }
          // لو فيه to فقط
          if (to != null && from == null) {
            return end.isAtSameMomentAs(to) || end.isBefore(to);
          }
          // لو الاتنين موجودين
          if (from != null && to != null) {
            final startsOk =
                start.isAtSameMomentAs(from) || start.isAfter(from);
            final endsOk = end.isAtSameMomentAs(to) || end.isBefore(to);
            return startsOk && endsOk;
          }
          return true;
        }).toList();
        return MapEntry(entry.key, list);
      }).where((e) => e.value.isNotEmpty),
    );

    final Map<String, List<InstantSalesModel>> newMap2 = Map.fromEntries(
      salesService.instantSalesTasks.entries.map((entry) {
        final list = entry.value.where((task) {
          final start = task.date;
          final end = task.date;
          // لو فيه from فقط
          if (from != null && to == null) {
            return start.isAtSameMomentAs(from) || start.isAfter(from);
          }
          // لو فيه to فقط
          if (to != null && from == null) {
            return end.isAtSameMomentAs(to) || end.isBefore(to);
          }
          // لو الاتنين موجودين
          if (from != null && to != null) {
            final startsOk =
                start.isAtSameMomentAs(from) || start.isAfter(from);
            final endsOk = end.isAtSameMomentAs(to) || end.isBefore(to);
            return startsOk && endsOk;
          }
          return true;
        }).toList();
        return MapEntry(entry.key, list);
      }).where((e) => e.value.isNotEmpty),
    );
    isLoading(false);

    salesService.filterProfitSalesTasks.assignAll(newMap);
    salesService.filterInstantSalesTasks.assignAll(newMap2);
    isFilter ? Get.back() : null;
  }

  // get all products
  final List<ProductModel> products = [];
  void getAllProducts() async {
    final result = await getAllProductsUsecase.call();
    products.assignAll(result);
  }

  // get ongoing projects
  final ApiConsumer api = Get.find<DioConsumer>();
  final List<OngoingProject> ongoingProjects = [];

  void getOngoingProjects() async {
    final result = await api.get(EndPoints.ongoingProjects);
    ongoingProjects.clear();
    ongoingProjects.addAll(
      (result.data['ongoing projects'] as List)
          .map((e) => OngoingProject.fromJson(e))
          .toList(),
    );
  }

  @override
  void onInit() {
    super.onInit();
    getInstantSales();
    getProfitSales(loding: false);
    getOngoingProjects();
    getAllProducts();
    animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
    ever(items, (_) => calculateGrandTotal());
  }

  @override
  void onClose() {
    animController.dispose();
    discountController.dispose();
    totalController.dispose();
    noteController.dispose();
    totalCostController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    super.onClose();
  }
}

class ItemModel {
  final RxString selectedItem = ''.obs;
  final RxBool selectedCustomersSellers = false.obs;
  final RxnString selectedValue = RxnString();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  final RxInt total = 0.obs;

  ItemModel() {
    priceController.addListener(_updateTotal);
    quantityController.addListener(_updateTotal);
  }

  void _updateTotal() {
    final price = int.tryParse(priceController.text.trim()) ?? 0;
    final quantity = int.tryParse(quantityController.text.trim()) ?? 0;
    total.value = price * quantity;
  }

  void onClose() {
    priceController.dispose();
    quantityController.dispose();
  }
}
