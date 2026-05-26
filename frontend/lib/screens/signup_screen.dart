import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_message.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService authService = AuthService();

  final TextEditingController idController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordCheckController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    idController.dispose();
    nicknameController.dispose();
    passwordController.dispose();
    passwordCheckController.dispose();
    super.dispose();
  }

  Future<void> signup() async {
    final userId = idController.text.trim();
    final nickname = nicknameController.text.trim();
    final password = passwordController.text.trim();
    final passwordCheck = passwordCheckController.text.trim();

    if (userId.isEmpty ||
        nickname.isEmpty ||
        password.isEmpty ||
        passwordCheck.isEmpty) {
      showMessage('모든 항목을 입력해주세요.');
      return;
    }

    if (userId.length < 4) {
      showMessage('아이디는 4자 이상으로 입력해주세요.');
      return;
    }

    if (nickname.length < 2) {
      showMessage('닉네임은 2자 이상으로 입력해주세요.');
      return;
    }

    if (password.length < 6) {
      showMessage('비밀번호는 6자 이상으로 입력해주세요.');
      return;
    }

    if (password != passwordCheck) {
      showMessage('비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final success = await authService.signup(
      userId: userId,
      nickname: nickname,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (success) {
      showMessage('회원가입이 완료되었습니다. 로그인해주세요.');

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        Navigator.pop(context);
      });
    } else {
      showMessage('이미 사용 중인 아이디입니다.');
    }
  }

  void showMessage(String message) {
    AppMessage.show(context, message);
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
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const Text(
                  '말꼬리',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '채팅 대전에서 사용할 계정을 만들어주세요',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 36),

                TextField(
                  controller: idController,
                  textInputAction: TextInputAction.next,
                  decoration: inputDecoration(
                    label: '아이디',
                    hint: '4자 이상 입력하세요',
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: nicknameController,
                  textInputAction: TextInputAction.next,
                  decoration: inputDecoration(
                    label: '닉네임',
                    hint: '채팅방에서 사용할 닉네임',
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: inputDecoration(
                    label: '비밀번호',
                    hint: '6자 이상 입력하세요',
                    icon: Icons.lock_outline,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passwordCheckController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => signup(),
                  decoration: inputDecoration(
                    label: '비밀번호 확인',
                    hint: '비밀번호를 다시 입력하세요',
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : signup,
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
                            '회원가입',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text('이미 계정이 있으신가요? 로그인하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
