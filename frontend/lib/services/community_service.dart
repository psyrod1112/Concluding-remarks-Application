import '../models/community_post.dart';

class CommunityService {
  static int _nextId = 4;

  static final List<CommunityPost> _posts = [
    CommunityPost(
      id: 1,
      title: '끝말잇기 한방단어 공유합니다',
      content: '나중에 게임 화면 연결되면 한방단어 목록도 정리해보면 좋을 것 같아요.',
      authorId: 'test1234',
      authorNickname: '테스트유저',
      category: '공략',
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      viewCount: 23,
      commentCount: 2,
    ),
    CommunityPost(
      id: 2,
      title: '랜덤 매칭 오래 걸릴 때 어떻게 처리할까요?',
      content: '상대가 없을 때 AI대결로 넘기는 방식도 괜찮을 것 같습니다.',
      authorId: 'word_master',
      authorNickname: '끝말고수',
      category: '질문',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      viewCount: 15,
      commentCount: 4,
    ),
    CommunityPost(
      id: 3,
      title: '친선 대결 방 만들기 기능 필요해 보여요',
      content: '초대 코드로 친구랑 방 입장하는 구조가 있으면 좋겠습니다.',
      authorId: 'apple_king',
      authorNickname: '사과왕',
      category: '자유',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      viewCount: 31,
      commentCount: 1,
    ),
  ];

  List<CommunityPost> getPosts({String category = '전체'}) {
    if (category == '전체') {
      return List.unmodifiable(_posts);
    }

    return List.unmodifiable(_posts.where((post) => post.category == category));
  }

  void createPost({
    required String title,
    required String content,
    required String authorId,
    required String authorNickname,
    required String category,
  }) {
    final post = CommunityPost(
      id: _nextId,
      title: title,
      content: content,
      authorId: authorId,
      authorNickname: authorNickname,
      category: category,
      createdAt: DateTime.now(),
    );

    _nextId++;
    _posts.insert(0, post);
  }

  CommunityPost increaseViewCount(int postId) {
    final index = _posts.indexWhere((post) => post.id == postId);

    if (index == -1) {
      throw Exception('게시글을 찾을 수 없습니다.');
    }

    final updatedPost = _posts[index].copyWith(
      viewCount: _posts[index].viewCount + 1,
    );

    _posts[index] = updatedPost;
    return updatedPost;
  }
}
