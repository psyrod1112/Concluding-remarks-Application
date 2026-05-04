class FriendlyRoom {
  final int id;
  final String title;
  final String hostId;
  final String hostNickname;
  final String? password;
  final int maxPlayerCount;
  final DateTime createdAt;
  final List<String> participantIds;

  FriendlyRoom({
    required this.id,
    required this.title,
    required this.hostId,
    required this.hostNickname,
    required this.createdAt,
    required this.participantIds,
    this.password,
    this.maxPlayerCount = 2,
  });

  bool get hasPassword => password != null && password!.isNotEmpty;

  int get currentPlayerCount => participantIds.length;

  bool get isFull => currentPlayerCount >= maxPlayerCount;

  String get roomCode => 'FR-${id.toString().padLeft(4, '0')}';

  FriendlyRoom copyWith({
    String? title,
    String? hostId,
    String? hostNickname,
    String? password,
    int? maxPlayerCount,
    DateTime? createdAt,
    List<String>? participantIds,
  }) {
    return FriendlyRoom(
      id: id,
      title: title ?? this.title,
      hostId: hostId ?? this.hostId,
      hostNickname: hostNickname ?? this.hostNickname,
      password: password ?? this.password,
      maxPlayerCount: maxPlayerCount ?? this.maxPlayerCount,
      createdAt: createdAt ?? this.createdAt,
      participantIds: participantIds ?? List<String>.from(this.participantIds),
    );
  }
}
