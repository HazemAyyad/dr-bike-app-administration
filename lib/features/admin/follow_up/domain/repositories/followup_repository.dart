import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/followup_modle.dart';

abstract class FollowupRepository {
  Future<List<FollowupModel>> getFollowup({required int page});

  Future<Either<Failure, String>> addAndUpdateFollowup({
    required String followupId,
    required String customerId,
    required String sellerId,
    required String productId,
    required String status,
  });

  Future<dynamic> getfollowupDetailsAndCancel({
    required String followupId,
    required bool isCancel,
  });

  Future<Either<Failure, String>> addNewFollwCustomer({
    required String name,
    required String type,
    required String phone,
    required String notes,
  });
}
