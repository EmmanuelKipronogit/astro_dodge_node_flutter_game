import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/game_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isLoggedIn = await AuthService.isLoggedIn();
  runApp(AstroDodgeApp(initialRoute: isLoggedIn ? '/game' : '/login'));
}

class AstroDodgeApp extends StatelessWidget {
  final String initialRoute;
  const AstroDodgeApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Astro Dodge Arcade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: Colors.cyanAccent,
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/game': (context) => const GameScreen(),
      },
    );
  }
}
