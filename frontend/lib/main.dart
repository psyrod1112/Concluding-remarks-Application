import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_screen.dart';
import 'screens/random_match_screen.dart';
import 'screens/community_screen.dart';
import 'screens/friendly_match_screen.dart';

void main() {
  runApp(const WordLegendApp());
}

class WordLegendApp extends StatelessWidget {
  const WordLegendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '끝말오브 레전드',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const MainScreen(),
        '/random-match': (context) => const RandomMatchScreen(),
        '/friendly-match': (context) => const FriendlyMatchScreen(),
        '/community': (context) => const CommunityScreen(),
      },
    );
  }
}
