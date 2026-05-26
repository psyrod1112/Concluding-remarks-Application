class Comment {
  final int id;
  final String content;
  final String authorId;
  final String authorNickname;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorNickname,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id:             json['id'] as int,
      content:        json['content'] as String,
      authorId:       (json['author_id'] ?? json['authorId'] ?? '') as String,
      authorNickname: (json['author_nickname'] ?? json['authorNickname'] ?? '') as String,
      createdAt:      DateTime.parse(json['created_at'] ?? json['createdAt']),
    );
  }
}
