import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/followup_repository.dart';

class AddNewFollowCustomerUsecase {
  final FollowupRepository followupRepository;

  AddNewFollowCustomerUsecase({required this.followupRepository});

  Future<Either<Failure, String>> call({
    required String name,
    required String type,
    required String phone,
    required String notes,
  }) {
    return followupRepository.addNewFollwCustomer(
      name: name,
      type: type,
      phone: phone,
      notes: notes,
    );
  }
}
