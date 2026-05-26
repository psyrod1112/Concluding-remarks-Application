import '../models/friendly_room.dart';
import 'api_client.dart';

enum JoinRoomResult {
  success,
  roomNotFound,
  full,
  alreadyJoined,
  alreadyInOtherRoom,
  passwordRequired,
  wrongPassword,
  error,
}

class FriendlyMatchService {
  // ── 방 목록 ──────────────────────────────────
  Future<List<FriendlyRoom>> getRooms() async {
    final data = await ApiClient.get('/api/game-rooms');
    return (data['rooms'] as List)
        .map((e) => FriendlyRoom.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 방 상세 조회 ─────────────────────────────
  Future<FriendlyRoom?> getRoomById(int roomId) async {
    try {
      final data = await ApiClient.get('/api/game-rooms/$roomId');
      return FriendlyRoom.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // ── 내가 참여 중인 방 조회 ───────────────────
  Future<FriendlyRoom?> getMyRoom() async {
    try {
      final data = await ApiClient.get('/api/game-rooms/my');
      return FriendlyRoom.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  // ── 방 만들기 ─────────────────────────────────
  /// 생성된 FriendlyRoom 반환. 이미 다른 방에 있으면 ApiException(400) throw.
  Future<FriendlyRoom> createRoom({
    required String title,
    String? password,
  }) async {
    final data = await ApiClient.post('/api/game-rooms', {
      'title': title,
      if (password != null && password.isNotEmpty) 'password': password,
    });
    return FriendlyRoom.fromJson(data['room'] as Map<String, dynamic>);
  }

  // ── 방 입장 ───────────────────────────────────
  Future<({JoinRoomResult result, FriendlyRoom? room})> joinRoom({
    required int roomId,
    String? password,
  }) async {
    try {
      final data = await ApiClient.post('/api/game-rooms/$roomId/join', {
        if (password != null) 'password': password,
      });
      final room = FriendlyRoom.fromJson(
        data['room'] as Map<String, dynamic>,
      );
      return (result: JoinRoomResult.success, room: room);
    } on ApiException catch (e) {
      final result = switch (e.statusCode) {
        400 => JoinRoomResult.alreadyInOtherRoom,
        403 => JoinRoomResult.wrongPassword,
        404 => JoinRoomResult.roomNotFound,
        422 => JoinRoomResult.passwordRequired,
        409 when e.message.contains('이미 이 방') => JoinRoomResult.alreadyJoined,
        409 => JoinRoomResult.full,
        _   => JoinRoomResult.error,
      };
      return (result: result, room: null);
    }
  }

  // ── 방 나가기 ─────────────────────────────────
  Future<bool> leaveRoom(int roomId) async {
    try {
      await ApiClient.post('/api/game-rooms/$roomId/leave', {});
      return true;
    } catch (_) {
      return false;
    }
  }
}
