import 'package:flutter/material.dart';
import '../../core/api.dart';
import '../../models/user.dart';

class CreateGroupScreen extends StatefulWidget {
  final List<User> users;
  const CreateGroupScreen({required this.users, super.key});
  @override State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _name = TextEditingController();
  final Set<String> _selected = {};
  bool _loading = false;

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await Api.post('/groups', {
        'name': _name.text.trim(),
        'members': _selected.toList(),
      });
      if (mounted) Navigator.pop(context);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _create,
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create'),
          )
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _name,
            decoration: const InputDecoration(
                labelText: 'Group Name',
                prefixIcon: Icon(Icons.group),
                border: OutlineInputBorder()),
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Select Members (${_selected.length} selected)',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.users.length,
            itemBuilder: (_, i) {
              final u = widget.users[i];
              final sel = _selected.contains(u.id);
              return CheckboxListTile(
                value: sel,
                onChanged: (v) => setState(() {
                  v! ? _selected.add(u.id) : _selected.remove(u.id);
                }),
                title: Text(u.username),
                secondary: CircleAvatar(
                  backgroundImage:
                      u.avatar.isNotEmpty ? NetworkImage(u.avatar) : null,
                  child: u.avatar.isEmpty
                      ? Text(u.username[0].toUpperCase()) : null,
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
