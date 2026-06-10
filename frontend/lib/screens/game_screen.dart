import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ai_difficulty.dart';
import '../services/auth_service.dart';
import '../services/game_socket_service.dart';
import '../utils/app_message.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String roomId = '';
  String roomType = 'random';
  String opponentId = '';
  bool isMockMode = false;
  AiDifficulty? aiDifficulty;
  int turnTimeLimitSeconds = 30;

  final TextEditingController wordController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String roomTitle = '말꼬리 대결';
  String opponentNickname = '상대방';

  bool isLoadedArguments = false;
  bool isListeningSocket = false;
  bool isMyTurn = false;
  bool isOpponentThinking = false;
  bool isGameOver = false;

  int myScore = 0;
  int opponentScore = 0;
  int remainingSeconds = 30;

  StreamSubscription<Map<String, dynamic>>? socketSubscription;

  final List<String> usedWords = [];
  final List<GameMessage> messages = [];

  String? currentWord;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (isLoadedArguments) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is Map<String, dynamic>) {
      roomId = arguments['roomId']?.toString() ?? roomId;
      roomType = arguments['roomType']?.toString() ?? roomType;
      roomTitle = arguments['roomTitle']?.toString() ?? roomTitle;
      opponentId = arguments['opponentId']?.toString() ?? opponentId;
      opponentNickname =
          arguments['opponentNickname']?.toString() ?? opponentNickname;
      isMockMode = arguments['isMockMode'] == true;
      isMyTurn = arguments['isMyTurn'] == true;
      aiDifficulty = aiDifficultyFromId(arguments['difficultyId']?.toString());
      turnTimeLimitSeconds = int.tryParse(
            arguments['turnTimeLimitSeconds']?.toString() ?? '',
          ) ??
          aiDifficulty?.turnTimeLimitSeconds ??
          30;
    }

    isLoadedArguments = true;

    if (isMockMode) {
      messages.add(
        const GameMessage(
          text: '게임 서버 연결 후 실제 대결이 진행됩니다.',
          type: GameMessageType.system,
        ),
      );
    } else {
      listenToSocket();
      connectFriendlyRoomIfNeeded();
      messages.add(
        GameMessage(
          text: roomType == 'friendly'
              ? '친선방 게임 서버에 입장 중입니다.'
              : isMyTurn
                  ? '첫 단어를 입력하세요.'
                  : '상대방의 입력을 기다리는 중입니다.',
          type: GameMessageType.system,
        ),
      );
    }

  }

  @override
  void dispose() {
    wordController.dispose();
    scrollController.dispose();
    socketSubscription?.cancel();
    super.dispose();
  }

  void listenToSocket() {
    if (isListeningSocket) return;
    isListeningSocket = true;

    final currentContext = context;

    socketSubscription = GameSocketService.instance.messages.listen((message) {
      final type = message['type']?.toString();

      switch (type) {
        case 'game_start':
          handleGameStart(message);
          break;
        case 'turn_start':
          handleTurnStart(message);
          break;
        case 'timer_tick':
          handleTimerTick(message);
          break;
        case 'word_accepted':
          handleWordAccepted(message);
          break;
        case 'word_invalid':
          if (!currentContext.mounted) return;
          AppMessage.show(
            currentContext,
            message['reason']?.toString() ?? '사용할 수 없는 단어입니다.',
          );
          break;
        case 'timeout':
          handleServerTimeout(message);
          break;
        case 'game_over':
          handleGameOver(message);
          break;
        case 'opponent_disconnected':
          setState(() {
            isGameOver = true;
            messages.add(
              GameMessage(
                text: message['message']?.toString() ?? '상대방 연결이 끊어졌습니다.',
                type: GameMessageType.system,
              ),
            );
          });
          break;
        case 'socket_closed':
          if (!isGameOver && currentContext.mounted) {
            AppMessage.show(currentContext, '게임 서버 연결이 종료되었습니다.');
          }
          break;
      }
    });
  }

  Future<void> connectFriendlyRoomIfNeeded() async {
    if (roomType != 'friendly') return;

    final currentContext = context;

    try {
      await GameSocketService.instance.connectAndAuth();
      GameSocketService.instance.joinRoom(roomId);
    } catch (e) {
      if (!currentContext.mounted) return;
      AppMessage.show(
        currentContext,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void handleGameStart(Map<String, dynamic> message) {
    final turnTime = int.tryParse(message['turnTime']?.toString() ?? '');

    setState(() {
      if (turnTime != null) {
        turnTimeLimitSeconds = turnTime;
        remainingSeconds = turnTime;
      }
      messages.add(
        const GameMessage(
          text: '게임이 시작되었습니다.',
          type: GameMessageType.system,
        ),
      );
    });
  }

  void handleTurnStart(Map<String, dynamic> message) {
    final user = AuthService().getCurrentUser();
    final turnNickname = message['turn']?.toString();
    final turnUserId = message['turnUserId']?.toString() ??
        message['turnPlayerId']?.toString() ??
        message['turnId']?.toString();
    final lastWord = message['lastWord']?.toString();
    final timeLimit = int.tryParse(message['timeLimit']?.toString() ?? '');
    final serverRemainingSeconds = int.tryParse(
      message['remainingSeconds']?.toString() ?? '',
    );

    setState(() {
      if (lastWord != null && lastWord.isNotEmpty) {
        currentWord = lastWord;
      }
      if (timeLimit != null) {
        turnTimeLimitSeconds = timeLimit;
      }
      isMyTurn = turnUserId != null && turnUserId.isNotEmpty
          ? turnUserId == user?.userId
          : turnNickname == user?.nickname;
      isOpponentThinking = false;
      remainingSeconds = serverRemainingSeconds ?? turnTimeLimitSeconds;
    });
  }

  void handleTimerTick(Map<String, dynamic> message) {
    final serverRemainingSeconds = int.tryParse(
      message['remainingSeconds']?.toString() ??
          message['secondsLeft']?.toString() ??
          message['timeLeft']?.toString() ??
          '',
    );

    if (serverRemainingSeconds == null) return;

    setState(() {
      remainingSeconds = serverRemainingSeconds;
    });
  }

  void handleWordAccepted(Map<String, dynamic> message) {
    final user = AuthService().getCurrentUser();
    final word = message['word']?.toString() ?? '';
    final submittedBy = message['submittedBy']?.toString();
    final isMine = submittedBy == user?.nickname;

    if (word.isEmpty) return;

    setState(() {
      if (!usedWords.contains(word)) {
        usedWords.add(word);
      }
      currentWord = word;

      if (isMine) {
        myScore += word.length * 10;
      } else {
        opponentScore += word.length * 10;
      }

      messages.add(
        GameMessage(
          text: word,
          type: isMine ? GameMessageType.mine : GameMessageType.opponent,
        ),
      );
    });

    scrollToBottom();
  }

  void handleServerTimeout(Map<String, dynamic> message) {
    final player = message['player']?.toString() ?? '플레이어';
    final livesLeft = message['livesLeft']?.toString();

    setState(() {
      messages.add(
        GameMessage(
          text: livesLeft == null ? '$player 시간 초과' : '$player 시간 초과 · 남은 기회 $livesLeft',
          type: GameMessageType.system,
        ),
      );
    });

    scrollToBottom();
  }

  void handleGameOver(Map<String, dynamic> message) {
    final winner = message['winner']?.toString() ?? '';
    final loser = message['loser']?.toString() ?? '';
    final scoreChange = message['scoreChange']?.toString();


    setState(() {
      isGameOver = true;
      isMyTurn = false;
      isOpponentThinking = false;
      messages.add(
        GameMessage(
          text: scoreChange == null || scoreChange.isEmpty
              ? '게임 종료 · 승리 $winner / 패배 $loser'
              : '게임 종료 · 승리 $winner / 패배 $loser · 점수 변동 $scoreChange',
          type: GameMessageType.system,
        ),
      );
    });

    scrollToBottom();
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

    if (usedWords.contains(word)) {
      AppMessage.show(context, '이미 사용한 단어입니다.');
      return;
    }

    if (isMockMode) {
      AppMessage.show(context, '게임 서버 연결 후 입력할 수 있습니다.');
      return;
    }

    try {
      GameSocketService.instance.submitWord(word);
      wordController.clear();
    } catch (e) {
      AppMessage.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String getCurrentLastLetter() {
    final word = currentWord;

    if (word == null || word.isEmpty) {
      return '';
    }

    return String.fromCharCode(word.runes.last);
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
              opponentLabel: roomType == 'ai' ? 'AI' : '상대',
              myScore: myScore,
              opponentScore: opponentScore,
              remainingSeconds: remainingSeconds,
              isMyTurn: isMyTurn,
              isOpponentThinking: isOpponentThinking,
            ),
            if (roomType == 'ai' && aiDifficulty != null)
              _AiBattleStatusCard(difficulty: aiDifficulty!),
            _CurrentWordCard(
              currentWord: currentWord,
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
                      enabled: isMyTurn && !isOpponentThinking && !isGameOver,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => submitWord(),
                      decoration: InputDecoration(
                        hintText: isGameOver
                            ? '게임이 종료되었습니다.'
                            : isMyTurn
                                ? nextStartLetter.isEmpty
                                    ? '첫 단어를 입력하세요'
                                    : '$nextStartLetter(으)로 시작하는 단어'
                                : roomType == 'ai'
                                    ? 'AI 턴입니다.'
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
                      onPressed: isMyTurn && !isOpponentThinking && !isGameOver
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
  final String opponentLabel;
  final int remainingSeconds;
  final bool isMyTurn;
  final bool isOpponentThinking;

  const _ScoreBoard({
    required this.myNickname,
    required this.opponentNickname,
    required this.opponentLabel,
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
                      ? '$opponentLabel 생각중'
                      : isMyTurn
                          ? '내 턴'
                          : '$opponentLabel 턴',
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
              label: opponentLabel,
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

class _AiBattleStatusCard extends StatelessWidget {
  final AiDifficulty difficulty;

  const _AiBattleStatusCard({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.primary.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.smart_toy_outlined, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI대결 · ${difficulty.title}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  difficulty.backendMemo,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${difficulty.turnTimeLimitSeconds}초 턴',
            style: TextStyle(
              fontSize: 12,
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
  final String? currentWord;
  final String nextStartLetter;

  const _CurrentWordCard({
    required this.currentWord,
    required this.nextStartLetter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasWord = currentWord != null && currentWord!.isNotEmpty;

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
                  hasWord ? '현재 단어' : '현재 단어 없음',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasWord ? currentWord! : '첫 단어를 기다리는 중',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (hasWord) ...[
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
