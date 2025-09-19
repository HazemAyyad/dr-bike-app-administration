// ignore_for_file: depend_on_referenced_packages

import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../models/followup_modle.dart';

class FollowupDatasource {
  final ApiConsumer api;

  FollowupDatasource({required this.api});

  Future<List<FollowupModel>> getFollowup() async {
    try {
      final response = await api.get(EndPoints.getFollowups);
      final data = response.data['followups'] as List;
      return data.toList().map((e) => FollowupModel.fromJson(e)).toList();
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }
}
