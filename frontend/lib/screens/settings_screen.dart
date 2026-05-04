import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_message.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void logout(BuildContext context) {
    AuthService().logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text('알림 설정'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  AppMessage.show(context, '알림 설정은 추후 연결 예정입니다.');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('앱 정보'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  AppMessage.show(context, '끝말오브 레전드 v0.1');
                },
              ),
              const Divider(height: 1),
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
