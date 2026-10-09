import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../databases/api/end_points.dart';
import 'user_data.dart';

enum SupportRealtimeState { disconnected, connecting, connected }

class SupportRealtimeService {
  SupportRealtimeService({
    required this.onPayload,
    required this.onState,
    required this.onReconnect,
  });

  // Pusher Channels and Reverb implement the same protocol. These production
  // defaults use Pusher until Reverb can be hosted on a WebSocket-capable VPS;
  // dart-defines can override them without changing the application code.
  static const _key = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: '9412537e6cb0209ec5e0',
  );
  static const _host = String.fromEnvironment(
    'REVERB_HOST',
    defaultValue: 'ws-ap2.pusher.com',
  );
  static const _scheme = String.fromEnvironment(
    'REVERB_SCHEME',
    defaultValue: 'wss',
  );
  static const _port = int.fromEnvironment('REVERB_PORT', defaultValue: 443);

  final void Function(Map<String, dynamic>) onPayload;
  final void Function(SupportRealtimeState) onState;
  final Future<void> Function() onReconnect;

  WebSocketChannel? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retry;
  Timer? _ping;
  String? _channel;
  String? _socketId;
  bool _disposed = false;
  int _attempt = 0;

  Future<void> watchInbox() => _watch('private-support.inbox');

  Future<void> watchConversation(int id) =>
      _watch('private-support.conversation.$id');

  Future<void> _watch(String channel) async {
    _channel = channel;
    _disposed = false;
    await _connect();
  }

  Future<void> _connect() async {
    if (_disposed || _channel == null || _key.isEmpty) {
      onState(SupportRealtimeState.disconnected);
      return;
    }
    onState(SupportRealtimeState.connecting);
    await _subscription?.cancel();
    await _socket?.sink.close();
    final api = Uri.parse(EndPoints.baserUrl);
    final uri = Uri(
      scheme: _scheme,
      host: _host.isEmpty ? api.host : _host,
      port: _port,
      path: '/app/$_key',
      queryParameters: const {
        'protocol': '7',
        'client': 'doctor-bike-admin',
        'version': '1.0',
        'flash': 'false',
      },
    );
    try {
      final socket = WebSocketChannel.connect(uri);
      _socket = socket;
      await socket.ready;
      _subscription = socket.stream.listen(
        _frame,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  Future<void> _frame(dynamic value) async {
    final decoded = jsonDecode(value.toString());
    if (decoded is! Map) return;
    final event = decoded['event']?.toString();
    dynamic data = decoded['data'];
    if (data is String && data.isNotEmpty) {
      try {
        data = jsonDecode(data);
      } catch (_) {}
    }
    if (event == 'pusher:connection_established' && data is Map) {
      _socketId = data['socket_id']?.toString();
      await _subscribe();
      return;
    }
    if (event == 'pusher:ping') {
      _send({'event': 'pusher:pong', 'data': const {}});
      return;
    }
    if (event == 'pusher_internal:subscription_succeeded') {
      final reconnected = _attempt > 0;
      _attempt = 0;
      onState(SupportRealtimeState.connected);
      _startPing();
      if (reconnected) await onReconnect();
      return;
    }
    if ((event == 'support.message.created' ||
            event == 'support.conversation.read' ||
            event == 'support.typing') &&
        data is Map) {
      onPayload(Map<String, dynamic>.from(data));
    }
  }

  Future<void> _subscribe() async {
    final channel = _channel;
    final socketId = _socketId;
    if (channel == null || socketId == null) return;
    final token = await UserData.getUserToken();
    final response = await Dio().post<Map<String, dynamic>>(
      '${EndPoints.baserUrl}broadcasting/auth',
      data: {'socket_id': socketId, 'channel_name': channel},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    _send({
      'event': 'pusher:subscribe',
      'data': {'auth': response.data?['auth'], 'channel': channel},
    });
  }

  void _send(Map<String, dynamic> value) =>
      _socket?.sink.add(jsonEncode(value));

  void _startPing() {
    _ping?.cancel();
    _ping = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _send({'event': 'pusher:ping', 'data': const {}}),
    );
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    onState(SupportRealtimeState.disconnected);
    _ping?.cancel();
    _retry?.cancel();
    _attempt++;
    _retry = Timer(Duration(seconds: _attempt.clamp(1, 15)), _connect);
  }

  Future<void> dispose() async {
    _disposed = true;
    _retry?.cancel();
    _ping?.cancel();
    await _subscription?.cancel();
    await _socket?.sink.close();
  }
}
