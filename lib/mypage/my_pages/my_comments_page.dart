import 'package:flutter/material.dart';
import '../../api_service.dart';

class MyCommentsPage extends StatelessWidget {
  const MyCommentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내가 쓴 댓글')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ApiService.fetchMyComments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('작성한 댓글이 없습니다.'));
          }

          final comments = snapshot.data!;
          return ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return ListTile(
                title: Text(comment['content']),
                subtitle: Text(
                  '게시글: ${comment['postTitle']} | 좋아요: ${comment['likes']} | 싫어요: ${comment['dislikes']}',
                ),
                trailing: const Icon(Icons.comment),
                onTap: () {
                  // TODO: navigate to the original post
                },
              );
            },
          );
        },
      ),
    );
  }
}
