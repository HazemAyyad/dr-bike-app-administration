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

class DebtLedgerController extends GetxController {
  final DebtLedgerRepository repository;

  DebtLedgerController({required this.repository});

  final RxInt currentTab = 0.obs;
  final tabs = ['ledgerCustomers', 'ledgerSuppliers'];

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedPeriod = 'all'.obs;
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

  double get tabTotalTaken => isCustomerTab
      ? (summary.value?.totalTakenCustomers ?? 0)
      : (summary.value?.totalTakenSellers ?? 0);

  double get tabTotalGiven => isCustomerTab
      ? (summary.value?.totalGivenCustomers ?? 0)
      : (summary.value?.totalGivenSellers ?? 0);

  List<LedgerPerson> get filteredPeople {
    if (searchQuery.value.isEmpty) return people;
    final q = searchQuery.value.toLowerCase();
    return people
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              (p.phone ?? '').contains(q),
        )
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadMainData();
  }

  Future<void> loadMainData() async {
    isLoading(true);
    await Future.wait([fetchSummary(), fetchPeople()]);
    isLoading(false);
  }

  Future<void> pullToRefresh() async {
    await loadMainData();
  }

  void changeTab(int index) {
    currentTab.value = index;
    fetchPeople();
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

  Future<void> openPerson(LedgerPerson person) async {
    selectedPerson = LedgerPersonInfo(
      id: person.id,
      name: person.name,
      phone: person.phone,
      personType: isCustomerTab ? 'customer' : 'seller',
    );
    await Get.to(() => const PersonDetailScreen());
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
    );
    result.fold(
      (failure) => Get.snackbar('error'.tr, failure.errMessage),
      (data) {
        personDetail.value = data;
        selectedPerson = data.person;
      },
    );
    personLoading(false);
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

  void openTransactionDetail(LedgerTransaction transaction) {
    selectedTransaction.value = transaction;
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
    String? note,
    String? boxId,
  }) async {
    final result = await repository.updateTransaction(
      id: id,
      type: type,
      amount: amount,
      transactionDate: transactionDate,
      note: note,
      boxId: boxId,
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
    )?.then((updated) async {
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

    final amountLine = LedgerFormat.shekel2(tx.amount);
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

  String formatTransactionTime(LedgerTransaction tx) {
    final raw = tx.createdAt ?? tx.transactionDate;
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw.replaceFirst(' ', 'T'));
      final now = DateTime.now();
      final isToday = dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day;
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

  Future<void> loadPersonArchive() async {
    if (selectedPerson == null) return;
    personArchiveLoading(true);
    final result = await repository.getPersonArchive(
      customerId: selectedPerson!.isCustomer ? selectedPerson!.id : null,
      sellerId: selectedPerson!.isCustomer ? null : selectedPerson!.id,
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
    )?.then((archived) async {
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

    final balance = personDetail.value?.balance ?? 0;
    if (balance <= 0) {
      Get.snackbar('error'.tr, 'ledgerNoDebtToCollect'.tr);
      return;
    }

    final phone = selectedPerson!.phone?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (phone.isEmpty) {
      Get.snackbar('error'.tr, 'ledgerNoPhone'.tr);
      return;
    }

    final message =
        'مرحباً ${selectedPerson!.name}\n'
        '${'ledgerDebtCollectionMessage'.tr}: ${balance.toStringAsFixed(2)} ₪';

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
    final balance = personDetail.value?.balance ?? 0;
    final amount = LedgerFormat.shekel2(balance.abs());
    final buffer = StringBuffer()
      ..writeln('${'ledgerReminderSmsBody'.tr} $amount')
      ..writeln('${'ledgerTransactionsLink'.tr}:')
      ..write(shareUrl);
    return buffer.toString();
  }

  String buildPerformanceReminderWhatsappMessage(String shareUrl) {
    final balance = personDetail.value?.balance ?? 0;
    const separator = '──────────────';
    final buffer = StringBuffer()
      ..writeln('ledgerReminderWhatsappBody'.tr)
      ..writeln(separator)
      ..writeln(LedgerFormat.shekel2(balance.abs()))
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

    final takenCount = detail.transactions.where((t) => t.isTaken).length;
    final givenCount = detail.transactions.where((t) => !t.isTaken).length;
    final imageBytes = await LedgerShareImageHelper.capturePerformanceReminder(
      personName: person.name,
      timeLabel: formatReminderTime(),
      reminderTitle: 'ledgerPerformanceReminder'.tr,
      balance: detail.balance,
      totalTaken: detail.totalTaken,
      totalGiven: detail.totalGiven,
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

    final balance = personDetail.value?.balance ?? 0;
    final message =
        '${'ledgerReportShareIntro'.tr} ${LedgerFormat.shekel2(balance)}\n'
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

    final file = await downloadPersonReport();
    if (file != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
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
}

/// Calculator logic for transaction entry screen
class TransactionCalculatorController extends GetxController {
  final DebtLedgerRepository repository;
  final GetShownBoxUsecase getShownBoxUsecase;
  final String personName;
  final String initialType;
  final bool isCustomer;
  final int personId;

  TransactionCalculatorController({
    required this.repository,
    required this.getShownBoxUsecase,
    required this.personName,
    required this.initialType,
    required this.isCustomer,
    required this.personId,
  });

  final RxList<ShownBoxesModel> shownBoxesList = <ShownBoxesModel>[].obs;
  final Rxn<ShownBoxesModel> selectedBox = Rxn<ShownBoxesModel>();

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
    _loadBoxes();
  }

  Future<void> _loadBoxes() async {
    final boxes = await getShownBoxUsecase.call(screen: 0);
    shownBoxesList.assignAll(
      boxes.where((b) => b.currency == 'شيكل').toList(),
    );
  }

  Future<void> pickReceiptImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked == null || picked.isEmpty) return;
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
              balanceAfter: createResult.balance,
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
