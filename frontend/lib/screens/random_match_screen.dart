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
  MatchedPlayer? matchedPlayer;

  Future<void> startMatching() async {
    setState(() {
      isSearching = true;
      matchedPlayer = null;
    });

    final opponent = await matchService.findRandomOpponent();

    if (!mounted) return;

    setState(() {
      isSearching = false;
      matchedPlayer = opponent;
    });

    AppMessage.show(context, '${opponent.nickname}님과 매칭되었습니다.');
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
    // TODO: 나중에 실제 끝말잇기 채팅방 화면으로 이동
    AppMessage.show(context, '게임방 입장은 추후 연결 예정입니다.');
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().getCurrentUser();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('랜덤 매칭'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
      ),
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
          ] else if (matchedPlayer != null) ...[
            _MatchedPlayerCard(player: matchedPlayer!),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: enterGameRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
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
                  foregroundColor: const Color(0xFF3F51B5),
                  side: const BorderSide(color: Color(0xFF3F51B5)),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
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
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Color(0xFF3F51B5),
            child: Icon(Icons.person, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $userId',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(Icons.sports_esports_outlined, color: Color(0xFF3F51B5)),
        ],
      ),
    );
  }
}

class _MatchGuideCard extends StatelessWidget {
  const _MatchGuideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '랜덤 매칭 안내',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 14),
          Text(
            '현재는 프론트 테스트용 임시 매칭입니다.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          SizedBox(height: 8),
          Text(
            '나중에 백엔드가 연결되면 실시간 접속자 중 한 명과 자동으로 매칭됩니다.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: Color(0xFF3F51B5),
            ),
          ),
          SizedBox(height: 20),
          Text(
            '상대를 찾는 중입니다...',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '실시간 끝말잇기 대전 상대를 검색하고 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
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
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3F51B5), width: 1.3),
      ),
      child: Column(
        children: [
          const Text(
            '매칭 완료',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3F51B5),
            ),
          ),
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 38,
            backgroundColor: Color(0xFFE8EAF6),
            child: Icon(
              Icons.person_outline,
              size: 42,
              color: Color(0xFF3F51B5),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            player.nickname,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${player.userId}',
            style: const TextStyle(color: Colors.black54),
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
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3F51B5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }
}
