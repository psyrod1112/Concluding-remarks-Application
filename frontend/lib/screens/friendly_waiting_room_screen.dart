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

class _FriendlyWaitingRoomScreenState
    extends State<FriendlyWaitingRoomScreen> {
  final FriendlyMatchService _service = FriendlyMatchService();

  FriendlyRoom? _room;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    // 서버에서 최신 상태로 동기화
    _loadRoom();
  }

  Future<void> _loadRoom() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final fresh = await _service.getRoomById(widget.room.id);
      if (!mounted) return;
      if (fresh == null) {
        // 방이 삭제됨 — 목록으로 복귀
        AppMessage.show(context, '방이 사라졌습니다.');
        Navigator.pop(context, true);
        return;
      }
      setState(() => _room = fresh);
    } catch (_) {
      // 네트워크 오류 시 기존 데이터 유지
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshRoom() async {
    await _loadRoom();
    if (mounted) AppMessage.show(context, '대기방 정보를 새로고침했습니다.');
  }

  bool _isMe(String userId) {
    final currentUser = AuthService().getCurrentUser();
    return currentUser != null && currentUser.userId == userId;
  }

  void _startGame(FriendlyRoom room) {
    if (room.currentPlayerCount < 2) {
      AppMessage.show(context, '상대가 들어오면 게임을 시작할 수 있습니다.');
      return;
    }

    final currentUser = AuthService().getCurrentUser();

    final opponent = room.participants.firstWhere(
      (p) => currentUser == null || p.userId != currentUser.userId,
      orElse: () => room.participants.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(
          arguments: {
            'roomId':            room.id.toString(),
            'roomType':          'friendly',
            'roomTitle':         room.title,
            'opponentId':        opponent.userId,
            'opponentNickname':  opponent.nickname,
            'isMockMode':        true,
          },
        ),
        builder: (context) => const GameScreen(),
      ),
    );
  }

  Future<void> _leaveRoom(FriendlyRoom room) async {
    final success = await _service.leaveRoom(room.id);
    if (!mounted) return;

    if (!success) {
      AppMessage.show(context, '방 나가기에 실패했습니다.');
      return;
    }

    AppMessage.show(context, '방에서 나갔습니다.');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;

    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('친선전 대기방')),
        body: const Center(child: CircularProgressIndicator()),
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
            onPressed: _refreshRoom,
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRoom,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // 방 정보 카드
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: colorScheme.primary.withOpacity(0.25)),
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

            // 참가 멤버
            Text(
              '참가 멤버',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            ...room.participants.map((participant) {
              final isHost = participant.userId == room.hostId;
              final me = _isMe(participant.userId);

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
                            '${participant.nickname}${me ? ' (나)' : ''}',
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

            // 빈 자리
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

            // 상태 안내
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
                      canStart
                          ? '게임을 시작할 수 있습니다.'
                          : '상대가 들어오기를 기다리는 중입니다.',
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

            // 게임 시작
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: canStart ? () => _startGame(room) : null,
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

            // 방 나가기
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => _leaveRoom(room),
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
      ),
    );
  }
}
