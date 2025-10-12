import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../data/models/expenses_models/destruction_model.dart';
import '../../data/models/expenses_models/expense_data_model.dart';
import '../../domain/usecases/get_all_dinancial_usecase.dart';
import '../../domain/usecases/expenses_usecases/add_destruction_usecase.dart';
import '../../domain/usecases/expenses_usecases/add_expense_usecase.dart';
import '../../domain/usecases/expenses_usecases/get_expenses_data_usecase.dart';
import 'finacial_service.dart';

class ExpensesController extends GetxController
    with GetTickerProviderStateMixin {
  final GetAllFinancialUsecase getAllFinancialUsecase;
  final AddDestructionUsecase addDestructionUsecase;
  final AddExpenseUsecase addExpenseUsecase;
  final GetExpensesDataUsecase getExpensesDataUsecase;
  final GetShownBoxUsecase getShownBoxUsecase;

  ExpensesController({
    required this.getAllFinancialUsecase,
    required this.addDestructionUsecase,
    required this.addExpenseUsecase,
    required this.getExpensesDataUsecase,
    required this.getShownBoxUsecase,
  });

  final formKey = GlobalKey<FormState>();

  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  // assets
  final TextEditingController productIdController = TextEditingController();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController piecesCountController = TextEditingController();
  final TextEditingController damageReasonController = TextEditingController();
  List<File> assetsFile = [];

  // expenses
  final TextEditingController expenseNameController = TextEditingController();
  final TextEditingController expensePriceController = TextEditingController();
  final TextEditingController expenseNoteController = TextEditingController();
  final TextEditingController boxIdController = TextEditingController();
  List<File> invoiceFile = [];
  List<File> expensesFile = [];

  final RxInt currentTab = 0.obs;
  final tabs = ['generalAdministrativeExpenses', 'DestructionProducts'].obs;

  final RxBool isLoading = false.obs;

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
  void filterExpensesByDate() {
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
  void getAllExpenses() async {
    FinacialService().expensesTasks.isEmpty
        ? isLoading(true)
        : isLoading(false);
    update();
    // expenses
    final expenses = await getAllFinancialUsecase.call(page: '2');
    final expensesJson = expenses['expenses'] as List;
    final expensesList = expensesJson
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();
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
        .toList();
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
  RxBool isLoadingGet = false.obs;
  String expenseId = '';
  // get expenses data
  void getExpensesData({required String expenseId}) async {
    isLoadingGet(true);
    update();
    // expenses
    final expenses = await getExpensesDataUsecase.call(expenseId: expenseId);
    this.expenseId = expenses.id.toString();
    expenseNameController.text = expenses.name;
    expensePriceController.text = expenses.price.toString();
    expenseNoteController.text = expenses.notes ?? '';
    boxIdController.text = expenses.boxId;
    invoiceFile = expenses.invoiceImg.map((e) => File(e)).toList();
    expensesFile = expenses.media.map((e) => File(e)).toList();
    isLoadingGet(false);
    update();
  }

  // add destruction
  void addDestruction(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      isLoading(true);
      final result = await addDestructionUsecase.call(
        productId: productIdController.text,
        piecesNumber: piecesCountController.text,
        destructionReason: damageReasonController.text,
        media: assetsFile,
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
          productIdController.clear();
          productNameController.clear();
          piecesCountController.clear();
          damageReasonController.clear();
          assetsFile.clear();
          getAllExpenses();
          isEditing.value = false;
          expenseId = '';
          update();
          Future.delayed(
            const Duration(milliseconds: 1500),
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
      update();
    }
  }

  RxBool isAddLoading = false.obs;
  // add expense
  void addExpense(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      isAddLoading(true);
      final result = await addExpenseUsecase.call(
        expenseId: isEditing.value ? expenseId : null,
        name: expenseNameController.text,
        price: expensePriceController.text,
        notes: expenseNoteController.text,
        boxId: boxIdController.text,
        invoiceImage: invoiceFile,
        media: expensesFile,
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
          invoiceFile.clear();
          expensesFile.clear();
          Future.delayed(
            const Duration(milliseconds: 1500),
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
      isAddLoading(false);
    }
  }

  final RxList<ShownBoxesModel> shownBoxesList = <ShownBoxesModel>[].obs;

  void getShowBoxes() async {
    final boxes = await getShownBoxUsecase.call(screen: currentTab.value);
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
    productIdController.dispose();
    productNameController.dispose();
    piecesCountController.dispose();
    damageReasonController.dispose();
    expenseNameController.dispose();
    expensePriceController.dispose();
    expenseNoteController.dispose();
    boxIdController.dispose();
    isEditing.value = false;
    expenseId = '';
    invoiceFile.clear();
    expensesFile.clear();
    assetsFile.clear();
    super.onClose();
  }
}
