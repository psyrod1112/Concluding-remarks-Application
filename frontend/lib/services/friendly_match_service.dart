import '../models/friendly_room.dart';

enum JoinRoomResult {
  success,
  roomNotFound,
  full,
  alreadyJoined,
  passwordRequired,
  wrongPassword,
}

class FriendlyMatchService {
  static int _nextId = 4;

  static final List<FriendlyRoom> _rooms = [
    FriendlyRoom(
      id: 1,
      title: '초보 환영 방',
      hostId: 'apple_king',
      hostNickname: '사과왕',
      createdAt: DateTime.now().subtract(const Duration(minutes: 7)),
      participantIds: const ['apple_king'],
    ),
    FriendlyRoom(
      id: 2,
      title: '친구랑 연습 중',
      hostId: 'word_master',
      hostNickname: '끝말고수',
      password: '1111',
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      participantIds: const ['word_master'],
    ),
    FriendlyRoom(
      id: 3,
      title: '빠른 대결 갑니다',
      hostId: 'banana_user',
      hostNickname: '바나나킥',
      createdAt: DateTime.now().subtract(const Duration(minutes: 32)),
      participantIds: const ['banana_user', 'legend_001'],
    ),
  ];

  List<FriendlyRoom> getRooms() {
    return List.unmodifiable(_rooms);
  }

  FriendlyRoom createRoom({
    required String title,
    required String hostId,
    required String hostNickname,
    String? password,
  }) {
    final room = FriendlyRoom(
      id: _nextId,
      title: title,
      hostId: hostId,
      hostNickname: hostNickname,
      password: password == null || password.isEmpty ? null : password,
      createdAt: DateTime.now(),
      participantIds: [hostId],
    );

    _nextId++;
    _rooms.insert(0, room);
    return room;
  }

  JoinRoomResult joinRoom({
    required int roomId,
    required String userId,
    String? password,
  }) {
    final index = _rooms.indexWhere((room) => room.id == roomId);

    if (index == -1) {
      return JoinRoomResult.roomNotFound;
    }

    final room = _rooms[index];

    if (room.participantIds.contains(userId)) {
      return JoinRoomResult.alreadyJoined;
    }

    if (room.isFull) {
      return JoinRoomResult.full;
    }

    if (room.hasPassword && (password == null || password.isEmpty)) {
      return JoinRoomResult.passwordRequired;
    }

    if (room.hasPassword && room.password != password) {
      return JoinRoomResult.wrongPassword;
    }

    final updatedParticipants = List<String>.from(room.participantIds)..add(userId);
    _rooms[index] = room.copyWith(participantIds: updatedParticipants);

    return JoinRoomResult.success;
  }
}
