import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';

class GameSocketService {
  GameSocketService._();

  static final GameSocketService instance = GameSocketService._();

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  bool get isConnected => _channel != null;

  Future<void> connectAndAuth() async {
    final token = ApiClient.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('로그인 토큰이 없습니다. 먼저 로그인해주세요.');
    }

    if (_channel != null) return;

    final channel = WebSocketChannel.connect(ApiClient.webSocketUri);
    _channel = channel;

    channel.stream.listen(
      (event) {
        try {
          final decoded = jsonDecode(event.toString());
          if (decoded is Map<String, dynamic>) {
            _messageController.add(decoded);
          } else if (decoded is Map) {
            _messageController.add(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {
          _messageController.add({
            'type': 'error',
            'message': '서버 메시지를 읽지 못했습니다.',
          });
        }
      },
      onError: (error) {
        _messageController.add({
          'type': 'error',
          'message': '게임 서버 연결 오류가 발생했습니다.',
        });
      },
      onDone: () {
        _channel = null;
        _messageController.add({
          'type': 'socket_closed',
          'message': '게임 서버 연결이 종료되었습니다.',
        });
      },
    );

    _send({
      'type': 'auth',
      'accessToken': token,
    });
  }

  void joinQueue() {
    _send({'type': 'join_queue'});
  }

  void leaveQueue() {
    _send({'type': 'leave_queue'});
  }

  void joinRoom(String roomId) {
    _send({
      'type': 'join_room',
      'roomId': roomId,
    });
  }

  void submitWord(String word) {
    _send({
      'type': 'submit_word',
      'word': word,
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void _send(Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null) {
      throw Exception('게임 서버에 연결되어 있지 않습니다.');
    }
    channel.sink.add(jsonEncode(payload));
  }
}
