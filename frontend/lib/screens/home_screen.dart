import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().getCurrentUser();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 56,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  user == null ? '게스트' : '${user.nickname}님',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user == null ? '로그인 정보 없음' : 'ID: ${user.userId}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _HomeMenuCard(
                  title: '랜덤 매칭',
                  icon: Icons.casino_outlined,
                  onTap: () {
                    Navigator.pushNamed(context, '/random-match');
                  },
                ),
                _HomeMenuCard(
                  title: '친선 대결',
                  icon: Icons.people_outline,
                  onTap: () {
                    Navigator.pushNamed(context, '/friendly-match');
                  },
                ),
                _HomeMenuCard(
                  title: '커뮤니티',
                  icon: Icons.forum_outlined,
                  onTap: () {
                    Navigator.pushNamed(context, '/community');
                  },
                ),
                _HomeMenuCard(
                  title: 'AI대결',
                  icon: Icons.smart_toy_outlined,
                  onTap: () {
                    Navigator.pushNamed(context, '/ai-battle');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeMenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeMenuCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: theme.cardColor,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
