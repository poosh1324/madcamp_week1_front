import 'package:flutter/material.dart';
import '../api_service.dart';

// 프로필 탭 화면
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.fetchUserInfo(), // fetch profile info from backend
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final data = snapshot.data!;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 80, color: Colors.orange),
                const SizedBox(height: 20),
                Text(
                  data['nickname'] ?? 'Unknown User',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('실명: ${data['realName'] ?? 'N/A'}'),
                Text('ID: ${data['username'] ?? 'N/A'}'),
                Text('소속: ${data['division'] ?? 'N/A'}'),
              ],
            ),
          );
        }
      },
    );
  }
}
