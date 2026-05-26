class RoomParticipant {
  final String userId;
  final String nickname;

  const RoomParticipant({required this.userId, required this.nickname});

  factory RoomParticipant.fromJson(Map<String, dynamic> json) {
    return RoomParticipant(
      userId:   json['userId']   as String,
      nickname: json['nickname'] as String,
    );
  }
}

class FriendlyRoom {
  final int id;
  final String title;
  final String hostId;
  final String hostNickname;
  final bool hasPassword;
  final int maxPlayerCount;
  final DateTime createdAt;
  final List<RoomParticipant> participants;

  const FriendlyRoom({
    required this.id,
    required this.title,
    required this.hostId,
    required this.hostNickname,
    required this.hasPassword,
    required this.createdAt,
    required this.participants,
    this.maxPlayerCount = 2,
  });

  int get currentPlayerCount => participants.length;

  bool get isFull => currentPlayerCount >= maxPlayerCount;

  String get roomCode => 'FR-${id.toString().padLeft(4, '0')}';

  factory FriendlyRoom.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'] as List<dynamic>? ?? [];
    return FriendlyRoom(
      id:             json['id'] as int,
      title:          json['title'] as String,
      hostId:         json['hostId'] as String,
      hostNickname:   json['hostNickname'] as String,
      hasPassword:    json['hasPassword'] as bool? ?? false,
      maxPlayerCount: json['maxPlayers'] as int? ?? 2,
      createdAt:      DateTime.parse(json['createdAt'].toString()),
      participants:   rawParticipants
          .map((e) => RoomParticipant.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
