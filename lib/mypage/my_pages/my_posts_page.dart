import 'package:flutter/material.dart';
import '../../api_service.dart';

class MyPostsPage extends StatelessWidget {
  const MyPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내가 쓴 글')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ApiService.fetchMyPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('작성한 글이 없습니다.'));
          }

          final posts = snapshot.data!;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return ListTile(
                title: Text(post['title']),
                subtitle: Text(
                  '분반: ${post['division']} | 좋아요: ${post['likes']} | 댓글: ${post['commentCount']}',
                ),
                trailing: const Icon(Icons.article),
                onTap: () {
                  // TODO: navigate to post detail
                },
              );
            },
          );
        },
      ),
    );
  }
}
