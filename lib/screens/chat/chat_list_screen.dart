import 'package:flutter/material.dart';
import '../../core/api.dart';
import '../../core/socket.dart';
import '../../core/storage.dart';
import '../../models/user.dart';
import '../../models/group.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../group/create_group_screen.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<User> _users = [];
  List<Group> _groups = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
    _listenSocket();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final q = _search.isNotEmpty ? '?search=$_search' : '';
      final users = await Api.get('/users$q');
      final groups = await Api.get('/groups');
      setState(() {
        _users = (users as List).map((u) => User.fromJson(Map<String, dynamic>.from(u))).toList();
        _groups = (groups as List).map((g) => Group.fromJson(Map<String, dynamic>.from(g))).toList();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _listenSocket() {
    SocketService.on('user:status', (data) {
      setState(() {
        for (var u in _users) {
          if (u.id == data['userId']) {
            final idx = _users.indexOf(u);
            _users[idx] = User(
              id: u.id,
              username: u.username,
              avatar: u.avatar,
              online: data['online'],
            );
          }
        }
      });
    });
  }

  @override
  void dispose() {
    SocketService.off('user:status');
    _tabs.dispose();
    super.dispose();
  }

  void _logout() async {
    await Storage.clear();
    SocketService.disconnect();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
        bottom: TabBar(controller: _tabs, tabs: const [
          Tab(text: 'Chats'),
          Tab(text: 'Groups'),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => CreateGroupScreen(users: _users)))
            .then((_) => _load()),
        child: const Icon(Icons.group_add),
      ),
      body: TabBarView(controller: _tabs, children: [
        // ── Users list ───────────────────────────
        Column(children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true),
              onChanged: (v) { _search = v; _load(); },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (_, i) {
                      final u = _users[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: u.avatar.isNotEmpty
                              ? NetworkImage(u.avatar) : null,
                          child: u.avatar.isEmpty
                              ? Text(u.username[0].toUpperCase()) : null,
                        ),
                        title: Text(u.username),
                        subtitle: Text(u.online ? 'Online' : 'Offline',
                            style: TextStyle(
                                color: u.online ? Colors.green : Colors.grey,
                                fontSize: 12)),
                        trailing: u.online
                            ? const CircleAvatar(
                                radius: 5, backgroundColor: Colors.green)
                            : null,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ChatScreen(
                                userId: u.id, username: u.username,
                                avatar: u.avatar))),
                      );
                    }),
          ),
        ]),
        // ── Groups list ──────────────────────────
        _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  itemCount: _groups.length,
                  itemBuilder: (_, i) {
                    final g = _groups[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: g.avatar.isNotEmpty
                            ? NetworkImage(g.avatar) : null,
                        child: g.avatar.isEmpty
                            ? Text(g.name[0].toUpperCase()) : null,
                      ),
                      title: Text(g.name),
                      subtitle: Text('${g.members.length} members',
                          style: const TextStyle(fontSize: 12)),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) =>
                              GroupChatScreen(group: g))),
                    );
                  }),
              ),
      ]),
    );
  }
}
