import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../models/all_boxes_logs_model.dart';
import '../models/box_details_model.dart';
import '../models/get_shown_boxes_model.dart';

class BoxesDatasource {
  final ApiConsumer api;

  BoxesDatasource({required this.api});

  // add box
  Future<Map<String, dynamic>> addBox({
    required String name,
    required String total,
    required String currency,
  }) async {
    try {
      final response = await api.post(
        EndPoints.addBox,
        data: {
          'name': name,
          'total': total,
          'currency': currency,
        },
      );
      final data = response.data;
      return data;
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

  // get shown boxes
  Future<List<GetShownBoxesModel>> getShownBoxes({required int screen}) async {
    try {
      final response = await api.get(
        screen == 0
            ? EndPoints.getShownBoxes
            : screen == 2
                ? EndPoints.getHiddenBoxes
                : EndPoints.getHiddenBoxes,
      );
      final data = response.data['boxes'] as List;
      return data.map((e) => GetShownBoxesModel.fromJson(e)).toList();
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

  // get all boxes logs
  Future<List<BoxLogModel>> getAllBoxesLogs() async {
    try {
      final response = await api.get(EndPoints.getBoxLogs);
      final data = response.data['box_logs'] as List;
      return data.map((e) => BoxLogModel.fromJson(e)).toList();
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

  // hide box
  Future<Map<String, dynamic>> transferBoxBalance({
    required String fromBoxId,
    required String toBoxId,
    required String total,
  }) async {
    try {
      final response = await api.post(EndPoints.transferBoxBalance, data: {
        'from_box_id': fromBoxId,
        'to_box_id': toBoxId,
        'total': total
      });
      final data = response.data;
      return data;
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

  // box details
  Future<BoxDetailsModel> boxDetails({required String boxId}) async {
    try {
      final response =
          await api.post(EndPoints.showBox, data: {'box_id': boxId});
      final data = response.data['box details'];
      return BoxDetailsModel.fromJson(data as Map<String, dynamic>);
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

  // add box balance
  Future<Map<String, dynamic>> addBoxBalance(
      {required String boxId, required String total}) async {
    try {
      final response = await api.post(EndPoints.addBoxBalance,
          data: {'box_id': boxId, 'total': total});
      final data = response.data;
      return data;
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

  // edit box
  Future<Map<String, dynamic>> editBox({
    required String boxId,
    required String name,
    required String total,
    required String isShown,
    required String currency,
  }) async {
    try {
      final response = await api.post(EndPoints.editBox, data: {
        'box_id': boxId,
        'name': name,
        'total': total,
        'is_shown': isShown,
        'currency': currency,
      });
      final data = response.data;
      return data;
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
