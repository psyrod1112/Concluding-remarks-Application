import 'package:flutter/material.dart';

import '../models/friendly_room.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/friendly_match_service.dart';
import '../utils/app_message.dart';
import 'friendly_waiting_room_screen.dart';

class FriendlyMatchScreen extends StatefulWidget {
  const FriendlyMatchScreen({super.key});

  @override
  State<FriendlyMatchScreen> createState() => _FriendlyMatchScreenState();
}

class _FriendlyMatchScreenState extends State<FriendlyMatchScreen> {
  final FriendlyMatchService _service = FriendlyMatchService();

  List<FriendlyRoom> _rooms = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final rooms = await _service.getRooms();
      if (!mounted) return;
      setState(() => _rooms = rooms);
    } catch (e) {
      if (!mounted) return;
      AppMessage.show(context, '방 목록을 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshRooms() async {
    await _loadRooms();
    if (mounted) AppMessage.show(context, '방 목록을 새로고침했습니다.');
  }

  void _openWaitingRoom(FriendlyRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendlyWaitingRoomScreen(room: room),
      ),
    ).then((_) {
      if (!mounted) return;
      _loadRooms();
    });
  }

  Future<void> _openCreateRoomSheet() async {
    final user = AuthService().getCurrentUser();
    if (user == null) {
      AppMessage.show(context, '로그인 정보가 없습니다.');
      return;
    }

    // 이미 참여 중인 방이 있으면 그 방으로 이동
    try {
      final myRoom = await _service.getMyRoom();
      if (!mounted) return;
      if (myRoom != null) {
        AppMessage.show(context, '이미 참여 중인 방이 있습니다.');
        _openWaitingRoom(myRoom);
        return;
      }
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CreateRoomSheet(
          onSubmit: ({required String title, required String? password}) {
            Navigator.pop(context);
            _createRoom(title: title, password: password);
          },
        );
      },
    );
  }

  Future<void> _createRoom({
    required String title,
    required String? password,
  }) async {
    try {
      final room = await _service.createRoom(title: title, password: password);
      if (!mounted) return;
      setState(() {
        _rooms.insert(0, room);
      });
      AppMessage.show(context, '${room.title} 방을 만들었습니다.');
      _openWaitingRoom(room);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 400) {
        // 이미 다른 방에 참여 중
        final myRoom = await _service.getMyRoom();
        if (!mounted) return;
        if (myRoom != null) {
          AppMessage.show(context, '이미 참여 중인 방이 있습니다.');
          _openWaitingRoom(myRoom);
        }
      } else {
        AppMessage.show(context, e.message);
      }
    } catch (_) {
      if (!mounted) return;
      AppMessage.show(context, '방 만들기에 실패했습니다.');
    }
  }

  Future<void> _enterRoom(FriendlyRoom room) async {
    final user = AuthService().getCurrentUser();
    if (user == null) {
      AppMessage.show(context, '로그인 정보가 없습니다.');
      return;
    }

    if (room.hasPassword) {
      final password = await showDialog<String>(
        context: context,
        builder: (context) => const _PasswordDialog(),
      );
      if (password == null) return;
      await _joinRoom(room: room, password: password);
    } else {
      await _joinRoom(room: room);
    }
  }

  Future<void> _joinRoom({
    required FriendlyRoom room,
    String? password,
  }) async {
    final joinRes = await _service.joinRoom(
      roomId: room.id,
      password: password,
    );

    if (!mounted) return;

    switch (joinRes.result) {
      case JoinRoomResult.success:
        final joinedRoom = joinRes.room;
        if (joinedRoom == null) return;
        await _loadRooms();
        if (!mounted) return;
        AppMessage.show(context, '${joinedRoom.title} 방에 입장했습니다.');
        _openWaitingRoom(joinedRoom);

      case JoinRoomResult.alreadyJoined ||
            JoinRoomResult.alreadyInOtherRoom:
        final myRoom = await _service.getMyRoom();
        if (!mounted) return;
        if (myRoom != null) {
          AppMessage.show(context, '이미 참여 중인 방이 있습니다.');
          _openWaitingRoom(myRoom);
        }

      case JoinRoomResult.full:
        AppMessage.show(context, '이미 가득 찬 방입니다.');

      case JoinRoomResult.passwordRequired:
        AppMessage.show(context, '비밀번호를 입력해주세요.');

      case JoinRoomResult.wrongPassword:
        AppMessage.show(context, '비밀번호가 일치하지 않습니다.');

      case JoinRoomResult.roomNotFound:
        AppMessage.show(context, '방을 찾을 수 없습니다.');
        _loadRooms();

      case JoinRoomResult.error:
        AppMessage.show(context, '입장 중 오류가 발생했습니다.');
    }
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('친선 대결'),
        actions: [
          IconButton(
            onPressed: _refreshRooms,
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateRoomSheet,
        icon: const Icon(Icons.add),
        label: const Text('방 만들기'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: _FriendlyGuideCard(),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadRooms,
                    child: _rooms.isEmpty
                        ? const _EmptyRoomView()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 92),
                            itemBuilder: (context, index) {
                              final room = _rooms[index];
                              return _RoomListItem(
                                room: room,
                                timeText: _formatTime(room.createdAt),
                                onEnter: () => _enterRoom(room),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemCount: _rooms.length,
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── 안내 카드 ──────────────────────────────────────
class _FriendlyGuideCard extends StatelessWidget {
  const _FriendlyGuideCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: colorScheme.primary.withOpacity(0.15),
            child: Icon(Icons.groups_2_outlined, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '친구와 방을 만들어 대결하세요',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '공개방 또는 비밀번호 방을 만들고, 현재 인원을 확인한 뒤 입장할 수 있습니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.65),
                    height: 1.35,
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

// ── 방 목록 아이템 ─────────────────────────────────
class _RoomListItem extends StatelessWidget {
  final FriendlyRoom room;
  final String timeText;
  final VoidCallback onEnter;

  const _RoomListItem({
    required this.room,
    required this.timeText,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFull = room.isFull;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isFull ? Colors.redAccent : colorScheme.primary.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RoomStatusBadge(
                text: room.hasPassword ? '비공개' : '공개',
                icon: room.hasPassword
                    ? Icons.lock_outline
                    : Icons.lock_open_outlined,
              ),
              const SizedBox(width: 8),
              _RoomStatusBadge(
                text: isFull ? '가득 참' : '대기중',
                icon: isFull ? Icons.block : Icons.play_circle_outline,
              ),
              const Spacer(),
              Text(
                timeText,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            room.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 17,
                color: colorScheme.onSurface.withOpacity(0.55),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '방장 ${room.hostNickname} · ${room.roomCode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: room.currentPlayerCount / room.maxPlayerCount,
                    minHeight: 9,
                    backgroundColor: colorScheme.onSurface.withOpacity(0.10),
                    color: isFull ? Colors.redAccent : colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.groups_outlined,
                size: 18,
                color: isFull ? Colors.redAccent : colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${room.currentPlayerCount}/${room.maxPlayerCount}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isFull ? Colors.redAccent : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: isFull ? null : onEnter,
                  child: const Text(
                    '입장',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomStatusBadge extends StatelessWidget {
  final String text;
  final IconData icon;

  const _RoomStatusBadge({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            text,
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

class _EmptyRoomView extends StatelessWidget {
  const _EmptyRoomView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        SizedBox(height: 120),
        Center(
          child: Text(
            '아직 생성된 친선 대결 방이 없습니다.',
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 방 만들기 Bottom Sheet ──────────────────────────
class _CreateRoomSheet extends StatefulWidget {
  final void Function({required String title, required String? password})
  onSubmit;

  const _CreateRoomSheet({required this.onSubmit});

  @override
  State<_CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<_CreateRoomSheet> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _usePassword = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (title.length < 2) {
      AppMessage.show(context, '방 제목은 2자 이상 입력해주세요.');
      return;
    }
    if (_usePassword && password.length < 4) {
      AppMessage.show(context, '비밀번호는 4자 이상 입력해주세요.');
      return;
    }

    widget.onSubmit(title: title, password: _usePassword ? password : null);
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: theme.cardColor,
      labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.75)),
      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.45)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                '친선 대결 방 만들기',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: '방 제목',
                  hint: '예: 친구랑 한 판',
                  icon: Icons.title,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SwitchListTile(
                  value: _usePassword,
                  contentPadding: EdgeInsets.zero,
                  activeColor: colorScheme.primary,
                  title: Text(
                    '비밀번호 설정',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    '친구만 들어오게 하려면 켜주세요.',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                  onChanged: (v) => setState(() => _usePassword = v),
                ),
              ),
              if (_usePassword) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: _inputDecoration(
                    label: '방 비밀번호',
                    hint: '4자 이상 입력하세요',
                    icon: Icons.lock_outline,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text(
                    '방 만들기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 비밀번호 입력 다이얼로그 ────────────────────────
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final pw = _ctrl.text.trim();
    if (pw.isEmpty) {
      AppMessage.show(context, '비밀번호를 입력해주세요.');
      return;
    }
    Navigator.pop(context, pw);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text(
        '비밀번호 입력',
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      content: TextField(
        controller: _ctrl,
        obscureText: true,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: '방 비밀번호',
          prefixIcon: const Icon(Icons.lock_outline),
          filled: true,
          fillColor: theme.scaffoldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('입장')),
      ],
    );
  }
}
