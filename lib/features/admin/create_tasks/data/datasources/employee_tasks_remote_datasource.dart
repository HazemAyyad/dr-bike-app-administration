import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile;
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/databases/api/api_consumer.dart';
import '../../../../../../core/databases/api/end_points.dart';
import '../../../../../../core/errors/error_model.dart';
import '../../../../../../core/errors/expentions.dart';
import '../../../checks/data/datasources/checks_datasource.dart';

class CreateEmployeeTasksDatasource {
  final ApiConsumer api;

  CreateEmployeeTasksDatasource({required this.api});

  // create employee task
  Future<Map<String, dynamic>> creatEmployeeTasks({
    required int employeeTaskId,
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
    required List<File> adminImg,
    required File audio,
  }) async {
    try {
      final subEmployeeTasksMap = <String, dynamic>{};

      for (int i = 0; i < subEmployeeTasks.length; i++) {
        if (subEmployeeTasks[i]['subTaskId'] != null) {
          subEmployeeTasksMap['sub_employee_tasks[$i][id]'] =
              subEmployeeTasks[i]['subTaskId'];
        } else {
          // الاسم
          subEmployeeTasksMap['sub_employee_tasks[$i][name]'] =
              subEmployeeTasks[i]['subTaskName'];
          // الصور
          final imgList = subEmployeeTasks[i]['subTaskImage'];
          if (imgList != null) {
            if (imgList is List) {
              for (var img in imgList) {
                if (img.toString().startsWith('http')) {
                  subEmployeeTasksMap[
                      'sub_employee_tasks[$i][admin_subtask__img][]'] = img;
                } else {
                  final compressedImg = await compressImage(XFile(img));
                  subEmployeeTasksMap[
                          'sub_employee_tasks[$i][admin_subtask__img][]'] =
                      await MultipartFile.fromFile(
                    compressedImg.path,
                    filename: compressedImg.path.split('/').last,
                  );
                }
              }
            } else {
              // حالة صورة واحدة فقط
              if (imgList.toString().contains('http')) {
                subEmployeeTasksMap[
                    'sub_employee_tasks[$i][admin_subtask__img][]'] = imgList;
              } else {
                final compressedImg = await compressImage(XFile(imgList));
                subEmployeeTasksMap[
                        'sub_employee_tasks[$i][admin_subtask__img][]'] =
                    await MultipartFile.fromFile(
                  compressedImg.path,
                  filename: compressedImg.path.split('/').last,
                );
              }
            }
          }
          // الوصف
          subEmployeeTasksMap['sub_employee_tasks[$i][description]'] =
              subEmployeeTasks[i]['subTaskdescription'];
          // مطلوب صورة أو لا
          subEmployeeTasksMap[
                  'sub_employee_tasks[$i][is_forced_to_upload_img]'] =
              subEmployeeTasks[i]['imageIsRequired'] == true ? 1 : 0;
        }
      }
      final response = await api.post(
        employeeTaskId != 0
            ? EndPoints.editEmployeeTask
            : EndPoints.createEmployeeTask,
        data: {
          if (employeeTaskId != 0) 'employee_task_id': employeeTaskId,
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
          if (adminImg.isNotEmpty)
            'admin_img[]': await Future.wait(
              adminImg.map((e) async {
                if (e.path.startsWith('http')) {
                  return e.path;
                } else {
                  final compressedImg = await compressImage(XFile(e.path));
                  return await MultipartFile.fromFile(
                    compressedImg.path,
                    filename: compressedImg.path.split('/').last,
                  );
                }
              }),
            ),
          if (audio.path.isNotEmpty)
            'audio': audio.path.startsWith('http')
                ? audio.path
                : await MultipartFile.fromFile(
                    audio.path,
                    filename: audio.path.split('/').last,
                    contentType: MediaType("audio", "x-m4a"),
                  ),
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
    required List<File> adminImg,
    required File audio,
    required RxList subSpecialTasks,
    required int specialTaskId,
  }) async {
    try {
      final subSpecialTasksMap = <String, dynamic>{};
      for (int i = 0; i < subSpecialTasks.length; i++) {
        if (subSpecialTasks[i]['subTaskId'] != null) {
          subSpecialTasksMap['sub_special_tasks[$i][id]'] =
              subSpecialTasks[i]['subTaskId'];
        } else {
          subSpecialTasksMap['sub_special_tasks[$i][name]'] =
              subSpecialTasks[i]['subTaskName'];
          if (subSpecialTasks[i]['subTaskImage'] != null) {
            final compressedImg =
                await compressImage(XFile(subSpecialTasks[i]['subTaskImage']));
            if (specialTaskId == 0) {
              subSpecialTasksMap[
                      'sub_special_tasks[$i][admin_subtask__img][]'] =
                  await MultipartFile.fromFile(
                compressedImg.path,
                filename: compressedImg.path.split('/').last,
              );
            } else {
              subSpecialTasksMap['sub_special_tasks[$i][admin_subtask_img][]'] =
                  await MultipartFile.fromFile(
                compressedImg.path,
                filename: compressedImg.path.split('/').last,
              );
            }
          }
          subSpecialTasksMap['sub_special_tasks[$i][description]'] =
              subSpecialTasks[i]['subTaskdescription'];
          subSpecialTasksMap[
                  'sub_special_tasks[$i][force_employee_to_add_img_for_sub_task]'] =
              subSpecialTasks[i]['imageIsRequired'] == true ? 1 : 0;
        }
      }
      final response = await api.post(
        specialTaskId != 0
            ? EndPoints.updateSpecialTask
            : EndPoints.createSpecialTask,
        data: {
          if (specialTaskId != 0) 'special_task_id': specialTaskId,
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
          if (adminImg.isNotEmpty)
            'admin_img[]': await Future.wait(
              adminImg.map((e) async {
                if (e.path.startsWith('http')) {
                  return e.path;
                } else {
                  final compressedImg = await compressImage(XFile(e.path));
                  return await MultipartFile.fromFile(
                    compressedImg.path,
                    filename: compressedImg.path.split('/').last,
                  );
                }
              }),
            ),
          if (audio.path.isNotEmpty)
            'audio': audio.path.startsWith('http')
                ? audio.path
                : await MultipartFile.fromFile(
                    audio.path,
                    filename: audio.path.split('/').last,
                    contentType: MediaType("audio", "x-m4a"),
                  )
          else
            'audio': '',
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
