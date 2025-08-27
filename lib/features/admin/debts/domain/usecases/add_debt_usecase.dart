import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/debts_repositories.dart';

class AddDebtUsecase {
  final DebtsRepository debtsRepository;

  AddDebtUsecase({required this.debtsRepository});

  Future<Either<Failure, String>> call({
    required String customerId,
    required String type,
    required String dueDate,
    required String total,
    required List<File> receiptImage,
    required String notes,
  }) {
    return debtsRepository.addDebt(
      customerId: customerId,
      type: type,
      dueDate: dueDate,
      total: total,
      receiptImage: receiptImage,
      notes: notes,
    );
  }
}
