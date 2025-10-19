import '../repositories/bills_repository.dart';

class GetBilltDetailsUsecase {
  final BillsRepository billsRepository;

  GetBilltDetailsUsecase({required this.billsRepository});

  Future<dynamic> call({required String billId, required bool isDownload}) {
    return billsRepository.getBillDetails(
      billId: billId,
      isDownload: isDownload,
    );
  }
}
