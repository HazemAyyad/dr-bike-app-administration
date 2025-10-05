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
    required List<File?> invoiceImage,
    required List<File?> media,
    String? expenseId,
  }) {
    return financialAffairsRepository.addExpense(
      name: name,
      price: price,
      notes: notes,
      boxId: boxId,
      invoiceImage: invoiceImage,
      media: media,
      expenseId: expenseId,
    );
  }
}
