import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import 'end_points.dart';

/// Shared by requests to our API only. Failed writes are never replayed.
class ApiRequestBackoff {
  ApiRequestBackoff({DateTime Function()? now})
      : _now = now ?? (() => DateTime.now());

  static final instance = ApiRequestBackoff();
  final DateTime Function() _now;
  DateTime? _until;
  int _failures = 0;
  int _statusCode = 429;

  Duration get remaining {
    final value = _until?.difference(_now()) ?? Duration.zero;
    return value.isNegative ? Duration.zero : value;
  }

  bool get isCoolingDown => remaining > Duration.zero;
  int get statusCode => _statusCode;

  bool appliesTo(Uri uri) => uri.origin == Uri.parse(EndPoints.baserUrl).origin;

  void failed(int statusCode, {String? retryAfter}) {
    if (statusCode != 429 &&
        statusCode != 503 &&
        statusCode != 502 &&
        statusCode != 504) {
      return;
    }
    // Concurrent failures belong to the same outage, not separate retries.
    if (!isCoolingDown) _failures = math.min(_failures + 1, 5);
    final seconds = math.min(
        (statusCode == 429 ? 30 : 5) * (1 << math.max(0, _failures - 1)), 300);
    var delay = Duration(seconds: seconds);
    final serverDelay = _retryAfter(retryAfter);
    if (serverDelay != null && serverDelay > delay) delay = serverDelay;
    final next = _now().add(delay);
    if (_until == null || next.isAfter(_until!)) _until = next;
    _statusCode = statusCode;
  }

  void succeeded() {
    if (isCoolingDown) {
      return; // An older in-flight success cannot lift a block.
    }
    _failures = 0;
    _until = null;
  }

  Duration? _retryAfter(String? value) {
    if (value == null) return null;
    final seconds = int.tryParse(value.trim());
    if (seconds != null) return Duration(seconds: math.max(0, seconds));
    try {
      final date = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US')
          .parseStrict(value.trim(), true);
      return date.difference(_now().toUtc());
    } catch (_) {
      return null;
    }
  }
}

class ApiRequestBackoffInterceptor extends Interceptor {
  ApiRequestBackoffInterceptor({ApiRequestBackoff? backoff})
      : backoff = backoff ?? ApiRequestBackoff.instance;

  final ApiRequestBackoff backoff;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!backoff.appliesTo(options.uri) || !backoff.isCoolingDown) {
      handler.next(options);
      return;
    }
    handler.reject(DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: backoff.statusCode,
        data: {'message': 'السيرفر مشغول حاليًا، جرّب بعد قليل.'},
      ),
      error: 'Request paused during server cooldown',
    ));
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (backoff.appliesTo(response.requestOptions.uri)) {
      if ((response.statusCode ?? 0) < 400) {
        backoff.succeeded();
      } else {
        backoff.failed(response.statusCode!,
            retryAfter: response.headers.value('retry-after'));
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (backoff.appliesTo(err.requestOptions.uri) && err.response != null) {
      backoff.failed(err.response!.statusCode ?? 0,
          retryAfter: err.response!.headers.value('retry-after'));
    }
    handler.next(err);
  }
}
