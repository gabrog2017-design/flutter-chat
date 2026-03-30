import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/api.dart';
import '../../core/socket.dart';
import '../../core/storage.dart';
import '../../models/group.dart';
import '../../models/message.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/typing_indicator.dart';

class GroupChatScreen extends StatefulWidget {
  final Group group;
  const GroupChatScreen({required this.group, super.key});
  @override State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<Message> _msgs = [];
  final String _myId = Storage.getUserId() ?? '';
  final Set<String> _typingUsers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    SocketService.joinGroup(widget.group.id);
    _loadHistory();
    _listenSocket();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await Api.get('/messages/group/${widget.group.id}');
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
      if (msg.groupId == widget.group.id) {
        setState(() => _msgs.add(msg));
        _scrollBottom();
      }
    });
    SocketService.on('typing:start', (data) {
      if (data['groupId'] == widget.group.id) {
        setState(() => _typingUsers.add(data['from']));
      }
    });
    SocketService.on('typing:stop', (data) {
      if (data['groupId'] == widget.group.id) {
        setState(() => _typingUsers.remove(data['from']));
      }
    });
  }

  @override
  void dispose() {
    SocketService.off('message:receive');
    SocketService.off('typing:start');
    SocketService.off('typing:stop');
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
    SocketService.sendGroupMessage(widget.group.id, text);
    final optimistic = Message(
        fromId: _myId,
        groupId: widget.group.id,
        content: text,
        status: 'sent');
    setState(() => _msgs.add(optimistic));
    _ctrl.clear();
    SocketService.typingStop(groupId: widget.group.id);
    _scrollBottom();
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    final res = await Api.uploadImage('/messages/image', File(picked.path),
        {'groupId': widget.group.id});
    if (res['_id'] != null) {
      SocketService.sendGroupMessage(
          widget.group.id, res['content'], type: 'image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: widget.group.avatar.isNotEmpty
                ? NetworkImage(widget.group.avatar) : null,
            child: widget.group.avatar.isEmpty
                ? Text(widget.group.name[0].toUpperCase()) : null,
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.group.name, style: const TextStyle(fontSize: 15)),
            Text('${widget.group.members.length} members',
                style: const TextStyle(fontSize: 11)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _msgs.length + (_typingUsers.isNotEmpty ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_typingUsers.isNotEmpty && i == _msgs.length) {
                      return const Align(
                          alignment: Alignment.centerLeft,
                          child: TypingIndicator());
                    }
                    final m = _msgs[i];
                    return MessageBubble(msg: m, isMe: m.fromId == _myId);
                  }),
        ),
        SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
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
                    v.isNotEmpty
                        ? SocketService.typingStart(groupId: widget.group.id)
                        : SocketService.typingStop(groupId: widget.group.id);
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
