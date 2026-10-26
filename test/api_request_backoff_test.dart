import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/api_request_backoff.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  int requests = 0;
  int status = 429;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests++;
    return ResponseBody.fromString('{}', status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      'retry-after': ['60'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('429 pauses API traffic, never replays writes, then recovers', () async {
    var now = DateTime.utc(2026, 10, 26);
    final backoff = ApiRequestBackoff(now: () => now);
    final adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: EndPoints.baserUrl))
      ..httpClientAdapter = adapter
      ..interceptors.add(ApiRequestBackoffInterceptor(backoff: backoff));
    addTearDown(() => dio.close());

    await expectLater(
        dio.post('sale', data: {'id': 7}), throwsA(isA<DioException>()));
    expect(backoff.remaining, const Duration(seconds: 60));
    await expectLater(
        dio.post('sale', data: {'id': 8}), throwsA(isA<DioException>()));
    await expectLater(dio.get('products'), throwsA(isA<DioException>()));
    expect(adapter.requests, 1);

    // External services do not share our API's rate limit.
    adapter.status = 200;
    await dio.get('https://example.com/external');
    expect(adapter.requests, 2);
    expect(backoff.isCoolingDown, isTrue);
    now = now.add(const Duration(seconds: 61));
    await dio.get('products');
    expect(adapter.requests, 3); // Neither failed POST was replayed.
    expect(backoff.isCoolingDown, isFalse);
  });

  test('respects HTTP dates, increases retry delay, ignores normal errors', () {
    var now = DateTime.utc(2026, 10, 26, 12);
    final backoff = ApiRequestBackoff(now: () => now);
    backoff.failed(403);
    expect(backoff.isCoolingDown, isFalse);
    backoff.failed(429, retryAfter: 'Mon, 26 Oct 2026 12:02:00 GMT');
    expect(backoff.remaining, const Duration(minutes: 2));
    backoff.succeeded();
    expect(backoff.isCoolingDown, isTrue);
    now = now.add(const Duration(minutes: 3));
    backoff.failed(429);
    expect(backoff.remaining, const Duration(seconds: 60));
    now = now.add(const Duration(minutes: 2));
    backoff.succeeded();
    backoff.failed(429);
    expect(backoff.remaining, const Duration(seconds: 30));
  });

  test('outage responses use a short growing cooldown', () {
    var now = DateTime.utc(2026);
    final backoff = ApiRequestBackoff(now: () => now);
    backoff.failed(503);
    expect(backoff.remaining, const Duration(seconds: 5));
    now = now.add(const Duration(seconds: 6));
    backoff.failed(502);
    expect(backoff.remaining, const Duration(seconds: 10));
  });
}
