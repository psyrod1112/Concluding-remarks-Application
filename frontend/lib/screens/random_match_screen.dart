import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/match_service.dart';
import '../utils/app_message.dart';

class RandomMatchScreen extends StatefulWidget {
  const RandomMatchScreen({super.key});

  @override
  State<RandomMatchScreen> createState() => _RandomMatchScreenState();
}

class _RandomMatchScreenState extends State<RandomMatchScreen> {
  final MatchService matchService = MatchService();

  bool isSearching = false;
  MatchedRoom? matchedRoom;

  Future<void> startMatching() async {
    final currentUser = AuthService().getCurrentUser();

    if (currentUser == null) {
      AppMessage.show(context, '로그인 후 랜덤 매칭을 이용할 수 있습니다.');
      return;
    }

    setState(() {
      isSearching = true;
      matchedRoom = null;
    });

    try {
      final room = await matchService.findRandomOpponent();

      if (!mounted) return;

      setState(() {
        isSearching = false;
        matchedRoom = room;
      });

      AppMessage.show(context, '${room.opponent.nickname}님과 매칭되었습니다.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSearching = false;
      });

      AppMessage.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> cancelMatching() async {
    await matchService.cancelMatching();

    if (!mounted) return;

    setState(() {
      isSearching = false;
    });

    AppMessage.show(context, '랜덤 매칭을 취소했습니다.');
  }

  void enterGameRoom() {
    final room = matchedRoom;
    if (room == null) return;

    Navigator.pushNamed(
      context,
      '/game',
      arguments: {
        'roomId': room.roomId,
        'roomType': 'random',
        'roomTitle': '랜덤 매칭',
        'opponentId': room.opponent.userId,
        'opponentNickname': room.opponent.nickname,
        'isMyTurn': room.isMyTurn,
        'isMockMode': false,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().getCurrentUser();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('랜덤 매칭')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _MyPlayerCard(
            nickname: currentUser?.nickname ?? '게스트',
            userId: currentUser?.userId ?? 'guest',
          ),
          const SizedBox(height: 24),

          if (isSearching) ...[
            const _SearchingCard(),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: cancelMatching,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '매칭 취소',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else if (matchedRoom != null) ...[
            _MatchedPlayerCard(player: matchedRoom!.opponent),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: enterGameRoom,
                child: const Text(
                  '게임방 입장',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: startMatching,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '다시 매칭하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else ...[
            const _MatchGuideCard(),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: startMatching,
                child: const Text(
                  '랜덤 매칭 시작',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MyPlayerCard extends StatelessWidget {
  final String nickname;
  final String userId;

  const _MyPlayerCard({required this.nickname, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primary,
            child: const Icon(Icons.person, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $userId',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.sports_esports_outlined, color: colorScheme.primary),
        ],
      ),
    );
  }
}

class _MatchGuideCard extends StatelessWidget {
  const _MatchGuideCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '랜덤 매칭 안내',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '접속 중인 사용자와 자동으로 매칭됩니다.',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            '매칭이 완료되면 상대의 전적과 점수를 확인한 뒤 게임방에 입장할 수 있습니다.',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchingCard extends StatelessWidget {
  const _SearchingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 36),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '상대를 찾는 중입니다...',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '접속 중인 끝말잇기 대전 상대를 검색하고 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchedPlayerCard extends StatelessWidget {
  final MatchedPlayer player;

  const _MatchedPlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.primary, width: 1.3),
      ),
      child: Column(
        children: [
          Text(
            '매칭 완료',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 38,
            backgroundColor: colorScheme.primary.withOpacity(0.15),
            child: Icon(
              Icons.person_outline,
              size: 42,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            player.nickname,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            player.userId.isEmpty ? 'ID 정보 없음' : 'ID: ${player.userId}',
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.65)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _OpponentStat(title: '점수', value: '${player.score}'),
              ),
              Expanded(
                child: _OpponentStat(title: '승', value: '${player.winCount}'),
              ),
              Expanded(
                child: _OpponentStat(title: '패', value: '${player.loseCount}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpponentStat extends StatelessWidget {
  final String title;
  final String value;

  const _OpponentStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 19,
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
    );
  }
}
