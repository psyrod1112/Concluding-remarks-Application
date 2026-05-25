import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().getCurrentUser();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: colorScheme.primary,
                child: const Icon(Icons.person, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Text(
                user?.nickname ?? '게스트',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user == null ? '로그인 정보 없음' : user.userId,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(
              child: _StatCard(title: '승리', value: '0'),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(title: '패배', value: '0'),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(title: '점수', value: '0'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            '전적과 랭킹 정보는 나중에 백엔드 연결 후 표시할 예정입니다.',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}
