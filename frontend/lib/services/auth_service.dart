class MockUser {
  final String userId;
  final String nickname;
  final String password;

  MockUser({
    required this.userId,
    required this.nickname,
    required this.password,
  });
}

class AuthService {
  static final Map<String, MockUser> _users = {
    'test1234': MockUser(
      userId: 'test1234',
      nickname: '테스트유저',
      password: '123456',
    ),
  };

  static MockUser? currentUser;

  Future<bool> login({required String userId, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final user = _users[userId];

    if (user == null) {
      return false;
    }

    if (user.password != password) {
      return false;
    }

    currentUser = user;
    return true;
  }

  Future<bool> signup({
    required String userId,
    required String nickname,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_users.containsKey(userId)) {
      return false;
    }

    _users[userId] = MockUser(
      userId: userId,
      nickname: nickname,
      password: password,
    );

    return true;
  }

  void logout() {
    currentUser = null;
  }

  MockUser? getCurrentUser() {
    return currentUser;
  }
}
