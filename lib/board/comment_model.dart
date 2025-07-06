class Comment {
  final String id;
  final String postId;
  final String? parentId;  // null이면 댓글, 값이 있으면 대댓글
  final String content;
  final String author;
  final String division;
  final DateTime createdAt;
  final int likes;
  final int dislikes;
  final List<Comment> replies;  // 대댓글 목록

  Comment({
    required this.id,
    required this.postId,
    this.parentId,
    required this.content,
    required this.author,
    required this.division,
    required this.createdAt,
    this.likes = 0,
    this.dislikes = 0,
    this.replies = const [],
  });

  // JSON에서 Comment 객체 생성
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['commentId']?.toString() ?? json['id']?.toString() ?? '0',
      postId: json['postId']?.toString() ?? '0',
      parentId: json['parentId']?.toString(),
      content: json['content']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      division: json['division']?.toString() ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString()) 
          : DateTime.now(),
      likes: json['likes'] is int 
          ? json['likes'] 
          : (int.tryParse(json['likes']?.toString() ?? '0') ?? 0),
      dislikes: json['dislikes'] is int 
          ? json['dislikes'] 
          : (int.tryParse(json['dislikes']?.toString() ?? '0') ?? 0),
      replies: json['replies'] != null
          ? (json['replies'] as List).map((reply) => Comment.fromJson(reply)).toList()
          : [],
    );
  }

  // Comment 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'parentId': parentId,
      'content': content,
      'author': author,
      'division': division,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
      'dislikes': dislikes,
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }

  // 시간 포맷 (예: "2시간 전", "1일 전")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${createdAt.month}/${createdAt.day}';
    }
  }

  // 댓글인지 대댓글인지 확인
  bool get isReply => parentId != null;

  // 대댓글 개수
  int get replyCount => replies.length;

  // 댓글 복사 (수정용)
  Comment copyWith({
    String? id,
    String? postId,
    String? parentId,
    String? content,
    String? author,
    String? division,
    DateTime? createdAt,
    int? likes,
    int? dislikes,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      author: author ?? this.author,
      division: division ?? this.division,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      replies: replies ?? this.replies,
    );
  }

  // 대댓글 추가
  Comment addReply(Comment reply) {
    return copyWith(replies: [...replies, reply]);
  }

  // 대댓글 제거
  Comment removeReply(String replyId) {
    return copyWith(
      replies: replies.where((reply) => reply.id != replyId).toList(),
    );
  }

  // 대댓글 업데이트
  Comment updateReply(Comment updatedReply) {
    final updatedReplies = replies.map((reply) {
      return reply.id == updatedReply.id ? updatedReply : reply;
    }).toList();
    return copyWith(replies: updatedReplies);
  }
} 