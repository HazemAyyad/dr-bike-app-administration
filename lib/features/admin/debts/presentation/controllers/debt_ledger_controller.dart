import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../data/models/debt_ledger_models.dart';
import '../../domain/repositories/debt_ledger_repository.dart';
import '../ledger/edit_transaction_sheet.dart';
import '../ledger/person_detail_screen.dart';
import '../ledger/transaction_detail_screen.dart';
import '../ledger/archive_transactions_sheet.dart';
import '../ledger/collection_reminder_sheet.dart';
import '../ledger/person_note_sheet.dart';
import '../ledger/ledger_format.dart';
import '../ledger/performance_reminder_sheet.dart';
import '../ledger/share_sheet.dart';
import '../ledger/ledger_flash_message_screen.dart';
import '../ledger/ledger_share_image_helper.dart';
import '../ledger/ledger_transaction_success_screen.dart';
import '../ledger/ledger_colors.dart';
import '../ledger/ledger_confirm_dialog.dart';
import '../ledger/person_archive_screen.dart';
import '../ledger/person_deleted_screen.dart';
import '../ledger/transaction_entry_screen.dart';
import '../ledger/ledger_pick_person_sheet.dart';
import '../../../../../routes/app_routes.dart';

class DebtLedgerController extends GetxController {
  final DebtLedgerRepository repository;

  DebtLedgerController({required this.repository});

  final RxInt currentTab = 0.obs;
  final tabs = ['ledgerCustomers', 'ledgerSuppliers'];

  static const List<String> ledgerCurrencies = ['شيكل', 'دولار', 'دينار'];
  final RxString selectedCurrency = 'شيكل'.obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedPeriod = 'all'.obs;
  final RxString selectedSort = 'newest'.obs;
  final RxString selectedDebtType = 'all'.obs;
  final RxnInt selectedCategoryId = RxnInt();
  final RxList<ContactCategory> categories = <ContactCategory>[].obs;
  final Rxn<DateTime> customStartDate = Rxn<DateTime>();
  final Rxn<DateTime> customEndDate = Rxn<DateTime>();

  final Rxn<LedgerSummary> summary = Rxn<LedgerSummary>();
  final RxList<LedgerPerson> people = <LedgerPerson>[].obs;

  final Rxn<LedgerPersonDetail> personDetail = Rxn<LedgerPersonDetail>();
  final RxBool personLoading = false.obs;

  final Rxn<LedgerPersonArchiveDetail> personArchiveDetail =
      Rxn<LedgerPersonArchiveDetail>();
  final RxBool personArchiveLoading = false.obs;

  final Rxn<LedgerPersonArchiveDetail> personDeletedDetail =
      Rxn<LedgerPersonArchiveDetail>();
  final RxBool personDeletedLoading = false.obs;

  LedgerPersonInfo? selectedPerson;
  bool get isCustomerTab => currentTab.value == 0;

  String get peopleType => isCustomerTab ? 'customers' : 'sellers';

  double get tabTotalTaken {
    final s = summary.value;
    if (s == null) return 0;
    return s
        .totalsFor(selectedCurrency.value, customers: isCustomerTab)
        .receivable;
  }

  double get tabTotalGiven {
    final s = summary.value;
    if (s == null) return 0;
    return s
        .totalsFor(selectedCurrency.value, customers: isCustomerTab)
        .payable;
  }

  LedgerCurrencyBalance? get personCurrencyBalance {
    final detail = personDetail.value;
    if (detail == null) return null;
    return detail.balanceFor(selectedCurrency.value);
  }

  List<String> get tabLabels => [
        '${'ledgerCustomers'.tr} (${summary.value?.customersCount ?? people.length})',
        '${'ledgerSuppliers'.tr} (${summary.value?.sellersCount ?? 0})',
      ];

  List<LedgerPerson> get filteredPeople {
    final list = searchQuery.value.isEmpty
        ? people.toList()
        : people.where(
            (p) {
              final q = searchQuery.value.toLowerCase();
              return p.name.toLowerCase().contains(q) ||
                  (p.phone ?? '').contains(q);
            },
          ).toList();
    list.removeWhere((person) => !_matchesDebtType(person));
    list.sort(_comparePeople);
    return list;
  }

  bool _matchesDebtType(LedgerPerson person) {
    switch (selectedDebtType.value) {
      case 'taken':
        return person.balance > 0;
      case 'given':
        return person.balance < 0;
      case 'settled':
        return person.balance.abs() < 0.001;
      case 'all':
      default:
        return true;
    }
  }

  int _comparePeople(LedgerPerson a, LedgerPerson b) {
    switch (selectedSort.value) {
      case 'oldest':
        return _personActivityDate(a).compareTo(_personActivityDate(b));
      case 'largest_amount':
        return b.balance.abs().compareTo(a.balance.abs());
      case 'smallest_amount':
        return a.balance.abs().compareTo(b.balance.abs());
      case 'alphabetical':
        return a.name.compareTo(b.name);
      case 'newest':
      default:
        return _personActivityDate(b).compareTo(_personActivityDate(a));
    }
  }

  DateTime _personActivityDate(LedgerPerson person) {
    final last = person.lastTransaction;
    final raw = last?.transactionDate ?? last?.createdAt;
    return DateTime.tryParse(raw ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  void changeSort(String sort) {
    selectedSort.value = sort;
  }

  void changeDebtType(String type) {
    selectedDebtType.value = type;
  }

  @override
  void onInit() {
    super.onInit();
    loadMainData();
  }

  Future<void> loadMainData() async {
    isLoading(true);
    await Future.wait([fetchSummary(), fetchPeople(), fetchCategories()]);
    isLoading(false);
  }

  Future<void> pullToRefresh() async {
    await loadMainData();
  }

  void changeTab(int index) {
    currentTab.value = index;
    fetchPeople();
  }

  void changeCurrency(String currency) {
    if (selectedCurrency.value == currency) return;
    selectedCurrency.value = currency;
    fetchPeople();
    if (selectedPerson != null) {
      loadPersonDetail();
      loadPersonActivity();
    }
  }

  Future<void> fetchSummary() async {
    final result = await repository.getSummary();
    result.fold((_) {}, (data) => summary.value = data);
  }

  Future<void> fetchPeople() async {
    isLoading(true);
    final result = await repository.getPeople(
      type: peopleType,
      search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      startDate: _formatDate(customStartDate.value),
      endDate: _formatDate(customEndDate.value),
      currency: selectedCurrency.value,
      categoryId: selectedCategoryId.value,
    );
    result.fold(
      (failure) => Get.snackbar('error'.tr, failure.errMessage),
      (data) => people.assignAll(data),
    );
    isLoading(false);
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
    fetchPeople();
  }

  Future<void> fetchCategories() async {
    final result = await repository.getCategories();
    result.fold(
      (failure) => Get.snackbar('error'.tr, failure.errMessage),
      (list) => categories.assignAll(list),
    );
  }

  Future<void> applyCategory(int? id) async {
    selectedCategoryId.value = id;
    await fetchPeople();
  }

  Future<bool> saveCategory({
    int? id,
    required String name,
    required String color,
    List<int> customerIds = const [],
    List<int> sellerIds = const [],
  }) async {
    final result = await repository.saveCategory(
      id: id,
      name: name,
      color: color,
      customerIds: customerIds,
      sellerIds: sellerIds,
    );
    final success = result.fold(
      (failure) {
        Get.snackbar('error'.tr, failure.errMessage);
        return false;
      },
      (_) => true,
    );
    if (success) {
      await fetchCategories();
      await fetchPeople();
    }
    return success;
  }

  Future<bool> deleteCategory(int id) async {
    final result = await repository.deleteCategory(id);
    final success = result.fold(
      (failure) {
        Get.snackbar('error'.tr, failure.errMessage);
        return false;
      },
      (_) => true,
    );
    if (success) {
      if (selectedCategoryId.value == id) {
        selectedCategoryId.value = null;
      }
      await fetchCategories();
      await fetchPeople();
    }
    return success;
  }

  Future<void> openPerson(LedgerPerson person) async {
    await _openPersonDetail(
      id: person.id,
      name: person.name,
      phone: person.phone,
      personType: person.personType,
    );
  }

  Future<void> _openPersonDetail({
    required int id,
    required String name,
    String? phone,
    required String personType,
  }) async {
    selectedPerson = LedgerPersonInfo(
      id: id,
      name: name,
      phone: phone,
      personType: personType,
    );
    await Get.to(() => const PersonDetailScreen());
    await loadMainData();
  }

  Future<void> openPickPersonForDebt() async {
    final picked = await Get.bottomSheet<LedgerPerson>(
      LedgerPickPersonSheet(
        isCustomer: isCustomerTab,
        repository: repository,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
    );
    if (picked == null) return;
    await _openPersonDetail(
      id: picked.id,
      name: picked.name,
      phone: picked.phone,
      personType: picked.personType,
    );
  }

  /// إضافة زبون أو تاجر جديد ثم تحديث قائمة دفتر الديون.
  Future<void> openAddPersonFromLedger() async {
    final isCustomer = isCustomerTab;
    await Get.toNamed(
      AppRoutes.ADDNEWCUSTOMERSCREEN,
      arguments: {
        'sellerId': '',
        'employeeId': '',
        'employeeType': isCustomer ? 'customer' : 'seller',
        'popOnceOnSuccess': true,
      },
    );
    await loadMainData();
  }

  Future<void> loadPersonDetail() async {
    if (selectedPerson == null) return;
    personLoading(true);
    final result = await repository.getPerson(
      customerId: selectedPerson!.isCustomer ? selectedPerson!.id : null,
      sellerId: selectedPerson!.isCustomer ? null : selectedPerson!.id,
      startDate: _formatDate(customStartDate.value),
      endDate: _formatDate(customEndDate.value),
      currency: selectedCurrency.value,
    );
    result.fold(
      (failure) => Get.snackbar('error'.tr, failure.errMessage),
      (data) {
        personDetail.value = data;
        selectedPerson = data.person;
      },
    );
    personLoading(false);
    await loadPersonActivity();
  }

  LedgerPersonInfo? get currentPerson =>
      personDetail.value?.person ?? selectedPerson;

  String? collectionReminderLabel(LedgerPersonInfo? person) {
    final raw = person?.collectionReminderAt;
    if (raw == null || raw.isEmpty) return null;
    try {
      final dt = DateTime.parse(raw);
      final formatted = DateFormat('dd MMMM', 'ar').format(dt);
      return '${'ledgerCollectionOn'.tr} $formatted';
    } catch (_) {
      return null;
    }
  }

  void openPersonNoteSheet() {
    final person = currentPerson;
    if (person == null) return;
    Get.bottomSheet(
      PersonNoteSheet(person: person),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void openCollectionReminderSheet() {
    Get.bottomSheet(
      const CollectionReminderSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<bool> savePersonNotes(String notes) async {
    final person = currentPerson;
    if (person == null) return false;

    final result = await repository.updatePersonMeta(
      customerId: person.isCustomer ? person.id : null,
      sellerId: person.isCustomer ? null : person.id,
      notes: notes.trim(),
      updateNotes: true,
    );

    return result.fold(
      (failure) {
        Get.snackbar('error'.tr, failure.errMessage);
        return false;
      },
      (updated) {
        _applyPersonMeta(updated);
        return true;
      },
    );
  }

  Future<bool> setCollectionReminder(DateTime date) async {
    final person = currentPerson;
    if (person == null) return false;

    final result = await repository.updatePersonMeta(
      customerId: person.isCustomer ? person.id : null,
      sellerId: person.isCustomer ? null : person.id,
      collectionReminderAt: DateFormat('yyyy-MM-dd').format(date),
      updateReminder: true,
    );

    return result.fold(
      (failure) {
        Get.snackbar('error'.tr, failure.errMessage);
        return false;
      },
      (updated) {
        _applyPersonMeta(updated);
        return true;
      },
    );
  }

  Future<bool> clearCollectionReminder() async {
    final person = currentPerson;
    if (person == null) return false;

    final result = await repository.updatePersonMeta(
      customerId: person.isCustomer ? person.id : null,
      sellerId: person.isCustomer ? null : person.id,
      clearCollectionReminder: true,
      updateReminder: true,
    );

    return result.fold(
      (failure) {
        Get.snackbar('error'.tr, failure.errMessage);
        return false;
      },
      (updated) {
        _applyPersonMeta(updated);
        return true;
      },
    );
  }

  void _applyPersonMeta(LedgerPersonInfo updated) {
    selectedPerson = updated;
    final detail = personDetail.value;
    if (detail != null) {
      personDetail.value = LedgerPersonDetail(
        person: updated,
        totalTaken: detail.totalTaken,
        totalGiven: detail.totalGiven,
        balance: detail.balance,
        balancesByCurrency: detail.balancesByCurrency,
        activeTransactionsCount: detail.activeTransactionsCount,
        transactions: detail.transactions,
      );
    }
  }

  DateTime get nextWeekReminderDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
  }

  DateTime get nextMonthReminderDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }

  final Rxn<LedgerTransaction> selectedTransaction = Rxn<LedgerTransaction>();
  final RxList<LedgerActivityEntry> transactionActivity =
      <LedgerActivityEntry>[].obs;
  final RxList<LedgerActivityEntry> personActivity =
      <LedgerActivityEntry>[].obs;
  final RxBool transactionActivityLoading = false.obs;
  final RxBool personActivityLoading = false.obs;

  Future<void> loadTransactionActivity(int transactionId) async {
    transactionActivityLoading(true);
    final result = await repository.getTransactionActivity(transactionId);
    result.fold(
      (failure) {
        transactionActivity.clear();
        Get.snackbar('error'.tr, failure.errMessage);
      },
      (list) => transactionActivity.assignAll(list),
    );
    transactionActivityLoading(false);
  }

  Future<void> loadPersonActivity() async {
    if (selectedPerson == null) return;
    personActivityLoading(true);
    final result = await repository.getPersonActivity(
      customerId: selectedPerson!.isCustomer ? selectedPerson!.id : null,
      sellerId: selectedPerson!.isCustomer ? null : selectedPerson!.id,
      currency: selectedCurrency.value,
    );
    result.fold(
      (failure) {
        personActivity.clear();
        Get.snackbar('error'.tr, failure.errMessage);
      },
      (list) => personActivity.assignAll(list),
    );
    personActivityLoading(false);
  }

  void openTransactionDetail(LedgerTransaction transaction) {
    selectedTransaction.value = transaction;
    loadTransactionActivity(transaction.id);
    Get.to(() => const TransactionDetailScreen())?.then((changed) {
      if (changed == true) {
        loadPersonDetail();
        fetchSummary();
      }
    });
  }

  Future<void> deleteTransaction(int id) async {
    final confirm = await showLedgerConfirmDialog(
      title: 'ledgerDeleteConfirmTitle'.tr,
      body: 'ledgerDeleteConfirmBody'.tr,
      confirmLabel: 'delete'.tr,
      confirmColor: Colors.red,
    );
    if (confirm != true) return;

    final result = await repository.deleteTransaction(id);
    result.fold(
      (failure) => Get.snackbar('error'.tr, failure.errMessage),
      (_) {
        Get.back(result: true);
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.snackbar('success'.tr, 'ledgerDeleted'.tr);
        });
      },
    );
  }

  Future<void> archiveTransactionFromDetail(int id) async {
    final confirm = await showLedgerConfirmDialog(
      title: 'ledgerArchiveConfirmTitle'.tr,
      body: 'ledgerArchiveConfirmBody'.tr,
      confirmLabel: 'ledgerArchive'.tr,
      confirmColor: LedgerColors.primaryBlue,
    );
    if (confirm != true) return;

    final result = await repository.archiveTransaction(id);
    result.fold(
      (failure) => Get.snackbar('error'.tr, failure.errMessage),
      (_) {
        Get.back(result: true);
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.snackbar('success'.tr, 'ledgerArchived'.tr);
        });
      },
    );
  }

  Future<bool> updateTransaction({
    required int id,
    required String type,
    required String amount,
    required String transactionDate,
    String? currency,
    String? note,
    String? boxId,
    List<File>? receiptImages,
  }) async {
    final result = await repository.updateTransaction(
      id: id,
      type: type,
      amount: amount,
      transactionDate: transactionDate,
      currency: currency,
      note: note,
      boxId: boxId,
      receiptImages: receiptImages,
    );
    return result.fold(
      (failure) {
        Get.snackbar('error'.tr, failure.errMessage);
        return false;
      },
      (tx) {
        selectedTransaction.value = tx;
        return true;
      },
    );
  }

  void openEditTransaction(LedgerTransaction transaction) {
    Get.bottomSheet(
      EditTransactionSheet(transaction: transaction),
      isScrollControlled: true,
    ).then((updated) async {
      if (updated == true) {
        await loadPersonDetail();
      }
    });
  }

  void openTransactionShareSheet(LedgerTransaction tx) {
    Get.bottomSheet(
      TransactionShareSheet(transaction: tx),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<String> _buildTransactionShareMessage(LedgerTransaction tx) async {
    final person = currentPerson ?? selectedPerson;

    String shareUrl = '';
    if (person != null) {
      final linkResult = await repository.createPersonShareLink(
        customerId: person.isCustomer ? person.id : null,
        sellerId: person.isCustomer ? null : person.id,
      );
      linkResult.fold((_) {}, (url) => shareUrl = url);
    }

    final amountLine = LedgerFormat.money(
      tx.amount,
      currency: tx.currency,
      fractionDigits: 2,
    );
    final separator = '──────────────';
    final buffer = StringBuffer()
      ..writeln('ledgerShareYouHaveTransaction'.tr)
      ..writeln(separator)
      ..writeln(amountLine)
      ..writeln(separator);

    if (shareUrl.isNotEmpty) {
      buffer
        ..writeln('ledgerViewAllTransactions'.tr)
        ..writeln(shareUrl);
    }

    return buffer.toString();
  }

  Future<void> shareSingleTransactionVia(
    LedgerTransaction tx,
    String channel,
  ) async {
    final person = currentPerson ?? selectedPerson;
    if (person == null) return;

    final message = await _buildTransactionShareMessage(tx);
    final phone = person.phone?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (channel == 'sms') {
      if (phone.isNotEmpty) {
        final uri = Uri.parse(
          'sms:$phone?body=${Uri.encodeComponent(message)}',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          return;
        }
      }
      await SharePlus.instance.share(ShareParams(text: message));
      return;
    }

    final imageBytes = await LedgerShareImageHelper.captureTransactionVoucher(
      personName: person.name,
      timeLabel: formatTransactionTime(tx),
      transactionValueLabel: 'ledgerTransactionValue'.tr,
      amount: tx.amount,
      isTaken: tx.isTaken,
    );

    File? voucherFile;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final dir = await getTemporaryDirectory();
      voucherFile = File(
        '${dir.path}/ledger_tx_${tx.id}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await voucherFile.writeAsBytes(imageBytes);
    }

    if (voucherFile != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(voucherFile.path)],
          text: message,
        ),
      );
      return;
    }

    if (phone.isNotEmpty) {
      final uri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    await SharePlus.instance.share(ShareParams(text: message));
  }

  String _formatLedgerDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw.replaceFirst(' ', 'T'));
      final now = DateTime.now();
      final isToday =
          dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final time = DateFormat('h:mm a', 'ar').format(dt);
      if (isToday) {
        return '${'ledgerTodayAt'.tr} $time';
      }
      final date = DateFormat('d MMMM', 'ar').format(dt);
      return '$date ${'ledgerAt'.tr} $time';
    } catch (_) {
      return raw;
    }
  }

  String formatTransactionTime(LedgerTransaction tx) {
    return _formatLedgerDateTime(tx.createdAt ?? tx.transactionDate);
  }

  String formatLastTransactionTime(LedgerLastTransaction? last) {
    if (last == null) return '';
    final raw = last.createdAt ?? last.transactionDate;
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw.replaceFirst(' ', 'T'));
      return _formatRelativeLedgerDate(dt);
    } catch (_) {
      return raw;
    }
  }

  String _formatRelativeLedgerDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(targetDay).inDays;

    if (diffDays <= 0) return 'ledgerToday'.tr;
    if (diffDays == 1) return 'ledgerYesterday'.tr;
    return 'ledgerDaysAgo'.trParams({'days': '$diffDays'});
  }

  Future<void> loadPersonArchive() async {
    if (selectedPerson == null) return;
    personArchiveLoading(true);
    final result = await repository.getPersonArchive(
      customerId: selectedPerson!.isCustomer ? selectedPerson!.id : null,
      sellerId: selectedPerson!.isCustomer ? null : selectedPerson!.id,
      currency: selectedCurrency.value,
    );
    result.fold(
      (failure) => Get.snackbar('error'.tr, failure.errMessage),
      (data) => personArchiveDetail.value = data,
    );
    personArchiveLoading(false);
  }

  void openArchiveSheet() {
    final txs = personDetail.value?.transactions ?? [];
    if (txs.isEmpty) {
      Get.snackbar('error'.tr, 'ledgerNoTransactions'.tr);
      return;
    }
    Get.bottomSheet(
      ArchiveTransactionsSheet(transactions: txs),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).then((archived) async {
      if (archived == true) {
        await loadPersonDetail();
        await fetchSummary();
        Get.snackbar('success'.tr, 'ledgerArchived'.tr);
      }
    });
  }

  Future<void> openPersonArchive() async {
    await Get.to(() => const PersonArchiveScreen());
    await loadPersonDetail();
    await fetchSummary();
  }

  Future<void> loadPersonDeleted() async {
    if (selectedPerson == null) return;
    personDeletedLoading(true);
    final result = await repository.getPersonDeleted(
      customerId: selectedPerson!.isCustomer ? selectedPerson!.id : null,
      sellerId: selectedPerson!.isCustomer ? null : selectedPerson!.id,
      currency: selectedCurrency.value,
    );
    result.fold(
      (failure) => Get.snackbar('error'.tr, failure.errMessage),
      (data) => personDeletedDetail.value = data,
    );
    personDeletedLoading(false);
  }

  Future<void> openPersonDeleted() async {
    await Get.to(() => const PersonDeletedScreen());
    await loadPersonDetail();
    await fetchSummary();
  }

  Future<bool> archiveTransactionsBulk(List<int> ids) async {
    final result = await repository.archiveTransactionsBulk(ids);
    return result.fold(
      (failure) {
        Get.snackbar('error'.tr, failure.errMessage);
        return false;
      },
      (_) => true,
    );
  }

  Future<bool> restoreTransactionsBulk(List<int> ids) async {
    final result = await repository.restoreTransactionsBulk(ids);
    return await result.fold(
      (failure) async {
        Get.snackbar('error'.tr, failure.errMessage);
        return false;
      },
      (_) async {
        await LedgerFlashMessageScreen.show('ledgerRestoredSuccess'.tr);
        await loadPersonArchive();
        await loadPersonDetail();
        await fetchSummary();
        return true;
      },
    );
  }

  void openTransactionEntry({required String type}) {
    if (selectedPerson == null) return;
    Get.to(
      () => TransactionEntryScreen(
        personName: selectedPerson!.name,
        type: type,
        isCustomer: selectedPerson!.isCustomer,
        personId: selectedPerson!.id,
        initialCurrency: selectedCurrency.value,
      ),
    )?.then((saved) {
      if (saved == true) {
        loadPersonDetail();
        fetchSummary();
      }
    });
  }

  Future<void> applyPeriod(String period) async {
    selectedPeriod.value = period;
    if (period != 'custom') {
      customStartDate.value = null;
      customEndDate.value = null;
    }
    await fetchPeople();
    if (Get.currentRoute.contains('PersonDetail')) {
      await loadPersonDetail();
    }
  }

  Future<void> setCustomPeriod(DateTime? start, DateTime? end) async {
    customStartDate.value = start;
    customEndDate.value = end;
    selectedPeriod.value = 'custom';
    await applyPeriod('custom');
  }

  Future<File?> downloadPersonReport() async {
    if (selectedPerson == null) return null;
    final result = await repository.downloadReport(
      customerId: selectedPerson!.isCustomer ? selectedPerson!.id : null,
      sellerId: selectedPerson!.isCustomer ? null : selectedPerson!.id,
      period: selectedPeriod.value,
      startDate: _formatDate(customStartDate.value),
      endDate: _formatDate(customEndDate.value),
      currency: selectedCurrency.value,
    );
    return result.fold(
      (failure) {
        Get.snackbar('error'.tr, 'ledgerReportFailed'.tr);
        return null;
      },
      (bytes) async {
        final dir = await getApplicationDocumentsDirectory();
        final file = File(
          '${dir.path}/debt_ledger_${selectedPerson!.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        await file.writeAsBytes(bytes);
        return file;
      },
    );
  }

  Future<void> collectDebtVia(String channel) async {
    if (selectedPerson == null) return;

    final currency = selectedCurrency.value;
    final balance = personCurrencyBalance?.balance ??
        personDetail.value?.balanceFor(currency).balance ??
        0;
    if (balance <= 0) {
      Get.snackbar('error'.tr, 'ledgerNoDebtToCollect'.tr);
      return;
    }

    final phone = selectedPerson!.phone?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (phone.isEmpty) {
      Get.snackbar('error'.tr, 'ledgerNoPhone'.tr);
      return;
    }

    final amountLabel = LedgerFormat.money(balance, currency: currency);
    final message = 'مرحباً ${selectedPerson!.name}\n'
        '${'ledgerDebtCollectionMessage'.tr}: $amountLabel';

    if (channel == 'whatsapp') {
      final uri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await SharePlus.instance.share(ShareParams(text: message));
      }
    } else {
      final uri = Uri.parse(
        'sms:$phone?body=${Uri.encodeComponent(message)}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await SharePlus.instance.share(ShareParams(text: message));
      }
    }
  }

  Future<String?> fetchPersonShareUrl() async {
    final person = selectedPerson;
    if (person == null) return null;

    String shareUrl = '';
    final linkResult = await repository.createPersonShareLink(
      customerId: person.isCustomer ? person.id : null,
      sellerId: person.isCustomer ? null : person.id,
    );
    linkResult.fold((_) => null, (url) => shareUrl = url);
    return shareUrl.isEmpty ? null : shareUrl;
  }

  String formatReminderTime() {
    final now = DateTime.now();
    final time = DateFormat('h:mm a', 'ar').format(now);
    final date = DateFormat('d MMMM', 'ar').format(now);
    return '$date ${'ledgerAt'.tr} $time';
  }

  String buildPerformanceReminderSmsMessage(String shareUrl) {
    final currency = selectedCurrency.value;
    final balance = personCurrencyBalance?.balance ?? 0;
    final amount = LedgerFormat.money(
      balance.abs(),
      currency: currency,
      fractionDigits: 2,
    );
    final buffer = StringBuffer()
      ..writeln('${'ledgerReminderSmsBody'.tr} $amount')
      ..writeln('${'ledgerTransactionsLink'.tr}:')
      ..write(shareUrl);
    return buffer.toString();
  }

  String buildPerformanceReminderWhatsappMessage(String shareUrl) {
    final currency = selectedCurrency.value;
    final balance = personCurrencyBalance?.balance ?? 0;
    const separator = '──────────────';
    final buffer = StringBuffer()
      ..writeln('ledgerReminderWhatsappBody'.tr)
      ..writeln(separator)
      ..writeln(
        LedgerFormat.money(
          balance.abs(),
          currency: currency,
          fractionDigits: 2,
        ),
      )
      ..writeln(separator)
      ..writeln('ledgerViewAllTransactions'.tr)
      ..write(shareUrl);
    return buffer.toString();
  }

  void openPerformanceReminderSheet() {
    Get.bottomSheet(
      const PerformanceReminderSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> sendPerformanceReminder({
    required String channel,
    required String shareUrl,
  }) async {
    final person = selectedPerson;
    final detail = personDetail.value;
    if (person == null || detail == null) return;

    final phone = person.phone?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (channel == 'sms') {
      final message = buildPerformanceReminderSmsMessage(shareUrl);
      if (phone.isNotEmpty) {
        final uri = Uri.parse(
          'sms:$phone?body=${Uri.encodeComponent(message)}',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          return;
        }
      }
      await SharePlus.instance.share(ShareParams(text: message));
      return;
    }

    final currency = selectedCurrency.value;
    final stats = detail.balanceFor(currency);
    final takenCount = detail.transactions.where((t) => t.isTaken).length;
    final givenCount = detail.transactions.where((t) => !t.isTaken).length;
    final imageBytes = await LedgerShareImageHelper.capturePerformanceReminder(
      personName: person.name,
      timeLabel: formatReminderTime(),
      reminderTitle: 'ledgerPerformanceReminder'.tr,
      balance: stats.balance,
      totalTaken: stats.totalTaken,
      totalGiven: stats.totalGiven,
      currency: currency,
      takenCount: takenCount,
      givenCount: givenCount,
      takenLabel: 'took'.tr,
      givenLabel: 'gave'.tr,
      transactionsWord: 'ledgerTransactionsWord'.tr,
    );

    final message = buildPerformanceReminderWhatsappMessage(shareUrl);

    File? imageFile;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final dir = await getTemporaryDirectory();
      imageFile = File(
        '${dir.path}/ledger_reminder_${person.id}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await imageFile.writeAsBytes(imageBytes);
    }

    if (imageFile != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imageFile.path)],
          text: message,
        ),
      );
      return;
    }

    if (phone.isNotEmpty) {
      final uri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    await SharePlus.instance.share(ShareParams(text: message));
  }

  Future<void> shareReportVia(String channel) async {
    final shareUrl = await fetchPersonShareUrl();
    if (shareUrl == null) {
      Get.snackbar('error'.tr, 'ledgerShareLinkFailed'.tr);
      return;
    }

    final currency = selectedCurrency.value;
    final balance = personCurrencyBalance?.balance ?? 0;
    final message =
        '${'ledgerReportShareIntro'.tr} ${LedgerFormat.money(balance, currency: currency, fractionDigits: 2)}\n'
        '${'ledgerViewAllTransactions'.tr}\n$shareUrl';

    final phone = selectedPerson?.phone?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (channel == 'sms') {
      if (phone.isNotEmpty) {
        final uri = Uri.parse(
          'sms:$phone?body=${Uri.encodeComponent(message)}',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          return;
        }
      }
      await SharePlus.instance.share(ShareParams(text: message));
      return;
    }

    final person = selectedPerson;
    if (person == null) return;

    final imageBytes = await LedgerShareImageHelper.captureReportVoucher(
      personName: person.name,
      timeLabel: formatReminderTime(),
      balanceLabel: 'ledgerBalance'.tr,
      amount: balance.abs(),
      isTaken: balance > 0,
    );

    File? voucherFile;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final dir = await getTemporaryDirectory();
      voucherFile = File(
        '${dir.path}/ledger_report_${person.id}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await voucherFile.writeAsBytes(imageBytes);
    }

    if (voucherFile != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(voucherFile.path)],
          text: message,
        ),
      );
      return;
    }

    if (phone.isNotEmpty) {
      final uri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    await SharePlus.instance.share(ShareParams(text: message));
  }

  Future<void> callPerson() async {
    final phone = selectedPerson?.phone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> openDownloadedReport(File file) async {
    await OpenFilex.open(file.path);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Color balanceColor(double balance) {
    if (balance > 0) return const Color(0xFF1B8A4A);
    if (balance < 0) return const Color(0xFFC62828);
    return const Color(0xFF757575);
  }

  /// تسمية الرصيد في القائمة الرئيسية: موجب = أخذت (أخضر)، سالب = أعطيت (أحمر).
  String balanceTypeLabel(double balance) {
    if (balance > 0) return 'took'.tr;
    if (balance < 0) return 'gave'.tr;
    return '';
  }
}

/// Calculator logic for transaction entry screen
class TransactionCalculatorController extends GetxController {
  final DebtLedgerRepository repository;
  final GetShownBoxUsecase getShownBoxUsecase;
  final String personName;
  final String initialType;
  final bool isCustomer;
  final int personId;
  final String initialCurrency;

  TransactionCalculatorController({
    required this.repository,
    required this.getShownBoxUsecase,
    required this.personName,
    required this.initialType,
    required this.isCustomer,
    required this.personId,
    required this.initialCurrency,
  });

  final RxList<ShownBoxesModel> allBoxes = <ShownBoxesModel>[].obs;
  final RxList<ShownBoxesModel> shownBoxesList = <ShownBoxesModel>[].obs;
  final Rxn<ShownBoxesModel> selectedBox = Rxn<ShownBoxesModel>();
  final RxString selectedCurrency = 'شيكل'.obs;

  final RxString display = '0'.obs;
  final RxString expression = ''.obs;
  final RxBool isSaving = false.obs;
  final RxString transactionType = 'taken'.obs;
  final Rxn<DateTime> selectedDate = Rxn<DateTime>(DateTime.now());
  final TextEditingController noteController = TextEditingController();
  final RxList<File> receiptImages = <File>[].obs;

  @override
  void onInit() {
    super.onInit();
    transactionType.value = initialType;
    selectedCurrency.value = initialCurrency;
    _loadBoxes();
  }

  Future<void> _loadBoxes() async {
    final boxes = await getShownBoxUsecase.call(screen: 0);
    allBoxes.assignAll(boxes);
    _applyBoxFilter();
  }

  void setCurrency(String currency) {
    selectedCurrency.value = currency;
    _applyBoxFilter();
  }

  void _applyBoxFilter() {
    shownBoxesList.assignAll(
      allBoxes.where((b) => b.currency == selectedCurrency.value).toList(),
    );
    final box = selectedBox.value;
    if (box != null && box.currency != selectedCurrency.value) {
      selectedBox.value = null;
    }
  }

  String get effectiveCurrency =>
      selectedBox.value?.currency ?? selectedCurrency.value;

  Future<void> pickReceiptImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    receiptImages.addAll(picked.map((x) => File(x.path)));
  }

  void removeReceiptImage(int index) {
    if (index >= 0 && index < receiptImages.length) {
      receiptImages.removeAt(index);
    }
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }

  void appendDigit(String digit) {
    if (display.value == '0' && digit != '.') {
      display.value = digit;
    } else {
      display.value = display.value + digit;
    }
  }

  void backspace() {
    if (display.value.length <= 1) {
      display.value = '0';
    } else {
      display.value = display.value.substring(0, display.value.length - 1);
    }
  }

  void clearAll() {
    display.value = '0';
    expression.value = '';
  }

  void applyOperator(String op) {
    final current = double.tryParse(display.value) ?? 0;
    if (expression.value.isEmpty) {
      expression.value = '$current $op';
    } else {
      calculateResult();
      expression.value = '${display.value} $op';
    }
    display.value = '0';
  }

  void calculateResult() {
    try {
      final parts = '${expression.value} ${display.value}'.split(' ');
      if (parts.length < 3) return;
      final a = double.parse(parts[0]);
      final op = parts[1];
      final b = double.parse(parts[2]);
      double result;
      switch (op) {
        case '+':
          result = a + b;
          break;
        case '-':
          result = a - b;
          break;
        case '×':
        case 'x':
          result = a * b;
          break;
        case '/':
          result = b == 0 ? 0 : a / b;
          break;
        case '%':
          result = a % b;
          break;
        default:
          result = b;
      }
      display.value = _trimNumber(result);
      expression.value = '';
    } catch (_) {
      display.value = '0';
      expression.value = '';
    }
  }

  String _trimNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  Future<void> saveTransaction() async {
    await _saveWithType(transactionType.value);
  }

  Future<void> _saveWithType(String type) async {
    if (isSaving.value) return;

    if (expression.value.isNotEmpty) {
      calculateResult();
    }

    final amount = double.tryParse(display.value) ?? 0;
    if (amount <= 0) {
      Get.snackbar('error'.tr, 'ledgerAmountRequired'.tr);
      return;
    }

    final box = selectedBox.value;

    isSaving.value = true;
    try {
      final result = await repository.createTransaction(
        customerId: isCustomer ? personId : null,
        sellerId: isCustomer ? null : personId,
        type: type,
        amount: amount.toStringAsFixed(2),
        currency: effectiveCurrency,
        transactionDate: DateFormat('yyyy-MM-dd').format(
          selectedDate.value ?? DateTime.now(),
        ),
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
        boxId: box?.boxId.toString(),
        receiptImages:
            receiptImages.isEmpty ? null : List<File>.from(receiptImages),
      );

      result.fold(
        (failure) {
          Get.snackbar(
            'error'.tr,
            failure.errMessage.isNotEmpty
                ? failure.errMessage
                : 'ledgerSaveFailed'.tr,
            duration: const Duration(seconds: 4),
          );
        },
        (createResult) {
          final ledger = Get.find<DebtLedgerController>();
          final tx = createResult.transaction;
          Get.off(
            () => LedgerTransactionSuccessScreen(
              personName: personName,
              type: type,
              typeLabel: tx.typeLabel,
              amount: tx.amount,
              currency: tx.currency,
              balanceAfter: tx.balanceAfter,
              timeLabel: ledger.formatTransactionTime(tx),
            ),
          );
        },
      );
    } finally {
      isSaving.value = false;
    }
  }
}
