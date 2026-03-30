import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/storage.dart';
import 'core/socket.dart';
import 'core/call_manager.dart';
import 'screens/auth/login_screen.dart';
import 'screens/chat/chat_list_screen.dart';

// Clave global para que CallManager pueda mostrar diálogos desde cualquier pantalla
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();

  // Registrar la key antes de conectar el socket
  CallManager.init(navigatorKey);

  if (Storage.isLoggedIn()) {
    SocketService.connect();
    CallManager.setupListeners();
  }

  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,   // <-- clave para el diálogo global
      title: 'Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('ru'),
      ],
      home: Storage.isLoggedIn()
          ? const ChatListScreen()
          : const LoginScreen(),
    );
  }
}
