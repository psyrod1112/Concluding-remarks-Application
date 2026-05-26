import 'package:flutter/material.dart';

import '../models/comment.dart';
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
  List<CommunityPost> _posts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await communityService.getPosts(category: selectedCategory);
      setState(() => _posts = posts);
    } catch (_) {
      if (mounted) AppMessage.show(context, '게시글을 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void changeCategory(String category) {
    setState(() => selectedCategory = category);
    _loadPosts();
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
      builder: (context) => _WritePostSheet(
        categories: categories.where((c) => c != '전체' && c != '공지').toList(),
        onSubmit: ({required String title, required String content, required String category}) {
          // 시트 닫기
          Navigator.pop(context);

          // 비동기로 API 호출 후 목록 갱신
          communityService
              .createPost(title: title, content: content, category: category)
              .then((_) {
                setState(() => selectedCategory = '전체');
                _loadPosts();
                AppMessage.show(this.context, '게시글이 등록되었습니다.');
              })
              .catchError((_) {
                AppMessage.show(this.context, '게시글 작성에 실패했습니다.');
              });
        },
      ),
    );
  }

  void openPostDetail(CommunityPost post) {
    showDialog(
      context: context,
      builder: (context) => _PostDetailDialog(
        post: post,
        communityService: communityService,
      ),
    ).then((_) => _loadPosts()); // 닫힐 때 목록 갱신 (조회수 반영)
  }

  String formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('커뮤니티')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openWritePostSheet,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('글쓰기'),
      ),
      body: Column(
        children: [
          // 카테고리 칩
          SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) => changeCategory(category),
                  backgroundColor: theme.cardColor,
                  selectedColor: colorScheme.primary.withOpacity(0.20),
                  labelStyle: TextStyle(
                    color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.12),
                  ),
                );
              },
            ),
          ),

          // 게시글 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                    ? const _EmptyPostView()
                    : RefreshIndicator(
                        onRefresh: _loadPosts,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                          itemCount: _posts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _PostListItem(
                            post: _posts[index],
                            timeText: formatTime(_posts[index].createdAt),
                            onTap: () => openPostDetail(_posts[index]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── 게시글 목록 아이템 ──────────────────────────
class _PostListItem extends StatelessWidget {
  final CommunityPost post;
  final String timeText;
  final VoidCallback onTap;

  const _PostListItem({required this.post, required this.timeText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: theme.cardColor,
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
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.45)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                post.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.65), height: 1.35),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: colorScheme.onSurface.withOpacity(0.45)),
                  const SizedBox(width: 4),
                  Text(post.authorNickname, style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.65))),
                  const Spacer(),
                  Icon(Icons.visibility_outlined, size: 16, color: colorScheme.onSurface.withOpacity(0.40)),
                  const SizedBox(width: 4),
                  Text('${post.viewCount}', style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.55))),
                  const SizedBox(width: 12),
                  Icon(Icons.chat_bubble_outline, size: 16, color: colorScheme.onSurface.withOpacity(0.40)),
                  const SizedBox(width: 4),
                  Text('${post.commentCount}', style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.55))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 카테고리 뱃지 ──────────────────────────────
class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
      ),
    );
  }
}

// ── 빈 목록 ──────────────────────────────────
class _EmptyPostView extends StatelessWidget {
  const _EmptyPostView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '아직 게시글이 없습니다.',
        style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)),
      ),
    );
  }
}

// ── 게시글 상세 다이얼로그 (댓글 포함) ───────────
class _PostDetailDialog extends StatefulWidget {
  final CommunityPost post;
  final CommunityService communityService;

  const _PostDetailDialog({required this.post, required this.communityService});

  @override
  State<_PostDetailDialog> createState() => _PostDetailDialogState();
}

class _PostDetailDialogState extends State<_PostDetailDialog> {
  final TextEditingController _commentController = TextEditingController();

  CommunityPost? _fullPost;
  List<Comment> _comments = [];
  bool _isLoadingPost = true;
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final post = await widget.communityService.getPost(widget.post.id);
      final comments = await widget.communityService.getComments(widget.post.id);
      setState(() {
        _fullPost = post;
        _comments = comments;
      });
    } catch (_) {
      // 실패 시 기존 post 그대로 표시
      setState(() => _fullPost = widget.post);
    } finally {
      if (mounted) setState(() => _isLoadingPost = false);
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = AuthService().getCurrentUser();
    if (user == null) {
      AppMessage.show(context, '로그인이 필요합니다.');
      return;
    }

    setState(() => _isSubmittingComment = true);
    try {
      final comment = await widget.communityService.createComment(
        postId: widget.post.id,
        content: content,
      );
      _commentController.clear();
      setState(() => _comments.add(comment));
    } catch (_) {
      if (mounted) AppMessage.show(context, '댓글 작성에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final post = _fullPost ?? widget.post;

    return AlertDialog(
      backgroundColor: theme.cardColor,
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: _isLoadingPost
            ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 메타 정보
                    Text(
                      '${post.authorNickname} · 조회 ${post.viewCount} · 댓글 ${_comments.length}',
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.65)),
                    ),
                    const SizedBox(height: 18),

                    // 본문
                    Text(
                      post.content,
                      style: TextStyle(fontSize: 15, height: 1.5, color: colorScheme.onSurface),
                    ),
                    const Divider(height: 36),

                    // 댓글 목록
                    if (_comments.isEmpty)
                      Text(
                        '아직 댓글이 없습니다.',
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.55)),
                      )
                    else
                      ..._comments.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: colorScheme.primary.withOpacity(0.15),
                                  child: Text(
                                    c.authorNickname.isNotEmpty ? c.authorNickname[0] : '?',
                                    style: TextStyle(fontSize: 12, color: colorScheme.primary),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(c.authorNickname, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 8),
                                          Text(_formatTime(c.createdAt), style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.5))),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(c.content, style: TextStyle(fontSize: 14, color: colorScheme.onSurface)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),

                    const SizedBox(height: 12),

                    // 댓글 입력
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _submitComment(),
                            decoration: InputDecoration(
                              hintText: '댓글을 입력하세요',
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _isSubmittingComment
                            ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2.5))
                            : IconButton(
                                onPressed: _submitComment,
                                icon: Icon(Icons.send, color: colorScheme.primary),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
      ],
    );
  }
}

// ── 글쓰기 시트 ────────────────────────────────
class _WritePostSheet extends StatefulWidget {
  final List<String> categories;
  final void Function({required String title, required String content, required String category}) onSubmit;

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

  InputDecoration _inputDeco(BuildContext context, {required String label, required IconData icon}) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: theme.cardColor,
      labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.75)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42, height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 22),
              Text('게시글 작성', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: theme.cardColor,
                decoration: _inputDeco(context, label: '카테고리', icon: Icons.category_outlined),
                items: widget.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) { if (v != null) setState(() => selectedCategory = v); },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: _inputDeco(context, label: '제목', icon: Icons.title),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: contentController,
                minLines: 5,
                maxLines: 8,
                decoration: _inputDeco(context, label: '내용', icon: Icons.notes_outlined),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: submit,
                  child: const Text('등록하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
