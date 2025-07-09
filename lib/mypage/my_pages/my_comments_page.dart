import 'package:flutter/material.dart';
import 'package:test_madcamp/board/board_api_service.dart';
import '../../api_service.dart';
import '../../board/post_detail_page.dart';

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
                onTap: () async {
                  try {
                    final post = await BoardApiService.getPost(
                      comment['postId'],
                    );
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostDetailPage(
                            post: post,
                            onPostUpdated: (_) {},
                            onPostDeleted: (_) {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Failed to load post: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('게시글을 불러오는 데 실패했습니다: $e')),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
