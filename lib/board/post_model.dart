class Post {
  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime createdAt;
  final int likes;
  final int dislikes;
  final String division;
  final int views;

  Post({
    required this.id,
    required this.title,
    required this.author,
    required this.createdAt,
    this.likes = 0,
    this.dislikes = 0,
    required this.content,
    this.division = '',
    this.views = 0,
  });

  // JSON에서 Post 객체 생성
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['postId']?.toString() ?? json['id']?.toString() ?? '0',
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
      likes: json['likes'] is int ? json['likes'] : (int.tryParse(json['likes']?.toString() ?? '0') ?? 0),
      dislikes: json['dislikes'] is int ? json['dislikes'] : (int.tryParse(json['dislikes']?.toString() ?? '0') ?? 0),
      division: json['division']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      views: json['views'] is int ? json['views'] : (int.tryParse(json['views']?.toString() ?? '0') ?? 0),
    );
  }

  // Post 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
      'views': views,
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

  // 게시글 복사 (수정용)
  Post copyWith({
    String? id,
    String? title,
    String? content,
    String? author,
    DateTime? createdAt,
    int? views,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      views: views ?? this.views,
    );
  }
} 