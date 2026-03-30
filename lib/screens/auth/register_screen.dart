import 'package:flutter/material.dart';
import '../../core/api.dart';
import '../../core/socket.dart';
import '../../core/storage.dart';
import '../../core/call_manager.dart';
import '../chat/chat_list_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  String _lang = 'en';
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (_user.text.trim().isEmpty || _pass.text.trim().isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Api.post(
        '/auth/register',
        {
          'username': _user.text.trim(),
          'password': _pass.text,
          'language': _lang
        },
        auth: false,
      );
      if (res['token'] != null) {
        await Storage.setToken(res['token']);
        await Storage.setUserId(res['user']['id']);
        await Storage.setUsername(res['user']['username']);
        await Storage.setAvatar(res['user']['avatar'] ?? '');
        await Storage.setLanguage(_lang);
        SocketService.connect();
        CallManager.setupListeners(); // <-- llamadas globales activas
        if (mounted) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const ChatListScreen()),
              (_) => false);
        }
      } else {
        setState(() => _error = res['error'] ?? 'Registration failed');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(children: [
          TextField(
            controller: _user,
            decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pass,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _lang,
            decoration: const InputDecoration(
                labelText: 'Language', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'es', child: Text('Español')),
              DropdownMenuItem(value: 'ru', child: Text('Русский')),
            ],
            onChanged: (v) => setState(() => _lang = v!),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Register'),
            ),
          ),
        ]),
      ),
    );
  }
}
