import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/debt_ledger_models.dart';

abstract class DebtLedgerRepository {
  Future<Either<Failure, LedgerSummary>> getSummary();
  Future<Either<Failure, List<LedgerPerson>>> getPeople({
    required String type,
    String? search,
    String? startDate,
    String? endDate,
    String? currency,
    int? categoryId,
  });
  Future<Either<Failure, List<ContactCategory>>> getCategories();
  Future<Either<Failure, void>> saveCategory({
    int? id,
    required String name,
    required String color,
    List<int> customerIds,
    List<int> sellerIds,
  });
  Future<Either<Failure, void>> deleteCategory(int id);
  Future<Either<Failure, List<LedgerPerson>>> getPeoplePicker({
    required String type,
    String? search,
  });
  Future<Either<Failure, String>> createPersonShareLink({
    int? customerId,
    int? sellerId,
  });
  Future<Either<Failure, LedgerPersonInfo>> updatePersonMeta({
    int? customerId,
    int? sellerId,
    String? notes,
    String? collectionReminderAt,
    bool clearCollectionReminder = false,
    bool updateNotes = false,
    bool updateReminder = false,
  });
  Future<Either<Failure, LedgerPersonDetail>> getPerson({
    int? customerId,
    int? sellerId,
    String? startDate,
    String? endDate,
    String? currency,
  });
  Future<Either<Failure, LedgerCreateResult>> createTransaction({
    int? customerId,
    int? sellerId,
    required String type,
    required String amount,
    required String transactionDate,
    String? currency,
    String? note,
    String? boxId,
    List<File>? receiptImages,
  });
  Future<Either<Failure, LedgerTransaction>> getTransaction(int id);
  Future<Either<Failure, LedgerTransaction>> updateTransaction({
    required int id,
    required String type,
    required String amount,
    required String transactionDate,
    String? currency,
    String? note,
    String? boxId,
    List<File>? receiptImages,
  });
  Future<Either<Failure, void>> archiveTransaction(int id);
  Future<Either<Failure, void>> deleteTransaction(int id);
  Future<Either<Failure, LedgerPersonArchiveDetail>> getPersonArchive({
    int? customerId,
    int? sellerId,
    String? currency,
  });
  Future<Either<Failure, LedgerPersonArchiveDetail>> getPersonDeleted({
    int? customerId,
    int? sellerId,
    String? currency,
  });
  Future<Either<Failure, void>> archiveTransactionsBulk(
      List<int> transactionIds);
  Future<Either<Failure, void>> restoreTransactionsBulk(
      List<int> transactionIds);
  Future<Either<Failure, Uint8List>> downloadReport({
    int? customerId,
    int? sellerId,
    String? period,
    String? startDate,
    String? endDate,
    String? currency,
  });
  Future<Either<Failure, LedgerReportData>> generateReportJson({
    int? customerId,
    int? sellerId,
    String? period,
    String? startDate,
    String? endDate,
    String? currency,
  });
  Future<Either<Failure, List<LedgerActivityEntry>>> getTransactionActivity(
    int transactionId,
  );
  Future<Either<Failure, List<LedgerActivityEntry>>> getPersonActivity({
    int? customerId,
    int? sellerId,
    String? currency,
  });
}
