import 'dart:math';

class MatchedPlayer {
  final String userId;
  final String nickname;
  final int score;
  final int winCount;
  final int loseCount;

  MatchedPlayer({
    required this.userId,
    required this.nickname,
    required this.score,
    required this.winCount,
    required this.loseCount,
  });
}

class MatchService {
  final List<MatchedPlayer> _mockPlayers = [
    MatchedPlayer(
      userId: 'apple_king',
      nickname: '사과왕',
      score: 1200,
      winCount: 8,
      loseCount: 3,
    ),
    MatchedPlayer(
      userId: 'word_master',
      nickname: '끝말고수',
      score: 1540,
      winCount: 14,
      loseCount: 5,
    ),
    MatchedPlayer(
      userId: 'banana_user',
      nickname: '바나나킥',
      score: 980,
      winCount: 4,
      loseCount: 6,
    ),
    MatchedPlayer(
      userId: 'legend_001',
      nickname: '레전드초보',
      score: 760,
      winCount: 2,
      loseCount: 9,
    ),
  ];

  Future<MatchedPlayer> findRandomOpponent() async {
    // TODO: 나중에 Node.js 백엔드 랜덤 매칭 API 또는 Socket.IO 연결
    // 예: socket.emit('join_random_queue')
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    return _mockPlayers[random.nextInt(_mockPlayers.length)];
  }

  Future<void> cancelMatching() async {
    // TODO: 나중에 백엔드 매칭 큐 취소 API 연결
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
