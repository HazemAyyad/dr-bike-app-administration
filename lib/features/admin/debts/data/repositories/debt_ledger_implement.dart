import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../data/datasources/debt_ledger_datasource.dart';
import '../../data/models/debt_ledger_models.dart';
import '../../domain/repositories/debt_ledger_repository.dart';

class DebtLedgerImplement implements DebtLedgerRepository {
  final NetworkInfo networkInfo;
  final DebtLedgerDatasource datasource;

  DebtLedgerImplement({
    required this.networkInfo,
    required this.datasource,
  });

  @override
  Future<Either<Failure, LedgerSummary>> getSummary() async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.getSummary();
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return Right(LedgerSummary.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, List<LedgerPerson>>> getPeople({
    required String type,
    String? search,
    String? startDate,
    String? endDate,
    String? currency,
    int? categoryId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.getPeople(
        type: type,
        search: search,
        startDate: startDate,
        endDate: endDate,
        currency: currency,
        categoryId: categoryId,
      );
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      final people = (data['people'] as List<dynamic>? ?? [])
          .map((e) => LedgerPerson.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(people);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, List<ContactCategory>>> getCategories() async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.getCategories();
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      final categories = (data['categories'] as List<dynamic>? ?? [])
          .map((e) => ContactCategory.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(categories);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, void>> saveCategory({
    int? id,
    required String name,
    required String color,
    List<int> customerIds = const [],
    List<int> sellerIds = const [],
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.saveCategory(
        id: id,
        name: name,
        color: color,
        customerIds: customerIds,
        sellerIds: sellerIds,
      );
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(int id) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.deleteCategory(id);
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, List<LedgerPerson>>> getPeoplePicker({
    required String type,
    String? search,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.getPeoplePicker(
        type: type,
        search: search,
      );
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      final people = (data['people'] as List<dynamic>? ?? [])
          .map((e) => LedgerPerson.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(people);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, String>> createPersonShareLink({
    int? customerId,
    int? sellerId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.createPersonShareLink(
        customerId: customerId,
        sellerId: sellerId,
      );
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return Right(data['share_url']?.toString() ?? '');
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, LedgerPersonInfo>> updatePersonMeta({
    int? customerId,
    int? sellerId,
    String? notes,
    String? collectionReminderAt,
    bool clearCollectionReminder = false,
    bool updateNotes = false,
    bool updateReminder = false,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.updatePersonMeta(
        customerId: customerId,
        sellerId: sellerId,
        notes: notes,
        collectionReminderAt: collectionReminderAt,
        clearCollectionReminder: clearCollectionReminder,
        updateNotes: updateNotes,
        updateReminder: updateReminder,
      );
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return Right(
          LedgerPersonInfo.fromJson(data['person'] as Map<String, dynamic>));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, LedgerPersonDetail>> getPerson({
    int? customerId,
    int? sellerId,
    String? startDate,
    String? endDate,
    String? currency,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.getPerson(
        customerId: customerId,
        sellerId: sellerId,
        startDate: startDate,
        endDate: endDate,
        currency: currency,
      );
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return Right(LedgerPersonDetail.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
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
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.createTransaction(
        customerId: customerId,
        sellerId: sellerId,
        type: type,
        amount: amount,
        transactionDate: transactionDate,
        currency: currency,
        note: note,
        boxId: boxId,
        receiptImages: receiptImages,
      );
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return Right(LedgerCreateResult.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, LedgerTransaction>> getTransaction(int id) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.getTransaction(id);
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return Right(LedgerTransaction.fromJson(
          data['transaction'] as Map<String, dynamic>));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, LedgerTransaction>> updateTransaction({
    required int id,
    required String type,
    required String amount,
    required String transactionDate,
    String? currency,
    String? note,
    String? boxId,
    List<File>? receiptImages,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.updateTransaction(
        id: id,
        type: type,
        amount: amount,
        transactionDate: transactionDate,
        currency: currency,
        note: note,
        boxId: boxId,
        receiptImages: receiptImages,
      );
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return Right(LedgerTransaction.fromJson(
          data['transaction'] as Map<String, dynamic>));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, LedgerPersonArchiveDetail>> getPersonArchive({
    int? customerId,
    int? sellerId,
    String? currency,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.getPersonArchive(
        customerId: customerId,
        sellerId: sellerId,
        currency: currency,
      );
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return Right(LedgerPersonArchiveDetail.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, LedgerPersonArchiveDetail>> getPersonDeleted({
    int? customerId,
    int? sellerId,
    String? currency,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.getPersonDeleted(
        customerId: customerId,
        sellerId: sellerId,
        currency: currency,
      );
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return Right(LedgerPersonArchiveDetail.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, void>> archiveTransactionsBulk(
    List<int> transactionIds,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.archiveTransactionsBulk(transactionIds);
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, void>> restoreTransactionsBulk(
    List<int> transactionIds,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.restoreTransactionsBulk(transactionIds);
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, void>> archiveTransaction(int id) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.archiveTransaction(id);
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(int id) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.deleteTransaction(id);
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> downloadReport({
    int? customerId,
    int? sellerId,
    String? period,
    String? startDate,
    String? endDate,
    String? currency,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final bytes = await datasource.downloadReport(
        customerId: customerId,
        sellerId: sellerId,
        period: period,
        startDate: startDate,
        endDate: endDate,
        currency: currency,
      );
      return Right(bytes);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, LedgerReportData>> generateReportJson({
    int? customerId,
    int? sellerId,
    String? period,
    String? startDate,
    String? endDate,
    String? currency,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.generateReportJson(
        customerId: customerId,
        sellerId: sellerId,
        period: period,
        startDate: startDate,
        endDate: endDate,
        currency: currency,
      );
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return Right(LedgerReportData.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  List<LedgerActivityEntry> _parseActivityList(Map<String, dynamic> data) {
    final list = data['activity'] as List<dynamic>? ?? [];
    return list
        .map((e) => LedgerActivityEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Either<Failure, List<LedgerActivityEntry>>> getTransactionActivity(
    int transactionId,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.getTransactionActivity(transactionId);
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return Right(_parseActivityList(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }

  @override
  Future<Either<Failure, List<LedgerActivityEntry>>> getPersonActivity({
    int? customerId,
    int? sellerId,
    String? currency,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final data = await datasource.getPersonActivity(
        customerId: customerId,
        sellerId: sellerId,
        currency: currency,
      );
      if (data['status'] != 'success') {
        return Left(ServerFailure(
            data['message']?.toString() ?? 'error', data['data'] ?? {}));
      }
      return Right(_parseActivityList(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }
}
