import 'package:flutter/material.dart';

import '../models/friendly_room.dart';
import '../services/auth_service.dart';
import '../services/friendly_match_service.dart';
import '../utils/app_message.dart';

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

  void openCreateRoomSheet() {
    final user = AuthService().getCurrentUser();

    if (user == null) {
      AppMessage.show(context, '로그인 정보가 없습니다.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CreateRoomSheet(
          onSubmit: ({required String title, required String? password}) {
            final room = friendlyMatchService.createRoom(
              title: title,
              hostId: user.userId,
              hostNickname: user.nickname,
              password: password,
            );

            setState(() {});
            Navigator.pop(context);
            AppMessage.show(this.context, '${room.title} 방을 만들었습니다.');
            openEnteredRoomDialog(room.copyWith());
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
        openEnteredRoomDialog(enteredRoom);
        break;
      case JoinRoomResult.alreadyJoined:
        AppMessage.show(context, '이미 입장한 방입니다.');
        openEnteredRoomDialog(room);
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

  void openEnteredRoomDialog(FriendlyRoom room) {
    showDialog(
      context: context,
      builder: (context) {
        return _EnteredRoomDialog(room: room);
      },
    );
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('친선 대결'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
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
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
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
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFFE8EAF6),
            child: Icon(Icons.groups_2_outlined, color: Color(0xFF3F51B5)),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '친구와 방을 만들어 대결하세요',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  '공개방 또는 비밀번호 방을 만들고, 현재 인원을 확인한 뒤 입장할 수 있습니다.',
                  style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.35),
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
    final isFull = room.isFull;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFull ? Colors.black12 : const Color(0xFFE8EAF6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RoomStatusBadge(
                text: room.hasPassword ? '비공개' : '공개',
                icon: room.hasPassword ? Icons.lock_outline : Icons.lock_open_outlined,
              ),
              const SizedBox(width: 8),
              _RoomStatusBadge(
                text: isFull ? '가득 참' : '대기중',
                icon: isFull ? Icons.block : Icons.play_circle_outline,
              ),
              const Spacer(),
              Text(
                timeText,
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            room.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 17, color: Colors.black45),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '방장 ${room.hostNickname} · ${room.roomCode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
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
                    backgroundColor: const Color(0xFFECEFF1),
                    color: isFull ? Colors.redAccent : const Color(0xFF3F51B5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.groups_outlined,
                size: 18,
                color: isFull ? Colors.redAccent : const Color(0xFF3F51B5),
              ),
              const SizedBox(width: 4),
              Text(
                '${room.currentPlayerCount}/${room.maxPlayerCount}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isFull ? Colors.redAccent : const Color(0xFF3F51B5),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: isFull ? null : onEnter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black12,
                    disabledForegroundColor: Colors.black38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF3F51B5)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3F51B5),
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
    return const Center(
      child: Text(
        '아직 생성된 친선 대결 방이 없습니다.',
        style: TextStyle(fontSize: 15, color: Colors.black45),
      ),
    );
  }
}

class _CreateRoomSheet extends StatefulWidget {
  final void Function({required String title, required String? password}) onSubmit;

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

    widget.onSubmit(
      title: title,
      password: usePassword ? password : null,
    );
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                '친선 대결 방 만들기',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: inputDecoration(
                  label: '방 제목',
                  hint: '예: 친구랑 한 판',
                  icon: Icons.title,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SwitchListTile(
                  value: usePassword,
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF3F51B5),
                  title: const Text(
                    '비밀번호 설정',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('친구만 들어오게 하려면 켜주세요.'),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
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
    return AlertDialog(
      title: const Text('비밀번호 입력'),
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
          fillColor: const Color(0xFFF5F6FA),
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
        ElevatedButton(
          onPressed: submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F51B5),
            foregroundColor: Colors.white,
          ),
          child: const Text('입장'),
        ),
      ],
    );
  }
}

class _EnteredRoomDialog extends StatelessWidget {
  final FriendlyRoom room;

  const _EnteredRoomDialog({required this.room});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '친선 대결 방 입장 완료',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            room.title,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoomInfoLine(label: '방 코드', value: room.roomCode),
                  const SizedBox(height: 8),
                  _RoomInfoLine(label: '방장', value: room.hostNickname),
                  const SizedBox(height: 8),
                  _RoomInfoLine(
                    label: '현재 인원',
                    value: '${room.currentPlayerCount}/${room.maxPlayerCount}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '실제 끝말잇기 채팅방 화면은 이후 게임 로직과 Socket.IO 연결 시 이 위치에서 Navigator로 이동시키면 됩니다.',
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.45),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            AppMessage.show(context, '게임방 화면은 추후 연결 예정입니다.');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F51B5),
            foregroundColor: Colors.white,
          ),
          child: const Text('게임 시작'),
        ),
      ],
    );
  }
}

class _RoomInfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _RoomInfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
