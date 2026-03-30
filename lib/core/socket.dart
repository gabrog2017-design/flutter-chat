import 'package:socket_io_client/socket_io_client.dart' as io;
import 'constants.dart';
import 'storage.dart';

class SocketService {
  static io.Socket? _socket;
  static bool _connected = false;

  static io.Socket get socket {
    if (_socket == null) throw Exception('Socket not connected');
    return _socket!;
  }

  static bool get isConnected => _connected;

  static void connect() {
    final token = Storage.getToken();
    if (token == null) return;

    _socket = io.io(AppConst.wsUrl, {
      'transports': ['websocket'],
      'auth': {'token': token},
      'autoConnect': true,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 10,
    });

    _socket!.onConnect((_) => _connected = true);
    _socket!.onDisconnect((_) => _connected = false);
    _socket!.onConnectError((e) => print('Socket error: $e'));
    _socket!.connect();
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _connected = false;
  }

  // ── Messages ────────────────────────────
  static void sendMessage(String to, String content, {String type = 'text'}) {
    _socket?.emit('message:send', {'to': to, 'content': content, 'type': type});
  }

  static void sendGroupMessage(String groupId, String content,
      {String type = 'text'}) {
    _socket?.emit(
        'group:message', {'groupId': groupId, 'content': content, 'type': type});
  }

  static void joinGroup(String groupId) =>
      _socket?.emit('group:join', groupId);

  static void markRead(String messageId, String from) =>
      _socket?.emit('message:read', {'messageId': messageId, 'from': from});

  static void markDelivered(String messageId, String from) =>
      _socket?.emit('message:delivered', {'messageId': messageId, 'from': from});

  // ── Typing ──────────────────────────────
  static void typingStart({String? to, String? groupId}) =>
      _socket?.emit('typing:start', {'to': to, 'groupId': groupId});

  static void typingStop({String? to, String? groupId}) =>
      _socket?.emit('typing:stop', {'to': to, 'groupId': groupId});

  // ── Calls ───────────────────────────────
  static void sendOffer(String to, String sdp, String type, bool isVideo) =>
      _socket?.emit(
          'call:offer', {'to': to, 'sdp': sdp, 'type': type, 'isVideo': isVideo});

  static void sendAnswer(String to, String sdp, String type) =>
      _socket?.emit('call:answer', {'to': to, 'sdp': sdp, 'type': type});

  static void sendIce(String to, Map candidate) =>
      _socket?.emit('call:ice', {'to': to, 'candidate': candidate});

  static void rejectCall(String to) =>
      _socket?.emit('call:reject', {'to': to});

  static void endCall(String to) =>
      _socket?.emit('call:end', {'to': to});

  // ── Listeners ───────────────────────────
  static void on(String event, Function(dynamic) handler) =>
      _socket?.on(event, handler);

  static void off(String event) => _socket?.off(event);
}
