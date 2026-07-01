import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide MultipartFile;
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/databases/api/api_consumer.dart';
import '../../../../../../core/databases/api/end_points.dart';
import '../../../../../../core/errors/error_model.dart';
import '../../../../../../core/errors/expentions.dart';
import '../../../checks/data/datasources/checks_datasource.dart';
import '../../../../../core/helpers/audio_helper.dart';
import '../../../../../core/helpers/task_details_debug.dart';
import '../../../../../core/helpers/task_media_paths.dart';
import '../../presentation/helpers/recurrence_config_helper.dart';

bool _isAudioPath(String path) => isAudioMediaPath(path);

MediaType? _uploadContentType(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.m4a')) return MediaType('audio', 'mp4');
  if (lower.endsWith('.aac')) return MediaType('audio', 'aac');
  if (lower.endsWith('.mp3')) return MediaType('audio', 'mpeg');
  if (lower.endsWith('.wav')) return MediaType('audio', 'wav');
  if (lower.endsWith('.mp4') || lower.endsWith('.mov')) {
    return MediaType('video', 'mp4');
  }
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return MediaType('image', 'jpeg');
  }
  if (lower.endsWith('.png')) return MediaType('image', 'png');
  return null;
}

Future<MultipartFile> _multipartFromPath(String path) async {
  final filename = path.split(RegExp(r'[/\\]')).last;
  final type = _uploadContentType(path);
  return MultipartFile.fromFile(
    path,
    filename: filename,
    contentType: type,
  );
}

Future<void> _appendSubtaskAdminUploads({
  required Map<String, dynamic> target,
  required int subIndex,
  required List<String> localPaths,
  String? audioPath,
}) async {
  var fileIndex = 0;
  final seen = <String>{};

  Future<void> addPath(String path) async {
    if (path.isEmpty || seen.contains(path)) return;
    seen.add(path);
    final key = 'sub_employee_tasks[$subIndex][admin_subtask__img][$fileIndex]';
    if (_isAudioPath(path)) {
      target[key] = await _multipartFromPath(path);
    } else {
      final file = localFileIsVideo(path)
          ? XFile(path)
          : await compressImage(XFile(path));
      target[key] = await _multipartFromPath(file.path);
    }
    fileIndex++;
  }

  for (final path in localPaths) {
    await addPath(path);
  }

  if (audioPath != null &&
      audioPath.isNotEmpty &&
      !audioPath.startsWith('http')) {
    await addPath(audioPath);
  }
}

class CreateEmployeeTasksDatasource {
  final ApiConsumer api;

  CreateEmployeeTasksDatasource({required this.api});

  /// Laravel expects indexed keys (`employee_ids[0]`, …), not a single `employee_ids[]` array.
  static Map<String, dynamic> employeeIdsFormFields(List<String> ids) {
    final map = <String, dynamic>{};
    for (var i = 0; i < ids.length; i++) {
      map['employee_ids[$i]'] = ids[i];
    }
    return map;
  }

  // create employee task
  Future<Map<String, dynamic>> creatEmployeeTasks({
    required int employeeTaskId,
    required String name,
    required String description,
    required String notes,
    required String employeeId,
    List<String> employeeIds = const [],
    required String points,
    required DateTime startTime,
    required DateTime endTime,
    required String taskRecurrence,
    required List<String> taskRecurrenceTime,
    required RxList subEmployeeTasks,
    required String notShownForEmployee,
    required String isForcedToUploadImg,
    required String proofMediaType,
    required String requiresAdminReview,
    required List<File> adminImg,
    required File audio,
    String? priority,
    Map<String, dynamic>? recurrenceConfig,
    int? templateId,
    int? occurrenceId,
  }) async {
    try {
      final subEmployeeTasksMap = <String, dynamic>{};

      for (int i = 0; i < subEmployeeTasks.length; i++) {
        final task = subEmployeeTasks[i];
        final hasId = task['subTaskId'] != null;

        if (hasId) {
          subEmployeeTasksMap['sub_employee_tasks[$i][id]'] = task['subTaskId'];
        }
        subEmployeeTasksMap['sub_employee_tasks[$i][name]'] =
            task['subTaskName'] ?? '';
        subEmployeeTasksMap['sub_employee_tasks[$i][description]'] =
            task['subTaskdescription'] ?? '';
        subEmployeeTasksMap['sub_employee_tasks[$i][is_forced_to_upload_img]'] =
            task['imageIsRequired'] == true ? 1 : 0;
        subEmployeeTasksMap['sub_employee_tasks[$i][proof_media_type]'] =
            task['proofMediaType']?.toString() ?? 'none';
        subEmployeeTasksMap['sub_employee_tasks[$i][bonus_points]'] =
            task['bonusPoints'] ?? 0;

        // لا نرسل صور الشبكة عند التعديل — تبقى على السيرفر ما لم يُرفع ملف جديد
        final imgList = task['subTaskImage'];
        if (imgList != null) {
          final localPaths = <String>[];
          if (imgList is List) {
            for (final img in imgList) {
              final s = img.toString();
              if (s.isNotEmpty && !s.startsWith('http')) {
                localPaths.add(s);
              }
            }
          } else {
            final s = imgList.toString();
            if (s.isNotEmpty && !s.startsWith('http')) {
              localPaths.add(s);
            }
          }
          await _appendSubtaskAdminUploads(
            target: subEmployeeTasksMap,
            subIndex: i,
            localPaths: localPaths,
            audioPath: task['subTaskAudio']?.toString(),
          );
        } else {
          final audioPath = task['subTaskAudio']?.toString() ?? '';
          if (audioPath.isNotEmpty && !audioPath.startsWith('http')) {
            await _appendSubtaskAdminUploads(
              target: subEmployeeTasksMap,
              subIndex: i,
              localPaths: const [],
              audioPath: audioPath,
            );
          }
        }
      }
      final configMap = recurrenceConfig ?? <String, dynamic>{};
      final isEdit = employeeTaskId != 0;
      final useV2 = isEdit
          ? (templateId != null && templateId > 0)
          : taskRecurrence != 'noRepeat' && taskRecurrence.isNotEmpty;

      final subNames = <String>[];
      for (var i = 0; i < subEmployeeTasks.length; i++) {
        final t = subEmployeeTasks[i];
        if (t is Map && t['subTaskName'] != null) {
          subNames.add(t['subTaskName'].toString());
        }
      }

      TaskDetailsDebug.createTask(
        subtasksSent: subEmployeeTasks.length,
        subtaskNames: subNames,
        assigneeCount: employeeIds.length,
        useV2: useV2,
        response: 'pending…',
      );

      final endpoint =
          isEdit ? EndPoints.editEmployeeTask : EndPoints.createEmployeeTask;
      final requestData = <String, dynamic>{
        if (isEdit) 'employee_task_id': employeeTaskId,
        if (templateId != null && templateId > 0) 'template_id': templateId,
        if (occurrenceId != null && occurrenceId > 0)
          'occurrence_id': occurrenceId,
        'name': name,
        'description': description,
        'notes': notes,
        'employee_id': employeeId,
        ...employeeIdsFormFields(employeeIds),
        'points': points,
        if (priority != null && priority.isNotEmpty) 'priority': priority,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'task_recurrence': taskRecurrence,
        'task_recurrence_time[]': taskRecurrenceTime,
        if (useV2) 'use_v2_recurrence': '1',
        if (useV2) ...RecurrenceConfigHelper.flattenForRequest(configMap),
        ...subEmployeeTasksMap,
        'not_shown_for_employee': notShownForEmployee,
        'is_forced_to_upload_img': isForcedToUploadImg,
        'proof_media_type': proofMediaType,
        'requires_admin_review': requiresAdminReview,
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
        if (audio.path.isNotEmpty && await audio.exists())
          'audio': audio.path.startsWith('http')
              ? audio.path
              : await MultipartFile.fromFile(
                  audio.path,
                  filename: audio.path.split('/').last,
                  contentType: MediaType('audio', 'x-m4a'),
                ),
      };
      if (kDebugMode && isEdit) {
        debugPrint(
          '[EmployeeTaskEdit] REQUEST | POST $endpoint | '
          'payload=${TaskDetailsDebug.compactJson(_debugSafePayload(requestData), maxLen: 8000)}',
        );
      }
      final response = await api.post(
        endpoint,
        data: requestData,
        isFormData: true,
      );
      final data = response.data;
      if (kDebugMode && isEdit) {
        debugPrint(
          '[EmployeeTaskEdit] RESPONSE | statusCode=${response.statusCode ?? '-'} | '
          'payload=${TaskDetailsDebug.compactJson(data, maxLen: 8000)}',
        );
      }
      TaskDetailsDebug.createTask(
        subtasksSent: subEmployeeTasks.length,
        subtaskNames: subNames,
        assigneeCount: employeeIds.length,
        useV2: useV2,
        response: data,
      );
      return data;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (kDebugMode) {
        debugPrint(
          '[EmployeeTaskEdit] DIO_ERROR | statusCode=${e.response?.statusCode ?? '-'} | '
          'type=${e.type} | message=${e.message ?? '-'} | '
          'payload=${TaskDetailsDebug.compactJson(data, maxLen: 8000)}',
        );
      }
      final responseMap =
          data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      throw ServerException(
        ErrorModel(
          errorMessage: responseMap['message']?.toString() ??
              e.message ??
              'Unknown error',
          status: responseMap['status'] ?? e.response?.statusCode ?? 500,
          data: responseMap['data'] is Map
              ? Map<String, dynamic>.from(responseMap['data'])
              : responseMap['errors'] is Map
                  ? {
                      'message': responseMap['message'] ?? 'Validation failed',
                      'errors':
                          Map<String, dynamic>.from(responseMap['errors']),
                    }
                  : <String, dynamic>{},
        ),
      );
    }
  }

  Map<String, dynamic> _debugSafePayload(Map<String, dynamic> payload) {
    return payload.map(
      (key, value) => MapEntry(key, _debugSafeValue(value)),
    );
  }

  dynamic _debugSafeValue(dynamic value) {
    if (value is MultipartFile) {
      return '<file:${value.filename ?? 'unnamed'}>';
    }
    if (value is List) {
      return value.map(_debugSafeValue).toList();
    }
    if (value is Map) {
      return value.map(
        (key, nested) => MapEntry(key.toString(), _debugSafeValue(nested)),
      );
    }
    return value;
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
