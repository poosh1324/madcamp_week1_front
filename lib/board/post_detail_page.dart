import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'post_model.dart';
import 'write_post_page.dart';
import 'comment_model.dart';
import 'board_api_service.dart';

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
  
  // 댓글 관련 상태 변수들
  List<Comment> comments = [];
  bool commentsLoading = false;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  String? _editingCommentId;  // 수정 중인 댓글 ID
  String? _replyingToCommentId;  // 답글 작성 중인 댓글 ID
  final Map<String, bool> _expandedReplies = {};  // 대댓글 펼침 상태

  @override
  void initState() {
    super.initState();
    currentPost = widget.post;

    _loadCurrentUser();  // 현재 사용자 정보 로드
    _loadComments();     // 댓글 목록 로드
    
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

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
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

  // 댓글 권한 체크
  bool _canEditComment(Comment comment) {
    if (currentUserId == null) return false;
    return currentUserId == comment.author;
  }

  // 댓글 목록 로드
  Future<void> _loadComments() async {
    setState(() {
      commentsLoading = true;
    });

    try {
      final loadedComments = await BoardApiService.getComments(currentPost.id);
      setState(() {
        comments = loadedComments;
        commentsLoading = false;
      });
    } catch (e) {
      setState(() {
        commentsLoading = false;
      });
      print('댓글 로드 실패: $e');
      
      // 에러 발생 시 더미 댓글 데이터 사용 (개발 중에만)
      _loadDummyComments();
    }
  }

  // 더미 댓글 데이터 로드
  void _loadDummyComments() {
    setState(() {
      comments = [
        Comment(
          id: '1',
          postId: currentPost.id,
          content: '정말 유용한 글이네요! 감사합니다.',
          author: '댓글러',
          division: '1',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          likes: 3,
          dislikes: 0,
          replies: [
            Comment(
              id: '1-1',
              postId: currentPost.id,
              parentId: '1',
              content: '저도 그렇게 생각해요!',
              author: '대댓글러',
              division: '2',
              createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
              likes: 1,
            ),
          ],
        ),
        Comment(
          id: '2',
          postId: currentPost.id,
          content: '더 많은 정보가 있으면 좋겠습니다.',
          author: '학습자',
          division: '2',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          likes: 1,
          dislikes: 0,
        ),
      ];
      
      // 대댓글 펼침 상태 초기화
      for (var comment in comments) {
        if (comment.replies.isNotEmpty) {
          _expandedReplies[comment.id] = true;
        }
      }
    });
  }

  // 댓글 또는 대댓글 작성
  Future<void> _writeComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글을 입력해주세요.')),
      );
      return;
    }

    try {
      if (_replyingToCommentId != null) {
        // 대댓글 작성
        final newReply = await BoardApiService.createComment(
          postId: currentPost.id,
          content: _commentController.text.trim(),
          parentId: _replyingToCommentId,
        );

        setState(() {
          // 부모 댓글 찾아서 대댓글 추가
          final parentIndex = comments.indexWhere((c) => c.id == _replyingToCommentId);
          if (parentIndex != -1) {
            comments[parentIndex] = comments[parentIndex].addReply(newReply);
            _expandedReplies[_replyingToCommentId!] = true;
          }
          _commentController.clear();
          _replyingToCommentId = null;
        });
      } else {
        // 일반 댓글 작성
        final newComment = await BoardApiService.createComment(
          postId: currentPost.id,
          content: _commentController.text.trim(),
        );

        setState(() {
          comments.add(newComment);
          _commentController.clear();
        });
      }

      _commentFocus.unfocus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_replyingToCommentId != null ? '답글이 작성되었습니다.' : '댓글이 작성되었습니다.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 작성 실패: ${e.toString()}')),
        );
      }
    }
  }

  // 댓글 수정
  Future<void> _editComment(Comment comment) async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글을 입력해주세요.')),
      );
      return;
    }

    try {
      final updatedComment = await BoardApiService.updateComment(
        commentId: comment.id,
        content: _commentController.text.trim(),
      );

      setState(() {
        if (comment.parentId != null) {
          // 대댓글 수정
          final parentIndex = comments.indexWhere((c) => c.id == comment.parentId);
          if (parentIndex != -1) {
            comments[parentIndex] = comments[parentIndex].updateReply(updatedComment);
          }
        } else {
          // 일반 댓글 수정
          final index = comments.indexWhere((c) => c.id == comment.id);
          if (index != -1) {
            comments[index] = updatedComment;
          }
        }
        _editingCommentId = null;
        _commentController.clear();
      });

      _commentFocus.unfocus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 수정되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 수정 실패: ${e.toString()}')),
        );
      }
    }
  }

  // 댓글 삭제
  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(comment.parentId != null ? '답글 삭제' : '댓글 삭제'),
        content: Text('정말로 이 ${comment.parentId != null ? '답글' : '댓글'}을 삭제하시겠습니까?'),
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
    );

    if (confirmed == true) {
      try {
        await BoardApiService.deleteComment(comment.id);
        
        setState(() {
          if (comment.parentId != null) {
            // 대댓글 삭제
            final parentIndex = comments.indexWhere((c) => c.id == comment.parentId);
            if (parentIndex != -1) {
              comments[parentIndex] = comments[parentIndex].removeReply(comment.id);
            }
          } else {
            // 일반 댓글 삭제
            comments.removeWhere((c) => c.id == comment.id);
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${comment.parentId != null ? '답글' : '댓글'}이 삭제되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('댓글 삭제 실패: ${e.toString()}')),
          );
        }
      }
    }
  }

  // 댓글 좋아요/싫어요
  Future<void> _likeComment(Comment comment, bool isLike) async {
    try {
      final updatedComment = await BoardApiService.likeComment(
        commentId: comment.id,
        isLike: isLike,
      );

      setState(() {
        if (comment.parentId != null) {
          // 대댓글 좋아요
          final parentIndex = comments.indexWhere((c) => c.id == comment.parentId);
          if (parentIndex != -1) {
            comments[parentIndex] = comments[parentIndex].updateReply(updatedComment);
          }
        } else {
          // 일반 댓글 좋아요
          final index = comments.indexWhere((c) => c.id == comment.id);
          if (index != -1) {
            comments[index] = updatedComment;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('좋아요/싫어요 실패: ${e.toString()}')),
        );
      }
    }
  }

  // 댓글 수정 시작
  void _startEditComment(Comment comment) {
    setState(() {
      _editingCommentId = comment.id;
      _commentController.text = comment.content;
      _replyingToCommentId = null;
    });
    _commentFocus.requestFocus();
  }

  // 답글 작성 시작
  void _startReplyComment(Comment comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _commentController.clear();
      _editingCommentId = null;
    });
    _commentFocus.requestFocus();
  }

  // 댓글 작성 취소
  void _cancelComment() {
    setState(() {
      _editingCommentId = null;
      _replyingToCommentId = null;
      _commentController.clear();
    });
    _commentFocus.unfocus();
  }

  // 대댓글 펼침/접기 토글
  void _toggleReplies(String commentId) {
    setState(() {
      _expandedReplies[commentId] = !(_expandedReplies[commentId] ?? false);
    });
  }

  // 전체 댓글 수 계산 (대댓글 포함)
  int get totalCommentsCount {
    int total = comments.length;
    for (var comment in comments) {
      total += comment.replies.length;
    }
    return total;
  }

  // 댓글 ID로 댓글 찾기 (대댓글 포함)
  Comment _findCommentById(String commentId) {
    // 먼저 일반 댓글에서 찾기
    for (var comment in comments) {
      if (comment.id == commentId) {
        return comment;
      }
      // 대댓글에서 찾기
      for (var reply in comment.replies) {
        if (reply.id == commentId) {
          return reply;
        }
      }
    }
    throw Exception('댓글을 찾을 수 없습니다: $commentId');
  }

  void _editPost() async {
    final result = await Navigator.push<Post>(
      context,
      MaterialPageRoute(builder: (context) => WritePostPage(post: currentPost)),
    );

    if (result != null) {
      setState(() {
        currentPost = result;
      });
      widget.onPostUpdated(result);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글이 수정되었습니다.')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('게시글이 삭제되었습니다.')));
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                      Icon(
                        Icons.visibility,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
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
                style: const TextStyle(fontSize: 16, height: 1.5),
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
                      label: const Text(
                        '삭제',
                        style: TextStyle(color: Colors.red),
                      ),
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const SizedBox(height: 32),
            
            // 댓글 섹션
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // 댓글 제목
                  Row(
                    children: [
                      const Icon(Icons.comment, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        '댓글 $totalCommentsCount개',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 댓글 작성란
                  _buildCommentInput(),
                  const SizedBox(height: 16),
                  
                  // 댓글 목록
                  if (commentsLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (comments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '첫 번째 댓글을 작성해보세요!',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return _buildCommentItem(comment);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 댓글 입력 위젯
  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 현재 상태 표시
          if (_editingCommentId != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text('댓글 수정 중...'),
                  const Spacer(),
                  TextButton(
                    onPressed: _cancelComment,
                    child: const Text('취소'),
                  ),
                ],
              ),
            ),
          
          if (_replyingToCommentId != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('답글 작성 중...'),
                  const Spacer(),
                  TextButton(
                    onPressed: _cancelComment,
                    child: const Text('취소'),
                  ),
                ],
              ),
            ),
          
          if (_editingCommentId != null || _replyingToCommentId != null)
            const SizedBox(height: 12),
          
          // 댓글 입력 필드
          TextField(
            controller: _commentController,
            focusNode: _commentFocus,
            decoration: InputDecoration(
              hintText: _replyingToCommentId != null 
                  ? '답글을 입력하세요...' 
                  : '댓글을 입력하세요...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 3,
            minLines: 1,
          ),
          const SizedBox(height: 12),
          
          // 버튼들
          Row(
            children: [
              const Spacer(),
              if (_editingCommentId != null || _replyingToCommentId != null)
                TextButton(
                  onPressed: _cancelComment,
                  child: const Text('취소'),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _editingCommentId != null 
                    ? () => _editComment(_findCommentById(_editingCommentId!))
                    : _writeComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(_editingCommentId != null 
                    ? '수정' 
                    : (_replyingToCommentId != null ? '답글' : '댓글')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 댓글 아이템 위젯
  Widget _buildCommentItem(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 댓글 본문
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 댓글 작성자 정보
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.green,
                      child: Text(
                        comment.division,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${comment.division}반 몰입러',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      comment.timeAgo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // 댓글 내용
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 12),
                
                // 댓글 액션 버튼들
                Row(
                  children: [
                    // 좋아요 버튼
                    InkWell(
                      onTap: () => _likeComment(comment, true),
                      child: Row(
                        children: [
                          const Icon(Icons.thumb_up, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text('${comment.likes}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // 싫어요 버튼
                    InkWell(
                      onTap: () => _likeComment(comment, false),
                      child: Row(
                        children: [
                          const Icon(Icons.thumb_down, size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text('${comment.dislikes}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // 답글 버튼
                    InkWell(
                      onTap: () => _startReplyComment(comment),
                      child: const Row(
                        children: [
                          Icon(Icons.reply, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('답글', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // 수정/삭제 버튼 (본인 댓글만)
                    if (_canEditComment(comment))
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 16),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _startEditComment(comment);
                              break;
                            case 'delete':
                              _deleteComment(comment);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('수정'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('삭제', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                
                // 대댓글 펼치기/접기 버튼
                if (comment.replies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: InkWell(
                      onTap: () => _toggleReplies(comment.id),
                      child: Row(
                        children: [
                          Icon(
                            _expandedReplies[comment.id] == true 
                                ? Icons.expand_less 
                                : Icons.expand_more,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '답글 ${comment.replies.length}개 ${_expandedReplies[comment.id] == true ? '접기' : '보기'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // 대댓글 목록
          if (comment.replies.isNotEmpty && _expandedReplies[comment.id] == true)
            Container(
              margin: const EdgeInsets.only(left: 32, top: 8),
              child: Column(
                children: comment.replies.map((reply) => _buildReplyItem(reply)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // 대댓글 아이템 위젯
  Widget _buildReplyItem(Comment reply) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 대댓글 작성자 정보
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.purple,
                child: Text(
                  reply.division,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${reply.division}반 몰입러',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                reply.timeAgo,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 대댓글 내용
          Text(
            reply.content,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 8),
          
          // 대댓글 액션 버튼들
          Row(
            children: [
              // 좋아요 버튼
              InkWell(
                onTap: () => _likeComment(reply, true),
                child: Row(
                  children: [
                    const Icon(Icons.thumb_up, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text('${reply.likes}', style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // 싫어요 버튼
              InkWell(
                onTap: () => _likeComment(reply, false),
                child: Row(
                  children: [
                    const Icon(Icons.thumb_down, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('${reply.dislikes}', style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // 수정/삭제 버튼 (본인 대댓글만)
              if (_canEditComment(reply))
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 14),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _startEditComment(reply);
                        break;
                      case 'delete':
                        _deleteComment(reply);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 14),
                          SizedBox(width: 8),
                          Text('수정'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 14, color: Colors.red),
                          SizedBox(width: 8),
                          Text('삭제', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
} 
