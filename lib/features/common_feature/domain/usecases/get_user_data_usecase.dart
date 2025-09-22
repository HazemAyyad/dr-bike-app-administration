import '../../../auth/data/models/user_model.dart';
import '../repositories/common_repositorie.dart';

class GetUserDataUsecase {
  final CommonRepository commonRepository;
  GetUserDataUsecase({required this.commonRepository});

  Future<UserModel> call() {
    return commonRepository.getUserData();
  }
}
