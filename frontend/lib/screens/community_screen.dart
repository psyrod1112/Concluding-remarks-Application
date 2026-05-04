import 'package:flutter/material.dart';

import '../models/community_post.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import '../utils/app_message.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService communityService = CommunityService();

  final List<String> categories = const ['전체', '자유', '질문', '공략', '공지'];

  String selectedCategory = '전체';

  List<CommunityPost> get posts {
    return communityService.getPosts(category: selectedCategory);
  }

  void changeCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  void openWritePostSheet() {
    final user = AuthService().getCurrentUser();

    if (user == null) {
      AppMessage.show(context, '로그인 정보가 없습니다.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WritePostSheet(
          categories: categories.where((category) => category != '전체').toList(),
          onSubmit:
              ({
                required String title,
                required String content,
                required String category,
              }) {
                communityService.createPost(
                  title: title,
                  content: content,
                  category: category,
                  authorId: user.userId,
                  authorNickname: user.nickname,
                );

                setState(() {
                  selectedCategory = '전체';
                });

                Navigator.pop(context);
                AppMessage.show(this.context, '게시글이 등록되었습니다.');
              },
        );
      },
    );
  }

  void openPostDetail(CommunityPost post) {
    final updatedPost = communityService.increaseViewCount(post.id);

    setState(() {});

    showDialog(
      context: context,
      builder: (context) {
        return _PostDetailDialog(post: updatedPost);
      },
    );
  }

  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '방금 전';
    }

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    }

    if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    }

    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final currentPosts = posts;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('커뮤니티'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openWritePostSheet,
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('글쓰기'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;

                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) => changeCategory(category),
                  selectedColor: const Color(0xFFE8EAF6),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? const Color(0xFF3F51B5)
                        : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF3F51B5)
                        : Colors.black12,
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemCount: categories.length,
            ),
          ),
          Expanded(
            child: currentPosts.isEmpty
                ? const _EmptyPostView()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                    itemBuilder: (context, index) {
                      final post = currentPosts[index];

                      return _PostListItem(
                        post: post,
                        timeText: formatTime(post.createdAt),
                        onTap: () => openPostDetail(post),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemCount: currentPosts.length,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PostListItem extends StatelessWidget {
  final CommunityPost post;
  final String timeText;
  final VoidCallback onTap;

  const _PostListItem({
    required this.post,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CategoryBadge(category: post.category),
                  const SizedBox(width: 8),
                  Text(
                    timeText,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                post.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.black45,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.authorNickname,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: Colors.black38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.viewCount}',
                    style: const TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: Colors.black38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentCount}',
                    style: const TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3F51B5),
        ),
      ),
    );
  }
}

class _EmptyPostView extends StatelessWidget {
  const _EmptyPostView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '아직 게시글이 없습니다.',
        style: TextStyle(fontSize: 15, color: Colors.black45),
      ),
    );
  }
}

class _WritePostSheet extends StatefulWidget {
  final List<String> categories;
  final void Function({
    required String title,
    required String content,
    required String category,
  })
  onSubmit;

  const _WritePostSheet({required this.categories, required this.onSubmit});

  @override
  State<_WritePostSheet> createState() => _WritePostSheetState();
}

class _WritePostSheetState extends State<_WritePostSheet> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.categories.first;
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void submit() {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      AppMessage.show(context, '제목과 내용을 모두 입력해주세요.');
      return;
    }

    if (title.length < 2) {
      AppMessage.show(context, '제목은 2자 이상 입력해주세요.');
      return;
    }

    if (content.length < 5) {
      AppMessage.show(context, '내용은 5자 이상 입력해주세요.');
      return;
    }

    widget.onSubmit(title: title, content: content, category: selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                '게시글 작성',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: inputDecoration(
                  label: '카테고리',
                  icon: Icons.category_outlined,
                ),
                items: widget.categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: inputDecoration(label: '제목', icon: Icons.title),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: contentController,
                minLines: 5,
                maxLines: 8,
                decoration: inputDecoration(
                  label: '내용',
                  icon: Icons.notes_outlined,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '등록하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _PostDetailDialog extends StatelessWidget {
  final CommunityPost post;

  const _PostDetailDialog({required this.post});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryBadge(category: post.category),
          const SizedBox(height: 12),
          Text(
            post.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${post.authorNickname} · 조회 ${post.viewCount} · 댓글 ${post.commentCount}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 18),
              Text(
                post.content,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '댓글 기능은 추후 백엔드 연결 후 구현 예정입니다.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
