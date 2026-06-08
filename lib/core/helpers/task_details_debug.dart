import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../databases/api/end_points.dart';

/// Trace for one task-details load (console + on-screen debug panel).
class TaskDetailsLoadTrace {
  TaskDetailsLoadTrace({
    required this.phase,
    required this.at,
    this.listTaskId,
    this.listOccurrenceId,
    this.listSource,
    this.listTaskName,
    this.resolvedTaskId,
    this.resolvedOccurrenceId,
    this.requestBody,
    this.httpStatusCode,
    this.apiStatus,
    this.apiMessage,
    this.loadedTaskId,
    this.loadedOccurrenceId,
    this.loadedName,
    this.loadedSource,
    this.subTasks = const [],
    this.extra,
  });

  final String phase;
  final DateTime at;
  final String? listTaskId;
  final String? listOccurrenceId;
  final String? listSource;
  final String? listTaskName;
  final String? resolvedTaskId;
  final String? resolvedOccurrenceId;
  final Map<String, dynamic>? requestBody;
  final int? httpStatusCode;
  final String? apiStatus;
  final String? apiMessage;
  final String? loadedTaskId;
  final String? loadedOccurrenceId;
  final String? loadedName;
  final String? loadedSource;
  final List<Map<String, String>> subTasks;
  final Map<String, dynamic>? extra;

  List<String> toLogLines() {
    final lines = <String>[
      '[$phase @ ${at.toIso8601String()}]',
      if (listTaskId != null)
        'LIST → taskId=$listTaskId occ=${listOccurrenceId ?? "-"} source=${listSource ?? "-"} name=${listTaskName ?? "-"}',
      if (resolvedTaskId != null)
        'RESOLVED → taskId=$resolvedTaskId occ=${resolvedOccurrenceId ?? "-"}',
      if (requestBody != null) 'REQUEST → ${jsonEncode(requestBody)}',
      if (httpStatusCode != null)
        'HTTP → $httpStatusCode status=$apiStatus msg=${apiMessage ?? "-"}',
      if (loadedTaskId != null)
        'LOADED → id=$loadedTaskId task_id field | occ=${loadedOccurrenceId ?? "-"} source=${loadedSource ?? "-"} name=${loadedName ?? "-"}',
      'SUBTASKS (${subTasks.length}):',
    ];
    if (subTasks.isEmpty) {
      lines.add('  (none)');
    } else {
      for (var i = 0; i < subTasks.length; i++) {
        final s = subTasks[i];
        lines.add(
          '  ${i + 1}. id=${s['id'] ?? '?'} name=${s['name'] ?? '?'} status=${s['status'] ?? '-'}',
        );
      }
    }
    if (extra != null && extra!.isNotEmpty) {
      lines.add('EXTRA → ${TaskDetailsDebug.compactJson(extra)}');
    }
    return lines;
  }
}

/// Debug logs for employee task details (console + [TaskDetailsDebugPanel]).
class TaskDetailsDebug {
  static const _tag = '[TaskDetails]';

  static final List<TaskDetailsLoadTrace> traces = <TaskDetailsLoadTrace>[];
  static const int maxTraces = 12;

  static void _push(TaskDetailsLoadTrace trace) {
    if (!kDebugMode) return;
    traces.insert(0, trace);
    while (traces.length > maxTraces) {
      traces.removeLast();
    }
    for (final line in trace.toLogLines()) {
      debugPrint('$_tag $line');
    }
  }

  static void clearTraces() {
    if (!kDebugMode) return;
    traces.clear();
  }

  static Map<String, dynamic> buildRequestBody({
    required String taskId,
    String? occurrenceId,
  }) {
    final body = <String, dynamic>{};
    if (occurrenceId != null && occurrenceId.isNotEmpty) {
      body['occurrence_id'] = occurrenceId;
    } else if (taskId.isNotEmpty) {
      body['employee_task_id'] = taskId;
    }
    return body;
  }

  static void tap({
    required String source,
    required String taskId,
    String? occurrenceId,
    String? taskName,
    String? status,
    String? listSource,
    String? resolvedTaskId,
    String? resolvedOccurrenceId,
  }) {
    if (!kDebugMode) return;
    _push(
      TaskDetailsLoadTrace(
        phase: 'TAP/$source',
        at: DateTime.now(),
        listTaskId: taskId,
        listOccurrenceId: occurrenceId,
        listSource: listSource,
        listTaskName: taskName,
        resolvedTaskId: resolvedTaskId ?? taskId,
        resolvedOccurrenceId: resolvedOccurrenceId ?? occurrenceId,
        extra: status != null ? {'status': status} : null,
      ),
    );
  }

  static void request({
    required String taskId,
    String? occurrenceId,
    String? note,
  }) {
    if (!kDebugMode) return;
    final body = buildRequestBody(taskId: taskId, occurrenceId: occurrenceId);
    debugPrint(
      '$_tag REQUEST | POST ${EndPoints.baserUrl}${EndPoints.showEmployeeTask} | '
      'body=${jsonEncode(body)}${note != null ? ' | $note' : ''}',
    );
  }

  static void httpResponse({
    required int? statusCode,
    required dynamic data,
    required String taskId,
    String? occurrenceId,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '$_tag HTTP | statusCode=${statusCode ?? '-'} | '
      'payload=${compactJson(data)}',
    );

    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final raw = map['employee_task'];
    if (raw is! Map) return;

    _push(_traceFromApiMap(
      phase: 'HTTP_RESPONSE',
      taskId: taskId,
      occurrenceId: occurrenceId,
      requestBody: buildRequestBody(taskId: taskId, occurrenceId: occurrenceId),
      httpStatusCode: statusCode,
      apiStatus: map['status']?.toString(),
      apiMessage: map['message']?.toString(),
      taskMap: Map<String, dynamic>.from(raw),
    ));
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
      _push(
        TaskDetailsLoadTrace(
          phase: 'API_ERROR',
          at: DateTime.now(),
          resolvedTaskId: taskId,
          resolvedOccurrenceId: occurrenceId,
          requestBody: buildRequestBody(
            taskId: taskId ?? '',
            occurrenceId: occurrenceId,
          ),
          apiStatus: status,
          apiMessage: message,
          extra: errors is Map ? Map<String, dynamic>.from(errors) : null,
        ),
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

    _push(_traceFromApiMap(
      phase: 'PARSED',
      taskId: taskId ?? '',
      occurrenceId: occurrenceId,
      requestBody: buildRequestBody(
        taskId: taskId ?? '',
        occurrenceId: occurrenceId,
      ),
      apiStatus: status,
      apiMessage: message,
      taskMap: Map<String, dynamic>.from(raw),
    ));
  }

  static TaskDetailsLoadTrace _traceFromApiMap({
    required String phase,
    required String taskId,
    String? occurrenceId,
    Map<String, dynamic>? requestBody,
    int? httpStatusCode,
    String? apiStatus,
    String? apiMessage,
    required Map<String, dynamic> taskMap,
  }) {
    final subs = _parseSubTasks(taskMap['sub_tasks']);
    return TaskDetailsLoadTrace(
      phase: phase,
      at: DateTime.now(),
      resolvedTaskId: taskId,
      resolvedOccurrenceId: occurrenceId,
      requestBody: requestBody,
      httpStatusCode: httpStatusCode,
      apiStatus: apiStatus,
      apiMessage: apiMessage,
      loadedTaskId: taskMap['task_id']?.toString() ?? taskMap['id']?.toString(),
      loadedOccurrenceId: taskMap['occurrence_id']?.toString(),
      loadedName: taskMap['name']?.toString(),
      loadedSource: taskMap['source']?.toString(),
      subTasks: subs,
    );
  }

  static List<Map<String, String>> _parseSubTasks(dynamic raw) {
    if (raw is! List) return const [];
    final out = <Map<String, String>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      out.add({
        'id': m['id']?.toString() ?? '?',
        'name': m['name']?.toString() ?? '?',
        'status': m['status']?.toString() ?? '-',
      });
    }
    return out;
  }

  static void modelLoaded({
    required String source,
    required int taskId,
    int? occurrenceId,
    required String name,
    required List<Map<String, String>> subTasks,
    String? cachedNote,
  }) {
    if (!kDebugMode) return;
    _push(
      TaskDetailsLoadTrace(
        phase: 'MODEL/$source',
        at: DateTime.now(),
        loadedTaskId: taskId.toString(),
        loadedOccurrenceId: occurrenceId?.toString(),
        loadedName: name,
        subTasks: subTasks,
        extra: cachedNote != null ? {'note': cachedNote} : null,
      ),
    );
  }

  static void createTask({
    required int subtasksSent,
    required List<String> subtaskNames,
    required int assigneeCount,
    required bool useV2,
    dynamic response,
  }) {
    if (!kDebugMode) return;
    _push(
      TaskDetailsLoadTrace(
        phase: 'CREATE_TASK',
        at: DateTime.now(),
        extra: {
          'subtasks_sent': subtasksSent,
          'subtask_names': subtaskNames,
          'assignees': assigneeCount,
          'use_v2': useV2,
          'response': response is Map ? response : response?.toString(),
        },
      ),
    );
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

  static void fail(String reason, {dynamic detail}) {
    if (!kDebugMode) return;
    debugPrint('$_tag FAIL | reason=$reason | detail=${compactJson(detail)}');
    _push(
      TaskDetailsLoadTrace(
        phase: 'FAIL/$reason',
        at: DateTime.now(),
        extra: detail is Map
            ? Map<String, dynamic>.from(detail)
            : {'detail': detail?.toString()},
      ),
    );
  }

  static void parseError(Object error, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    debugPrint('$_tag PARSE_ERROR | $error');
    if (stackTrace != null) {
      debugPrint('$_tag STACK | $stackTrace');
    }
    fail('parse_error', detail: error.toString());
  }

  static String compactJson(dynamic value, {int maxLen = 1200}) {
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
