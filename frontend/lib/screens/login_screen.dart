import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_message.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService();

  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final userId = idController.text.trim();
    final password = passwordController.text.trim();

    if (userId.isEmpty || password.isEmpty) {
      showMessage('아이디와 비밀번호를 모두 입력해주세요.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final success = await authService.login(userId: userId, password: password);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      showMessage('아이디 또는 비밀번호가 올바르지 않습니다.');
    }
  }

  void showMessage(String message) {
    AppMessage.show(context, message);
  }

  void findId() {
    showMessage('아이디 찾기 기능은 추후 연결 예정입니다.');
  }

  void findPassword() {
    showMessage('비밀번호 찾기 기능은 추후 연결 예정입니다.');
  }

  InputDecoration inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '말꼬리',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '끝말잇기 실시간 채팅 대전',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 48),

                TextField(
                  controller: idController,
                  textInputAction: TextInputAction.next,
                  decoration: inputDecoration(
                    label: '아이디',
                    hint: '아이디를 입력하세요',
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => login(),
                  decoration: inputDecoration(
                    label: '비밀번호',
                    hint: '비밀번호를 입력하세요',
                    icon: Icons.lock_outline,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : findId,
                      child: const Text('아이디 찾기'),
                    ),
                    const Text('|', style: TextStyle(color: Colors.black38)),
                    TextButton(
                      onPressed: isLoading ? null : findPassword,
                      child: const Text('비밀번호 찾기'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3F51B5),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.indigo.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '로그인',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '아직 계정이 없으신가요?',
                      style: TextStyle(color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.pushNamed(context, '/signup');
                            },
                      child: const Text(
                        '회원가입',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Text(
                  '테스트 계정: test1234 / 123456',
                  style: TextStyle(fontSize: 13, color: Colors.black45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
