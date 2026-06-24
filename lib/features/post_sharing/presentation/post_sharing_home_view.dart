import 'dart:async';
import 'dart:io';

import 'package:courtly/features/post_sharing/data/post_sharing_seed.dart';
import 'package:courtly/features/post_sharing/domain/post_sharing_post.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

const Color _postPurple = Color(0xFF1A004D);
const Color _postPanel = Color(0xFF2B0067);
const Color _postPanelSoft = Color(0xFF59308B);
const Color _postPink = Color(0xFFFF2DD2);

class PostSharingHomeView extends StatefulWidget {
  const PostSharingHomeView({super.key});

  @override
  State<PostSharingHomeView> createState() => _PostSharingHomeViewState();
}

class _PostSharingHomeViewState extends State<PostSharingHomeView> {
  List<PostSharingPost> _posts = List<PostSharingPost>.of(
    PostSharingSeed.openingPosts,
  );
  int _checkInDays = 213;
  final Set<int> _checkedDays = {2, 8, 14, 21};

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _PostBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 42, 22, 0),
                child: _PostTopBar(onCompose: _openComposer),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                child: _ShortcutRow(
                  onCheckIn: _openCheckIn,
                  onRanking: _openRanking,
                ),
              ),
            ),
            SliverList.separated(
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    index == 0 ? 0 : 4,
                    22,
                    index == _posts.length - 1 ? 120 : 0,
                  ),
                  child: _PostCard(
                    post: post,
                    onOpenDetail: () => _openDetail(post),
                    onOpenProfile: () => _openProfile(post),
                    onToggleLike: () => _toggleLike(post.id),
                    onToggleFollow: () => _toggleFollow(post.id),
                    onMore: () => _showPostActions(post),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 18),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openComposer() async {
    final draft = await Navigator.of(context).push<PostSharingDraft>(
      CupertinoPageRoute<PostSharingDraft>(
        builder: (_) => const PostComposerPage(),
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    final post = PostSharingPost(
      id: 'local-post-${DateTime.now().microsecondsSinceEpoch}',
      authorName: 'You',
      createdAtLabel: _formatNow(),
      body: draft.body,
      imageAsset: 'assets/images/Backhand.png',
      avatarAsset: 'assets/images/Story.png',
      likes: 0,
      isLiked: false,
      isFollowed: true,
      comments: const [],
      videoAssets: const [
        'assets/images/Backhand.png',
        'assets/images/Forehand.png',
        'assets/images/Profile.png',
      ],
    );

    setState(() => _posts = [post, ..._posts]);
  }

  Future<void> _openDetail(PostSharingPost post) async {
    final updated = await Navigator.of(context).push<PostSharingPost>(
      CupertinoPageRoute<PostSharingPost>(
        builder: (_) => PostDetailPage(
          post: post,
          onCompose: () {
            unawaited(_openComposer());
          },
        ),
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    _replacePost(updated.id, updated);
  }

  Future<void> _openProfile(PostSharingPost post) async {
    final updated = await Navigator.of(context).push<PostSharingPost>(
      CupertinoPageRoute<PostSharingPost>(
        builder: (_) => PostUserHomePage(post: post),
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    _replacePost(updated.id, updated);
  }

  Future<void> _openCheckIn() async {
    final checked = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        builder: (_) => TennisCheckInPage(
          checkedDays: _checkedDays,
          checkInDays: _checkInDays,
        ),
      ),
    );

    if (checked == true && mounted) {
      setState(() {
        _checkedDays.add(24);
        _checkInDays += 1;
      });
    }
  }

  void _openRanking() {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute<void>(builder: (_) => const TennisRankingPage()));
  }

  void _toggleLike(String postId) {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index == -1) {
      return;
    }

    final post = _posts[index];
    final nextLiked = !post.isLiked;
    final nextLikes = (post.likes + (nextLiked ? 1 : -1))
        .clamp(0, 999999)
        .toInt();
    _replacePostAt(index, post.copyWith(isLiked: nextLiked, likes: nextLikes));
  }

  void _toggleFollow(String postId) {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index == -1) {
      return;
    }

    final post = _posts[index];
    _replacePostAt(index, post.copyWith(isFollowed: !post.isFollowed));
  }

  Future<void> _showPostActions(PostSharingPost post) async {
    final action = await showCupertinoModalPopup<_PostAction>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: Text(post.authorName),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(_PostAction.profile),
              child: const Text('View profile'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(_PostAction.report),
              child: const Text('Report post'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(_PostAction.hide),
              child: const Text('Hide post'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _PostAction.profile:
        unawaited(_openProfile(post));
      case _PostAction.report:
        await _showNotice(
          title: 'Report sent',
          message: 'Thanks for helping keep Post sharing useful.',
        );
      case _PostAction.hide:
        setState(() {
          _posts = _posts.where((entry) => entry.id != post.id).toList();
        });
    }
  }

  void _replacePost(String postId, PostSharingPost post) {
    final index = _posts.indexWhere((entry) => entry.id == postId);
    if (index == -1) {
      return;
    }
    _replacePostAt(index, post);
  }

  void _replacePostAt(int index, PostSharingPost post) {
    setState(() {
      final nextPosts = List<PostSharingPost>.of(_posts);
      nextPosts[index] = post;
      _posts = nextPosts;
    });
  }

  Future<void> _showNotice({required String title, required String message}) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _formatNow() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    return '$year/$month/$day $hour:$minute';
  }
}

enum _PostAction { profile, report, hide }

class _PostBackground extends StatelessWidget {
  const _PostBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/Strings.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        DecoratedBox(
          decoration: BoxDecoration(color: _postPurple.withValues(alpha: 0.72)),
        ),
        child,
      ],
    );
  }
}

class _PostTopBar extends StatelessWidget {
  const _PostTopBar({required this.onCompose});

  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/Spin.png',
          width: 154,
          height: 32,
          fit: BoxFit.contain,
        ),
        const Spacer(),
        CupertinoButton(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          onPressed: onCompose,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: CupertinoColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: SizedBox.square(
              dimension: 40,
              child: Center(
                child: Image.asset(
                  'assets/images/Singles.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.onCheckIn, required this.onRanking});

  final VoidCallback onCheckIn;
  final VoidCallback onRanking;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ShortcutCard(
            title: 'Tennis\nclock in',
            imageAsset: 'assets/images/Ace.png',
            onPressed: onCheckIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ShortcutCard(
            title: 'Ranking\nlist',
            imageAsset: 'assets/images/Backhand.png',
            onPressed: onRanking,
          ),
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.title,
    required this.imageAsset,
    required this.onPressed,
  });

  final String title;
  final String imageAsset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: _postPanel,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _postPurple.withValues(alpha: 0.44),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 14,
              child: Text(
                title,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoColors.white,
                  fontSize: 15,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 8,
              child: Image.asset(
                imageAsset == 'assets/images/Ace.png'
                    ? 'assets/images/Ace.png'
                    : 'assets/images/Rally.png',
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onOpenDetail,
    required this.onOpenProfile,
    required this.onToggleLike,
    required this.onToggleFollow,
    required this.onMore,
  });

  final PostSharingPost post;
  final VoidCallback onOpenDetail;
  final VoidCallback onOpenProfile;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleFollow;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _postPanel.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CupertinoButton(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  onPressed: onOpenProfile,
                  child: _Avatar(assetPath: post.avatarAsset, size: 40),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CupertinoButton(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    onPressed: onOpenProfile,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _postText(context).copyWith(
                            color: CupertinoColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          post.createdAtLabel,
                          style: _postText(context).copyWith(
                            color: CupertinoColors.white.withValues(
                              alpha: 0.54,
                            ),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _FollowButton(
                  isFollowed: post.isFollowed,
                  onPressed: onToggleFollow,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.body,
              style: _postText(context).copyWith(
                color: CupertinoColors.white.withValues(alpha: 0.86),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              onPressed: onOpenDetail,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1.18,
                  child: Image.asset(
                    post.imageAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _PostMetricButton(
                  iconAsset: post.isLiked
                      ? 'assets/images/Racquet.png'
                      : 'assets/images/Volley.png',
                  label: _countLabel(post.likes),
                  onPressed: onToggleLike,
                ),
                const SizedBox(width: 22),
                _PostMetricButton(
                  iconData: CupertinoIcons.chat_bubble_fill,
                  label: _countLabel(post.comments.length),
                  onPressed: onOpenDetail,
                ),
                const Spacer(),
                _PostMetricButton(
                  iconAsset: 'assets/images/Courtside.png',
                  onPressed: onMore,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PostMetricButton extends StatelessWidget {
  const _PostMetricButton({
    required this.onPressed,
    this.iconAsset,
    this.iconData,
    this.label,
  });

  final String? iconAsset;
  final IconData? iconData;
  final String? label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null)
            Image.asset(iconAsset!, width: 22, height: 22, fit: BoxFit.contain)
          else
            Icon(iconData, color: CupertinoColors.white, size: 20),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(
              label!,
              style: _postText(context).copyWith(
                color: CupertinoColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.isFollowed, required this.onPressed});

  final bool isFollowed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Image.asset(
        isFollowed ? 'assets/images/Chat.png' : 'assets/images/Huddle.png',
        width: 96,
        height: 30,
        fit: BoxFit.fill,
      ),
    );
  }
}

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({
    required this.post,
    required this.onCompose,
    super.key,
  });

  final PostSharingPost post;
  final VoidCallback onCompose;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late PostSharingPost _post = widget.post;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return CupertinoPageScaffold(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _post.imageAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Color(0x22000000),
                  Color(0xDD1A004D),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 12,
            child: _RoundIconButton(
              icon: CupertinoIcons.chevron_left,
              onPressed: () => Navigator.of(context).pop(_post),
            ),
          ),
          Positioned(
            top: 42,
            right: 18,
            child: CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              onPressed: widget.onCompose,
              child: Image.asset(
                'assets/images/Singles.png',
                width: 42,
                height: 42,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 270 + keyboardInset,
            child: _DetailAuthorBlock(post: _post, onFollow: _toggleFollow),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: keyboardInset,
            height: 270,
            child: _DetailCommentsPanel(
              post: _post,
              controller: _commentController,
              onSend: _sendComment,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFollow() {
    setState(() => _post = _post.copyWith(isFollowed: !_post.isFollowed));
  }

  void _sendComment() {
    final body = _commentController.text.trim();
    if (body.isEmpty) {
      return;
    }

    setState(() {
      _post = _post.copyWith(
        comments: [
          ..._post.comments,
          PostSharingComment(
            authorName: 'You',
            createdAtLabel: 'now',
            body: body,
            avatarAsset: 'assets/images/Story.png',
          ),
        ],
      );
      _commentController.clear();
    });
  }
}

class _DetailAuthorBlock extends StatelessWidget {
  const _DetailAuthorBlock({required this.post, required this.onFollow});

  final PostSharingPost post;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                post.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _postText(context).copyWith(
                  color: CupertinoColors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _FollowButton(isFollowed: post.isFollowed, onPressed: onFollow),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          post.createdAtLabel,
          style: _postText(context).copyWith(
            color: CupertinoColors.white.withValues(alpha: 0.62),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          post.body,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: _postText(context).copyWith(
            color: CupertinoColors.white.withValues(alpha: 0.88),
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Discuss',
          style: _postText(context).copyWith(
            color: CupertinoColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _DetailCommentsPanel extends StatelessWidget {
  const _DetailCommentsPanel({
    required this.post,
    required this.controller,
    required this.onSend,
  });

  final PostSharingPost post;
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: _postPanel),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              physics: const BouncingScrollPhysics(),
              itemCount: post.comments.length,
              itemBuilder: (context, index) {
                return _PostCommentRow(comment: post.comments[index]);
              },
              separatorBuilder: (context, index) {
                return SizedBox(
                  height: 22,
                  child: Center(
                    child: ColoredBox(
                      color: CupertinoColors.white.withValues(alpha: 0.22),
                      child: const SizedBox(height: 1, width: double.infinity),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: _PostCommentComposer(controller: controller, onSend: onSend),
          ),
        ],
      ),
    );
  }
}

class PostComposerPage extends StatefulWidget {
  const PostComposerPage({super.key});

  @override
  State<PostComposerPage> createState() => _PostComposerPageState();
}

class _PostComposerPageState extends State<PostComposerPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _bodyController = TextEditingController();
  String? _imagePath;
  bool _isPickingImage = false;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return CupertinoPageScaffold(
      child: _PostBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 40,
              left: 12,
              child: _RoundIconButton(
                icon: CupertinoIcons.chevron_left,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: 52,
              left: 74,
              right: 74,
              child: Text(
                'Post sharing',
                textAlign: TextAlign.center,
                style: _postText(context).copyWith(
                  color: CupertinoColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(28, 120, 28, 48 + keyboardInset),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _ComposerImageCard(
                      imagePath: _imagePath,
                      isPickingImage: _isPickingImage,
                      onPressed: _pickImage,
                    ),
                    const SizedBox(height: 24),
                    _ComposerBodyField(controller: _bodyController),
                    const SizedBox(height: 74),
                    CupertinoButton(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      onPressed: _releasePost,
                      child: Image.asset(
                        'assets/images/Lesson.png',
                        width: 290,
                        height: 55,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 84,
        maxWidth: 1600,
      );
      if (image != null && mounted) {
        setState(() => _imagePath = image.path);
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _releasePost() async {
    final body = _bodyController.text.trim();
    if (_imagePath == null) {
      await _showDraftNotice(
        title: 'Select a photo',
        message: 'Choose one tennis moment before publishing.',
      );
      return;
    }

    if (body.isEmpty) {
      await _showDraftNotice(
        title: 'Add your thoughts',
        message: 'Write a short post before releasing it.',
      );
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pop(PostSharingDraft(body: body, imagePath: _imagePath!));
  }

  Future<void> _showDraftNotice({
    required String title,
    required String message,
  }) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class _ComposerImageCard extends StatelessWidget {
  const _ComposerImageCard({
    required this.imagePath,
    required this.isPickingImage,
    required this.onPressed,
  });

  final String? imagePath;
  final bool isPickingImage;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 256,
        height: 210,
        decoration: BoxDecoration(
          color: _postPanelSoft.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(22),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: isPickingImage
              ? const Center(
                  child: CupertinoActivityIndicator(
                    color: CupertinoColors.white,
                  ),
                )
              : imagePath == null
              ? Icon(
                  CupertinoIcons.plus,
                  color: CupertinoColors.white.withValues(alpha: 0.34),
                  size: 64,
                )
              : Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
        ),
      ),
    );
  }
}

class _ComposerBodyField extends StatelessWidget {
  const _ComposerBodyField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _postPanelSoft.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        height: 142,
        child: CupertinoTextField(
          controller: controller,
          maxLines: null,
          expands: true,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          placeholder: 'Please input your mood and feelings',
          placeholderStyle: _postText(context).copyWith(
            color: CupertinoColors.white.withValues(alpha: 0.34),
            fontSize: 14,
          ),
          style: _postText(context).copyWith(
            color: CupertinoColors.white,
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
          decoration: const BoxDecoration(),
          cursorColor: CupertinoColors.white,
        ),
      ),
    );
  }
}

class PostUserHomePage extends StatefulWidget {
  const PostUserHomePage({required this.post, super.key});

  final PostSharingPost post;

  @override
  State<PostUserHomePage> createState() => _PostUserHomePageState();
}

class _PostUserHomePageState extends State<PostUserHomePage> {
  late PostSharingPost _post = widget.post;
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _post.imageAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22000000),
                  Color(0x991A004D),
                  Color(0xFF1A004D),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 12,
            child: _RoundIconButton(
              icon: CupertinoIcons.chevron_left,
              onPressed: () => Navigator.of(context).pop(_post),
            ),
          ),
          Positioned(
            top: 50,
            right: 18,
            child: const Icon(
              CupertinoIcons.ellipsis_circle_fill,
              color: CupertinoColors.white,
              size: 28,
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            top: 300,
            bottom: 104,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailAuthorBlock(post: _post, onFollow: _toggleFollow),
                const SizedBox(height: 18),
                _ProfileSegmentedTabs(
                  selectedIndex: _selectedTab,
                  onChanged: (index) => setState(() => _selectedTab = index),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _selectedTab == 0
                      ? _VideoGrid(videoAssets: _post.videoAssets)
                      : _ProfilePostPreview(post: _post),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFollow() {
    setState(() => _post = _post.copyWith(isFollowed: !_post.isFollowed));
  }
}

class _ProfileSegmentedTabs extends StatelessWidget {
  const _ProfileSegmentedTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProfileTabLabel(
          label: 'Videos',
          isSelected: selectedIndex == 0,
          onPressed: () => onChanged(0),
        ),
        const SizedBox(width: 28),
        _ProfileTabLabel(
          label: 'Post',
          isSelected: selectedIndex == 1,
          onPressed: () => onChanged(1),
        ),
      ],
    );
  }
}

class _ProfileTabLabel extends StatelessWidget {
  const _ProfileTabLabel({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Text(
        label,
        style: _postText(context).copyWith(
          color: isSelected
              ? CupertinoColors.white
              : CupertinoColors.white.withValues(alpha: 0.4),
          fontSize: 16,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VideoGrid extends StatelessWidget {
  const _VideoGrid({required this.videoAssets});

  final List<String> videoAssets;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.78,
      ),
      itemCount: videoAssets.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                videoAssets[index],
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withValues(alpha: 0.28),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(
                    dimension: 34,
                    child: Icon(
                      CupertinoIcons.play_fill,
                      color: CupertinoColors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfilePostPreview extends StatelessWidget {
  const _ProfilePostPreview({required this.post});

  final PostSharingPost post;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: _PostCard(
        post: post,
        onOpenDetail: () {},
        onOpenProfile: () {},
        onToggleLike: () {},
        onToggleFollow: () {},
        onMore: () {},
      ),
    );
  }
}

class TennisCheckInPage extends StatefulWidget {
  const TennisCheckInPage({
    required this.checkedDays,
    required this.checkInDays,
    super.key,
  });

  final Set<int> checkedDays;
  final int checkInDays;

  @override
  State<TennisCheckInPage> createState() => _TennisCheckInPageState();
}

class _TennisCheckInPageState extends State<TennisCheckInPage> {
  late final Set<int> _checkedDays = Set<int>.of(widget.checkedDays);
  late int _checkInDays = widget.checkInDays;
  bool _checkedToday = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _PostBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 40,
              left: 12,
              child: _RoundIconButton(
                icon: CupertinoIcons.chevron_left,
                onPressed: () => Navigator.of(context).pop(_checkedToday),
              ),
            ),
            Positioned(
              top: 52,
              left: 74,
              right: 74,
              child: Text(
                'Tennis Diary',
                textAlign: TextAlign.center,
                style: _postText(context).copyWith(
                  color: CupertinoColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Positioned.fill(
              top: 100,
              bottom: 114,
              left: 22,
              right: 22,
              child: Column(
                children: [
                  _DiaryBoard(days: _checkInDays),
                  const SizedBox(height: 18),
                  _CalendarCard(checkedDays: _checkedDays),
                  const SizedBox(height: 18),
                  CupertinoButton(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    onPressed: _clockIn,
                    child: Image.asset(
                      'assets/images/Footwork.png',
                      width: double.infinity,
                      height: 55,
                      fit: BoxFit.fill,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CupertinoButton(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    onPressed: _retroClockIn,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA8F2E5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 18),
                          Expanded(
                            child: Text(
                              'Forgot to clock in for 1 day',
                              style: _postText(context).copyWith(
                                color: const Color(0xFF4E9A91),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/images/Tiebreak.png',
                            width: 104,
                            height: 27,
                            fit: BoxFit.fill,
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clockIn() {
    if (_checkedToday) {
      return;
    }

    setState(() {
      _checkedToday = true;
      _checkedDays.add(24);
      _checkInDays += 1;
    });
  }

  void _retroClockIn() {
    setState(() => _checkedDays.add(1));
  }
}

class _DiaryBoard extends StatelessWidget {
  const _DiaryBoard({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/Backhand.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF44D98F).withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 22,
            child: Text(
              '$days',
              style: _postText(context).copyWith(
                color: CupertinoColors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 70,
            width: 150,
            child: Text(
              'You have checked in continuously',
              style: _postText(context).copyWith(
                color: CupertinoColors.white.withValues(alpha: 0.88),
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.checkedDays});

  final Set<int> checkedDays;

  @override
  Widget build(BuildContext context) {
    final days = List<int>.generate(35, (index) => index - 1);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/Ace.png',
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                '2026/06',
                style: _postText(context).copyWith(
                  color: const Color(0xFF6E6A75),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final label in [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun',
              ])
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: _postText(context).copyWith(
                      color: const Color(0xFFC4BECF),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final active = day > 0 && checkedDays.contains(day);
              final highlighted = day == 1 || day == 24;

              return DecoratedBox(
                decoration: BoxDecoration(
                  color: active
                      ? _postPink
                      : highlighted
                      ? const Color(0xFFFFDCEB)
                      : const Color(0xFFF7F4F8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: active
                      ? const Icon(
                          CupertinoIcons.check_mark,
                          color: CupertinoColors.white,
                          size: 13,
                        )
                      : Text(
                          day > 0 ? '$day' : '',
                          style: _postText(context).copyWith(
                            color: const Color(0xFF98909E),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class TennisRankingPage extends StatelessWidget {
  const TennisRankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = PostSharingSeed.ranking;

    return CupertinoPageScaffold(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/Strings.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCCED88FF), Color(0xFF090D14)],
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 12,
            child: _RoundIconButton(
              icon: CupertinoIcons.chevron_left,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: 100,
            left: 24,
            child: Image.asset(
              'assets/images/Umpire.png',
              width: 220,
              height: 52,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            top: 190,
            child: _RankingPodium(entries: entries.take(3).toList()),
          ),
          Positioned(
            left: 22,
            right: 22,
            top: 382,
            bottom: 108,
            child: _RankingList(entries: entries.skip(3).toList()),
          ),
        ],
      ),
    );
  }
}

class _RankingPodium extends StatelessWidget {
  const _RankingPodium({required this.entries});

  final List<PostRankingEntry> entries;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumPerson(
              entry: entries[1],
              asset: 'assets/images/Drop.png',
            ),
          ),
          Expanded(
            child: _PodiumPerson(
              entry: entries[0],
              asset: 'assets/images/Advantage.png',
              isWinner: true,
            ),
          ),
          Expanded(
            child: _PodiumPerson(
              entry: entries[2],
              asset: 'assets/images/Deuce.png',
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumPerson extends StatelessWidget {
  const _PodiumPerson({
    required this.entry,
    required this.asset,
    this.isWinner = false,
  });

  final PostRankingEntry entry;
  final String asset;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              asset,
              width: isWinner ? 86 : 72,
              height: isWinner ? 94 : 82,
              fit: BoxFit.contain,
            ),
            _Avatar(assetPath: entry.avatarAsset, size: isWinner ? 42 : 34),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _postText(context).copyWith(
            color: CupertinoColors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: isWinner ? 78 : 62,
          height: isWinner ? 74 : 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isWinner
                  ? const [Color(0xFFFFF060), Color(0xFFF0B400)]
                  : const [Color(0xFFFFCDB8), Color(0xFFEFA06F)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '${entry.checkInDays}',
              style: _postText(context).copyWith(
                color: CupertinoColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.entries});

  final List<PostRankingEntry> entries;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        physics: const BouncingScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (context, index) {
          return SizedBox(
            height: 18,
            child: Center(
              child: ColoredBox(
                color: CupertinoColors.white.withValues(alpha: 0.08),
                child: const SizedBox(height: 1, width: double.infinity),
              ),
            ),
          );
        },
        itemBuilder: (context, index) {
          final entry = entries[index];

          return Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  entry.rank.toString().padLeft(2, '0'),
                  style: _postText(context).copyWith(
                    color: CupertinoColors.white.withValues(alpha: 0.48),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Avatar(assetPath: entry.avatarAsset, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _postText(context).copyWith(
                    color: CupertinoColors.white.withValues(alpha: 0.64),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${entry.checkInDays}',
                style: _postText(context).copyWith(
                  color: CupertinoColors.white.withValues(alpha: 0.52),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PostCommentRow extends StatelessWidget {
  const _PostCommentRow({required this.comment});

  final PostSharingComment comment;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(assetPath: comment.avatarAsset, size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      comment.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _postText(context).copyWith(
                        color: CupertinoColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    comment.createdAtLabel,
                    style: _postText(context).copyWith(
                      color: CupertinoColors.white.withValues(alpha: 0.48),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.ellipsis_vertical,
                    color: CupertinoColors.white.withValues(alpha: 0.72),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                comment.body,
                style: _postText(context).copyWith(
                  color: CupertinoColors.white.withValues(alpha: 0.84),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostCommentComposer extends StatelessWidget {
  const _PostCommentComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _postPanelSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: controller,
                placeholder: 'Please enter...',
                padding: const EdgeInsets.only(left: 18, right: 10),
                style: _postText(context).copyWith(
                  color: CupertinoColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                placeholderStyle: _postText(context).copyWith(
                  color: CupertinoColors.white.withValues(alpha: 0.42),
                  fontSize: 13,
                ),
                decoration: const BoxDecoration(),
                cursorColor: CupertinoColors.white,
              ),
            ),
            CupertinoButton(
              minimumSize: Size.zero,
              padding: const EdgeInsets.only(right: 6),
              onPressed: onSend,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: CupertinoColors.white,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 40,
                  child: Center(
                    child: Image.asset(
                      'assets/images/Singles.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.black.withValues(alpha: 0.22),
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: 40,
          child: Icon(icon, color: CupertinoColors.white, size: 21),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.assetPath, required this.size});

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

TextStyle _postText(BuildContext context) {
  return CupertinoTheme.of(context).textTheme.textStyle.copyWith(
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );
}

String _countLabel(int value) {
  if (value >= 1000) {
    return '999+';
  }

  return '$value';
}
