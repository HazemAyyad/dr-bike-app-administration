import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failure.dart';
import '../../repositories/financial_affairs_repository.dart';

class AddExpenseUsecase {
  final FinancialAffairsRepository financialAffairsRepository;

  AddExpenseUsecase({required this.financialAffairsRepository});

  Future<Either<Failure, String>> call({
    required String name,
    required String price,
    required String notes,
    required String boxId,
    required String expenseType,
    required String expenseDate,
    required List<File?> invoiceImage,
    required List<File?> media,
    void Function(double progress)? onUploadProgress,
    String? expenseId,
  }) {
    return financialAffairsRepository.addExpense(
      name: name,
      price: price,
      notes: notes,
      boxId: boxId,
      expenseType: expenseType,
      expenseDate: expenseDate,
      invoiceImage: invoiceImage,
      media: media,
      onUploadProgress: onUploadProgress,
      expenseId: expenseId,
    );
  }
}
