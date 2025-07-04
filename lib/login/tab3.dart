import 'package:flutter/material.dart';

// 프로필 탭 화면
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 80, color: Colors.orange),
          SizedBox(height: 20),
          Text(
            '프로필 화면',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text('사용자 프로필 정보를 표시할 수 있어요!'),
        ],
      ),
    );
  }
}
