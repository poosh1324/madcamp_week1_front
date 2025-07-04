class Post {
  final int id;
  final String title;
  final String content;
  final String author;
  final DateTime createdAt;
  final int views;
  final List<String> tags;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
    this.views = 0,
    this.tags = const [],
  });

  // JSON에서 Post 객체 생성
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      author: json['author'],
      createdAt: DateTime.parse(json['createdAt']),
      views: json['views'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
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
      'tags': tags,
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
    int? id,
    String? title,
    String? content,
    String? author,
    DateTime? createdAt,
    int? views,
    List<String>? tags,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      views: views ?? this.views,
      tags: tags ?? this.tags,
    );
  }
} 