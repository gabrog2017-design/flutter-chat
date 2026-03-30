import 'user.dart';

class Group {
  final String id;
  final String name;
  final String avatar;
  final String adminId;
  final List<User> members;

  Group({
    required this.id,
    required this.name,
    this.avatar = '',
    required this.adminId,
    this.members = const [],
  });

  factory Group.fromJson(Map<String, dynamic> j) => Group(
        id: j['_id'] ?? '',
        name: j['name'] ?? '',
        avatar: j['avatar'] ?? '',
        adminId: j['admin'] is Map ? j['admin']['_id'] : j['admin'] ?? '',
        members: (j['members'] as List? ?? [])
            .map((m) => User.fromJson(m is Map ? Map<String, dynamic>.from(m) : {}))
            .toList(),
      );
}
