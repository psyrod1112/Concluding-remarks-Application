/// AI대결 난이도 정의
///
/// 프론트 화면 표시와 AI대결 난이도 식별에 사용합니다.
enum AiDifficulty { easy, normal, hard, expert }

extension AiDifficultyInfo on AiDifficulty {
  String get id {
    switch (this) {
      case AiDifficulty.easy:
        return 'easy';
      case AiDifficulty.normal:
        return 'normal';
      case AiDifficulty.hard:
        return 'hard';
      case AiDifficulty.expert:
        return 'expert';
    }
  }

  String get title {
    switch (this) {
      case AiDifficulty.easy:
        return '쉬움';
      case AiDifficulty.normal:
        return '보통';
      case AiDifficulty.hard:
        return '어려움';
      case AiDifficulty.expert:
        return '전문가';
    }
  }

  String get opponentId => 'ai_$id';

  String get opponentNickname {
    switch (this) {
      case AiDifficulty.easy:
        return 'AI 새싹';
      case AiDifficulty.normal:
        return 'AI 라이벌';
      case AiDifficulty.hard:
        return 'AI 고수';
      case AiDifficulty.expert:
        return 'AI 마스터';
    }
  }

  String get description {
    switch (this) {
      case AiDifficulty.easy:
        return '짧고 쉬운 단어 위주로 응답합니다.';
      case AiDifficulty.normal:
        return '일반적인 끝말잇기 실력으로 대결합니다.';
      case AiDifficulty.hard:
        return '더 긴 단어와 까다로운 단어를 사용합니다.';
      case AiDifficulty.expert:
        return '제한 시간과 단어 선택이 가장 어렵습니다.';
    }
  }

  String get backendMemo {
    switch (this) {
      case AiDifficulty.easy:
        return 'temperature 높음 · 쉬운 어휘';
      case AiDifficulty.normal:
        return '기본 프롬프트 · 표준 검증';
      case AiDifficulty.hard:
        return '낮은 실수율 · 긴 단어 우선';
      case AiDifficulty.expert:
        return '고난도 사전 · 전략형 응답';
    }
  }

  int get turnTimeLimitSeconds {
    switch (this) {
      case AiDifficulty.easy:
        return 35;
      case AiDifficulty.normal:
        return 30;
      case AiDifficulty.hard:
        return 25;
      case AiDifficulty.expert:
        return 20;
    }
  }

}

AiDifficulty aiDifficultyFromId(String? id) {
  switch (id) {
    case 'easy':
      return AiDifficulty.easy;
    case 'normal':
      return AiDifficulty.normal;
    case 'hard':
      return AiDifficulty.hard;
    case 'expert':
      return AiDifficulty.expert;
    default:
      return AiDifficulty.normal;
  }
}
