class User {
  final String id;
  final String username;
  final String avatar;
  final bool online;
  final DateTime? lastSeen;

  User({
    required this.id,
    required this.username,
    this.avatar = '',
    this.online = false,
    this.lastSeen,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['_id'] ?? j['id'] ?? '',
        username: j['username'] ?? '',
        avatar: j['avatar'] ?? '',
        online: j['online'] ?? false,
        lastSeen:
            j['lastSeen'] != null ? DateTime.tryParse(j['lastSeen']) : null,
      );
}
