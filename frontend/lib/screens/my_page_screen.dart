import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  Future<Map<String, dynamic>?> _loadStats(String userId) async {
    try {
      return await ApiClient.get('/api/users/$userId/stats');
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().getCurrentUser();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // 프로필 카드
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(18)),
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
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                user == null ? '로그인 정보 없음' : user.userId,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.65)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 전적 카드 — 실제 API
        if (user != null)
          FutureBuilder<Map<String, dynamic>?>(
            future: _loadStats(user.userId),
            builder: (context, snapshot) {
              final stats = snapshot.data;
              final winCount  = stats?['winCount']  ?? 0;
              final loseCount = stats?['loseCount'] ?? 0;
              final score     = stats?['score']     ?? 0;

              return Row(
                children: [
                  Expanded(child: _StatCard(title: '승리', value: '$winCount')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(title: '패배', value: '$loseCount')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(title: '점수', value: '$score')),
                ],
              );
            },
          )
        else
          const Row(
            children: [
              Expanded(child: _StatCard(title: '승리', value: '-')),
              SizedBox(width: 12),
              Expanded(child: _StatCard(title: '패배', value: '-')),
              SizedBox(width: 12),
              Expanded(child: _StatCard(title: '점수', value: '-')),
            ],
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
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.primary),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.65))),
        ],
      ),
    );
  }
}
