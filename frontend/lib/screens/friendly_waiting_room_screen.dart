import 'package:flutter/material.dart';

import '../models/friendly_room.dart';
import '../services/auth_service.dart';
import '../services/friendly_match_service.dart';
import '../utils/app_message.dart';
import 'game_screen.dart';

class FriendlyWaitingRoomScreen extends StatefulWidget {
  final FriendlyRoom room;

  const FriendlyWaitingRoomScreen({super.key, required this.room});

  @override
  State<FriendlyWaitingRoomScreen> createState() =>
      _FriendlyWaitingRoomScreenState();
}

class _FriendlyWaitingRoomScreenState extends State<FriendlyWaitingRoomScreen> {
  final FriendlyMatchService friendlyMatchService = FriendlyMatchService();

  FriendlyRoom? get currentRoom {
    return friendlyMatchService.getRoomById(widget.room.id);
  }

  String getNickname({
    required String participantId,
    required FriendlyRoom room,
  }) {
    final currentUser = AuthService().getCurrentUser();

    if (participantId == room.hostId) {
      return room.hostNickname;
    }

    if (currentUser != null && participantId == currentUser.userId) {
      return currentUser.nickname;
    }

    final mockNicknames = {
      'legend_001': '레전드초보',
      'apple_king': '사과왕',
      'word_master': '끝말고수',
      'banana_user': '바나나킥',
    };

    return mockNicknames[participantId] ?? participantId;
  }

  bool isMe(String participantId) {
    final currentUser = AuthService().getCurrentUser();
    return currentUser != null && currentUser.userId == participantId;
  }

  void refreshRoom() {
    setState(() {});
    AppMessage.show(context, '대기방 정보를 새로고침했습니다.');
  }

  void startGame(FriendlyRoom room) {
    if (room.currentPlayerCount < 2) {
      AppMessage.show(context, '상대가 들어오면 게임을 시작할 수 있습니다.');
      return;
    }

    final currentUser = AuthService().getCurrentUser();

    final opponentId = room.participantIds.firstWhere(
      (id) => currentUser == null || id != currentUser.userId,
      orElse: () => room.hostId,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(
          arguments: {
            'roomId': room.id.toString(),
            'roomType': 'friendly',
            'roomTitle': room.title,
            'opponentId': opponentId,
            'opponentNickname': getNickname(
              participantId: opponentId,
              room: room,
            ),
            'isMockMode': true,
          },
        ),
        builder: (context) => const GameScreen(),
      ),
    );
  }

  void leaveRoom(FriendlyRoom room) {
    final currentUser = AuthService().getCurrentUser();

    if (currentUser == null) {
      AppMessage.show(context, '로그인 정보가 없습니다.');
      return;
    }

    final success = friendlyMatchService.leaveRoom(
      roomId: room.id,
      userId: currentUser.userId,
    );

    if (!success) {
      AppMessage.show(context, '방 나가기에 실패했습니다.');
      return;
    }

    AppMessage.show(context, '방에서 나갔습니다.');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final room = currentRoom;

    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('친선전 대기방')),
        body: Center(
          child: Text(
            '방이 삭제되었거나 찾을 수 없습니다.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canStart = room.currentPlayerCount >= 2;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('친선전 대기방'),
        actions: [
          IconButton(
            onPressed: refreshRoom,
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.primary.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colorScheme.primary.withOpacity(0.15),
                      child: Icon(
                        room.hasPassword
                            ? Icons.lock_outline
                            : Icons.lock_open_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${room.roomCode} · ${room.hasPassword ? '비공개방' : '공개방'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withOpacity(0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: room.currentPlayerCount / room.maxPlayerCount,
                    minHeight: 10,
                    backgroundColor: colorScheme.onSurface.withOpacity(0.10),
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '현재 인원 ${room.currentPlayerCount}/${room.maxPlayerCount}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '참가 멤버',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...room.participantIds.map((participantId) {
            final isHost = participantId == room.hostId;
            final me = isMe(participantId);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isHost
                        ? colorScheme.primary
                        : colorScheme.primary.withOpacity(0.16),
                    child: Icon(
                      isHost ? Icons.workspace_premium : Icons.person,
                      color: isHost ? Colors.white : colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${getNickname(participantId: participantId, room: room)}${me ? ' (나)' : ''}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isHost ? '방장' : '참가자',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.60),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isHost)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'HOST',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          if (room.currentPlayerCount < room.maxPlayerCount)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.08),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.onSurface.withOpacity(0.08),
                    child: Icon(
                      Icons.person_add_alt_1,
                      color: colorScheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '빈 자리 · 상대 대기 중',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  canStart ? Icons.sports_esports : Icons.hourglass_empty,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    canStart ? '게임을 시작할 수 있습니다.' : '상대가 들어오기를 기다리는 중입니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: canStart ? () => startGame(room) : null,
              child: Text(
                canStart ? '게임 시작' : '상대 대기 중',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () => leaveRoom(room),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '방 나가기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
