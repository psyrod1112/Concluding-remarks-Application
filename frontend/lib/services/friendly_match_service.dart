import '../models/friendly_room.dart';

enum JoinRoomResult {
  success,
  roomNotFound,
  full,
  alreadyJoined,
  alreadyInOtherRoom,
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

  FriendlyRoom? getRoomById(int roomId) {
    try {
      return _rooms.firstWhere((room) => room.id == roomId);
    } catch (_) {
      return null;
    }
  }

  FriendlyRoom? getJoinedRoomByUserId(String userId) {
    try {
      return _rooms.firstWhere((room) => room.participantIds.contains(userId));
    } catch (_) {
      return null;
    }
  }

  bool isUserInAnyRoom(String userId) {
    return getJoinedRoomByUserId(userId) != null;
  }

  FriendlyRoom? createRoom({
    required String title,
    required String hostId,
    required String hostNickname,
    String? password,
  }) {
    if (isUserInAnyRoom(hostId)) {
      return null;
    }

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

    final joinedRoom = getJoinedRoomByUserId(userId);

    if (joinedRoom != null) {
      if (joinedRoom.id == roomId) {
        return JoinRoomResult.alreadyJoined;
      }

      return JoinRoomResult.alreadyInOtherRoom;
    }

    final room = _rooms[index];

    if (room.isFull) {
      return JoinRoomResult.full;
    }

    if (room.hasPassword && (password == null || password.isEmpty)) {
      return JoinRoomResult.passwordRequired;
    }

    if (room.hasPassword && room.password != password) {
      return JoinRoomResult.wrongPassword;
    }

    final updatedParticipants = List<String>.from(room.participantIds)
      ..add(userId);

    _rooms[index] = room.copyWith(participantIds: updatedParticipants);

    return JoinRoomResult.success;
  }

  bool leaveRoom({required int roomId, required String userId}) {
    final index = _rooms.indexWhere((room) => room.id == roomId);

    if (index == -1) {
      return false;
    }

    final room = _rooms[index];

    if (!room.participantIds.contains(userId)) {
      return false;
    }

    final updatedParticipants = List<String>.from(room.participantIds)
      ..remove(userId);

    if (updatedParticipants.isEmpty || room.hostId == userId) {
      _rooms.removeAt(index);
      return true;
    }

    _rooms[index] = room.copyWith(participantIds: updatedParticipants);

    return true;
  }
}
