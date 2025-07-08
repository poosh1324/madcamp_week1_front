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
  String? currentUserId; // 현재 사용자 ID
  String? currentUserToken; // 현재 사용자 토큰
  bool isLoading = true; // 로딩 상태

  // 댓글 관련 상태 변수들
  List<Comment> comments = [];
  bool commentsLoading = false;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  String? _editingCommentId; // 수정 중인 댓글 ID
  String? _replyingToCommentId; // 답글 작성 중인 댓글 ID
  final Map<String, bool> _expandedReplies = {}; // 대댓글 펼침 상태

  @override
  void initState() {
    super.initState();
    currentPost = widget.post;
    print("🥹currentPost.views: ${currentPost.views}");
    print("🥹currentPost.likes: ${currentPost.likes}");
    print("🥹currentPost.author: ${currentPost.author}");

    _loadCurrentUser(); // 현재 사용자 정보 로드
    _loadComments(); // 댓글 목록 로드

    //조회수 증가 (실제로는 서버에 요청)
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   setState(() {
    //     currentPost = currentPost.copyWith(views: currentPost.views + 1);
    //   });
    //   widget.onPostUpdated(currentPost);
    // });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  // 현재 사용자 ID와 토큰 가져오기
  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      currentUserId = prefs.getString('username');
      
      // 토큰 가져와서 상태 변수에 저장
      currentUserToken = await BoardApiService.getToken();

      print('=== 권한 체크 ===');
      print('현재 사용자: $currentUserId');
      print('현재 토큰: $currentUserToken');
      print('작성자: ${currentPost.author}');
      print('수정 권한: ${currentPost.qualified}');
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

  // // 수정/삭제 권한 체크
  // bool _canEdit() {
  //   print("currentUserId: $currentUserId");
  //   print("currentPost.author: ${currentPost.author}");
  //   print("currentUserToken: $currentUserToken");
    
  //   // 토큰이 없으면 권한 없음
  //   if (currentUserToken == null || currentUserId == null) return false;
    
  //   // 현재 사용자와 작성자 비교 (토큰이 아닌 사용자 ID로 비교)
  //   return currentUserId == currentPost.author;
  // }

  // 현재 토큰 가져오기 (다른 함수에서 사용 가능)
  String? get currentToken => currentUserToken;

  // 댓글 권한 체크
  // bool _canEditComment(Comment comment) {
  //   if (currentUserId == null) return false;
  //   return currentUserId == comment.author;
  // }

  // 댓글 목록 로드
  Future<void> _loadComments() async {
    setState(() {
      commentsLoading = true;
    });

    try {
      print('🔄 서버에서 댓글 로드 시도...');
      final loadedComments = await BoardApiService.getComments(currentPost.id);
      setState(() {
        comments = loadedComments;
        commentsLoading = false;
      });
    } catch (e) {
      setState(() {
        commentsLoading = false;
      });
      print('❌ 댓글 로드 실패: $e');
      print('🔄 더미 데이터로 폴백...');

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('댓글을 입력해주세요.')));
      }
      return;
    }

    try {
      print('대댓글 커멘트 아이디: $_replyingToCommentId');
      if (_replyingToCommentId != null) {
        // 대댓글 작성
        final newReply = await BoardApiService.createComment(
          postId: currentPost.id,
          content: _commentController.text.trim(),
          parentId: _replyingToCommentId,
        );

        setState(() {
          // 부모 댓글 찾아서 대댓글 추가 - Flutter 감지를 위해 새 리스트 생성
          final parentIndex = comments.indexWhere(
            (c) => c.id == _replyingToCommentId,
          );
          if (parentIndex != -1) {
            final updatedParent = comments[parentIndex].addReply(newReply);
            comments = List.from(comments);
            comments[parentIndex] = updatedParent;
            _expandedReplies[_replyingToCommentId!] = true;
          }
          _commentController.clear();
          _replyingToCommentId = null;
        });
      } else {
        // 일반 댓글 작성
        print('뭐에여? ${currentPost.id}');
        final newComment = await BoardApiService.createComment(
          postId: currentPost.id,
          content: _commentController.text.trim(),
        );

        setState(() {
          // 일반 댓글 추가 - 새 리스트 생성
          comments = [...comments, newComment];
          _commentController.clear();
        });
      }

      _commentFocus.unfocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _replyingToCommentId != null ? '답글이 작성되었습니다.' : '댓글이 작성되었습니다.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('댓글 작성 실패: ${e.toString()}')));
      }
    }
  }

  // 댓글 수정
  Future<void> _editComment(Comment comment) async {
    if (_commentController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('댓글을 입력해주세요.')));
      }
      return;
    }

    try {
      final updatedComment = await BoardApiService.updateComment(
        commentId: comment.id,
        content: _commentController.text.trim(),
        parentId: comment.parentId,
      );
      print('updatedcomment.content: ${updatedComment.content}');
      comment = comment.copyWith(content: updatedComment.content);
      setState(() {
        if (comment.parentId != null) {
          // 대댓글 수정 - Flutter 감지를 위해 새 리스트 생성
          final parentIndex = comments.indexWhere(
            (c) => c.id == comment.parentId,
          );
          if (parentIndex != -1) {
            final updatedParent = comments[parentIndex].updateReply(comment);

            // 새로운 리스트를 만들어서 Flutter가 변화를 감지하도록 함
            comments = List.from(comments);
            comments[parentIndex] = updatedParent;
          }
        } else {
          // 일반 댓글 수정 - 일관성을 위해 새 리스트 생성
          final index = comments.indexWhere((c) => c.id == comment.id);
          if (index != -1) {
            comments = List.from(comments);
            comments[index] = updatedComment;
          }
        }
        _editingCommentId = null;
        _commentController.clear();
      });

      _commentFocus.unfocus();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('댓글이 수정되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('댓글 수정 실패: ${e.toString()}')));
      }
    }
  }

  // 댓글 삭제
  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(comment.parentId != null ? '답글 삭제' : '댓글 삭제'),
        content: Text(
          '정말로 이 ${comment.parentId != null ? '답글' : '댓글'}을 삭제하시겠습니까?',
        ),
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
            // 대댓글 삭제 - Flutter 감지를 위해 새 리스트 생성
            final parentIndex = comments.indexWhere(
              (c) => c.id == comment.parentId,
            );
            if (parentIndex != -1) {
              final updatedParent = comments[parentIndex].removeReply(
                comment.id,
              );
              comments = List.from(comments);
              comments[parentIndex] = updatedParent;
            }
          } else {
            // 일반 댓글 삭제 - 새 리스트 생성
            comments = comments.where((c) => c.id != comment.id).toList();
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${comment.parentId != null ? '답글' : '댓글'}이 삭제되었습니다.',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('댓글 삭제 실패: ${e.toString()}')));
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
      print("🥹comment.parentId: ${comment.parentId}");
      print("🥹comment.likes: ${comment.likes}");

      if (updatedComment == "like cancelled") {
        comment = comment.copyWith(likes: comment.likes - 1);
      } else if (updatedComment == "dislike cancelled") {
        comment = comment.copyWith(dislikes: comment.dislikes - 1);
      } else if (updatedComment == "liked comment") {
        comment = comment.copyWith(likes: comment.likes + 1);
      } else if (updatedComment == "disliked comment") {
        comment = comment.copyWith(dislikes: comment.dislikes + 1);
      } else if (updatedComment == "Changed vote to dislike") {
        comment = comment.copyWith(
          likes: comment.likes - 1,
          dislikes: comment.dislikes + 1,
        );
      } else if (updatedComment == "Changed vote to like") {
        comment = comment.copyWith(
          likes: comment.likes + 1,
          dislikes: comment.dislikes - 1,
        );
      }
      print("🥹comment.likes: ${comment.likes}");

      setState(() {
        if (comment.parentId != null) {
          // 대댓글 좋아요 - Flutter 감지를 위해 새 리스트 생성
          final parentIndex = comments.indexWhere(
            (c) => c.id == comment.parentId,
          );
          if (parentIndex != -1) {
            final updatedParent = comments[parentIndex].updateReply(comment);
            comments = List.from(comments);
            comments[parentIndex] = updatedParent;
          }
        } else {
          // 일반 댓글 좋아요 - 새 리스트 생성
          final index = comments.indexWhere((c) => c.id == comment.id);
          if (index != -1) {
            comments = List.from(comments);
            comments[index] = comment;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('좋아요/싫어요 실패: ${e.toString()}')));
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

  // 게시글 좋아요/싫어요
  Future<void> _likePost(bool isLike) async {
    try {
      final result = await BoardApiService.likePost(
        postId: currentPost.id,
        isLike: isLike,
      );

      print("게시글 좋아요 결과: $result");

      // 결과에 따라 좋아요/싫어요 수 업데이트
      int newLikes = currentPost.likes;
      int newDislikes = currentPost.dislikes;

      if (result.contains("Post like removed")) {
        newLikes -= 1;
      } else if (result.contains("Post dislike removed")) {
        newDislikes -= 1;
      } else if (result.contains("Post liked successfully")) {
        newLikes += 1;
      } else if (result.contains("Post disliked successfully")) {
        newDislikes += 1;
      } else if (result.contains("Post vote changed to dislike")) {
        newLikes -= 1;
        newDislikes += 1;
      } else if (result.contains("Post vote changed to like")) {
        newLikes += 1;
        newDislikes -= 1;
      }

      setState(() {
        currentPost = currentPost.copyWith(
          likes: newLikes,
          dislikes: newDislikes,
        );
      });

      // 상위 위젯에 업데이트 알림
      widget.onPostUpdated(currentPost);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('좋아요/싫어요 실패: ${e.toString()}')));
      }
    }
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

    // null 체크 후 갱신
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'MeveryTime',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          // 권한 체크: 본인이 작성한 글일 때만 메뉴 표시
          if (!isLoading && currentPost.qualified)
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('수정'),
                          onTap: () {
                            Navigator.pop(context);
                            _editPost();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text('삭제', style: TextStyle(color: Colors.red)),
                          onTap: () {
                            Navigator.pop(context);
                            _deletePost();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade200,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 작성자 정보 - 인스타그램 스타일
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[600],
                    child: Text(
                      currentPost.division.substring(0, 1),
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
                          '${currentPost.author}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          currentPost.timeAgo,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.visibility,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${currentPost.views}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 제목
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "${currentPost.title}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 내용
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                currentPost.content,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),

            // 액션 버튼들 - 인스타그램 스타일
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // 좋아요 버튼
                  InkWell(
                    onTap: () => _likePost(true),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 24,
                            color: currentPost.likes > 0 ? Colors.red : Colors.black,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${currentPost.likes}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 댓글 버튼
                  InkWell(
                    onTap: () {
                      // 댓글 섹션으로 스크롤 (기존 기능 유지)
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 24,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$totalCommentsCount',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 싫어요 버튼 (인스타그램에는 없지만 기능 유지)
                  InkWell(
                    onTap: () => _likePost(false),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.heart_broken_outlined,
                            size: 24,
                            color: currentPost.dislikes > 0 ? Colors.blue : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${currentPost.dislikes}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 구분선
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              height: 1,
              color: Colors.grey.shade200,
            ),

            // 댓글 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      child: const Text(
                        '첫 번째 댓글을 작성해보세요!',
                        style: TextStyle(
                          color: Colors.grey,
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
            const SizedBox(height: 16),
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
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 현재 상태 표시
          if (_editingCommentId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '댓글 수정 중...',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _cancelComment,
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_replyingToCommentId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '답글 작성 중...',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _cancelComment,
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 댓글 입력 필드
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocus,
                  decoration: InputDecoration(
                    hintText: _replyingToCommentId != null
                        ? '답글을 입력하세요...'
                        : '댓글을 입력하세요...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  minLines: 1,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _editingCommentId != null
                    ? () => _editComment(_findCommentById(_editingCommentId!))
                    : _writeComment,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _editingCommentId != null
                        ? '수정'
                        : (_replyingToCommentId != null ? '답글' : '게시'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 댓글 본문
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 댓글 작성자 정보
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey[600],
                      child: Text(
                        comment.author.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${comment.author}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                comment.timeAgo,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.content,
                            style: const TextStyle(fontSize: 14, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    // 수정/삭제 버튼 (본인 댓글만)
                    if (comment.qualified)
                      InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (context) => Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit),
                                    title: const Text('수정'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _startEditComment(comment);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete, color: Colors.red),
                                    title: const Text('삭제', style: TextStyle(color: Colors.red)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _deleteComment(comment);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.more_vert, size: 16, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // 댓글 액션 버튼들
                Row(
                  children: [
                    // 좋아요 버튼
                    InkWell(
                      onTap: () => _likeComment(comment, true),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Row(
                          children: [
                            Icon(
                              comment.likes > 0 ? Icons.thumb_up : Icons.thumb_up_outlined,
                              size: 16,
                              color: comment.likes > 0 ? Colors.blue : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${comment.likes}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 싫어요 버튼
                    InkWell(
                      onTap: () => _likeComment(comment, false),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.thumb_down_outlined,
                              size: 16,
                              color: comment.dislikes > 0 ? Colors.blue : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${comment.dislikes}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 답글 버튼
                    InkWell(
                      onTap: () => _startReplyComment(comment),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Text(
                          '답글 달기',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // 대댓글 펼치기/접기 버튼
                if (comment.replies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: InkWell(
                      onTap: () => _toggleReplies(comment.id),
                      child: Text(
                        '답글 ${comment.replies.length}개 ${_expandedReplies[comment.id] == true ? '숨기기' : '보기'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 대댓글 목록
          if (comment.replies.isNotEmpty &&
              _expandedReplies[comment.id] == true)
            Container(
              margin: const EdgeInsets.only(left: 40),
              child: Column(
                children: comment.replies
                    .map((reply) => _buildReplyItem(reply))
                    .toList(),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${reply.author}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          reply.timeAgo,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reply.content,
                      style: const TextStyle(fontSize: 13, height: 1.3),
                    ),
                  ],
                ),
              ),
              // 수정/삭제 버튼 (본인 대댓글만)
              if (reply.qualified)
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (context) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit),
                              title: const Text('수정'),
                              onTap: () {
                                Navigator.pop(context);
                                _startEditComment(reply);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete, color: Colors.red),
                              title: const Text('삭제', style: TextStyle(color: Colors.red)),
                              onTap: () {
                                Navigator.pop(context);
                                _deleteComment(reply);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.more_vert, size: 14, color: Colors.grey),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // 대댓글 액션 버튼들
          Row(
            children: [
              // 좋아요 버튼
              InkWell(
                onTap: () => _likeComment(reply, true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    children: [
                      Icon(
                        reply.likes > 0 ? Icons.thumb_up : Icons.thumb_up_outlined,
                        size: 14,
                        color: reply.likes > 0 ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${reply.likes}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              // 싫어요 버튼
              InkWell(
                onTap: () => _likeComment(reply, false),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.thumb_down_outlined,
                        size: 14,
                        color: reply.dislikes > 0 ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${reply.dislikes}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
