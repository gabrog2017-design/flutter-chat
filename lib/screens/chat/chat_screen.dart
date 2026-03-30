import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/api.dart';
import '../../core/socket.dart';
import '../../core/storage.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/typing_indicator.dart';
import '../call/call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String userId, username, avatar;
  const ChatScreen(
      {required this.userId, required this.username, required this.avatar, super.key});
  @override State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<Message> _msgs = [];
  final String _myId = Storage.getUserId() ?? '';
  bool _typing = false;
  bool _loading = true;
  bool _incomingCall = false;
  bool _incomingVideo = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _listenSocket();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await Api.get('/messages/${widget.userId}');
      setState(() {
        _msgs.addAll((data as List)
            .map((m) => Message.fromJson(Map<String, dynamic>.from(m))));
      });
    } finally {
      setState(() => _loading = false);
      _scrollBottom();
    }
  }

  void _listenSocket() {
    SocketService.on('message:receive', (data) {
      final msg = Message.fromJson(Map<String, dynamic>.from(data));
      if (msg.fromId == widget.userId || msg.toId == widget.userId) {
        setState(() => _msgs.add(msg));
        _scrollBottom();
        if (msg.id.isNotEmpty) SocketService.markRead(msg.id, msg.fromId);
      }
    });

    SocketService.on('message:sent', (data) {
      final msg = Message.fromJson(Map<String, dynamic>.from(data));
      setState(() {
        final idx = _msgs.lastIndexWhere((m) => m.id.isEmpty);
        if (idx != -1) _msgs[idx] = msg;
      });
    });

    SocketService.on('message:status', (data) {
      setState(() {
        for (var m in _msgs) {
          if (m.id == data['messageId']) m.status = data['status'];
        }
      });
    });

    SocketService.on('typing:start', (data) {
      if (data['from'] == widget.userId) setState(() => _typing = true);
    });
    SocketService.on('typing:stop', (data) {
      if (data['from'] == widget.userId) setState(() => _typing = false);
    });

    SocketService.on('call:offer', (data) {
      if (data['from'] == widget.userId) {
        setState(() {
          _incomingCall = true;
          _incomingVideo = data['isVideo'] ?? false;
        });
      }
    });
    SocketService.on('call:end', (_) => setState(() => _incomingCall = false));
    SocketService.on('call:reject', (_) => setState(() => _incomingCall = false));
  }

  @override
  void dispose() {
    SocketService.off('message:receive');
    SocketService.off('message:sent');
    SocketService.off('message:status');
    SocketService.off('typing:start');
    SocketService.off('typing:stop');
    SocketService.off('call:offer');
    SocketService.off('call:end');
    SocketService.off('call:reject');
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final optimistic = Message(
        fromId: _myId, toId: widget.userId, content: text, status: 'sent');
    setState(() => _msgs.add(optimistic));
    SocketService.sendMessage(widget.userId, text);
    _ctrl.clear();
    SocketService.typingStop(to: widget.userId);
    _scrollBottom();
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    final res = await Api.uploadImage(
        '/messages/image', File(picked.path), {'to': widget.userId});
    if (res['_id'] != null) {
      final msg = Message.fromJson(res);
      setState(() => _msgs.add(msg));
      SocketService.socket.emit('message:send', {
        'to': widget.userId,
        'content': res['content'],
        'type': 'image'
      });
      _scrollBottom();
    }
  }

  void _startCall(bool isVideo) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => CallScreen(
            peerId: widget.userId,
            peerName: widget.username,
            isVideo: isVideo,
            isCaller: true)));
  }

  void _acceptCall() {
    setState(() => _incomingCall = false);
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => CallScreen(
            peerId: widget.userId,
            peerName: widget.username,
            isVideo: _incomingVideo,
            isCaller: false)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 36,
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundImage:
                widget.avatar.isNotEmpty ? NetworkImage(widget.avatar) : null,
            child: widget.avatar.isEmpty
                ? Text(widget.username[0].toUpperCase()) : null,
          ),
          const SizedBox(width: 10),
          Text(widget.username, style: const TextStyle(fontSize: 16)),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.call),
              onPressed: () => _startCall(false)),
          IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: () => _startCall(true)),
        ],
      ),
      body: Column(children: [
        // Incoming call banner
        if (_incomingCall)
          Container(
            color: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Icon(_incomingVideo ? Icons.videocam : Icons.call,
                  color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      _incomingVideo
                          ? 'Incoming video call from ${widget.username}'
                          : 'Incoming call from ${widget.username}',
                      style: const TextStyle(color: Colors.white))),
              TextButton(
                  onPressed: () {
                    SocketService.rejectCall(widget.userId);
                    setState(() => _incomingCall = false);
                  },
                  child: const Text('Decline',
                      style: TextStyle(color: Colors.white70))),
              FilledButton(
                  onPressed: _acceptCall,
                  style: FilledButton.styleFrom(backgroundColor: Colors.white),
                  child: Text('Accept',
                      style: TextStyle(color: Colors.green.shade700))),
            ]),
          ),
        // Messages
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _msgs.length + (_typing ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_typing && i == _msgs.length) {
                      return const Align(
                          alignment: Alignment.centerLeft,
                          child: TypingIndicator());
                    }
                    final m = _msgs[i];
                    return MessageBubble(
                        msg: m, isMe: m.fromId == _myId);
                  }),
        ),
        // Input bar
        SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4, offset: const Offset(0, -1))],
            ),
            child: Row(children: [
              IconButton(
                  icon: const Icon(Icons.image_outlined),
                  onPressed: _sendImage),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  minLines: 1, maxLines: 4,
                  decoration: const InputDecoration(
                      hintText: 'Message...',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      isDense: true),
                  onChanged: (v) {
                    if (v.isNotEmpty) {
                      SocketService.typingStart(to: widget.userId);
                    } else {
                      SocketService.typingStop(to: widget.userId);
                    }
                  },
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: _send),
            ]),
          ),
        ),
      ]),
    );
  }
}
