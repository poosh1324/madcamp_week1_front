class ImageComment {
  final String commentId;
  final String content;
  final String author;
  final DateTime createdAt;
  final int likes;
  final int dislikes;
  final String? parentId;
  final List<ImageComment> replies;

  ImageComment({
    required this.commentId,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.likes,
    required this.dislikes,
    this.parentId,
    this.replies = const [],
  });

  factory ImageComment.fromJson(Map<String, dynamic> json) {
    return ImageComment(
      commentId: json['commentId'],
      content: json['content'],
      author: json['author'],
      createdAt: DateTime.parse(json['createdAt']),
      likes: json['likes'] ?? 0,
      dislikes: json['dislikes'] ?? 0,
      parentId: json['parent_id'],
      replies: json['replies'] != null
          ? (json['replies'] as List)
                .map((item) => ImageComment.fromJson(item))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'content': content,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
      'dislikes': dislikes,
      'parent_id': parentId,
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }
}
