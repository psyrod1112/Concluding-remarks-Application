import '../models/ai_difficulty.dart';
import 'api_client.dart';

class AiBattleSession {
  final String roomId;
  final String roomType;
  final AiDifficulty difficulty;
  final String opponentId;
  final String opponentNickname;
  final bool isMockMode;

  const AiBattleSession({
    required this.roomId,
    required this.roomType,
    required this.difficulty,
    required this.opponentId,
    required this.opponentNickname,
    required this.isMockMode,
  });

  String get roomTitle => 'AI대결 · ${difficulty.title}';

  Map<String, dynamic> toGameArguments() {
    return {
      'roomId': roomId,
      'roomType': roomType,
      'roomTitle': roomTitle,
      'opponentId': opponentId,
      'opponentNickname': opponentNickname,
      'isMockMode': isMockMode,
      'difficultyId': difficulty.id,
      'difficultyTitle': difficulty.title,
      'turnTimeLimitSeconds': difficulty.turnTimeLimitSeconds,
    };
  }
}

class AiBattleService {
  /// true: 프론트 작업용 mock 세션
  /// false: 나중에 백엔드 AI대결 API가 준비되면 실제 API 호출
  static bool useMockAi = true;

  Future<AiBattleSession> createSession(AiDifficulty difficulty) async {
    if (useMockAi) {
      await Future.delayed(const Duration(milliseconds: 250));
      return AiBattleSession(
        roomId: 'ai-${difficulty.id}-${DateTime.now().millisecondsSinceEpoch}',
        roomType: 'ai',
        difficulty: difficulty,
        opponentId: difficulty.opponentId,
        opponentNickname: difficulty.opponentNickname,
        isMockMode: true,
      );
    }

    // 백엔드 연결 시 권장 API
    // POST /api/ai-matches
    // body: { "difficulty": "easy|normal|hard|expert" }
    // response 예시:
    // {
    //   "roomId": "...",
    //   "difficulty": "normal",
    //   "opponent": { "id": "ai_normal", "nickname": "AI 라이벌" }
    // }
    final data = await ApiClient.post('/api/ai-matches', {
      'difficulty': difficulty.id,
    });

    final responseDifficulty = aiDifficultyFromId(
      data['difficulty']?.toString(),
    );
    final opponent = data['opponent'] as Map<String, dynamic>?;

    return AiBattleSession(
      roomId: data['roomId'].toString(),
      roomType: 'ai',
      difficulty: responseDifficulty,
      opponentId: opponent?['id']?.toString() ?? responseDifficulty.opponentId,
      opponentNickname:
          opponent?['nickname']?.toString() ?? responseDifficulty.opponentNickname,
      isMockMode: false,
    );
  }
}
