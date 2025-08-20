import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../models/employee_task_model.dart';

class EmployeeTasksDataSource {
  final ApiConsumer api;

  EmployeeTasksDataSource({required this.api});

  // create employee task
  Future<Map<String, dynamic>> creatEmployeeTasks({
    required String name,
    required String description,
    required String notes,
    required String employeeId,
    required String points,
    required DateTime startTime,
    required DateTime endTime,
    required String taskRecurrence,
    required List<String> taskRecurrenceTime,
    required RxList subEmployeeTasks,
    required String notShownForEmployee,
    required String isForcedToUploadImg,
    required XFile? adminImg,
    required File audio,
  }) async {
    try {
      final subEmployeeTasksMap = <String, dynamic>{};

      for (int i = 0; i < subEmployeeTasks.length; i++) {
        subEmployeeTasksMap['sub_employee_tasks[$i][name]'] =
            subEmployeeTasks[i]['subTaskName'];
        subEmployeeTasksMap['sub_employee_tasks[$i][admin_subtask__img]'] =
            await MultipartFile.fromFile(
          subEmployeeTasks[i]['subTaskImage'],
          filename: subEmployeeTasks[i]['subTaskImage'].split('/').last,
        );
        subEmployeeTasksMap['sub_employee_tasks[$i][description]'] =
            subEmployeeTasks[i]['subTaskdescription'];
        subEmployeeTasksMap['sub_employee_tasks[$i][is_forced_to_upload_img]'] =
            subEmployeeTasks[i]['imageIsRequired'] == true ? 1 : 0;
      }
      final response = await api.post(
        EndPoints.createEmployeeTask,
        data: {
          'name': name,
          'description': description,
          'notes': notes,
          'employee_id': employeeId,
          'points': points,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'task_recurrence': taskRecurrence,
          'task_recurrence_time[]': taskRecurrenceTime,
          ...subEmployeeTasksMap,
          if (adminImg != null)
            'admin_img': await MultipartFile.fromFile(
              adminImg.path,
              filename: adminImg.name,
            ),
          // if (employeeImg == null) 'employee_img': '',
          // if (documentImg != null && documentImg.path.contains('http://'))
          //   'document_img': documentImg.path,

          'audio': audio.path.isEmpty
              ? ''
              : await MultipartFile.fromFile(
                  audio.path,
                  filename: audio.path.split('/').last,
                  contentType: MediaType("audio", "x-m4a"), // ✅ السيرفر يقبله
                ),
        },
        isFormData: true,
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
          },
        ),
      );
      final data = response.data;
      print('Response data: $response');
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

  // get employee tasks
  Future<List<EmployeeTaskModel>> getEmployeeTasks({required int page}) async {
    try {
      final response = await api.get(
        page == 0
            ? EndPoints.getEmployeeTasks
            : page == 1
                ? EndPoints.getCompletedTasks
                : EndPoints.getCanceledTasks,
      );
      List<EmployeeTaskModel> tasks = (response.data[page == 0
              ? 'ongoing employee tasks'
              : page == 1
                  ? 'completed employee tasks'
                  : 'canceled employee tasks'] as List)
          .map((e) => EmployeeTaskModel.fromJson(e))
          .toList();
      return tasks;
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

  // create employee task
  Future<Map<String, dynamic>> cancelEmployeeTask({
    required String employeeTaskId,
    required bool cancelWithRepetition,
  }) async {
    try {
      final response = await api.post(
        cancelWithRepetition
            ? EndPoints.cancelEmployeeTaskWithRepetition
            : EndPoints.cancelEmployeeTask,
        data: {'employee_task_id': employeeTaskId},
      );
      final data = response.data;
      // print('Response data: $response');
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

  // get task details
  Future<dynamic> getTaskDetails({required String taskId}) async {
    try {
      final response = await api.post(
        EndPoints.showEmployeeTask,
        queryParameters: {'employee_task_id': taskId},
      );
      final data = response.data;
      // print('Response data: $response');
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
