import '../../../debts/data/models/debt_ledger_models.dart';
import '../repositories/general_data_list_repository.dart';

class GetContactCategoriesUseCase {
  final GeneralDataListRepository generalDataListRepository;

  GetContactCategoriesUseCase({required this.generalDataListRepository});

  Future<List<ContactCategory>> call() {
    return generalDataListRepository.getContactCategories();
  }
}
