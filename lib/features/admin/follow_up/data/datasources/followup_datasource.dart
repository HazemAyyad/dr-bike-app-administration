import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../models/followup_modle.dart';

class FollowupDatasource {
  final ApiConsumer api;

  FollowupDatasource({required this.api});

  Future<List<FollowupModel>> getFollowup({required int page}) async {
    try {
      final response = await api.get(
          page == 0
              ? EndPoints.getInitialFollowups
              : page == 1
                  ? EndPoints.getInformPersonFollowups
                  : page == 2
                      ? EndPoints.getFinishAndAgreementFollowups
                      : EndPoints.getArchivedFollowups,
          queryParameters: {'page': page});
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

  // get all followups
  Future<Map<String, dynamic>> addAndUpdateFollowup({
    required String followupId,
    required String customerId,
    required String sellerId,
    required String productId,
    required String status,
  }) async {
    try {
      final response = await api.post(
          followupId.isNotEmpty
              ? EndPoints.updateFollowup
              : EndPoints.addFollowup,
          data: {
            if (followupId.isNotEmpty) 'followup_id': followupId,
            if (customerId.isNotEmpty) 'customer_id': customerId,
            if (sellerId.isNotEmpty) 'seller_id': sellerId,
            'product_id': productId,
            if (status.isNotEmpty) 'status': status
          });
      return response.data;
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

  // get followup Details
  Future<Map<String, dynamic>> getfollowupDetailsAndCancel({
    required String followupId,
    required bool isCancel,
  }) async {
    try {
      final response = await api.post(
          isCancel ? EndPoints.cancelFollowup : EndPoints.showFollowup,
          data: {'followup_id': followupId});
      return response.data;
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

  // add New Follw Customer
  Future<Map<String, dynamic>> addNewFollwCustomer({
    required String name,
    required String type,
    required String phone,
    required String notes,
  }) async {
    try {
      final response = await api.post(EndPoints.storeCustomer, data: {
        'name': name,
        'type': type,
        'phone': phone,
        'notes': notes,
      });
      return response.data;
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
