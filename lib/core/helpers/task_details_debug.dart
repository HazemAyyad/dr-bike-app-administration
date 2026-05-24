import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../databases/api/end_points.dart';

/// Debug logs for employee task details API (visible in `flutter run` console).
class TaskDetailsDebug {
  static const _tag = '[TaskDetails]';

  static void tap({
    required String source,
    required String taskId,
    String? occurrenceId,
    String? taskName,
    String? status,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '$_tag TAP | source=$source | taskId=$taskId | '
      'occurrenceId=${occurrenceId ?? '-'} | name=${taskName ?? '-'} | '
      'status=${status ?? '-'}',
    );
  }

  static void request({
    required String taskId,
    String? occurrenceId,
  }) {
    if (!kDebugMode) return;
    final body = <String, dynamic>{};
    if (occurrenceId != null && occurrenceId.isNotEmpty) {
      body['occurrence_id'] = occurrenceId;
    } else if (taskId.isNotEmpty) {
      body['employee_task_id'] = taskId;
    }
    debugPrint(
      '$_tag REQUEST | POST ${EndPoints.baserUrl}${EndPoints.showEmployeeTask} | '
      'body=${jsonEncode(body)}',
    );
  }

  static void httpResponse({
    required int? statusCode,
    required dynamic data,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '$_tag HTTP | statusCode=${statusCode ?? '-'} | '
      'payload=${_compactJson(data)}',
    );
  }

  static void apiResult({
    required dynamic result,
    String? taskId,
    String? occurrenceId,
  }) {
    if (!kDebugMode) return;
    if (result is! Map) {
      fail(
        'unexpected_response_type',
        detail: 'expected Map, got ${result.runtimeType}',
      );
      return;
    }

    final map = Map<String, dynamic>.from(result);
    final status = map['status']?.toString() ?? '-';
    final message = map['message']?.toString();
    final errors = map['errors'];

    if (status == 'error') {
      fail(
        'api_status_error',
        detail: {
          'message': message,
          'errors': errors,
          'taskId': taskId,
          'occurrenceId': occurrenceId,
        },
      );
      return;
    }

    final raw = map['employee_task'];
    if (raw is! Map) {
      fail(
        'missing_employee_task',
        detail: {
          'keys': map.keys.toList(),
          'message': message,
        },
      );
      return;
    }

    final task = Map<String, dynamic>.from(raw);
    success(
      id: task['id']?.toString(),
      taskId: task['task_id']?.toString() ?? taskId,
      occurrenceId: task['occurrence_id']?.toString() ?? occurrenceId,
      name: task['name']?.toString(),
      status: task['status']?.toString(),
      subTasksCount: task['sub_tasks'] is List
          ? (task['sub_tasks'] as List).length
          : 0,
    );
  }

  static void success({
    String? id,
    String? taskId,
    String? occurrenceId,
    String? name,
    String? status,
    int subTasksCount = 0,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '$_tag OK | id=$id | taskId=$taskId | occurrenceId=${occurrenceId ?? '-'} | '
      'name=${name ?? '-'} | status=${status ?? '-'} | subTasks=$subTasksCount',
    );
  }

  static void fail(String reason, {dynamic detail}) {
    if (!kDebugMode) return;
    debugPrint('$_tag FAIL | reason=$reason | detail=${_compactJson(detail)}');
  }

  static void parseError(Object error, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    debugPrint('$_tag PARSE_ERROR | $error');
    if (stackTrace != null) {
      debugPrint('$_tag STACK | $stackTrace');
    }
  }

  static void screen({
    required String phase,
    String? taskId,
    String? occurrenceId,
    String? note,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '$_tag SCREEN | phase=$phase | taskId=${taskId ?? '-'} | '
      'occurrenceId=${occurrenceId ?? '-'}${note != null ? ' | $note' : ''}',
    );
  }

  static String _compactJson(dynamic value, {int maxLen = 1200}) {
    if (value == null) return 'null';
    try {
      final text = jsonEncode(value);
      if (text.length <= maxLen) return text;
      return '${text.substring(0, maxLen)}…(${text.length} chars)';
    } catch (_) {
      return value.toString();
    }
  }
}
