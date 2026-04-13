import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
import '../models/all_boxes_logs_model.dart';
import '../models/box_details_model.dart';
import '../models/get_shown_boxes_model.dart';

class BoxesDatasource {
  final ApiConsumer api;

  BoxesDatasource({required this.api});

  Map<String, dynamic> _unwrapResponse(dynamic raw) {
    final root = asMap(raw);
    final data = root['data'];
    if (data is Map) {
      final merged = Map<String, dynamic>.from(asMap(data));
      if (root.containsKey('status')) merged['status'] = root['status'];
      if (root.containsKey('message')) merged['message'] = root['message'];
      return merged;
    }
    return root;
  }

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
  Future<List<ShownBoxesModel>> getShownBoxes({required int screen}) async {
    try {
      final response = await api.get(
        screen == 0
            ? EndPoints.getShownBoxes
            : screen == 2
                ? EndPoints.getHiddenBoxes
                : EndPoints.getHiddenBoxes,
      );
      final raw = response.data;
      if (kDebugMode) {
        debugParseLog(
          'BoxesDatasource.getShownBoxes',
          'endpoint screen=$screen rawKeys=${asMap(raw).keys.toList()}',
        );
        final sample = extractMapListFromResponse(raw, 'boxes');
        if (sample.isNotEmpty) {
          debugParseLog(
            'BoxesDatasource.getShownBoxes',
            'sampleShownBox=${sample.first}',
          );
        }
      }
      return mapListFromResponseKey(
        raw,
        'boxes',
        (Map<String, dynamic> m) => ShownBoxesModel.fromJson(m),
        debugScope: 'BoxesDatasource.getShownBoxes',
      );
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
      final raw = response.data;
      if (kDebugMode) {
        debugParseLog(
          'BoxesDatasource.getAllBoxesLogs',
          'rawKeys=${asMap(raw).keys.toList()}',
        );
        final sample = extractMapListFromResponse(raw, 'box_logs');
        if (sample.isNotEmpty) {
          debugParseLog(
            'BoxesDatasource.getAllBoxesLogs',
            'sampleLog=${sample.first}',
          );
        }
      }
      return mapListFromResponseKey(
        raw,
        'box_logs',
        (Map<String, dynamic> m) => BoxLogModel.fromJson(m),
        debugScope: 'BoxesDatasource.getAllBoxesLogs',
      );
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
      final raw = response.data;
      final root = _unwrapResponse(raw);
      if (kDebugMode) {
        debugParseLog(
          'BoxesDatasource.boxDetails',
          'endpoint=${EndPoints.showBox} keys=${root.keys.toList()}',
        );
      }
      dynamic details = root['box details'];
      details ??= asMap(raw)['box details'];
      final detailsMap = asMap(details);
      if (kDebugMode && detailsMap.isNotEmpty) {
        debugParseLog(
          'BoxesDatasource.boxDetails',
          'sampleFields=${detailsMap.map((k, v) => MapEntry(k, v.runtimeType))}',
        );
      }
      return BoxDetailsModel.fromJson(detailsMap);
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
      final response = await api
          .post(name.isEmpty ? EndPoints.deleteBox : EndPoints.editBox, data: {
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
