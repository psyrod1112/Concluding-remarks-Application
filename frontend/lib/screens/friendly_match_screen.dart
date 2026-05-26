import 'package:flutter/material.dart';

import '../models/friendly_room.dart';
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
  final FriendlyMatchService friendlyMatchService = FriendlyMatchService();

  List<FriendlyRoom> get rooms => friendlyMatchService.getRooms();

  void refreshRooms() {
    setState(() {});
    AppMessage.show(context, '방 목록을 새로고침했습니다.');
  }

  void openWaitingRoom(FriendlyRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendlyWaitingRoomScreen(room: room),
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void openCreateRoomSheet() {
    final user = AuthService().getCurrentUser();

    if (user == null) {
      AppMessage.show(context, '로그인 정보가 없습니다.');
      return;
    }

    final joinedRoom = friendlyMatchService.getJoinedRoomByUserId(user.userId);

    if (joinedRoom != null) {
      AppMessage.show(context, '이미 참여 중인 방이 있습니다.');
      openWaitingRoom(joinedRoom);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CreateRoomSheet(
          onSubmit: ({required String title, required String? password}) {
            final joinedRoom = friendlyMatchService.getJoinedRoomByUserId(
              user.userId,
            );

            if (joinedRoom != null) {
              Navigator.pop(context);
              AppMessage.show(this.context, '이미 참여 중인 방이 있습니다.');
              openWaitingRoom(joinedRoom);
              return;
            }

            final room = friendlyMatchService.createRoom(
              title: title,
              hostId: user.userId,
              hostNickname: user.nickname,
              password: password,
            );

            if (room == null) {
              Navigator.pop(context);
              AppMessage.show(this.context, '이미 참여 중인 방이 있습니다.');
              return;
            }

            setState(() {});
            Navigator.pop(context);
            AppMessage.show(this.context, '${room.title} 방을 만들었습니다.');
            openWaitingRoom(room);
          },
        );
      },
    );
  }

  Future<void> enterRoom(FriendlyRoom room) async {
    final user = AuthService().getCurrentUser();

    if (user == null) {
      AppMessage.show(context, '로그인 정보가 없습니다.');
      return;
    }

    final joinedRoom = friendlyMatchService.getJoinedRoomByUserId(user.userId);

    if (joinedRoom != null) {
      AppMessage.show(context, '이미 참여 중인 방이 있습니다.');
      openWaitingRoom(joinedRoom);
      return;
    }

    if (room.hasPassword) {
      final password = await showDialog<String>(
        context: context,
        builder: (context) {
          return const _PasswordDialog();
        },
      );

      if (password == null) {
        return;
      }

      joinRoom(room: room, userId: user.userId, password: password);
      return;
    }

    joinRoom(room: room, userId: user.userId);
  }

  void joinRoom({
    required FriendlyRoom room,
    required String userId,
    String? password,
  }) {
    final joinedRoom = friendlyMatchService.getJoinedRoomByUserId(userId);

    if (joinedRoom != null) {
      AppMessage.show(context, '이미 참여 중인 방이 있습니다.');
      openWaitingRoom(joinedRoom);
      return;
    }

    final result = friendlyMatchService.joinRoom(
      roomId: room.id,
      userId: userId,
      password: password,
    );

    switch (result) {
      case JoinRoomResult.success:
        setState(() {});
        final enteredRoom = rooms.firstWhere((item) => item.id == room.id);
        AppMessage.show(context, '${enteredRoom.title} 방에 입장했습니다.');
        openWaitingRoom(enteredRoom);
        break;

      case JoinRoomResult.alreadyJoined:
        final joinedRoom = friendlyMatchService.getJoinedRoomByUserId(userId);

        if (joinedRoom != null) {
          AppMessage.show(context, '이미 참여 중인 방입니다.');
          openWaitingRoom(joinedRoom);
        } else {
          AppMessage.show(context, '이미 입장한 방입니다.');
        }
        break;

      case JoinRoomResult.alreadyInOtherRoom:
        final joinedRoom = friendlyMatchService.getJoinedRoomByUserId(userId);

        if (joinedRoom != null) {
          AppMessage.show(context, '이미 다른 방에 참여 중입니다.');
          openWaitingRoom(joinedRoom);
        } else {
          AppMessage.show(context, '이미 다른 방에 참여 중입니다.');
        }
        break;

      case JoinRoomResult.full:
        AppMessage.show(context, '이미 가득 찬 방입니다.');
        break;

      case JoinRoomResult.passwordRequired:
        AppMessage.show(context, '비밀번호를 입력해주세요.');
        break;

      case JoinRoomResult.wrongPassword:
        AppMessage.show(context, '비밀번호가 일치하지 않습니다.');
        break;

      case JoinRoomResult.roomNotFound:
        AppMessage.show(context, '방을 찾을 수 없습니다.');
        break;
    }
  }

  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '방금 전';
    }

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    }

    if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    }

    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final currentRooms = rooms;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('친선 대결'),
        actions: [
          IconButton(
            onPressed: refreshRooms,
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateRoomSheet,
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
            child: currentRooms.isEmpty
                ? const _EmptyRoomView()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 92),
                    itemBuilder: (context, index) {
                      final room = currentRooms[index];

                      return _RoomListItem(
                        room: room,
                        timeText: formatTime(room.createdAt),
                        onEnter: () => enterRoom(room),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemCount: currentRooms.length,
                  ),
          ),
        ],
      ),
    );
  }
}

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
          color: isFull
              ? Colors.redAccent
              : colorScheme.primary.withOpacity(0.25),
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

    return Center(
      child: Text(
        '아직 생성된 친선 대결 방이 없습니다.',
        style: TextStyle(
          fontSize: 15,
          color: colorScheme.onSurface.withOpacity(0.55),
        ),
      ),
    );
  }
}

class _CreateRoomSheet extends StatefulWidget {
  final void Function({required String title, required String? password})
  onSubmit;

  const _CreateRoomSheet({required this.onSubmit});

  @override
  State<_CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<_CreateRoomSheet> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool usePassword = false;

  @override
  void dispose() {
    titleController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void submit() {
    final title = titleController.text.trim();
    final password = passwordController.text.trim();

    if (title.isEmpty) {
      AppMessage.show(context, '방 제목을 입력해주세요.');
      return;
    }

    if (title.length < 2) {
      AppMessage.show(context, '방 제목은 2자 이상 입력해주세요.');
      return;
    }

    if (usePassword && password.length < 4) {
      AppMessage.show(context, '비밀번호는 4자 이상 입력해주세요.');
      return;
    }

    widget.onSubmit(title: title, password: usePassword ? password : null);
  }

  InputDecoration inputDecoration({
    required BuildContext context,
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
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
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: inputDecoration(
                  context: context,
                  label: '방 제목',
                  hint: '예: 친구랑 한 판',
                  icon: Icons.title,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SwitchListTile(
                  value: usePassword,
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
                  onChanged: (value) {
                    setState(() {
                      usePassword = value;
                    });
                  },
                ),
              ),
              if (usePassword) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => submit(),
                  decoration: inputDecoration(
                    context: context,
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
                  onPressed: submit,
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

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  void submit() {
    final password = passwordController.text.trim();

    if (password.isEmpty) {
      AppMessage.show(context, '비밀번호를 입력해주세요.');
      return;
    }

    Navigator.pop(context, password);
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
        controller: passwordController,
        obscureText: true,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => submit(),
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
        ElevatedButton(onPressed: submit, child: const Text('입장')),
      ],
    );
  }
}
