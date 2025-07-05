import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'post_model.dart';
import 'write_post_page.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;
  final Function(Post) onPostUpdated;
  final Function(String) onPostDeleted;

  const PostDetailPage({
    super.key,
    required this.post,
    required this.onPostUpdated,
    required this.onPostDeleted,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late Post currentPost;
  String? currentUserId;  // 현재 사용자 ID
  bool isLoading = true;   // 로딩 상태

  @override
  void initState() {
    super.initState();
    currentPost = widget.post;
    _loadCurrentUser();  // 현재 사용자 정보 로드
    
    // 디버깅을 위한 division 값 확인
    print('=== Division 디버깅 ===');
    print('division 값: "${currentPost.division}"');
    print('division 길이: ${currentPost.division.length}');
    print('division 타입: ${currentPost.division.runtimeType}');
    print('division isEmpty: ${currentPost.division.isEmpty}');
    print('====================');
    
    // 조회수 증가 (실제로는 서버에 요청)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        currentPost = currentPost.copyWith(views: currentPost.views + 1);
      });
      widget.onPostUpdated(currentPost);
    });
  }

  // 현재 사용자 ID 가져오기
  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      currentUserId = prefs.getString('user_id');
      
      print('=== 권한 체크 ===');
      print('현재 사용자: $currentUserId');
      print('작성자: ${currentPost.author}');
      print('수정 권한: ${_canEdit()}');
      print('================');
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('사용자 정보 로드 실패: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // 수정/삭제 권한 체크
  bool _canEdit() {
    if (currentUserId == null) return false;
    // 간단한 비교 (실제로는 authorId와 비교해야 함)
    return currentUserId == currentPost.author;
  }

  void _editPost() async {
    final result = await Navigator.push<Post>(
      context,
      MaterialPageRoute(
        builder: (context) => WritePostPage(post: currentPost),
      ),
    );

    if (result != null) {
      setState(() {
        currentPost = result;
      });
      widget.onPostUpdated(result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 수정되었습니다.')),
      );
    }
  }

  void _deletePost() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        widget.onPostDeleted(currentPost.id);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글이 삭제되었습니다.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // 권한 체크: 본인이 작성한 글일 때만 메뉴 표시
          if (!isLoading && _canEdit())
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editPost();
                    break;
                  case 'delete':
                    _deletePost();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('수정'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('삭제', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              currentPost.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 작성자 정보
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue,
                    child: Text(
                      currentPost.division,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${currentPost.division}반 몰입러',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          currentPost.timeAgo,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.visibility, 
                           size: 16, 
                           color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${currentPost.views}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 내용
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                currentPost.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 액션 버튼들 (권한이 있을 때만 표시)
            if (!isLoading && _canEdit())
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editPost,
                      icon: const Icon(Icons.edit),
                      label: const Text('수정'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deletePost,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('삭제', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            
            // 권한이 없을 때 안내 메시지 (선택사항)
            if (!isLoading && !_canEdit())
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '다른 사용자가 작성한 게시글입니다.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
} 