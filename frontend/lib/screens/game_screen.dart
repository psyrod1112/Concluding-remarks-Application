import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_message.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // 임시
  String roomId = 'mock-room';
  String roomType = 'mock';
  String opponentId = 'mock-opponent';
  bool isMockMode = true;

  final TextEditingController wordController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String roomTitle = '말꼬리 대결';
  String opponentNickname = '상대방';

  bool isLoadedArguments = false;
  bool isMyTurn = true;
  bool isOpponentThinking = false;

  int myScore = 0;
  int opponentScore = 0;
  int remainingSeconds = 30;

  Timer? turnTimer;

  // MOCK START: 백엔드 연결 전까지 화면 테스트용으로만 사용하는 임시 데이터
  // 실제 백엔드 연결 후에는 서버에서 현재 단어, 사용 단어 목록, 점수, 턴 정보를 받아와야 함
  final List<String> usedWords = ['사과'];

  final List<GameMessage> messages = [
    GameMessage(text: '게임이 시작되었습니다.', type: GameMessageType.system),
    GameMessage(text: '시작 단어: 사과', type: GameMessageType.system),
  ];
  // MOCK END

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (isLoadedArguments) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is Map<String, dynamic>) {
      roomId = arguments['roomId'] ?? roomId;
      roomType = arguments['roomType'] ?? roomType;
      roomTitle = arguments['roomTitle'] ?? roomTitle;
      opponentId = arguments['opponentId'] ?? opponentId;
      opponentNickname = arguments['opponentNickname'] ?? opponentNickname;
      isMockMode = arguments['isMockMode'] ?? isMockMode;
    }

    isLoadedArguments = true;
    startTimer();
  }

  @override
  void dispose() {
    wordController.dispose();
    scrollController.dispose();
    turnTimer?.cancel();
    super.dispose();
  }

  void startTimer() {
    turnTimer?.cancel();

    setState(() {
      remainingSeconds = 30;
    });

    turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (!isMyTurn || isOpponentThinking) return;

      if (remainingSeconds <= 0) {
        timer.cancel();
        handleTimeout();
        return;
      }

      setState(() {
        remainingSeconds--;
      });
    });
  }

  void handleTimeout() {
    setState(() {
      isMyTurn = false;
      messages.add(
        const GameMessage(
          text: '시간 초과로 턴이 넘어갔습니다.',
          type: GameMessageType.system,
        ),
      );
    });

    AppMessage.show(context, '시간이 초과되었습니다.');

    // MOCK START: 백엔드 연결 전 임시 상대 턴 처리
    // 실제 연결 후에는 서버에서 시간 초과 처리 결과를 받아와야 함
    simulateMockOpponentTurn();
    // MOCK END
  }

  void submitWord() {
    final word = wordController.text.trim();

    if (word.isEmpty) {
      AppMessage.show(context, '단어를 입력해주세요.');
      return;
    }

    if (word.length < 2) {
      AppMessage.show(context, '두 글자 이상의 단어를 입력해주세요.');
      return;
    }

    // MOCK START: 백엔드 연결 전 임시 중복 검사
    // 실제 연결 후에는 백엔드에서 중복 단어 여부를 판정해야 함
    if (usedWords.contains(word)) {
      AppMessage.show(context, '이미 사용한 단어입니다.');
      return;
    }
    // MOCK END

    // TODO: 백엔드 연결 시 이 위치에서 단어 제출 API 호출
    //
    // 예시 엔드포인트:
    // POST /api/game/rooms/{roomId}/words
    //
    // 요청 예시:
    // {
    //   "word": word
    // }
    //
    // 백엔드에서 처리해야 할 것:
    // 1. 실제 존재하는 단어인지 검사
    // 2. 끝말잇기 규칙 검사
    // 3. 두음법칙 처리
    // 4. 중복 단어 검사
    // 5. 점수 계산
    // 6. 턴 변경
    //
    // 프론트는 서버 응답을 받아 화면만 갱신하면 됨

    // MOCK START: 백엔드 연결 전 임시 화면 업데이트
    // 실제 연결 후에는 서버 응답값으로 messages, score, turn 상태를 갱신해야 함
    setState(() {
      usedWords.add(word);
      myScore += word.length * 10;
      isMyTurn = false;
      wordController.clear();

      messages.add(GameMessage(text: word, type: GameMessageType.mine));
    });

    scrollToBottom();
    simulateMockOpponentTurn();
    // MOCK END
  }

  // MOCK START: 백엔드 연결 전까지 상대가 단어를 입력한 것처럼 보이게 하는 임시 함수
  // 실제 게임에서는 Socket.IO 또는 API 응답으로 상대 입력 결과를 받아와야 함
  Future<void> simulateMockOpponentTurn() async {
    setState(() {
      isOpponentThinking = true;
    });

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    final mockWord = getMockOpponentWord();

    setState(() {
      usedWords.add(mockWord);
      opponentScore += mockWord.length * 10;
      isOpponentThinking = false;
      isMyTurn = true;

      messages.add(GameMessage(text: mockWord, type: GameMessageType.opponent));
    });

    scrollToBottom();
    startTimer();
  }

  String getMockOpponentWord() {
    final mockWords = [
      '과자',
      '자동차',
      '차고',
      '고래',
      '래퍼',
      '퍼즐',
      '즐거움',
      '음악',
      '악기',
      '기차',
    ];

    for (final word in mockWords) {
      if (!usedWords.contains(word)) {
        return word;
      }
    }

    return '끝말';
  }
  // MOCK END

  String getCurrentLastLetter() {
    final currentWord = usedWords.last;

    if (currentWord.isEmpty) {
      return '';
    }

    return String.fromCharCode(currentWord.runes.last);
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().getCurrentUser();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nextStartLetter = getCurrentLastLetter();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(roomTitle)),
      body: SafeArea(
        child: Column(
          children: [
            _ScoreBoard(
              myNickname: user?.nickname ?? '게스트',
              opponentNickname: opponentNickname,
              myScore: myScore,
              opponentScore: opponentScore,
              remainingSeconds: remainingSeconds,
              isMyTurn: isMyTurn,
              isOpponentThinking: isOpponentThinking,
            ),
            _CurrentWordCard(
              currentWord: usedWords.last,
              nextStartLetter: nextStartLetter,
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                itemBuilder: (context, index) {
                  return _MessageBubble(message: messages[index]);
                },
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemCount: messages.length,
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.onSurface.withOpacity(0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: wordController,
                      enabled: isMyTurn && !isOpponentThinking,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => submitWord(),
                      decoration: InputDecoration(
                        hintText: isMyTurn
                            ? '$nextStartLetter(으)로 시작하는 단어'
                            : '상대 턴입니다.',
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isMyTurn && !isOpponentThinking
                          ? submitWord
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBoard extends StatelessWidget {
  final String myNickname;
  final String opponentNickname;
  final int myScore;
  final int opponentScore;
  final int remainingSeconds;
  final bool isMyTurn;
  final bool isOpponentThinking;

  const _ScoreBoard({
    required this.myNickname,
    required this.opponentNickname,
    required this.myScore,
    required this.opponentScore,
    required this.remainingSeconds,
    required this.isMyTurn,
    required this.isOpponentThinking,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PlayerScoreCard(
              label: '나',
              nickname: myNickname,
              score: myScore,
              isActive: isMyTurn && !isOpponentThinking,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    '$remainingSeconds',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isOpponentThinking
                      ? '상대 생각중'
                      : isMyTurn
                      ? '내 턴'
                      : '상대 턴',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _PlayerScoreCard(
              label: '상대',
              nickname: opponentNickname,
              score: opponentScore,
              isActive: !isMyTurn || isOpponentThinking,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerScoreCard extends StatelessWidget {
  final String label;
  final String nickname;
  final int score;
  final bool isActive;

  const _PlayerScoreCard({
    required this.label,
    required this.nickname,
    required this.score,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primary.withOpacity(0.16)
            : colorScheme.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? colorScheme.primary
              : colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score점',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentWordCard extends StatelessWidget {
  final String currentWord;
  final String nextStartLetter;

  const _CurrentWordCard({
    required this.currentWord,
    required this.nextStartLetter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primary.withOpacity(0.15),
            child: Icon(Icons.text_fields, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현재 단어',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentWord,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '다음 시작 글자: $nextStartLetter',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
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

class _MessageBubble extends StatelessWidget {
  final GameMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isMine = message.type == GameMessageType.mine;
    final isSystem = message.type == GameMessageType.system;

    return Align(
      alignment: isSystem
          ? Alignment.center
          : isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSystem
              ? colorScheme.onSurface.withOpacity(0.08)
              : isMine
              ? colorScheme.primary
              : colorScheme.onSurface.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 14,
            color: isMine ? Colors.white : colorScheme.onSurface,
            fontWeight: isSystem ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class GameMessage {
  final String text;
  final GameMessageType type;

  const GameMessage({required this.text, required this.type});
}

enum GameMessageType { mine, opponent, system }
