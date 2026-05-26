import 'api_client.dart';

/// 로그인된 유저 정보 모델
class User {
  final String userId;
  final String nickname;

  User({required this.userId, required this.nickname});
}

class AuthService {
  /// 앱 전역에서 접근하는 현재 로그인 유저
  static User? currentUser;

  // ── 로그인 ─────────────────────────────
  Future<bool> login({
    required String userId,
    required String password,
  }) async {
    try {
      final data = await ApiClient.post('/api/auth/login', {
        'userId': userId,
        'password': password,
      });

      // 백엔드 응답: { accessToken, refreshToken, user: { id, userId, nickname } }
      ApiClient.setTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );

      currentUser = User(
        userId: data['user']['userId'],
        nickname: data['user']['nickname'],
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  // ── 회원가입 ────────────────────────────
  Future<bool> signup({
    required String userId,
    required String nickname,
    required String password,
  }) async {
    try {
      await ApiClient.post('/api/auth/register', {
        'userId': userId,
        'nickname': nickname,
        'password': password,
      });
      return true;
    } on ApiException catch (e) {
      // 409 = 이미 사용 중인 아이디
      if (e.statusCode == 409) return false;
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── 로그아웃 ────────────────────────────
  Future<void> logout() async {
    try {
      await ApiClient.post('/api/auth/logout', {
        if (ApiClient.refreshToken != null)
          'refreshToken': ApiClient.refreshToken!,
      });
    } catch (_) {
      // 서버 오류여도 클라이언트 토큰은 무조건 삭제
    } finally {
      ApiClient.clearTokens();
      currentUser = null;
    }
  }

  // ── 현재 유저 조회 ──────────────────────
  User? getCurrentUser() => currentUser;
}
