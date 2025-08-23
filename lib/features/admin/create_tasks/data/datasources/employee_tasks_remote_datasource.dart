import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/databases/api/api_consumer.dart';
import '../../../../../../core/databases/api/end_points.dart';
import '../../../../../../core/errors/error_model.dart';
import '../../../../../../core/errors/expentions.dart';

class CreateEmployeeTasksDataSource {
  final ApiConsumer api;

  CreateEmployeeTasksDataSource({required this.api});

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
        subEmployeeTasks[i]['subTaskImage'] != null ||
                subEmployeeTasks[i]['subTaskImage'].path.startsWith('http')
            ? subEmployeeTasksMap[
                    'sub_employee_tasks[$i][admin_subtask__img[]]'] =
                subEmployeeTasks[i]['subTaskImage']
            : subEmployeeTasksMap[
                    'sub_employee_tasks[$i][admin_subtask__img[]]'] =
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
          'employee_task_id': 250,
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
          'not_shown_for_employee': notShownForEmployee,
          'is_forced_to_upload_img': isForcedToUploadImg,
          if (adminImg != null)
            'admin_img[]': adminImg.path.startsWith('http')
                ? adminImg
                : await MultipartFile.fromFile(
                    adminImg.path,
                    filename: adminImg.path.split('/').last,
                  ),
          'audio': audio.path.isEmpty
              ? ''
              : audio.path.startsWith('http')
                  ? audio.path
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

  // create special task
  Future<Map<String, dynamic>> creatSpecialTasks({
    required String name,
    required String description,
    required String notes,
    required DateTime startDate,
    required DateTime endDate,
    required String notShownForEmployee,
    required String taskRecurrence,
    required List<String> taskRecurrenceTime,
    required bool forceEmployeeToAddImg,
    required XFile? adminImg,
    required File audio,
    required RxList subSpecialTasks,
  }) async {
    try {
      final subSpecialTasksMap = <String, dynamic>{};

      for (int i = 0; i < subSpecialTasks.length; i++) {
        subSpecialTasksMap['sub_special_tasks[$i][name]'] =
            subSpecialTasks[i]['subTaskName'];
        subSpecialTasks[i]['subTaskImage'] != null
            ? subSpecialTasksMap['sub_special_tasks[$i][admin_subtask__img]'] =
                await MultipartFile.fromFile(
                subSpecialTasks[i]['subTaskImage'] ?? '',
                filename: subSpecialTasks[i]['subTaskImage'].split('/').last,
              )
            : subSpecialTasksMap['sub_special_tasks[$i][admin_subtask__img]'] =
                '';
        subSpecialTasksMap['sub_special_tasks[$i][description]'] =
            subSpecialTasks[i]['subTaskdescription'];
        subSpecialTasksMap[
                'sub_special_tasks[$i][force_employee_to_add_img_for_sub_task]'] =
            subSpecialTasks[i]['imageIsRequired'] == true ? 1 : 0;
      }
      final response = await api.post(
        EndPoints.createSpecialTask,
        data: {
          'name': name,
          'description': description,
          'notes': notes,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'not_shown_for_employee': notShownForEmployee,
          'task_recurrence': taskRecurrence,
          'task_recurrence_time[]': taskRecurrenceTime,
          ...subSpecialTasksMap,
          'force_employee_to_add_img': forceEmployeeToAddImg ? 1 : 0,
          if (adminImg != null)
            'admin_img': await MultipartFile.fromFile(
              adminImg.path,
              filename: adminImg.name,
            ),
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
