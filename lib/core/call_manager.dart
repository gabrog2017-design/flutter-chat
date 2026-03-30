import 'package:flutter/material.dart';
import 'socket.dart';
import '../screens/call/call_screen.dart';

/// Maneja las llamadas entrantes globalmente.
/// El diálogo aparece sin importar en qué pantalla estés.
class CallManager {
  static GlobalKey<NavigatorState>? _navigatorKey;
  static bool _listenersSetup = false;
  static BuildContext? _activeDialogCtx;

  /// Llamar una sola vez en main.dart con el navigatorKey del MaterialApp.
  static void init(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Llamar después de cada SocketService.connect()
  /// (en main.dart, login_screen y register_screen).
  static void setupListeners() {
    if (_listenersSetup) return;
    _listenersSetup = true;

    SocketService.on('call:offer', (data) {
      final ctx = _navigatorKey?.currentContext;
      if (ctx == null || _activeDialogCtx != null) return;

      final from     = '${data['from'] ?? ''}';
      final name     = '${data['fromUsername'] ?? data['from'] ?? 'Unknown'}';
      final isVideo  = (data['isVideo'] as bool?) ?? false;

      showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (dialogCtx) {
          _activeDialogCtx = dialogCtx;
          return _CallDialog(
            callerId: from,
            callerName: name,
            isVideo: isVideo,
          );
        },
      ).then((_) => _activeDialogCtx = null);
    });

    SocketService.on('call:end',    (_) => _dismissDialog());
    SocketService.on('call:reject', (_) => _dismissDialog());
  }

  static void _dismissDialog() {
    final ctx = _activeDialogCtx;
    if (ctx != null && Navigator.of(ctx).canPop()) {
      Navigator.of(ctx).pop();
    }
    _activeDialogCtx = null;
  }
}

class _CallDialog extends StatelessWidget {
  final String callerId;
  final String callerName;
  final bool isVideo;

  const _CallDialog({
    required this.callerId,
    required this.callerName,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        Icon(isVideo ? Icons.videocam : Icons.call, color: Colors.green),
        const SizedBox(width: 8),
        Text(isVideo ? 'Video Call' : 'Voice Call'),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            callerName.isNotEmpty ? callerName[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 28, color: Colors.blue),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          callerName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          isVideo ? 'Incoming video call...' : 'Incoming call...',
          style: const TextStyle(color: Colors.grey),
        ),
      ]),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          icon: const Icon(Icons.call_end),
          label: const Text('Decline'),
          onPressed: () {
            SocketService.rejectCall(callerId);
            Navigator.of(context).pop();
          },
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.green),
          icon: Icon(isVideo ? Icons.videocam : Icons.call),
          label: const Text('Accept'),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CallScreen(
                peerId: callerId,
                peerName: callerName,
                isVideo: isVideo,
                isCaller: false,
              ),
            ));
          },
        ),
      ],
    );
  }
}
