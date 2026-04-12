import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile;
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../checks/data/datasources/checks_datasource.dart';
import '../models/employee_task_model.dart';

class EmployeeTasksDatasource {
  final ApiConsumer api;

  EmployeeTasksDatasource({required this.api});

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
        final compressedImg =
            await compressImage(XFile(subEmployeeTasks[i]['subTaskImage']));
        subEmployeeTasksMap['sub_employee_tasks[$i][admin_subtask__img]'] =
            await MultipartFile.fromFile(
          compressedImg.path,
          filename: compressedImg.path.split('/').last,
        );
        subEmployeeTasksMap['sub_employee_tasks[$i][description]'] =
            subEmployeeTasks[i]['subTaskdescription'];
        subEmployeeTasksMap['sub_employee_tasks[$i][is_forced_to_upload_img]'] =
            subEmployeeTasks[i]['imageIsRequired'] == true ? 1 : 0;
      }
      XFile? compressedImg;
      if (adminImg != null) {
        compressedImg = await compressImage(XFile(adminImg.path));
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
          if (compressedImg != null)
            'admin_img': await MultipartFile.fromFile(
              compressedImg.path,
              filename: compressedImg.path.split('/').last,
            ),
          // if (employeeImg == null) 'employee_img': '',
          // if (documentImg != null && documentImg.path.contains('http://'))
          //   'document_img': documentImg.path,

          'audio': audio.path.isEmpty
              ? ''
              : await MultipartFile.fromFile(
                  audio.path,
                  filename: audio.path.split('/').last,
                  contentType: MediaType("audio", "x-m4a"),
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
      final raw = response.data;
      if (raw is! Map) {
        debugParseLog(
          'EmployeeTasksDS',
          'getEmployeeTasks: expected Map, got ${raw.runtimeType}',
        );
        return [];
      }
      final map = Map<String, dynamic>.from(raw);
      final key = page == 0
          ? 'ongoing employee tasks'
          : page == 1
              ? 'completed employee tasks'
              : 'canceled employee tasks';
      final listRaw = map[key];
      if (listRaw == null) {
        debugParseLog(
          'EmployeeTasksDS',
          'getEmployeeTasks: missing "$key", keys=${map.keys.toList()}',
        );
        return [];
      }
      return mapList(
        listRaw,
        (Map<String, dynamic> m) => EmployeeTaskModel.fromJson(m),
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

  // create employee task
  Future<Map<String, dynamic>> cancelEmployeeTask({
    required String employeeTaskId,
    required bool cancelWithRepetition,
    required bool isCompleted,
  }) async {
    try {
      final response = await api.post(
        cancelWithRepetition
            ? EndPoints.cancelEmployeeTaskWithRepetition
            : isCompleted
                ? EndPoints.changeEmployeeTaskToCompleted
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

  // uplode task image
  Future<dynamic> uplodeTaskImage({
    required bool isSubTask,
    required String taskId,
    required List<File> image,
  }) async {
    try {
      final subEmployeeTasksMap = <String, dynamic>{};
      subEmployeeTasksMap['employee_img[]'] = await Future.wait(
        image.map((e) async {
          final compressedImg = await compressImage(XFile(e.path));
          return await MultipartFile.fromFile(
            compressedImg.path,
            filename: compressedImg.path.split('/').last,
          );
        }),
      );
      final response = await api.post(
        isSubTask
            ? EndPoints.editEmployeeSubTaskImages
            : EndPoints.editEmployeeTaskImages,
        data: {
          if (isSubTask) 'sub_employee_task_id': taskId,
          if (!isSubTask) 'employee_task_id': taskId,
          ...subEmployeeTasksMap,
        },
        isFormData: true,
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
