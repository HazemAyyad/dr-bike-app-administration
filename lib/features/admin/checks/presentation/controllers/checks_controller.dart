import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/helpers/app_navigation.dart';
import '../../../../../routes/app_routes.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../data/models/check_model.dart';
import '../../data/models/general_incoming_model.dart';
import '../../data/models/general_outgoing_data_model.dart';
import '../../../../../core/services/banks_service.dart';
import '../../domain/usecases/add_checks_usecase.dart';
import '../../domain/usecases/add_incoming_checks_batch_usecase.dart';
import '../../domain/usecases/all_customers_sellers_usecase.dart';
import '../../domain/usecases/cashed_to_person_cancel_usecase.dart';
import '../../domain/usecases/delete_check_usecase.dart';
import '../../domain/usecases/edit_checks_usecase.dart';
import '../../domain/usecases/general_checks_data_usecase.dart';
import '../../domain/usecases/get_checks_usecase.dart';
import '../../domain/usecases/return_check_usercase.dart';
import '../../domain/usecases/chash_to_box_usecase.dart';
import '../../domain/repositories/checks_repository.dart';
import 'checks_serves.dart';

class ChecksController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static const _exchangeFromKey = 'checks_exchange_from_currency';
  static const _exchangeToKey = 'checks_exchange_to_currency';

  final AddChecksUsecase addChecksUsecase;
  final AddIncomingChecksBatchUsecase addIncomingChecksBatchUsecase;
  final GetChecksUsecase getChecksUsecase;
  final GeneralChecksDataUsecase generalChecksDataUsecase;
  final CashedToPersonOrCashedUsecase cashedToPersonCancelUsecase;
  final AllCustomersSellersUsecase allCustomersSellersUsecase;
  // final GeneralOutgoingDataUsecase generalOutgoingDataUsecase;
  final ReturnCheckUsercase returnCheckUsercase;
  final GetShownBoxUsecase getShownBoxUsecase;
  final ChashToBoxUsecase chashToBoxUsecase;
  final EditChecksUsecase editChecksUsecase;
  final DeleteCheckUsecase deleteCheckUsecase;

  ChecksController({
    required this.addChecksUsecase,
    required this.addIncomingChecksBatchUsecase,
    required this.getChecksUsecase,
    required this.generalChecksDataUsecase,
    required this.cashedToPersonCancelUsecase,
    required this.allCustomersSellersUsecase,
    // required this.generalOutgoingDataUsecase,
    required this.returnCheckUsercase,
    required this.getShownBoxUsecase,
    required this.chashToBoxUsecase,
    required this.editChecksUsecase,
    required this.deleteCheckUsecase,
  });

  final GlobalKey formKey = GlobalKey<FormState>();

  final FocusNode checkValueFocus = FocusNode();
  final FocusNode checkNumberFocus = FocusNode();
  final FocusNode bankNameFocus = FocusNode();
  final FocusNode notesFocus = FocusNode();

  final TextEditingController checkValueController = TextEditingController();
  final TextEditingController exchangeAmountController =
      TextEditingController(text: '1');

  final TextEditingController employeeNameController = TextEditingController();

  final TextEditingController notesController = TextEditingController();

  final RxBool amountFilter = false.obs;

  final RxBool dateFilter = false.obs;

  // متغيرات للتقويم
  final selectedDay = DateTime.now().obs;
  final isCalendarVisible = false.obs;
  final receivedDay = DateTime.now().obs;
  final isReceivedCalendarVisible = false.obs;
  // دالة لإظهار/إخفاء التقويم
  void toggleCalendar() {
    isCalendarVisible.value = !isCalendarVisible.value;
  }

  void toggleReceivedCalendar() {
    isReceivedCalendarVisible.value = !isReceivedCalendarVisible.value;
  }

  // العملات
  final TextEditingController currencyController = TextEditingController();
  List<String> currency = [
    'currency',
    'currency1',
    'currency2',
  ].obs;

  final List<ExchangeCurrency> exchangeCurrencies = const [
    ExchangeCurrency(code: 'ILS', translationKey: 'currency', symbol: '₪'),
    ExchangeCurrency(code: 'USD', translationKey: 'currency1', symbol: r'$'),
    ExchangeCurrency(code: 'JOD', translationKey: 'currency2', symbol: 'JD'),
  ];

  final exchangeFromCurrency = 'ILS'.obs;
  final exchangeToCurrency = 'USD'.obs;
  final exchangeRate = 0.0.obs;
  final convertedExchangeAmount = 0.0.obs;
  final exchangeRateDate = ''.obs;
  final exchangeError = ''.obs;
  final isExchangeLoading = false.obs;
  Timer? _exchangeDebounce;
  final Dio _exchangeDio = Dio(
    BaseOptions(
      baseUrl: 'https://api.frankfurter.dev/v2',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  ExchangeCurrency exchangeCurrencyByCode(String code) {
    return exchangeCurrencies.firstWhere(
      (currency) => currency.code == code,
      orElse: () => exchangeCurrencies.first,
    );
  }

  void loadSavedExchangeCurrencies() {
    final storage = GetStorage();
    final savedFrom = storage.read<String>(_exchangeFromKey);
    final savedTo = storage.read<String>(_exchangeToKey);
    if (savedFrom != null &&
        exchangeCurrencies.any((currency) => currency.code == savedFrom)) {
      exchangeFromCurrency.value = savedFrom;
    }
    if (savedTo != null &&
        exchangeCurrencies.any((currency) => currency.code == savedTo)) {
      exchangeToCurrency.value = savedTo;
    }
    if (exchangeFromCurrency.value == exchangeToCurrency.value) {
      exchangeToCurrency.value =
          exchangeFromCurrency.value == 'USD' ? 'ILS' : 'USD';
    }
  }

  void _saveExchangeCurrencies() {
    final storage = GetStorage();
    storage.write(_exchangeFromKey, exchangeFromCurrency.value);
    storage.write(_exchangeToKey, exchangeToCurrency.value);
  }

  void onExchangeAmountChanged(String value) {
    _calculateExchange();
  }

  void changeExchangeFrom(String? code) {
    if (code == null || code == exchangeFromCurrency.value) return;
    exchangeFromCurrency.value = code;
    if (exchangeFromCurrency.value == exchangeToCurrency.value) {
      exchangeToCurrency.value =
          exchangeCurrencies.firstWhere((item) => item.code != code).code;
    }
    _saveExchangeCurrencies();
    fetchExchangeRate();
  }

  void changeExchangeTo(String? code) {
    if (code == null || code == exchangeToCurrency.value) return;
    exchangeToCurrency.value = code;
    if (exchangeFromCurrency.value == exchangeToCurrency.value) {
      exchangeFromCurrency.value =
          exchangeCurrencies.firstWhere((item) => item.code != code).code;
    }
    _saveExchangeCurrencies();
    fetchExchangeRate();
  }

  void swapExchangeCurrencies() {
    final previousFrom = exchangeFromCurrency.value;
    exchangeFromCurrency.value = exchangeToCurrency.value;
    exchangeToCurrency.value = previousFrom;
    _saveExchangeCurrencies();
    fetchExchangeRate();
  }

  void _calculateExchange() {
    final amount = double.tryParse(exchangeAmountController.text.trim()) ?? 0.0;
    convertedExchangeAmount.value = amount * exchangeRate.value;
  }

  Future<void> fetchExchangeRate() async {
    _exchangeDebounce?.cancel();
    _exchangeDebounce = Timer(const Duration(milliseconds: 250), () async {
      final from = exchangeFromCurrency.value;
      final to = exchangeToCurrency.value;

      if (from == to) {
        exchangeRate.value = 1;
        exchangeRateDate.value = '';
        exchangeError.value = '';
        _calculateExchange();
        return;
      }

      isExchangeLoading.value = true;
      exchangeError.value = '';

      try {
        final response = await _exchangeDio.get<Map<String, dynamic>>(
          '/rate/$from/$to',
        );
        final data = response.data ?? {};
        final rawRate = data['rate'];
        final rate = rawRate is num
            ? rawRate.toDouble()
            : double.tryParse(rawRate?.toString() ?? '');

        if (rate == null || rate <= 0) {
          throw const FormatException('Invalid exchange rate');
        }

        exchangeRate.value = rate;
        exchangeRateDate.value = data['date']?.toString() ?? '';
        _calculateExchange();
      } catch (_) {
        exchangeError.value = 'exchangeRateFailed'.tr;
      } finally {
        isExchangeLoading.value = false;
      }
    });
  }

  String formatExchangeNumber(double value) {
    if (value == 0) return '0';
    return value.toStringAsFixed(value.abs() >= 100 ? 2 : 4);
  }

  final TextEditingController checkNumberController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController incomingBatchCountController =
      TextEditingController(text: '1');
  // صورة الشيك من الامام
  final Rx<XFile?> checkFrontImage = Rx<XFile?>(null);
  // List<File> checkFrontImage = [];
  // صورة الشيك من الخلف
  final Rx<XFile?> checkBackImage = Rx<XFile?>(null);
  // List<File> checkBackImage = [];
  final RxList<IncomingCheckDraft> incomingBatchRows =
      <IncomingCheckDraft>[].obs;

  DateTime _addMonths(DateTime date, int months) {
    return DateTime(date.year, date.month + months, date.day);
  }

  /// يولّد رقم شيك متسلسلاً من الرقم الأساسي (مثلاً 1001 → 1002، 1003…).
  String sequentialCheckNumber(String base, int index) {
    final trimmed = base.trim();
    if (trimmed.isEmpty) return '';
    if (index == 0) return trimmed;
    final match = RegExp(r'^(.*?)(\d+)$').firstMatch(trimmed);
    if (match != null) {
      final prefix = match.group(1)!;
      final digits = match.group(2)!;
      final next = int.parse(digits) + index;
      return '$prefix${next.toString().padLeft(digits.length, '0')}';
    }
    return '$trimmed-${index + 1}';
  }

  void generateIncomingBatchRows() {
    final count = int.tryParse(incomingBatchCountController.text.trim()) ?? 0;
    if (count < 1) {
      Get.snackbar('error'.tr, 'incomingBatchCountRequired'.tr);
      return;
    }

    for (final row in incomingBatchRows) {
      row.dispose();
    }

    final defaultCurrency = currencyController.text.isEmpty
        ? 'currency'.tr
        : currencyController.text.tr;
    incomingBatchRows.assignAll(
      List.generate(
        count,
        (index) => IncomingCheckDraft(
          total: checkValueController.text,
          dueDate: _addMonths(selectedDay.value, index),
          currency: defaultCurrency,
          checkId: sequentialCheckNumber(checkNumberController.text, index),
          bankName: bankNameController.text,
          notes: notesController.text,
        ),
      ),
    );
    update();
  }

  final currentTab = 0.obs;
  final tabs = ['didNotActOnIt', 'actedOnIt', 'archive'].obs;

  final isLoading = false.obs;
  final isBulkSelectionMode = false.obs;
  final RxSet<int> selectedBulkCheckIds = <int>{}.obs;

  void changeTab(int index) {
    currentTab.value = index;
    clearBulkSelection();
    // generalData();
    update();
  }

  void startBulkSelection() {
    isBulkSelectionMode.value = true;
    update();
  }

  void clearBulkSelection() {
    selectedBulkCheckIds.clear();
    isBulkSelectionMode.value = false;
    update();
  }

  void toggleBulkCheck(CheckModel check) {
    if (selectedBulkCheckIds.contains(check.id)) {
      selectedBulkCheckIds.remove(check.id);
    } else {
      selectedBulkCheckIds.add(check.id);
    }
    isBulkSelectionMode.value = selectedBulkCheckIds.isNotEmpty;
    update();
  }

  List<CheckModel> get selectedBulkChecks => activeFilteredChecks
      .where((check) => selectedBulkCheckIds.contains(check.id))
      .toList(growable: false);

  double selectedBulkTotalForCurrency(String currency) {
    return selectedBulkChecks
        .where((check) => check.currency == currency)
        .fold<double>(
          0,
          (sum, check) => sum + (double.tryParse(check.total) ?? 0),
        );
  }

  int _countChecksInMap(Map<String, List<CheckModel>> source) {
    var n = 0;
    for (final list in source.values) {
      n += list.length;
    }
    return n;
  }

  final notActedTabCount = 0.obs;
  final actedTabCount = 0.obs;
  final archiveTabCount = 0.obs;

  int get notActedCount => notActedTabCount.value;
  int get actedCount => actedTabCount.value;
  int get archiveCount => archiveTabCount.value;

  void _syncTabCounts() {
    notActedTabCount.value = _countChecksInMap(filteredInComingTasks);
    actedTabCount.value = _countChecksInMap(filteredCashedToPersonTasks);
    archiveTabCount.value = _countChecksInMap(filteredArchiveTasks);
  }

  Map<String, List<CheckModel>> get _activeFilteredMap {
    if (currentTab.value == 0) return filteredInComingTasks;
    if (currentTab.value == 1) return filteredCashedToPersonTasks;
    return filteredArchiveTasks;
  }

  List<CheckModel> get activeFilteredChecks =>
      _activeFilteredMap.values.expand((e) => e).toList(growable: false);

  double _sumCurrency(String currencyKey) {
    double sum = 0.0;
    for (final c in activeFilteredChecks) {
      final cur = c.currency.trim().toLowerCase();
      final matches = currencyKey == 'shekel'
          ? (cur.contains('شيكل') ||
              cur.contains('shekel') ||
              cur.contains('ils') ||
              cur.contains('nis') ||
              cur.contains('₪'))
          : currencyKey == 'dollar'
              ? (cur.contains('دولار') ||
                  cur.contains('dollar') ||
                  cur.contains('usd') ||
                  cur.contains(r'$'))
              : (cur.contains('دينار') ||
                  cur.contains('dinar') ||
                  cur.contains('jd'));
      if (!matches) continue;
      sum += double.tryParse(c.total.toString()) ?? 0.0;
    }
    return sum;
  }

  String get activeFilteredCount => activeFilteredChecks.length.toString();
  String get activeFilteredTotalShekel => _sumCurrency('shekel').toString();
  String get activeFilteredTotalDollar => _sumCurrency('dollar').toString();
  String get activeFilteredTotalDinar => _sumCurrency('dinar').toString();

  RxBool selectedCustomersSellers = false.obs;

  bool isInComing = false;

  // الشيكات الصادرة
  RxList<String> outgoingChecksDidNotActOnIt = <String>[
    'endorseTheCheck',
    'returnedCheck',
    'voidTheCheck',
    'deleteCheck'
  ].obs;

  RxList<String> outgoingChecksActedOnIt = <String>[
    'cashTheCheck',
    'returnedCheck',
    'voidTheCheck',
  ].obs;

  // الشيكات الواردة
  RxList<String> incomingChecksDidNotActOnIt = <String>[
    'endorseTheCheck',
    'cashTheCheck',
    'returnedCheck',
    'deleteCheck',
    'voidTheCheck'
  ].obs;

  RxList<String> incomingChecksActedOnIt =
      <String>['cashTheCheck', 'returnedCheck'].obs;

  RxList<String> archive = ['deleteCheck'].obs;

  // add checks
  void addChecks({
    required BuildContext context,
    required bool isInComing,
    String? customerId,
    String? sellerId,
  }) async {
    if ((formKey.currentState as FormState).validate()) {
      isLoading(true);
      if (!Get.isRegistered<BanksService>()) {
        Get.put(BanksService());
      }
      await Get.find<BanksService>()
          .findOrCreateByName(bankNameController.text);
      final result = await addChecksUsecase.call(
        isInComing: isInComing,
        customerId: customerId,
        sellerId: sellerId,
        total: checkValueController.text,
        dueDate: selectedDay.value,
        currency: currencyController.text.tr,
        checkId: checkNumberController.text,
        bankName: bankNameController.text,
        frontImage: checkFrontImage.value,
        backImage: checkBackImage.value,
        notes: notesController.text,
      );
      result.fold(
        (failure) {
          isLoading(false);
          update();

          final errors = failure.data['errors'];
          String errorMessage = '';
          if (errors is Map) {
            errorMessage = errors.entries
                .map((e) => "${e.key}: ${(e.value as List).join(', ')}")
                .join("\n");
          } else {
            errorMessage = errors.toString();
          }
          Helpers.showCustomDialogError(
            context: context,
            title: errorMessage,
            message: failure.errMessage,
          );
        },
        (success) {
          getGeneralChecksData();
          // generalData();
          getCashedToPerson();
          getNotCashed();
          getArchive();

          resetCheckFormFields();
          _popToChecksListScreen();
          Helpers.showCustomDialogSuccess(
            context: context,
            title: 'success'.tr,
            message: success,
          );
        },
      );
    }
    isLoading(false);
    update();
  }

  void resetCheckFormFields() {
    checkValueController.clear();
    currencyController.clear();
    checkNumberController.clear();
    bankNameController.clear();
    notesController.clear();
    checkFrontImage.value = null;
    checkBackImage.value = null;
    selectedDay.value = DateTime.now();
    isCalendarVisible.value = false;
  }

  void _popToChecksListScreen() {
    Future.delayed(
      const Duration(milliseconds: 650),
      () => AppNavigation.popToRoute(
        isInComing
            ? AppRoutes.INCOMINGCHECKSSCREEN
            : AppRoutes.OUTGOINGCHECKSSCREEN,
      ),
    );
  }

  void addIncomingChecksBatch({
    required BuildContext context,
    String? customerId,
    String? sellerId,
  }) async {
    if (!(formKey.currentState as FormState).validate()) return;
    if (incomingBatchRows.isEmpty) {
      generateIncomingBatchRows();
      if (incomingBatchRows.isEmpty) return;
    }

    isLoading(true);
    if (!Get.isRegistered<BanksService>()) {
      Get.put(BanksService());
    }

    for (final row in incomingBatchRows) {
      await Get.find<BanksService>().findOrCreateByName(row.bankName.text);
    }

    final items = incomingBatchRows
        .map(
          (row) => IncomingCheckBatchItem(
            total: row.total.text,
            dueDate: row.dueDate.value,
            currency: row.currency.value,
            checkId: row.checkId.text,
            bankName: row.bankName.text,
            notes: row.notes.text,
            frontImage: row.frontImage.value,
            backImage: row.backImage.value,
          ),
        )
        .toList();

    final result = await addIncomingChecksBatchUsecase.call(
      customerId: customerId,
      sellerId: sellerId,
      receivedAt: receivedDay.value,
      checks: items,
    );

    result.fold(
      (failure) {
        final errors = failure.data['errors'];
        final errorMessage = errors is Map
            ? errors.entries
                .map((e) => "${e.key}: ${(e.value as List).join(', ')}")
                .join("\n")
            : errors.toString();
        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: errorMessage,
        );
      },
      (success) {
        getGeneralChecksData();
        getCashedToPerson();
        getNotCashed();
        getArchive();
        resetCheckForm();
        _popToChecksListScreen();
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

  void resetCheckForm() {
    checkValueController.clear();
    currencyController.clear();
    checkNumberController.clear();
    bankNameController.clear();
    notesController.clear();
    incomingBatchCountController.text = '1';
    checkFrontImage.value = null;
    checkBackImage.value = null;
    selectedDay.value = DateTime.now();
    receivedDay.value = DateTime.now();
    isCalendarVisible.value = false;
    isReceivedCalendarVisible.value = false;
    for (final row in incomingBatchRows) {
      row.dispose();
    }
    incomingBatchRows.clear();
    editBeneficiaryName = '';
    editBeneficiaryIsCustomer = true;
  }

  final RxnString selectedValue = RxnString();
  RxBool isEdit = false.obs;
  final Rx<XFile?> editCheckFrontImage = Rx<XFile?>(null);
  final Rx<XFile?> editCheckBackImage = Rx<XFile?>(null);

  String? checkId;
  String editBeneficiaryName = '';
  bool editBeneficiaryIsCustomer = true;

  void _setEditBeneficiaryFromCheck(CheckModel check) {
    editBeneficiaryName = '';
    editBeneficiaryIsCustomer = true;
    selectedValue.value = null;

    if (check.customer != null) {
      selectedValue.value = check.customer!.id.toString();
      selectedCustomersSellers.value = true;
      editBeneficiaryIsCustomer = true;
      editBeneficiaryName = check.customer!.name;
      return;
    }
    if (check.seller != null) {
      selectedValue.value = check.seller!.id.toString();
      selectedCustomersSellers.value = false;
      editBeneficiaryIsCustomer = false;
      editBeneficiaryName = check.seller!.name;
      return;
    }
    if (check.fromCustomer != null) {
      selectedValue.value = check.fromCustomer!.id.toString();
      selectedCustomersSellers.value = true;
      editBeneficiaryIsCustomer = true;
      editBeneficiaryName = check.fromCustomer!.name;
      return;
    }
    if (check.fromSeller != null) {
      selectedValue.value = check.fromSeller!.id.toString();
      selectedCustomersSellers.value = false;
      editBeneficiaryIsCustomer = false;
      editBeneficiaryName = check.fromSeller!.name;
      return;
    }
    if (check.toCustomer != null) {
      selectedValue.value = check.toCustomer!.id.toString();
      selectedCustomersSellers.value = true;
      editBeneficiaryIsCustomer = true;
      editBeneficiaryName = check.toCustomer!.name;
      return;
    }
    if (check.toSeller != null) {
      selectedValue.value = check.toSeller!.id.toString();
      selectedCustomersSellers.value = false;
      editBeneficiaryIsCustomer = false;
      editBeneficiaryName = check.toSeller!.name;
    }
  }

  void getCeckData({CheckModel? check, required bool isOutgoing}) {
    isInComing = !isOutgoing;
    if (isEdit.value) {
      checkId = check!.id.toString();
      checkValueController.text = check.total.toString();
      final currencyMatches =
          currency.where((element) => element.tr == check.currency);
      currencyController.text = currencyMatches.isEmpty
          ? check.currency
          : currencyMatches.first;
      checkNumberController.text = check.checkId;
      bankNameController.text = check.bankName;
      editCheckFrontImage.value =
          check.frontImage != null ? XFile(check.frontImage!) : null;
      editCheckBackImage.value =
          check.backImage != null ? XFile(check.backImage!) : null;
      selectedDay.value = check.dueDate;
      isCalendarVisible.value = false;
      _setEditBeneficiaryFromCheck(check);
      notesController.text = check.notes ?? '';
      receivedDay.value = check.createdAt;
      for (final row in incomingBatchRows) {
        row.dispose();
      }
      incomingBatchRows.clear();
      Get.toNamed(
        AppRoutes.NEWCHECKSCREEN,
        arguments: {'isNewCheck': isOutgoing, 'isEdit': true},
      );
    } else {
      Get.toNamed(
        AppRoutes.NEWCHECKSCREEN,
        arguments: {'isNewCheck': isOutgoing},
      );
      selectedValue.value = null;
      // false = تاجر (seller) هو الافتراضي
      selectedCustomersSellers.value = false;
      checkId = null;
      editBeneficiaryName = '';
      editBeneficiaryIsCustomer = true;
      checkValueController.clear();
      currencyController.clear();
      checkNumberController.clear();
      bankNameController.clear();
      notesController.clear();
      incomingBatchCountController.text = '1';
      editCheckFrontImage.value = null;
      editCheckBackImage.value = null;
      selectedDay.value = DateTime.now();
      receivedDay.value = DateTime.now();
      isCalendarVisible.value = false;
      isReceivedCalendarVisible.value = false;
      for (final row in incomingBatchRows) {
        row.dispose();
      }
      incomingBatchRows.clear();
    }
    update();
  }

  // edit checks
  void editChecks({
    required BuildContext context,
    required bool isInComing,
    required String checkId,
  }) async {
    if ((formKey.currentState as FormState).validate()) {
      isLoading(true);
      final result = await editChecksUsecase.call(
        isInComing: isInComing,
        outgoingCheckId: checkId,
        dueDate: selectedDay.value,
        checkId: checkNumberController.text,
        bankName: bankNameController.text,
        total: isInComing ? null : checkValueController.text,
        currency: isInComing ? null : currencyController.text.tr,
        frontImage: checkFrontImage.value != null
            ? XFile(checkFrontImage.value!.path)
            : editCheckFrontImage.value != null
                ? XFile(editCheckFrontImage.value!.path)
                : null,
        backImage: checkBackImage.value != null
            ? XFile(checkBackImage.value!.path)
            : editCheckBackImage.value != null
                ? XFile(editCheckBackImage.value!.path)
                : null,
        notes: notesController.text,
      );
      result.fold(
        (failure) {
          isLoading(false);
          update();

          final errors = failure.data['errors'];
          String errorMessage = '';
          if (errors is Map) {
            errorMessage = errors.entries
                .map((e) => "${e.key}: ${(e.value as List).join(', ')}")
                .join("\n");
          } else {
            errorMessage = errors.toString();
          }
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: errorMessage,
          );
        },
        (success) {
          getGeneralChecksData();
          // generalData();
          getCashedToPerson();
          getNotCashed();
          getArchive();

          resetCheckFormFields();
          _popToChecksListScreen();
          Helpers.showCustomDialogSuccess(
            context: context,
            title: 'success'.tr,
            message: success,
          );
        },
      );
    }
    isLoading(false);
    update();
  }

  // cash to person or cancel
  void cashedToPersonOrCashed({
    required String checkId,
    String? customerId,
    String? sellerId,
  }) async {
    isLoading(true);
    final result = await cashedToPersonCancelUsecase.call(
      isInComing: isInComing,
      checkId: checkId,
      customerId: customerId,
      sellerId: sellerId,
    );
    result.fold(
      (failure) {
        isLoading(false);
        update();
        Get.snackbar(
          'error'.tr,
          failure.errMessage,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
      (success) async {
        Get.back();
        await Future.wait([
          getGeneralChecksData(),
          // generalData(),
          getCashedToPerson(),
          getNotCashed(),
          getArchive(),
        ]);
        // Future.delayed(
        //   const Duration(milliseconds: 1500),
        //   () {
        //     Get.back();
        //   },
        // );
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
    );
    isLoading(false);
    update();
  }

  Future<void> bulkCashedToPersonOrCashed({
    String? customerId,
    String? sellerId,
  }) async {
    final ids = selectedBulkCheckIds.map((e) => e.toString()).toList();
    if (ids.isEmpty) return;
    isLoading(true);
    String? failureMessage;
    String? successMessage;
    var processed = 0;
    for (final id in ids) {
      final result = await cashedToPersonCancelUsecase.call(
        isInComing: isInComing,
        checkId: id,
        customerId: customerId,
        sellerId: sellerId,
      );
      result.fold(
        (failure) => failureMessage = failure.errMessage,
        (success) {
          successMessage = success;
          processed++;
        },
      );
      if (failureMessage != null) break;
    }
    Get.back();
    clearBulkSelection();
    await Future.wait([
      getGeneralChecksData(),
      getCashedToPerson(isStopLoding: false),
      getNotCashed(isStopLoding: false),
      getArchive(isStopLoding: false),
    ]);
    isLoading(false);
    Get.snackbar(
      failureMessage == null ? 'success'.tr : 'error'.tr,
      failureMessage ?? successMessage ?? '${'selectedChecks'.tr}: $processed',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(milliseconds: 1500),
    );
    update();
  }

  // return check
  void returnCheck({required String checkId, required bool isCancel}) async {
    isLoading(true);
    final result = await returnCheckUsercase.call(
      checkId: checkId,
      isInComing: isInComing,
      isCancel: isCancel,
    );
    result.fold(
      (failure) async {
        isLoading(false);
        update();

        await Future.wait([
          getGeneralChecksData(),
          // generalData(),
          getCashedToPerson(),
          getNotCashed(),
          getArchive(),
        ]);
        Future.delayed(
          const Duration(milliseconds: 1500),
          () {
            Get.back();
          },
        );
      },
      (success) async {
        Get.back();
        await Future.wait([
          getGeneralChecksData(),
          // generalData(),
          getCashedToPerson(),
          getNotCashed(),
          getArchive(),
        ]);
        // Future.delayed(
        //   const Duration(milliseconds: 1500),
        //   () {
        //     Get.back();
        //   },
        // );
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
    );
    isLoading(false);
    update();
  }

  Future<void> bulkReturnCheck({required bool isCancel}) async {
    final ids = selectedBulkCheckIds.map((e) => e.toString()).toList();
    if (ids.isEmpty) return;
    isLoading(true);
    String? failureMessage;
    String? successMessage;
    var processed = 0;
    for (final id in ids) {
      final result = await returnCheckUsercase.call(
        checkId: id,
        isInComing: isInComing,
        isCancel: isCancel,
      );
      result.fold(
        (failure) => failureMessage = failure.errMessage,
        (success) {
          successMessage = success;
          processed++;
        },
      );
      if (failureMessage != null) break;
    }
    Get.back();
    clearBulkSelection();
    await Future.wait([
      getGeneralChecksData(),
      getCashedToPerson(isStopLoding: false),
      getNotCashed(isStopLoding: false),
      getArchive(isStopLoding: false),
    ]);
    isLoading(false);
    Get.snackbar(
      failureMessage == null ? 'success'.tr : 'error'.tr,
      failureMessage ?? successMessage ?? '${'selectedChecks'.tr}: $processed',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(milliseconds: 1500),
    );
    update();
  }

  // cash to box
  void chashToBox({required String checkId, required String boxId}) async {
    isLoading(true);
    final result = await chashToBoxUsecase.chashToBox(
      checkId: checkId,
      boxId: boxId,
      isInComing: isInComing,
    );
    result.fold(
      (failure) {
        isLoading(false);
        update();

        Get.snackbar(
          'error'.tr,
          failure.errMessage,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
      (success) async {
        Get.back();
        await Future.wait([
          getGeneralChecksData(),
          // generalData(),
          getCashedToPerson(),
          getNotCashed(),
          getArchive(),
        ]);
        // Future.delayed(
        //   const Duration(milliseconds: 1500),
        //   () {
        //     Get.back();
        //   },
        // );
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
    );

    isLoading(false);
    update();
  }

  Future<void> bulkChashToBox({required String boxId}) async {
    final ids = selectedBulkCheckIds.map((e) => e.toString()).toList();
    if (ids.isEmpty) return;
    isLoading(true);
    String? failureMessage;
    String? successMessage;
    var processed = 0;
    for (final id in ids) {
      final result = await chashToBoxUsecase.chashToBox(
        checkId: id,
        boxId: boxId,
        isInComing: isInComing,
      );
      result.fold(
        (failure) => failureMessage = failure.errMessage,
        (success) {
          successMessage = success;
          processed++;
        },
      );
      if (failureMessage != null) break;
    }
    Get.back();
    clearBulkSelection();
    await Future.wait([
      getGeneralChecksData(),
      getCashedToPerson(isStopLoding: false),
      getNotCashed(isStopLoding: false),
      getArchive(isStopLoding: false),
    ]);
    isLoading(false);
    Get.snackbar(
      failureMessage == null ? 'success'.tr : 'error'.tr,
      failureMessage ?? successMessage ?? '${'selectedChecks'.tr}: $processed',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(milliseconds: 1500),
    );
    update();
  }

  // delete check
  void deleteCheck({required String checkId}) async {
    isLoading(true);
    final result = await deleteCheckUsecase.deleteCheck(
      checkId: checkId,
      isInComing: isInComing,
    );
    result.fold(
      (failure) {
        isLoading(false);
        update();
        Get.snackbar(
          'error'.tr,
          failure.errMessage,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1000),
        );
      },
      (success) async {
        Get.back();
        await Future.wait([
          getArchive(isStopLoding: false),
          // generalData(),
          getCashedToPerson(isStopLoding: false),
          getNotCashed(isStopLoding: false),
          getGeneralChecksData(),
        ]);
        // Future.delayed(
        //   const Duration(milliseconds: 1000),
        //   () {
        //     Get.back();
        //   },
        // );
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1000),
        );
      },
    );
    isLoading(false);
    update();
  }

  Future<void> bulkDeleteCheck() async {
    final ids = selectedBulkCheckIds.map((e) => e.toString()).toList();
    if (ids.isEmpty) return;
    isLoading(true);
    String? failureMessage;
    String? successMessage;
    var processed = 0;
    for (final id in ids) {
      final result = await deleteCheckUsecase.deleteCheck(
        checkId: id,
        isInComing: isInComing,
      );
      result.fold(
        (failure) => failureMessage = failure.errMessage,
        (success) {
          successMessage = success;
          processed++;
        },
      );
      if (failureMessage != null) break;
    }
    Get.back();
    clearBulkSelection();
    await Future.wait([
      getArchive(isStopLoding: false),
      getCashedToPerson(isStopLoding: false),
      getNotCashed(isStopLoding: false),
      getGeneralChecksData(),
    ]);
    isLoading(false);
    Get.snackbar(
      failureMessage == null ? 'success'.tr : 'error'.tr,
      failureMessage ?? successMessage ?? '${'selectedChecks'.tr}: $processed',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(milliseconds: 1500),
    );
    update();
  }

  // get all not cashed outgoing checks
  final Rxn<NotCashedModel> inComingChecksList = Rxn<NotCashedModel>(null);
  final Map<String, List<CheckModel>> inComingTasks = {};
  final Map<String, double> totalInComing = {};

  Future<void> getNotCashed({bool isStopLoding = true}) async {
    if (isStopLoding) isLoading(true);

    filteredInComingTasks.clear();
    inComingTasks.clear();
    totalInComing.clear();

    final result = await getChecksUsecase.call(
      endPoint: isInComing
          ? EndPoints.inComingChecks
          : EndPoints.notCashedOutgoingChecks,
    );

    inComingChecksList.value =
        NotCashedModel.fromJson(result, checksPath: 'not_cashed_checks');

    for (var task in inComingChecksList.value!.inComingChecksList) {
      String dateKey =
          "${task.dueDate.year}/${task.dueDate.month.toString().padLeft(2, '0')}";
      if (inComingTasks.containsKey(dateKey)) {
        if (!inComingTasks[dateKey]!.any((a) => a.id == task.id)) {
          inComingTasks[dateKey]!.add(task);
        }
      } else {
        inComingTasks[dateKey] = [task];
      }
      final total = double.tryParse(task.total.toString()) ?? 0.0;
      totalInComing[dateKey] = (totalInComing[dateKey] ?? 0.0) + total;
    }

    inComingTasks.forEach((key, tasks) {
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    });

    // 📆 رتب الشهور تصاعديًا (الأقدم → الأحدث)
    var entries = inComingTasks.entries.toList();
    entries.sort((e1, e2) {
      final parts1 = e1.key.split('/');
      final parts2 = e2.key.split('/');
      final year1 = int.tryParse(parts1[0]) ?? 0;
      final month1 = int.tryParse(parts1[1]) ?? 0;
      final year2 = int.tryParse(parts2[0]) ?? 0;
      final month2 = int.tryParse(parts2[1]) ?? 0;
      if (year1 != year2) return year1.compareTo(year2);
      return month1.compareTo(month2);
    });

    entries = entries.reversed.toList(); // الأحدث فوق

    final sortedMap = Map<String, List<CheckModel>>.fromEntries(entries);
    inComingTasks
      ..clear()
      ..addAll(sortedMap);
    filteredInComingTasks.assignAll(inComingTasks);
    _syncTabCounts();

    if (isStopLoding) isLoading(false);
    update();
  }

  // get cashed to person checks
  final Rxn<NotCashedModel> cashedToPerson = Rxn<NotCashedModel>(null);
  final Map<String, List<CheckModel>> cashedToPersonTasks = {};
  final Map<String, double> totalCashedToPerson = {};

  Future<void> getCashedToPerson({bool isStopLoding = true}) async {
    if (isStopLoding) isLoading(true);

    filteredCashedToPersonTasks.clear();
    cashedToPersonTasks.clear();
    totalCashedToPerson.clear();

    final result = await getChecksUsecase.call(
      endPoint: isInComing
          ? EndPoints.cashedIncomingChecks
          : EndPoints.cashedOutgoingChecks,
    );

    cashedToPerson.value =
        NotCashedModel.fromJson(result, checksPath: 'cashed_to_person_checks');

    for (var task in cashedToPerson.value!.inComingChecksList) {
      final dateKey =
          "${task.dueDate.year}/${task.dueDate.month.toString().padLeft(2, '0')}";

      cashedToPersonTasks.putIfAbsent(dateKey, () => []);
      if (!cashedToPersonTasks[dateKey]!.any((a) => a.id == task.id)) {
        cashedToPersonTasks[dateKey]!.add(task);
      }

      final total = double.tryParse(task.total.toString()) ?? 0.0;
      totalCashedToPerson[dateKey] =
          (totalCashedToPerson[dateKey] ?? 0.0) + total;
    }

    // ترتيب الشيكات داخل كل شهر
    cashedToPersonTasks.forEach((key, tasks) {
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    });

    // ترتيب الشهور (الأحدث فوق)
    final entries = cashedToPersonTasks.entries.toList()
      ..sort((e1, e2) {
        final y1 = int.parse(e1.key.split('/')[0]);
        final m1 = int.parse(e1.key.split('/')[1]);
        final y2 = int.parse(e2.key.split('/')[0]);
        final m2 = int.parse(e2.key.split('/')[1]);
        return y1 != y2 ? y2.compareTo(y1) : m2.compareTo(m1);
      });

    final sortedMap = Map<String, List<CheckModel>>.fromEntries(entries);

    cashedToPersonTasks
      ..clear()
      ..addAll(sortedMap);

    filteredCashedToPersonTasks.assignAll(cashedToPersonTasks);
    _syncTabCounts();

    if (isStopLoding) isLoading(false);
    update();
  }

  // get cashed to person checks
  final Rxn<NotCashedModel> archiveData = Rxn<NotCashedModel>(null);
  final Map<String, List<CheckModel>> archiveTasks = {};
  final Map<String, double> totalArchive = {};

  Future<void> getArchive({bool isStopLoding = true}) async {
    if (isStopLoding) isLoading(true);

    filteredArchiveTasks.clear();
    archiveTasks.clear();
    totalArchive.clear();
    final result = await getChecksUsecase.call(
      endPoint: isInComing
          ? EndPoints.archivedIncomingChecks
          : EndPoints.archivedOutgoingChecks,
    );
    archiveData.value =
        NotCashedModel.fromJson(result, checksPath: 'archived_checks');

    for (var task in archiveData.value!.inComingChecksList) {
      String dateKey =
          "${task.dueDate.year}/${task.dueDate.month.toString().padLeft(2, '0')}";
      if (archiveTasks.containsKey(dateKey)) {
        if (!archiveTasks[dateKey]!.any((a) => a.id == task.id)) {
          archiveTasks[dateKey]!.add(task);
        }
      } else {
        archiveTasks[dateKey] = [task];
      }
      final total = double.tryParse(task.total.toString()) ?? 0.0;
      totalArchive[dateKey] = (totalArchive[dateKey] ?? 0.0) + total;
    }
    filteredArchiveTasks.assignAll(archiveTasks);
    _syncTabCounts();
    if (isStopLoding) isLoading(false);
    update();
  }

  /// Load all three tabs for current [isInComing] direction (incoming vs outgoing).
  Future<void> loadAllChecksTabs({bool showLoading = true}) async {
    if (showLoading) {
      isLoading(true);
      update();
    }
    try {
      await getNotCashed(isStopLoding: false);
      await getCashedToPerson(isStopLoding: false);
      await getArchive(isStopLoding: false);
      _syncTabCounts();
    } catch (e) {
      debugPrint('[Checks] loadAllChecksTabs failed: $e');
    } finally {
      if (showLoading) {
        isLoading(false);
      }
      update();
    }
  }

  void openOutgoingChecks() {
    isInComing = false;
    currentTab.value = 1;
    loadAllChecksTabs();
    Get.toNamed(AppRoutes.OUTGOINGCHECKSSCREEN);
  }

  void openIncomingChecks() {
    isInComing = true;
    currentTab.value = 0;
    loadAllChecksTabs();
    Get.toNamed(AppRoutes.INCOMINGCHECKSSCREEN);
  }

  // get general checks data
  // final Rxn<GeneralChecksDataModel> generalChecksData =
  //     Rxn<GeneralChecksDataModel>(null);

  Future<void> getGeneralChecksData() async {
    try {
      final result = await generalChecksDataUsecase.call();
      ChecksServes().generalChecksData.value = result;
      update();
    } catch (e) {
      debugPrint('[Checks] getGeneralChecksData failed: $e');
    }
  }

  // get all customers and sellers
  final RxList<SellerModel> allCustomersList = <SellerModel>[].obs;
  final RxList<SellerModel> allSellersList = <SellerModel>[].obs;

  void getAllCustomersAndSellers() async {
    try {
      final resultCustomers = await allCustomersSellersUsecase.call(
          endPoint: EndPoints.all_customers);
      final resultSellers = await allCustomersSellersUsecase.call(
          endPoint: EndPoints.all_sellers);
      allSellersList.assignAll(resultSellers);
      allCustomersList.assignAll(resultCustomers);
    } catch (e) {
      debugPrint('[Checks] getAllCustomersAndSellers failed: $e');
    }
  }

  // get general incoming
  final Rxn<GeneralIncomingModel> generalIncoming =
      Rxn<GeneralIncomingModel>(null);

  // get general outgoing
  final Rxn<GeneralOutgoingDataModel> generalOutgoing =
      Rxn<GeneralOutgoingDataModel>(null);

  // Future<void> generalData() async {
  //   isLoading(true);
  //   final result =
  //       await generalOutgoingDataUsecase.call(isInComing: isInComing);
  //   isInComing
  //       ? generalIncoming.value = GeneralIncomingModel.fromJson(result)
  //       : generalOutgoing.value = GeneralOutgoingDataModel.fromJson(result);
  //   isLoading(false);
  //   update();
  // }

  // get shown boxes
  final RxList<ShownBoxesModel> shownBoxesList = <ShownBoxesModel>[].obs;

  void getShowBoxes() async {
    try {
      final boxes = await getShownBoxUsecase.call(screen: 0);
      shownBoxesList.value = boxes;
    } catch (e) {
      debugPrint('[Checks] getShowBoxes failed: $e');
    }
  }

  // filter assets by date
  // فلترة وتجميع الشيكات حسب التاريخ + الترتيب
  Map<String, List<CheckModel>> filterChecks(
    Map<String, List<CheckModel>> source,
    String nameQuery,
    bool filterByAmount,
  ) {
    // لو الفلاتر كلها فاضية → رجع النسخة الأصلية زي ما هي
    if (nameQuery.isEmpty && !filterByAmount) {
      return Map.from(source);
    }

    final allChecks = source.values.expand((tasks) => tasks).toList();

    final filtered = allChecks.where((check) {
      bool matchesName = true;
      bool matchesAmount = true;

      // فلترة بالاسم
      if (nameQuery.isNotEmpty) {
        if (check.customer != null) {
          matchesName = check.customer!.name
              .toLowerCase()
              .contains(nameQuery.toLowerCase());
        }
        if (check.seller != null) {
          matchesName = check.seller!.name
              .toLowerCase()
              .contains(nameQuery.toLowerCase());
        }
        if (check.fromCustomer != null) {
          matchesName = check.fromCustomer!.name
              .toLowerCase()
              .contains(nameQuery.toLowerCase());
        }
        if (check.fromSeller != null) {
          matchesName = check.fromSeller!.name
              .toLowerCase()
              .contains(nameQuery.toLowerCase());
        }
      }

      // فلترة بالمبلغ (أكبر من 0)
      if (filterByAmount) {
        matchesAmount = (double.tryParse(check.total.toString()) ?? 0) > 0;
      }

      return matchesName && matchesAmount;
    }).toList();

    // إعادة التجميع حسب التاريخ (شهر/سنة)
    final Map<String, List<CheckModel>> grouped = {};
    for (var check in filtered) {
      final dateKey =
          "${check.dueDate.year}/${check.dueDate.month.toString().padLeft(2, '0')}";
      grouped.putIfAbsent(dateKey, () => []).add(check);
    }

    // الترتيب داخل كل شهر
    grouped.forEach((key, checks) {
      checks.sort((a, b) {
        if (filterByAmount) {
          // لو فلترة بالمبلغ → رتب تنازلي حسب المبلغ
          final totalA = double.tryParse(a.total.toString()) ?? 0.0;
          final totalB = double.tryParse(b.total.toString()) ?? 0.0;
          return totalB.compareTo(totalA);
        } else {
          // لو مفيش فلترة مبلغ → رتب حسب اليوم
          return a.dueDate.day.compareTo(b.dueDate.day);
        }
      });
    });

    // ترتيب الشهور زمنيًا (قديم → جديد)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final aParts = a.split('/');
        final bParts = b.split('/');
        final aDate = DateTime(int.parse(aParts[0]), int.parse(aParts[1]));
        final bDate = DateTime(int.parse(bParts[0]), int.parse(bParts[1]));
        return aDate.compareTo(bDate);
      });

    final Map<String, List<CheckModel>> sortedGrouped = {
      for (var key in sortedKeys) key: grouped[key]!
    };

    return sortedGrouped;
  }

  Map<String, List<CheckModel>> filteredInComingTasks = {};
  Map<String, List<CheckModel>> filteredCashedToPersonTasks = {};
  Map<String, List<CheckModel>> filteredArchiveTasks = {};

  void applyFilters() {
    final query = employeeNameController.text.trim();

    filteredCashedToPersonTasks.assignAll(
      filterChecks(cashedToPersonTasks, query, amountFilter.value),
    );

    filteredArchiveTasks.assignAll(
      filterChecks(archiveTasks, query, amountFilter.value),
    );

    filteredInComingTasks.assignAll(
      filterChecks(inComingTasks, query, amountFilter.value),
    );
    _syncTabCounts();
    Get.back();
    update();
  }

  void searchBar(String value) {
    bool matches(CheckModel check, String query) {
      final q = query.toLowerCase();
      return (check.checkId.toLowerCase().contains(q)) ||
          (check.bankName.toLowerCase().contains(q)) ||
          (check.currency.toLowerCase().contains(q)) ||
          (check.total.toLowerCase().contains(q)) ||
          (check.dueDate.toString().contains(q)) ||
          (check.notes?.toLowerCase().contains(q) ?? false) ||
          (check.customer?.name.toLowerCase().contains(q) ?? false) ||
          (check.seller?.name.toLowerCase().contains(q) ?? false) ||
          (check.fromCustomer?.name.toLowerCase().contains(q) ?? false) ||
          (check.fromSeller?.name.toLowerCase().contains(q) ?? false);
    }

    if (value.isNotEmpty) {
      filteredInComingTasks = Map.fromEntries(
        inComingTasks.entries.map((entry) {
          final filtered =
              entry.value.where((check) => matches(check, value)).toList();
          return MapEntry(entry.key, filtered);
        }).where((entry) => entry.value.isNotEmpty),
      );

      filteredCashedToPersonTasks = Map.fromEntries(
        cashedToPersonTasks.entries.map((entry) {
          final filtered =
              entry.value.where((check) => matches(check, value)).toList();
          return MapEntry(entry.key, filtered);
        }).where((entry) => entry.value.isNotEmpty),
      );

      filteredArchiveTasks = Map.fromEntries(
        archiveTasks.entries.map((entry) {
          final filtered =
              entry.value.where((check) => matches(check, value)).toList();
          return MapEntry(entry.key, filtered);
        }).where((entry) => entry.value.isNotEmpty),
      );
    } else {
      filteredInComingTasks.assignAll(inComingTasks);
      filteredCashedToPersonTasks.assignAll(cashedToPersonTasks);
      filteredArchiveTasks.assignAll(archiveTasks);
    }

    _syncTabCounts();
    update();
  }

  Future<void> pullToRefresh() async {
    try {
      await getGeneralChecksData();
      await loadAllChecksTabs(showLoading: true);
    } catch (e) {
      debugPrint('[Checks] pullToRefresh failed: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadSavedExchangeCurrencies();
    fetchExchangeRate();
    getGeneralChecksData();

    getAllCustomersAndSellers();
    getShowBoxes();
  }

  @override
  @override
  void onClose() {
    checkValueFocus.dispose();
    checkNumberFocus.dispose();
    bankNameFocus.dispose();
    notesFocus.dispose();
    checkValueController.dispose();
    currencyController.dispose();
    checkNumberController.dispose();
    bankNameController.dispose();
    notesController.dispose();
    incomingBatchCountController.dispose();
    for (final row in incomingBatchRows) {
      row.dispose();
    }
    employeeNameController.dispose();
    exchangeAmountController.dispose();
    _exchangeDebounce?.cancel();
    super.onClose();
  }
}

class ExchangeCurrency {
  const ExchangeCurrency({
    required this.code,
    required this.translationKey,
    required this.symbol,
  });

  final String code;
  final String translationKey;
  final String symbol;
}

class IncomingCheckDraft {
  IncomingCheckDraft({
    required String total,
    required DateTime dueDate,
    required String currency,
    required String checkId,
    required String bankName,
    required String notes,
  })  : total = TextEditingController(text: total),
        dueDate = dueDate.obs,
        currency = currency.obs,
        checkId = TextEditingController(text: checkId),
        bankName = TextEditingController(text: bankName),
        notes = TextEditingController(text: notes);

  final TextEditingController total;
  final Rx<DateTime> dueDate;
  final RxString currency;
  final TextEditingController checkId;
  final TextEditingController bankName;
  final TextEditingController notes;
  final Rx<XFile?> frontImage = Rx<XFile?>(null);
  final Rx<XFile?> backImage = Rx<XFile?>(null);

  void dispose() {
    total.dispose();
    checkId.dispose();
    bankName.dispose();
    notes.dispose();
  }
}
