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

  CommunityPost copyWith({int? viewCount, int? commentCount}) {
    return CommunityPost(
      id: id,
      title: title,
      content: content,
      authorId: authorId,
      authorNickname: authorNickname,
      category: category,
      createdAt: createdAt,
      viewCount: viewCount ?? this.viewCount,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}
