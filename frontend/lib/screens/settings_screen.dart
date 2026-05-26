import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_message.dart';
import '../controllers/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void logout(BuildContext context) {
    AuthService().logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: themeController,
                builder: (context, child) {
                  return SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text(
                      '다크모드',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('네이비 계열의 어두운 테마로 변경합니다.'),
                    value: themeController.isDarkMode,
                    onChanged: (value) {
                      themeController.setDarkMode(value);

                      AppMessage.show(
                        context,
                        value ? '다크모드를 켰습니다.' : '라이트모드로 변경했습니다.',
                      );
                    },
                  );
                },
              ),
              Divider(height: 1, color: theme.dividerColor),
              ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text('알림 설정'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  AppMessage.show(context, '알림 설정은 추후 연결 예정입니다.');
                },
              ),
              Divider(height: 1, color: theme.dividerColor),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('앱 정보'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  AppMessage.show(context, '말꼬리 v0.1');
                },
              ),
              Divider(height: 1, color: theme.dividerColor),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  '로그아웃',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => logout(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
