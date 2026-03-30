import 'package:flutter/material.dart';
import '../../core/api.dart';
import '../../core/socket.dart';
import '../../core/storage.dart';
import '../chat/chat_list_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (_user.text.trim().isEmpty || _pass.text.trim().isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Api.post('/auth/login',
          {'username': _user.text.trim(), 'password': _pass.text},
          auth: false);
      if (res['token'] != null) {
        await Storage.setToken(res['token']);
        await Storage.setUserId(res['user']['id']);
        await Storage.setUsername(res['user']['username']);
        await Storage.setAvatar(res['user']['avatar'] ?? '');
        SocketService.connect();
        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const ChatListScreen()));
        }
      } else {
        setState(() => _error = res['error'] ?? 'Login failed');
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(children: [
              const Icon(Icons.chat_bubble_rounded, size: 72, color: Colors.blue),
              const SizedBox(height: 16),
              Text('Chat', style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 36),
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
                onSubmitted: (_) => _login(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Login'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text("Don't have an account? Register"),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
