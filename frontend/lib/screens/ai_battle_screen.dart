import 'package:flutter/material.dart';

import '../models/ai_difficulty.dart';
import '../services/ai_battle_service.dart';
import '../utils/app_message.dart';

class AiBattleScreen extends StatefulWidget {
  const AiBattleScreen({super.key});

  @override
  State<AiBattleScreen> createState() => _AiBattleScreenState();
}

class _AiBattleScreenState extends State<AiBattleScreen> {
  final AiBattleService _service = AiBattleService();
  AiDifficulty? _loadingDifficulty;

  Future<void> _startBattle(AiDifficulty difficulty) async {
    if (_loadingDifficulty != null) return;

    setState(() => _loadingDifficulty = difficulty);

    try {
      final session = await _service.createSession(difficulty);
      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/game',
        arguments: session.toGameArguments(),
      );
    } catch (_) {
      if (!mounted) return;
      AppMessage.show(context, 'AI대결을 시작하지 못했습니다.');
    } finally {
      if (mounted) setState(() => _loadingDifficulty = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('AI대결')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const _AiBattleGuideCard(),
          const SizedBox(height: 18),
          Text(
            '난이도 선택',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...AiDifficulty.values.map(
            (difficulty) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DifficultyCard(
                difficulty: difficulty,
                isLoading: _loadingDifficulty == difficulty,
                isDisabled: _loadingDifficulty != null,
                onTap: () => _startBattle(difficulty),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const _BackendReadyCard(),
        ],
      ),
    );
  }
}

class _AiBattleGuideCard extends StatelessWidget {
  const _AiBattleGuideCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colorScheme.primary.withOpacity(0.15),
            child: Icon(Icons.smart_toy_outlined, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI와 바로 끝말잇기 대결',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '난이도를 선택하면 AI 상대와 끝말잇기 대결을 시작합니다.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: colorScheme.onSurface.withOpacity(0.68),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final AiDifficulty difficulty;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.difficulty,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  IconData get icon {
    switch (difficulty) {
      case AiDifficulty.easy:
        return Icons.sentiment_satisfied_alt_outlined;
      case AiDifficulty.normal:
        return Icons.psychology_alt_outlined;
      case AiDifficulty.hard:
        return Icons.local_fire_department_outlined;
      case AiDifficulty.expert:
        return Icons.workspace_premium_outlined;
    }
  }

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
        onTap: isDisabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colorScheme.primary.withOpacity(0.14),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          difficulty.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SmallChip(
                          text: '${difficulty.turnTimeLimitSeconds}초',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      difficulty.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.65),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '난이도 코드: ${difficulty.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String text;

  const _SmallChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BackendReadyCard extends StatelessWidget {
  const _BackendReadyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.storage_outlined, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI대결 결과는 난이도, 상대 정보, 승패, 점수 변동과 함께 저장할 수 있습니다.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
