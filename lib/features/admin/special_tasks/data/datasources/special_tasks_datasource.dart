import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../models/special_task_details_model.dart';
import '../models/special_task_model.dart';

class SpecialTasksDatasource {
  final ApiConsumer api;

  SpecialTasksDatasource({required this.api});

// get special tasks
  Future<List<SpecialTaskModel>> specialTasks({required String page}) async {
    try {
      final response = await api.get(
        page == '0'
            ? EndPoints.getOngoingSpecialTasks
            : page == '1'
                ? EndPoints.getNoDateSpecialTasks
                : EndPoints.getCompletedSpecialTasks,
      );
      List<SpecialTaskModel> specialTasks = (response.data[page == '0'
              ? ApiKey.ongoing_tasks
              : page == '1'
                  ? ApiKey.no_date_tasks
                  : ApiKey.completed_tasks] as List)
          .map((e) => SpecialTaskModel.fromJson(e))
          .toList();
      return specialTasks;
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

  // change special task to completed
  Future<Map<String, dynamic>> completedSpecialTasks(
      {required String specialTaskId}) async {
    try {
      final response = await api.post(
        EndPoints.changeSpecialTaskToCompleted,
        data: {'special_task_id': specialTaskId},
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

  // special task details
  Future<SpecialTaskDetailsModel> getSpecialTasksDetails(
      {required String specialTaskId}) async {
    try {
      final response = await api.post(
        EndPoints.showSpecialTask,
        data: {'special_task_id': specialTaskId},
      );
      return SpecialTaskDetailsModel.fromJson(
        response.data['special_task'],
        response.data['images_path_info'],
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

  // cancel special task
  Future<Map<String, dynamic>> cancelSpecialTask({
    required String specialTaskId,
    required bool repitition,
    required bool isTransfer,
    DateTime? endDate,
  }) async {
    try {
      final response = await api.post(
        repitition
            ? EndPoints.cancelSpecialTaskWithRepetition
            : isTransfer
                ? EndPoints.transferSpecialTask
                : EndPoints.cancelSpecialTask,
        data: {
          'special_task_id': specialTaskId,
          if (isTransfer) 'end_date': endDate
        },
        isFormData: true,
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
}
