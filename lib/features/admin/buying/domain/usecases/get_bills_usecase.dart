import '../repositories/bills_repository.dart';

class GetBillsUsecase {
  final BillsRepository billsRepository;

  GetBillsUsecase({required this.billsRepository});

  Future<dynamic> call({required String page}) {
    return billsRepository.getBills(page: page);
  }
}
