import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../data/models/expenses_models/destruction_model.dart';
import '../../data/models/expenses_models/expense_data_model.dart';
import '../../data/models/expenses_models/expense_detail_model.dart';
import '../../domain/usecases/get_all_dinancial_usecase.dart';
import '../../domain/usecases/expenses_usecases/add_destruction_usecase.dart';
import '../../domain/usecases/expenses_usecases/add_expense_usecase.dart';
import '../../domain/usecases/expenses_usecases/get_expenses_data_usecase.dart';
import '../../domain/usecases/expenses_usecases/get_expense_report_usecase.dart';
import 'finacial_service.dart';

class ExpensesController extends GetxController
    with GetTickerProviderStateMixin {
  final GetAllFinancialUsecase getAllFinancialUsecase;
  final AddDestructionUsecase addDestructionUsecase;
  final AddExpenseUsecase addExpenseUsecase;
  final GetExpensesDataUsecase getExpensesDataUsecase;
  final GetShownBoxUsecase getShownBoxUsecase;
  final GetExpenseReportUsecase getExpenseReportUsecase;

  ExpensesController({
    required this.getAllFinancialUsecase,
    required this.addDestructionUsecase,
    required this.addExpenseUsecase,
    required this.getExpensesDataUsecase,
    required this.getShownBoxUsecase,
    required this.getExpenseReportUsecase,
  });

  final formKey = GlobalKey<FormState>();

  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final RxBool isSearchVisible = false.obs;

  void toggleSearch() {
    isSearchVisible.toggle();
    if (!isSearchVisible.value) {
      searchController.clear();
      searchBar('');
    }
  }

  void closeSearch() {
    isSearchVisible.value = false;
    searchController.clear();
    searchBar('');
  }

  // assets
  final TextEditingController productIdController = TextEditingController();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController piecesCountController = TextEditingController();
  final TextEditingController damageReasonController = TextEditingController();
  List<File> assetsFile = [];
  final RxList<DestructionDraftLine> destructionDraftLines =
      <DestructionDraftLine>[].obs;

  Future<void> addSelectedDestructionProduct() async {
    final id = int.tryParse(productIdController.text);
    if (id == null || productNameController.text.trim().isEmpty) return;
    if (destructionDraftLines.any((line) => line.productId == id)) return;
    final response = await getAllFinancialUsecase.call(
      page: '8',
      filters: {'product_id': id},
    );
    final raw = response is Map ? response['layers'] : null;
    final layers = raw is List
        ? raw
            .whereType<Map>()
            .map((e) =>
                DestructionCostLayer.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <DestructionCostLayer>[];
    destructionDraftLines.add(DestructionDraftLine(
      productId: id,
      productName: productNameController.text.trim(),
      layers: layers,
    ));
    productIdController.clear();
    productNameController.clear();
    update();
  }

  void removeDestructionLine(int index) {
    destructionDraftLines.removeAt(index);
    update();
  }

  // expenses
  final TextEditingController expenseNameController = TextEditingController();
  final TextEditingController expensePriceController = TextEditingController();
  final TextEditingController expenseNoteController = TextEditingController();
  final TextEditingController boxIdController = TextEditingController();
  final TextEditingController expenseDateController = TextEditingController();
  final RxString expenseType = 'general'.obs;
  List<File> invoiceFile = [];
  List<File> expensesFile = [];

  void setInvoiceFiles(List<File> files) {
    invoiceFile = files;
    update();
  }

  void setExpenseMediaFiles(List<File> files) {
    expensesFile = files;
    update();
  }

  void removeInvoiceFileAt(int index) {
    if (index < 0 || index >= invoiceFile.length) return;
    invoiceFile.removeAt(index);
    update();
  }

  void removeExpenseMediaAt(int index) {
    if (index < 0 || index >= expensesFile.length) return;
    expensesFile.removeAt(index);
    update();
  }

  final RxInt currentTab = 0.obs;
  final tabs = ['generalAdministrativeExpenses', 'DestructionProducts'].obs;

  final RxBool isLoading = false.obs;
  final RxString expenseTypeFilter = ''.obs;

  void changeTab(int index) {
    currentTab.value = index;
    update();
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
      'title': 'addExpense',
      'icon': AssetsManager.moneyIcon,
      'route': AppRoutes.ADDEXPENSESCREEN,
    },
    {
      'title': 'DestructionProducts',
      'icon': AssetsManager.invoiceIcon,
      'route': AppRoutes.DESTRUCTIONPRODUCTSSCREEN,
    },
  ];

  // filter assets by date
  final expensesFilter = <String, List<ExpenseModel>>{}.obs;
  final destructionsFilter = <String, List<DestructionModel>>{}.obs;
  Future<void> filterExpensesByDate() async {
    await getAllExpenses(applyFilters: true);
    Get.back();
  }

  void setExpenseTypeFilter(String type) {
    expenseTypeFilter.value = type;
    getAllExpenses(applyFilters: true);
  }

  Future<void> downloadExpenseReport(
    String format, {
    String? expenseTypeOverride,
  }) async {
    try {
      final bytes = await getExpenseReportUsecase.call(
        format: format,
        filters: {
          if (fromController.text.isNotEmpty) 'from': fromController.text,
          if (toController.text.isNotEmpty) 'to': toController.text,
          if ((expenseTypeOverride ?? expenseTypeFilter.value).isNotEmpty)
            'expense_type': expenseTypeOverride ?? expenseTypeFilter.value,
        },
      );
      final root = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download/Doctor Bike/Reports')
          : Directory(
              '${(await getApplicationDocumentsDirectory()).path}/Doctor Bike/Reports',
            );
      if (!await root.exists()) await root.create(recursive: true);
      final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
      final file = File('${root.path}/expenses-$stamp.$format');
      await file.writeAsBytes(bytes, flush: true);
      Get.snackbar('success'.tr, 'تم تنزيل التقرير: ${file.path}');
      await OpenFilex.open(file.path);
    } catch (error) {
      Get.snackbar('error'.tr, error.toString());
    }
  }

  Future<void> resetFilters() async {
    fromController.clear();
    toController.clear();
    expenseTypeFilter.value = '';
    closeSearch();
    await getAllExpenses();
  }

  void filterExpensesLocallyByDate() {
    final from = DateTime.tryParse(fromController.text);
    final to = DateTime.tryParse(toController.text);

    // رجع الداتا الأصلية قبل أي فلترة
    expensesFilter.assignAll(FinacialService().expensesTasks);
    destructionsFilter.assignAll(FinacialService().destructionsTasks);

    final Map<String, List<ExpenseModel>> filtered = {};
    final Map<String, List<DestructionModel>> destructionsFiltered = {};
    expensesFilter.forEach(
      (dateKey, tasks) {
        for (var task in tasks) {
          bool matches = true;
          // لو فيه "من"
          if (from != null) {
            matches = task.createdAt.isAtSameMomentAs(from) ||
                task.createdAt.isAfter(from);
          }
          // لو فيه "إلى"
          if (to != null) {
            matches = matches &&
                (task.createdAt.isAtSameMomentAs(to) ||
                    task.createdAt.isBefore(to));
          }
          if (matches) {
            filtered.putIfAbsent(dateKey, () => []);
            filtered[dateKey]!.add(task);
          }
        }
      },
    );
    destructionsFilter.forEach(
      (dateKey, tasks) {
        for (var task in tasks) {
          bool matches = true;
          // لو فيه "من"
          if (from != null) {
            matches = task.createdAt.isAtSameMomentAs(from) ||
                task.createdAt.isAfter(from);
          }
          // لو فيه "إلى"
          if (to != null) {
            matches = matches &&
                (task.createdAt.isAtSameMomentAs(to) ||
                    task.createdAt.isBefore(to));
          }
          if (matches) {
            destructionsFiltered.putIfAbsent(dateKey, () => []);
            destructionsFiltered[dateKey]!.add(task);
          }
        }
      },
    );

    expensesFilter.assignAll(filtered);
    destructionsFilter.assignAll(destructionsFiltered);
    update();
    Get.back();
  }

  // get all assets
  Future<void> getAllExpenses({bool applyFilters = false}) async {
    FinacialService().expensesTasks.isEmpty
        ? isLoading(true)
        : isLoading(false);
    update();
    // expenses
    final expenses = await getAllFinancialUsecase.call(
      page: '2',
      filters: applyFilters
          ? {
              if (fromController.text.isNotEmpty) 'from': fromController.text,
              if (toController.text.isNotEmpty) 'to': toController.text,
              if (expenseTypeFilter.value.isNotEmpty)
                'expense_type': expenseTypeFilter.value,
              'per_page': 100,
            }
          : const {'per_page': 100},
    );
    final expensesJson = expenses['expenses'] as List;
    final expensesList = expensesJson
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();
    FinacialService().expensesTasks.clear();
    FinacialService().expenses.assignAll(expensesList);
    expensesFilter.value = FinacialService().expensesTasks;
    for (var task in FinacialService().expenses) {
      String dayName =
          DateFormat.EEEE(Get.locale!.languageCode).format(task.createdAt);
      String dateKey =
          "$dayName ${task.createdAt.year}-${task.createdAt.month}-${task.createdAt.day}";

      if (FinacialService().expensesTasks.containsKey(dateKey)) {
        if (!FinacialService()
            .expensesTasks[dateKey]!
            .any((a) => a.id == task.id)) {
          FinacialService().expensesTasks[dateKey]!.add(task);
        }
      } else {
        FinacialService().expensesTasks[dateKey] = [task];
      }
    }

    // destructions
    final destructions = await getAllFinancialUsecase.call(page: '3');
    final destructionsJson = destructions['destructions'] as List;
    final destructionsList = destructionsJson
        .map((e) => DestructionModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    FinacialService().destructionsTasks.clear();
    FinacialService().destructions.assignAll(destructionsList);
    destructionsFilter.value = FinacialService().destructionsTasks;
    for (var task in FinacialService().destructions) {
      String dayName =
          DateFormat.EEEE(Get.locale!.languageCode).format(task.createdAt);
      String dateKey =
          "$dayName ${task.createdAt.year}-${task.createdAt.month}-${task.createdAt.day}";
      if (FinacialService().destructionsTasks.containsKey(dateKey)) {
        if (!FinacialService()
            .destructionsTasks[dateKey]!
            .any((a) => a.destructionId == task.destructionId)) {
          FinacialService().destructionsTasks[dateKey]!.add(task);
        }
      } else {
        FinacialService().destructionsTasks[dateKey] = [task];
      }
    }
    isLoading(false);
    update();
  }

  RxBool isEditing = false.obs;

  /// Details open read-only first; the user explicitly enters edit mode.
  RxBool isExpenseReadOnly = false.obs;
  RxBool isLoadingGet = false.obs;
  final Rxn<ExpenseDetailModel> selectedExpense = Rxn<ExpenseDetailModel>();
  String expenseId = '';
  // get expenses data
  Future<void> getExpensesData({required String expenseId}) async {
    isLoadingGet(true);
    update();
    // expenses
    final expenses = await getExpensesDataUsecase.call(expenseId: expenseId);
    selectedExpense.value = expenses;
    this.expenseId = expenses.id.toString();
    expenseNameController.text = expenses.name;
    expensePriceController.text = expenses.price.toString();
    expenseNoteController.text = expenses.notes ?? '';
    boxIdController.text = expenses.boxId;
    expenseType.value = expenses.expenseType;
    expenseDateController.text =
        DateFormat('yyyy-MM-dd').format(expenses.expenseDate);
    invoiceFile = expenses.invoiceImg.map((e) => File(e)).toList();
    expensesFile = expenses.media.map((e) => File(e)).toList();
    isLoadingGet(false);
    update();
  }

  // add destruction
  void addDestruction(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      if (destructionDraftLines.isEmpty) {
        await addSelectedDestructionProduct();
      }
      if (destructionDraftLines.isEmpty) return;
      isLoading(true);
      final items = destructionDraftLines
          .map((line) => <String, dynamic>{
                'product_id': line.productId,
                'pieces_number': line.quantity.value,
                if (line.selectedLayer.value != null)
                  'cost_layer_id': line.selectedLayer.value!.id,
              })
          .toList();
      final result = await addDestructionUsecase.call(
        productId: '',
        piecesNumber: '',
        destructionReason: damageReasonController.text,
        media: assetsFile,
        items: items,
      );
      if (!context.mounted) return;
      result.fold(
        (failure) {
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: failure.data['message'],
          );
        },
        (success) {
          destructionDraftLines.clear();
          productIdController.clear();
          productNameController.clear();
          piecesCountController.clear();
          damageReasonController.clear();
          assetsFile.clear();
          getAllExpenses();
          currentTab.value = 1;
          isEditing.value = false;
          expenseId = '';
          update();
          Future.delayed(const Duration(milliseconds: 700), () => Get.back());
          Helpers.showCustomDialogSuccess(
            context: context,
            title: 'success'.tr,
            message: success,
          );
        },
      );
      isLoading(false);
      update();
    }
  }

  Future<void> editDestructionDetails(
    BuildContext context, {
    required String destructionId,
    required String reason,
  }) async {
    isLoading(true);
    final result = await addDestructionUsecase.edit(
      destructionId: destructionId,
      destructionReason: reason,
      media: assetsFile,
    );
    if (!context.mounted) return;
    result.fold(
      (failure) => Helpers.showCustomDialogError(
        context: context,
        title: failure.errMessage,
        message: failure.data['message'],
      ),
      (success) {
        assetsFile.clear();
        getAllExpenses();
        Get.back();
        Get.back();
        Helpers.showCustomDialogSuccess(
          context: context,
          title: 'success'.tr,
          message: success,
        );
      },
    );
    isLoading(false);
    update();
  }

  RxBool isAddLoading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  // add expense
  void addExpense(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      final wasEditing = isEditing.value;
      isAddLoading(true);
      uploadProgress.value = 0;
      final result = await addExpenseUsecase.call(
        expenseId: isEditing.value ? expenseId : null,
        name: expenseNameController.text,
        price: expensePriceController.text,
        notes: expenseNoteController.text,
        boxId: boxIdController.text,
        expenseType: expenseType.value,
        expenseDate: expenseDateController.text.isEmpty
            ? DateFormat('yyyy-MM-dd').format(DateTime.now())
            : expenseDateController.text,
        invoiceImage: invoiceFile,
        media: expensesFile,
        onUploadProgress: (progress) => uploadProgress.value = progress,
      );
      result.fold(
        (failure) {
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: failure.data['message'],
          );
        },
        (success) {
          FinacialService().expensesTasks.clear();
          getAllExpenses();
          expenseNameController.clear();
          expensePriceController.clear();
          expenseNoteController.clear();
          boxIdController.clear();
          expenseDateController.clear();
          expenseType.value = 'general';
          invoiceFile.clear();
          expensesFile.clear();
          currentTab.value = 0;
          isEditing.value = false;
          update();
          Future.delayed(
            const Duration(milliseconds: 1500),
            () {
              if (Get.key.currentState?.canPop() ?? false) Get.back();
              if (wasEditing && (Get.key.currentState?.canPop() ?? false)) {
                Get.back();
              }
            },
          );
          Helpers.showCustomDialogSuccess(
            context: context,
            title: 'success'.tr,
            message: success,
          );
        },
      );
      isAddLoading(false);
      uploadProgress.value = 0;
    }
  }

  final RxList<ShownBoxesModel> shownBoxesList = <ShownBoxesModel>[].obs;

  void getShowBoxes() async {
    final boxes = await getShownBoxUsecase.call(screen: 3);
    shownBoxesList.value = boxes;
  }

  void searchBar(String value) {
    final search = value.toLowerCase();

    if (value.isNotEmpty) {
      final filteredExpenses = <String, List<ExpenseModel>>{};
      final filteredDestructions = <String, List<DestructionModel>>{};

      FinacialService().expensesTasks.forEach((key, list) {
        final filteredList = list.where((element) {
          return element.name.toLowerCase().contains(search) ||
              element.price.toLowerCase().contains(search) ||
              element.createdAt.toString().toLowerCase().contains(search);
        }).toList();

        if (filteredList.isNotEmpty) filteredExpenses[key] = filteredList;
      });

      FinacialService().destructionsTasks.forEach((key, list) {
        final filteredList = list.where((element) {
          return element.productName.toLowerCase().contains(search) ||
              element.piecesNumber.toLowerCase().contains(search) ||
              element.destructionReason.toLowerCase().contains(search) ||
              element.destructionValue
                  .toString()
                  .toLowerCase()
                  .contains(search) ||
              element.createdAt.toString().toLowerCase().contains(search);
        }).toList();

        if (filteredList.isNotEmpty) filteredDestructions[key] = filteredList;
      });

      expensesFilter.value = filteredExpenses;
      destructionsFilter.value = filteredDestructions;
    } else {
      expensesFilter.value = FinacialService().expensesTasks;
      destructionsFilter.value = FinacialService().destructionsTasks;
    }

    update();
  }

  @override
  void onInit() {
    expenseDateController.text =
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    getAllExpenses();
    getShowBoxes();
    expensesFilter.assignAll(FinacialService().expensesTasks);
    destructionsFilter.assignAll(FinacialService().destructionsTasks);
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
    super.onInit();
  }

  @override
  void onClose() {
    animController.dispose();
    opacityAnimation.isDismissed;
    sizeAnimation.isDismissed;
    fromController.dispose();
    toController.dispose();
    searchController.dispose();
    productIdController.dispose();
    productNameController.dispose();
    piecesCountController.dispose();
    damageReasonController.dispose();
    expenseNameController.dispose();
    expensePriceController.dispose();
    expenseNoteController.dispose();
    boxIdController.dispose();
    expenseDateController.dispose();
    isEditing.value = false;
    expenseId = '';
    invoiceFile.clear();
    expensesFile.clear();
    assetsFile.clear();
    super.onClose();
  }
}

class DestructionCostLayer {
  const DestructionCostLayer(
      {required this.id,
      required this.unitCost,
      required this.remainingQuantity,
      required this.currency});
  final int id;
  final double unitCost;
  final double remainingQuantity;
  final String currency;
  factory DestructionCostLayer.fromJson(Map<String, dynamic> json) =>
      DestructionCostLayer(
        id: int.tryParse('${json['id']}') ?? 0,
        unitCost: double.tryParse('${json['unit_cost']}') ?? 0,
        remainingQuantity:
            double.tryParse('${json['remaining_quantity']}') ?? 0,
        currency: '${json['currency'] ?? 'شيكل'}',
      );
}

class DestructionDraftLine {
  DestructionDraftLine(
      {required this.productId,
      required this.productName,
      required this.layers}) {
    if (layers.isNotEmpty) selectedLayer.value = layers.first;
  }
  final int productId;
  final String productName;
  final List<DestructionCostLayer> layers;
  final RxInt quantity = 1.obs;
  final Rxn<DestructionCostLayer> selectedLayer = Rxn<DestructionCostLayer>();
}
