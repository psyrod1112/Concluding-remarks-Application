import 'dart:async';

import 'game_socket_service.dart';

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

  factory MatchedPlayer.fromJson(dynamic json) {
    if (json is Map) {
      return MatchedPlayer(
        userId: json['userId']?.toString() ?? '',
        nickname: json['nickname']?.toString() ?? '상대방',
        score: int.tryParse(json['score']?.toString() ?? '') ?? 0,
        winCount: int.tryParse(json['winCount']?.toString() ?? '') ?? 0,
        loseCount: int.tryParse(json['loseCount']?.toString() ?? '') ?? 0,
      );
    }

    return MatchedPlayer(
      userId: '',
      nickname: json?.toString() ?? '상대방',
      score: 0,
      winCount: 0,
      loseCount: 0,
    );
  }
}

class MatchedRoom {
  final String roomId;
  final MatchedPlayer opponent;
  final bool isMyTurn;

  MatchedRoom({
    required this.roomId,
    required this.opponent,
    required this.isMyTurn,
  });
}

class MatchService {
  final GameSocketService _socket = GameSocketService.instance;

  Future<MatchedRoom> findRandomOpponent() async {
    final completer = Completer<MatchedRoom>();
    StreamSubscription<Map<String, dynamic>>? subscription;

    subscription = _socket.messages.listen((message) {
      final type = message['type']?.toString();

      if (type == 'match_found') {
        if (!completer.isCompleted) {
          completer.complete(
            MatchedRoom(
              roomId: message['roomId']?.toString() ?? '',
              opponent: MatchedPlayer.fromJson(message['opponent']),
              isMyTurn: message['isMyTurn'] == true,
            ),
          );
        }
        return;
      }

      if (type == 'auth_fail' || type == 'error') {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception(message['message']?.toString() ?? '매칭 중 오류가 발생했습니다.'),
          );
        }
      }
    });

    try {
      await _socket.connectAndAuth();
      _socket.joinQueue();
      return await completer.future.timeout(const Duration(minutes: 5));
    } finally {
      await subscription?.cancel();
    }
  }

  Future<void> cancelMatching() async {
    if (_socket.isConnected) {
      _socket.leaveQueue();
    }
  }
}
