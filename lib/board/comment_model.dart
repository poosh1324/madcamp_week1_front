class Comment {
  final String id;
  final String postId;
  final String content;
  final String author;
  final String division;
  final DateTime createdAt;
  final int likes;
  final int dislikes;

  Comment({
    required this.id,
    required this.postId,
    required this.content,
    required this.author,
    required this.division,
    required this.createdAt,
    this.likes = 0,
    this.dislikes = 0,
  });

  // JSON에서 Comment 객체 생성
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['commentId']?.toString() ?? json['id']?.toString() ?? '0',
      postId: json['postId']?.toString() ?? '0',
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
    );
  }

  // Comment 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'content': content,
      'author': author,
      'division': division,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
      'dislikes': dislikes,
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

  // 댓글 복사 (수정용)
  Comment copyWith({
    String? id,
    String? postId,
    String? content,
    String? author,
    String? division,
    DateTime? createdAt,
    int? likes,
    int? dislikes,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      content: content ?? this.content,
      author: author ?? this.author,
      division: division ?? this.division,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
    );
  }
} 