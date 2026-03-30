import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/api.dart';
import '../../core/storage.dart';
import '../../core/socket.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = Storage.getUsername() ?? '';
  String _avatar = Storage.getAvatar() ?? '';
  String _lang = Storage.getLanguage() ?? 'en';
  bool _uploading = false;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ]),
      ),
    );
    if (src == null) return;
    final picked = await picker.pickImage(source: src, imageQuality: 75);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final res = await Api.uploadAvatar(File(picked.path));
      if (res['avatar'] != null) {
        await Storage.setAvatar(res['avatar']);
        setState(() => _avatar = res['avatar']);
        if (mounted) ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Photo updated')));
      }
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _changeLang(String lang) async {
    await Api.put('/auth/language', {'language': lang});
    await Storage.setLanguage(lang);
    setState(() => _lang = lang);
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
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Center(
          child: Stack(children: [
            CircleAvatar(
              radius: 54,
              backgroundImage: _avatar.isNotEmpty ? NetworkImage(_avatar) : null,
              child: _avatar.isEmpty
                  ? Text(_username.isNotEmpty ? _username[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 36))
                  : null,
            ),
            Positioned(
              bottom: 0, right: 0,
              child: GestureDetector(
                onTap: _uploading ? null : _pickAvatar,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _uploading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.camera_alt,
                          color: Colors.white, size: 18),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(_username,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 32),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Language'),
          trailing: DropdownButton<String>(
            value: _lang,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'es', child: Text('Español')),
              DropdownMenuItem(value: 'ru', child: Text('Русский')),
            ],
            onChanged: (v) { if (v != null) _changeLang(v); },
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red)),
          onTap: _logout,
        ),
      ]),
    );
  }
}
