import '../../data/models/check_model.dart';
import '../repositories/checks_repository.dart';

class AllCustomersSellersUsecase {
  final ChecksRepository checksRepository;

  AllCustomersSellersUsecase({required this.checksRepository});

  Future<List<SellerModel>> call({required String endPoint}) {
    return checksRepository.allCustomersSellers(endPoint: endPoint);
  }
}
