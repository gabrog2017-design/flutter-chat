class Message {
  final String id;
  final String fromId;
  final String fromUsername;
  final String? toId;
  final String? groupId;
  final String type; // text | image
  final String content;
  String status; // sent | delivered | read
  final DateTime createdAt;

  Message({
    this.id = '',
    required this.fromId,
    this.fromUsername = '',
    this.toId,
    this.groupId,
    this.type = 'text',
    required this.content,
    this.status = 'sent',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Message.fromJson(Map<String, dynamic> j) {
    final from = j['from'];
    String fromId = '';
    String fromUsername = '';
    if (from is Map) {
      fromId = from['_id'] ?? '';
      fromUsername = from['username'] ?? '';
    } else {
      fromId = from ?? '';
    }
    return Message(
      id: j['_id'] ?? '',
      fromId: fromId,
      fromUsername: fromUsername,
      toId: j['to'],
      groupId: j['group'],
      type: j['type'] ?? 'text',
      content: j['content'] ?? '',
      status: j['status'] ?? 'sent',
      createdAt:
          j['createdAt'] != null ? DateTime.parse(j['createdAt']) : DateTime.now(),
    );
  }

  bool get isMe {
    // Set from context before display
    return false;
  }
}
