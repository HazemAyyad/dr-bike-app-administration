import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/followup_repository.dart';
import '../datasources/followup_datasource.dart';
import '../models/followup_modle.dart';

class FollowupImplement implements FollowupRepository {
  final NetworkInfo networkInfo;
  final FollowupDatasource followupDataSource;

  FollowupImplement(
      {required this.networkInfo, required this.followupDataSource});

  @override
  Future<List<FollowupModel>> getFollowup() async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await followupDataSource.getFollowup();
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }
}
