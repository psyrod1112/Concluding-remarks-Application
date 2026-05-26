class CommunityPost {
  final int id;
  final String title;
  final String content;
  final String authorId;
  final String authorNickname;
  final String category;
  final DateTime createdAt;
  final int viewCount;
  final int commentCount;

  CommunityPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorNickname,
    required this.category,
    required this.createdAt,
    this.viewCount = 0,
    this.commentCount = 0,
  });

  /// 백엔드 응답 JSON → CommunityPost
  /// 목록: snake_case (view_count, created_at, author_id ...)
  /// 상세: camelCase (viewCount, createdAt, authorId ...)
  /// 둘 다 처리
  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id:             json['id'] as int,
      title:          json['title'] as String,
      content:        (json['content'] ?? '') as String,
      category:       json['category'] as String,
      authorId:       (json['author_id'] ?? json['authorId'] ?? '') as String,
      authorNickname: (json['author_nickname'] ?? json['authorNickname'] ?? '') as String,
      createdAt:      DateTime.parse(json['created_at'] ?? json['createdAt']),
      viewCount:      (json['view_count'] ?? json['viewCount'] ?? 0) as int,
      // COUNT()는 DB에서 문자열로 올 수 있으므로 int.parse 처리
      commentCount:   int.parse((json['comment_count'] ?? json['commentCount'] ?? 0).toString()),
    );
  }

  CommunityPost copyWith({int? viewCount, int? commentCount}) {
    return CommunityPost(
      id:             id,
      title:          title,
      content:        content,
      authorId:       authorId,
      authorNickname: authorNickname,
      category:       category,
      createdAt:      createdAt,
      viewCount:      viewCount ?? this.viewCount,
      commentCount:   commentCount ?? this.commentCount,
    );
  }
}
