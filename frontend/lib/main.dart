import 'package:flutter/material.dart';

import 'controllers/theme_controller.dart';
import 'themes/app_theme.dart';

import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_screen.dart';
import 'screens/random_match_screen.dart';
import 'screens/community_screen.dart';
import 'screens/friendly_match_screen.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const WordLegendApp());
}

class WordLegendApp extends StatelessWidget {
  const WordLegendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, child) {
        return MaterialApp(
          title: '말꼬리',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeController.themeMode,
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/home': (context) => const MainScreen(),
            '/random-match': (context) => const RandomMatchScreen(),
            '/friendly-match': (context) => const FriendlyMatchScreen(),
            '/community': (context) => const CommunityScreen(),
            '/game': (context) => const GameScreen(),
          },
        );
      },
    );
  }
}
