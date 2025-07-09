import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../board/board_api_service.dart';
import '../../board/post_detail_page.dart';

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
                onTap: () async {
                  try {
                    final updatedPost = await BoardApiService.getPost(
                      post['postId'],
                    );
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostDetailPage(
                            post: updatedPost,
                            onPostUpdated: (_) {},
                            onPostDeleted: (_) {},
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('게시글 불러오기 오류: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('게시글을 불러오는 데 실패했습니다: $e')),
                    );
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
