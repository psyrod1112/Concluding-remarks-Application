import '../models/community_post.dart';
import '../models/comment.dart';
import 'api_client.dart';

class CommunityService {
  // ── 게시글 목록 ─────────────────────────
  Future<List<CommunityPost>> getPosts({String category = '전체'}) async {
    final query = category == '전체' ? '' : '?category=$category';
    final data = await ApiClient.get('/api/community/posts$query');
    return (data['posts'] as List)
        .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 게시글 작성 ─────────────────────────
  Future<CommunityPost> createPost({
    required String title,
    required String content,
    required String category,
  }) async {
    final data = await ApiClient.post('/api/community/posts', {
      'title': title,
      'content': content,
      'category': category,
    });
    return CommunityPost.fromJson(data['post'] as Map<String, dynamic>);
  }

  // ── 게시글 상세 (조회수 +1 서버에서 자동 처리) ──
  Future<CommunityPost> getPost(int postId) async {
    final data = await ApiClient.get('/api/community/posts/$postId');
    return CommunityPost.fromJson(data);
  }

  // ── 댓글 목록 ──────────────────────────
  Future<List<Comment>> getComments(int postId) async {
    final data = await ApiClient.get('/api/community/posts/$postId/comments');
    return (data['comments'] as List)
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 댓글 작성 ──────────────────────────
  Future<Comment> createComment({
    required int postId,
    required String content,
  }) async {
    final data = await ApiClient.post(
      '/api/community/posts/$postId/comments',
      {'content': content},
    );
    return Comment.fromJson(data['comment'] as Map<String, dynamic>);
  }
}
