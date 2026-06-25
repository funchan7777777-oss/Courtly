import 'dart:async';
import 'dart:io';

import 'package:courtly/features/club_chats/presentation/club_chats_view.dart';
import 'package:courtly/features/court_reels/data/court_reel_seed.dart';
import 'package:courtly/features/post_sharing/data/post_sharing_seed.dart';
import 'package:courtly/features/post_sharing/domain/post_sharing_post.dart';
import 'package:courtly/shared/data/courtly_media_assets.dart';
import 'package:courtly/shared/presentation/courtly_safe_layout.dart';
import 'package:courtly/shared/social/courtly_moderation.dart';
import 'package:courtly/shared/social/courtly_social_store.dart';
import 'package:courtly/shared/social/courtly_user_directory.dart';
import 'package:courtly/shared/social/courtly_user_profile.dart';
import 'package:courtly/shared/social/courtly_user_profile_page.dart';
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
  Set<String> _reportedContentIds = {};
  Set<String> _blockedUserIds = {};

  @override
  void initState() {
    super.initState();
    CourtlySocialStore.relationshipVersion.addListener(
      _handleRelationshipChanged,
    );
    unawaited(_loadModerationState());
    unawaited(_loadRelationshipState());
  }

  @override
  void dispose() {
    CourtlySocialStore.relationshipVersion.removeListener(
      _handleRelationshipChanged,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visiblePosts = _visiblePosts;

    return CupertinoPageScaffold(
      child: _PostBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  22,
                  courtlySafeTop(context, 8),
                  22,
                  0,
                ),
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
            SliverToBoxAdapter(
              child: _ActivePlayersStrip(onOpenProfile: _openUserProfile),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            if (visiblePosts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _PostEmptyState(),
              )
            else
              SliverList.separated(
                itemCount: visiblePosts.length,
                itemBuilder: (context, index) {
                  final post = visiblePosts[index];

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      index == 0 ? 0 : 4,
                      22,
                      index == visiblePosts.length - 1 ? 120 : 0,
                    ),
                    child: _PostCard(
                      post: post,
                      onOpenDetail: () => _openDetail(post),
                      onOpenProfile: () => _openProfile(post),
                      onToggleLike: () => _toggleLike(post.id),
                      onToggleFollow: () {
                        unawaited(_toggleFollow(post.id));
                      },
                      onMore: () => _showPostActions(post),
                    ),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 18),
              ),
          ],
        ),
      ),
    );
  }

  List<PostSharingPost> get _visiblePosts {
    return _posts
        .where(
          (post) =>
              !_hiddenUserIds.contains(post.authorId) &&
              !_reportedContentIds.contains('post:${post.id}'),
        )
        .toList(growable: false);
  }

  Set<String> get _hiddenUserIds {
    return _hiddenUserIdsFor(_reportedContentIds, _blockedUserIds);
  }

  Future<void> _loadModerationState() async {
    final store = CourtlySocialStore.instance;
    final reported = await store.reportedContentIds();
    final blocked = await store.blockedUserIds();
    if (!mounted) {
      return;
    }
    final hiddenUsers = _hiddenUserIdsFor(reported, blocked);
    setState(() {
      _reportedContentIds = reported;
      _blockedUserIds = blocked;
      _posts = _posts
          .map(
            (post) => post.copyWith(
              comments: post.comments
                  .where(
                    (comment) =>
                        !reported.contains('post-comment:${comment.id}') &&
                        !hiddenUsers.contains(comment.authorId),
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false);
    });
  }

  Future<void> _loadRelationshipState() async {
    final store = CourtlySocialStore.instance;
    final nextPosts = <PostSharingPost>[];
    for (final post in _posts) {
      final requested = await store.hasRequestedFollow(post.authorId);
      final following = await store.isFollowing(post.authorId);
      nextPosts.add(post.copyWith(isFollowed: requested || following));
    }
    if (!mounted) {
      return;
    }
    setState(() => _posts = nextPosts);
  }

  void _handleRelationshipChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_loadRelationshipState());
  }

  Future<void> _openComposer() async {
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(builder: (_) => const PostComposerPage()),
    );
  }

  Future<void> _openDetail(PostSharingPost post) async {
    final updated = await Navigator.of(context).push<PostSharingPost>(
      CupertinoPageRoute<PostSharingPost>(
        builder: (_) => PostDetailPage(
          post: post,
          onOpenProfile: _openUserProfile,
          onModerated: _handleModerationResult,
          onCompose: () {
            unawaited(_openComposer());
          },
        ),
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    _replacePostsByUser(
      updated.authorId,
      (post) => post.id == updated.id
          ? updated
          : post.copyWith(isFollowed: updated.isFollowed),
    );
  }

  Future<void> _openProfile(PostSharingPost post) async {
    await _openUserProfile(
      CourtlyUserDirectory.fromIdentity(
        id: post.authorId,
        name: post.authorName,
        avatarAsset: post.avatarAsset,
        heroAsset: post.imageAsset,
      ),
    );
  }

  Future<void> _openUserProfile(CourtlyUserProfile profile) async {
    await Navigator.of(context).push<CourtlyModerationResult>(
      CupertinoPageRoute<CourtlyModerationResult>(
        builder: (_) => CourtlyUserProfilePage(
          profile: profile,
          videos: _profileVideosFor(profile.id),
          posts: _profilePostsFor(profile.id),
          onOpenChat: (profile) {
            unawaited(openClubChatForProfile(context, profile));
          },
          onModerated: (result) {
            unawaited(_loadModerationState());
          },
          onRelationshipChanged: () {
            unawaited(_loadRelationshipState());
          },
        ),
      ),
    );
    if (mounted) {
      await _loadModerationState();
      unawaited(_loadRelationshipState());
    }
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

  Future<void> _toggleFollow(String postId) async {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index == -1) {
      return;
    }

    final post = _posts[index];
    if (post.isFollowed) {
      return;
    }

    await CourtlySocialStore.instance.requestFollow(post.authorId);
    if (!mounted) {
      return;
    }
    _replacePostsByUser(
      post.authorId,
      (entry) => entry.copyWith(isFollowed: true),
    );
  }

  Future<void> _showPostActions(PostSharingPost post) async {
    final result = await showCourtlyModerationSheet(
      context: context,
      targetId: 'post:${post.id}',
      targetType: 'post',
      title: post.authorName,
      userId: post.authorId,
      summary: post.body,
    );

    if (!mounted || result == null) {
      return;
    }

    await _handleModerationResult(result);
  }

  Future<void> _handleModerationResult(CourtlyModerationResult result) async {
    await _loadModerationState();
    if (!mounted) {
      return;
    }
    if (result.action == CourtlyModerationAction.block) {
      await showCourtlyActionSuccess(
        context: context,
        title: 'User blocked',
        message:
            'That player and their posts, comments, and chats will stay hidden.',
      );
      return;
    }

    await showCourtlyActionSuccess(
      context: context,
      title: 'Report sent',
      message: 'The report was saved locally and this item is now hidden.',
    );
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

  void _replacePostsByUser(
    String userId,
    PostSharingPost Function(PostSharingPost post) update,
  ) {
    setState(() {
      _posts = _posts
          .map((post) => post.authorId == userId ? update(post) : post)
          .toList(growable: false);
    });
  }

  List<CourtlyProfileVideoItem> _profileVideosFor(String userId) {
    return CourtReelSeed.openingFeed
        .where(
          (reel) =>
              reel.userId == userId &&
              !_hiddenUserIds.contains(reel.userId) &&
              !_reportedContentIds.contains('reel:${reel.id}'),
        )
        .map(
          (reel) => CourtlyProfileVideoItem(
            id: reel.id,
            thumbnailAsset: reel.backdropAsset,
          ),
        )
        .toList(growable: false);
  }

  List<CourtlyProfilePostItem> _profilePostsFor(String userId) {
    return _posts
        .where(
          (post) =>
              post.authorId == userId &&
              !_hiddenUserIds.contains(post.authorId) &&
              !_reportedContentIds.contains('post:${post.id}'),
        )
        .map(
          (post) => CourtlyProfilePostItem(
            id: post.id,
            imageAsset: post.imageAsset,
            body: post.body,
          ),
        )
        .toList(growable: false);
  }

  Set<String> _hiddenUserIdsFor(Set<String> reported, Set<String> blocked) {
    return {
      ...blocked,
      for (final contentId in reported)
        if (contentId.startsWith('user:')) contentId.substring(5),
    };
  }
}

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

class _PostEmptyState extends StatelessWidget {
  const _PostEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/Love.png',
        width: 190,
        height: 190,
        fit: BoxFit.contain,
      ),
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
            imageAsset: 'assets/images/clock.png',
            onPressed: onCheckIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ShortcutCard(
            title: 'Ranking\nlist',
            imageAsset: 'assets/images/Rankinglist.png',
            onPressed: onRanking,
          ),
        ),
      ],
    );
  }
}

class _ActivePlayersStrip extends StatelessWidget {
  const _ActivePlayersStrip({required this.onOpenProfile});

  final ValueChanged<CourtlyUserProfile> onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: CourtlyMediaAssets.allHeads.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final profile =
              CourtlyUserDirectory.featuredProfiles(
                CourtlyMediaAssets.allHeads.length,
              )[index %
                  CourtlyUserDirectory.featuredProfiles(
                    CourtlyMediaAssets.allHeads.length,
                  ).length];

          return CupertinoButton(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            onPressed: () => onOpenProfile(profile),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: index.isEven ? _postPink : CupertinoColors.white,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: _Avatar(assetPath: profile.avatarAsset, size: 52),
              ),
            ),
          );
        },
      ),
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
      child: SizedBox(
        height: 78,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            semanticLabel: title,
          ),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpenDetail,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _postPanel.withValues(alpha: 0.98),
              const Color(0xFF21005A).withValues(alpha: 0.98),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.08),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 18,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CupertinoButton(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    onPressed: onOpenProfile,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CupertinoColors.white.withValues(alpha: 0.18),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: _Avatar(assetPath: post.avatarAsset, size: 44),
                      ),
                    ),
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
                              fontSize: 16,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            post.createdAtLabel,
                            style: _postText(context).copyWith(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.56,
                              ),
                              fontSize: 11,
                              height: 1,
                              fontWeight: FontWeight.w800,
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
                  const SizedBox(width: 8),
                  _PostMoreButton(onPressed: onMore),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                post.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: _postText(context).copyWith(
                  color: CupertinoColors.white.withValues(alpha: 0.88),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                onPressed: onOpenDetail,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1.24,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _PostImage(
                          imagePath: post.imageAsset,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                CupertinoColors.black.withValues(alpha: 0.02),
                                CupertinoColors.black.withValues(alpha: 0.2),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _PostMetricButton(
                    iconAsset: post.isLiked
                        ? 'assets/images/Locker.png'
                        : 'assets/images/Hei.png',
                    label: _countLabel(post.likes),
                    onPressed: onToggleLike,
                  ),
                  const SizedBox(width: 10),
                  _PostMetricButton(
                    iconData: CupertinoIcons.chat_bubble_fill,
                    label: _countLabel(post.comments.length),
                    onPressed: onOpenDetail,
                  ),
                  const Spacer(),
                  _PostDetailButton(onPressed: onOpenDetail),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostMoreButton extends StatelessWidget {
  const _PostMoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: CupertinoColors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Icon(
          CupertinoIcons.ellipsis,
          color: CupertinoColors.white.withValues(alpha: 0.86),
          size: 21,
        ),
      ),
    );
  }
}

class _PostDetailButton extends StatelessWidget {
  const _PostDetailButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: CupertinoColors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.chevron_right,
          color: _postPanel,
          size: 21,
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
      child: Container(
        height: 34,
        padding: EdgeInsets.symmetric(horizontal: label == null ? 8 : 10),
        decoration: BoxDecoration(
          color: CupertinoColors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconAsset != null)
              Image.asset(
                iconAsset!,
                width: 21,
                height: 21,
                fit: BoxFit.contain,
              )
            else
              Icon(iconData, color: CupertinoColors.white, size: 19),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: _postText(context).copyWith(
                  color: CupertinoColors.white,
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
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
    required this.onOpenProfile,
    required this.onModerated,
    super.key,
  });

  final PostSharingPost post;
  final VoidCallback onCompose;
  final ValueChanged<CourtlyUserProfile> onOpenProfile;
  final ValueChanged<CourtlyModerationResult> onModerated;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late PostSharingPost _post = widget.post;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    CourtlySocialStore.relationshipVersion.addListener(
      _handleRelationshipChanged,
    );
    unawaited(_syncRelationshipState());
  }

  @override
  void dispose() {
    CourtlySocialStore.relationshipVersion.removeListener(
      _handleRelationshipChanged,
    );
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
          _PostImage(
            imagePath: _post.imageAsset,
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
            top: courtlySafeTop(context, 8),
            left: 12,
            child: _RoundIconButton(
              icon: CupertinoIcons.chevron_left,
              onPressed: () => Navigator.of(context).pop(_post),
            ),
          ),
          Positioned(
            top: courtlySafeTop(context, 10),
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
            child: _DetailAuthorBlock(
              post: _post,
              onFollow: () {
                unawaited(_toggleFollow());
              },
              onOpenProfile: _openAuthorProfile,
            ),
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
              onOpenProfile: _openCommentProfile,
              onReportComment: _reportComment,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFollow() async {
    if (_post.isFollowed) {
      return;
    }

    await CourtlySocialStore.instance.requestFollow(_post.authorId);
    if (!mounted) {
      return;
    }
    setState(() => _post = _post.copyWith(isFollowed: true));
  }

  void _handleRelationshipChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_syncRelationshipState());
  }

  Future<void> _syncRelationshipState() async {
    final store = CourtlySocialStore.instance;
    final requested = await store.hasRequestedFollow(_post.authorId);
    final following = await store.isFollowing(_post.authorId);
    if (!mounted) {
      return;
    }
    setState(() {
      _post = _post.copyWith(isFollowed: requested || following);
    });
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
            id: 'local-post-comment-${DateTime.now().microsecondsSinceEpoch}',
            authorId: 'you',
            authorName: 'You',
            createdAtLabel: 'now',
            body: body,
            avatarAsset: CourtlyMediaAssets.womenHeads.first,
          ),
        ],
      );
      _commentController.clear();
    });
  }

  void _openAuthorProfile() {
    widget.onOpenProfile(
      CourtlyUserDirectory.fromIdentity(
        id: _post.authorId,
        name: _post.authorName,
        avatarAsset: _post.avatarAsset,
        heroAsset: _post.imageAsset,
      ),
    );
  }

  void _openCommentProfile(PostSharingComment comment) {
    widget.onOpenProfile(
      CourtlyUserDirectory.fromIdentity(
        id: comment.authorId,
        name: comment.authorName,
        avatarAsset: comment.avatarAsset,
      ),
    );
  }

  Future<void> _reportComment(PostSharingComment comment) async {
    final result = await showCourtlyModerationSheet(
      context: context,
      targetId: 'post-comment:${comment.id}',
      targetType: 'comment',
      title: comment.authorName,
      userId: comment.authorId,
      summary: comment.body,
    );
    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _post = _post.copyWith(
        comments: _post.comments
            .where((entry) => entry.id != comment.id)
            .toList(growable: false),
      );
    });
    widget.onModerated(result);
  }
}

class _DetailAuthorBlock extends StatelessWidget {
  const _DetailAuthorBlock({
    required this.post,
    required this.onFollow,
    required this.onOpenProfile,
  });

  final PostSharingPost post;
  final VoidCallback onFollow;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: CupertinoButton(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                onPressed: onOpenProfile,
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
    required this.onOpenProfile,
    required this.onReportComment,
  });

  final PostSharingPost post;
  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<PostSharingComment> onOpenProfile;
  final ValueChanged<PostSharingComment> onReportComment;

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
                final comment = post.comments[index];
                return _PostCommentRow(
                  comment: comment,
                  onOpenProfile: () => onOpenProfile(comment),
                  onReport: () => onReportComment(comment),
                );
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
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(28, 108, 28, 48 + keyboardInset),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Share a court moment',
                      textAlign: TextAlign.center,
                      style: _postText(context).copyWith(
                        color: CupertinoColors.white,
                        fontSize: 24,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Photo, match note, and the point worth remembering.',
                      textAlign: TextAlign.center,
                      style: _postText(context).copyWith(
                        color: CupertinoColors.white.withValues(alpha: 0.58),
                        fontSize: 12,
                        height: 1.28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _ComposerImageCard(
                      imagePath: _imagePath,
                      isPickingImage: _isPickingImage,
                      onPressed: _pickImage,
                    ),
                    const SizedBox(height: 24),
                    _ComposerBodyField(controller: _bodyController),
                    const SizedBox(height: 18),
                    _ComposerReleaseButton(onPressed: _releasePost),
                  ],
                ),
              ),
            ),
            Positioned(
              top: courtlySafeTop(context, 8),
              left: 12,
              child: _RoundIconButton(
                icon: CupertinoIcons.chevron_left,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: courtlySafeTop(context, 20),
              left: 74,
              right: 74,
              child: Text(
                'Create post',
                textAlign: TextAlign.center,
                style: _postText(context).copyWith(
                  color: CupertinoColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await _chooseImageSource();
    if (source == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() => _isPickingImage = true);
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1800,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (image != null && mounted) {
        setState(() => _imagePath = image.path);
      }
    } catch (_) {
      if (mounted) {
        await _showDraftNotice(
          title: 'Upload unavailable',
          message: 'Please check camera or photo access, then try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<ImageSource?> _chooseImageSource() {
    return showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Add court photo'),
          message: const Text(
            'Take a new photo or choose one from your album.',
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              child: const Text('Take photo'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              child: const Text('Choose from album'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  Future<void> _releasePost() async {
    final body = _bodyController.text.trim();
    if (_imagePath == null) {
      await _showDraftNotice(
        title: 'Add a court photo',
        message: 'Pick one image from your album or take a fresh court shot.',
      );
      return;
    }

    if (body.isEmpty) {
      await _showDraftNotice(
        title: 'Write a caption',
        message: 'Add a short note so the moment has context.',
      );
      return;
    }

    if (!mounted) {
      return;
    }
    await showCourtlyReviewDialog(context, contentLabel: 'photo post');
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
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
    final selectedImagePath = imagePath;

    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 246,
        decoration: BoxDecoration(
          color: _postPanelSoft.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.12),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (selectedImagePath != null)
                Image.file(
                  File(selectedImagePath),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6F3BA8).withValues(alpha: 0.72),
                        const Color(0xFF2B0067).withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
              if (selectedImagePath != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        CupertinoColors.black.withValues(alpha: 0.04),
                        CupertinoColors.black.withValues(alpha: 0.38),
                      ],
                    ),
                  ),
                ),
              if (isPickingImage)
                const Center(
                  child: CupertinoActivityIndicator(
                    color: CupertinoColors.white,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: CupertinoColors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(
                          dimension: 54,
                          child: Icon(
                            selectedImagePath == null
                                ? CupertinoIcons.camera_fill
                                : CupertinoIcons.photo_fill_on_rectangle_fill,
                            color: CupertinoColors.white,
                            size: 27,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        selectedImagePath == null
                            ? 'Add your court shot'
                            : 'Change photo',
                        style: _postText(context).copyWith(
                          color: CupertinoColors.white,
                          fontSize: 20,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedImagePath == null
                            ? 'Camera or album'
                            : 'Tap to replace it',
                        style: _postText(context).copyWith(
                          color: CupertinoColors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: const [
                          _ComposerSourcePill(
                            icon: CupertinoIcons.camera,
                            label: 'Camera',
                          ),
                          SizedBox(width: 8),
                          _ComposerSourcePill(
                            icon: CupertinoIcons.photo_on_rectangle,
                            label: 'Album',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerSourcePill extends StatelessWidget {
  const _ComposerSourcePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: CupertinoColors.white, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: _postText(context).copyWith(
                color: CupertinoColors.white,
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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
        color: _postPanelSoft.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.12),
        ),
      ),
      child: SizedBox(
        height: 156,
        child: CupertinoTextField(
          controller: controller,
          maxLines: null,
          expands: true,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          placeholder: 'Write the rally, score, or feeling behind this moment.',
          placeholderStyle: _postText(context).copyWith(
            color: CupertinoColors.white.withValues(alpha: 0.42),
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w800,
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

class _ComposerReleaseButton extends StatelessWidget {
  const _ComposerReleaseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: _postPink,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66FF2DD2),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.paperplane_fill,
              color: CupertinoColors.white,
              size: 19,
            ),
            const SizedBox(width: 9),
            Text(
              'Publish post',
              style: _postText(context).copyWith(
                color: CupertinoColors.white,
                fontSize: 17,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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
  void initState() {
    super.initState();
    CourtlySocialStore.relationshipVersion.addListener(
      _handleRelationshipChanged,
    );
    unawaited(_syncRelationshipState());
  }

  @override
  void dispose() {
    CourtlySocialStore.relationshipVersion.removeListener(
      _handleRelationshipChanged,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _PostImage(
            imagePath: _post.imageAsset,
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
            top: courtlySafeTop(context, 8),
            left: 12,
            child: _RoundIconButton(
              icon: CupertinoIcons.chevron_left,
              onPressed: () => Navigator.of(context).pop(_post),
            ),
          ),
          Positioned(
            top: courtlySafeTop(context, 18),
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
                _DetailAuthorBlock(
                  post: _post,
                  onFollow: () {
                    unawaited(_toggleFollow());
                  },
                  onOpenProfile: () {},
                ),
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

  Future<void> _toggleFollow() async {
    if (_post.isFollowed) {
      return;
    }

    await CourtlySocialStore.instance.requestFollow(_post.authorId);
    if (!mounted) {
      return;
    }
    setState(() => _post = _post.copyWith(isFollowed: true));
  }

  void _handleRelationshipChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_syncRelationshipState());
  }

  Future<void> _syncRelationshipState() async {
    final store = CourtlySocialStore.instance;
    final requested = await store.hasRequestedFollow(_post.authorId);
    final following = await store.isFollowing(_post.authorId);
    if (!mounted) {
      return;
    }
    setState(() {
      _post = _post.copyWith(isFollowed: requested || following);
    });
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
              _PostImage(
                imagePath: videoAssets[index],
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
              top: courtlySafeTop(context, 8),
              left: 12,
              child: _RoundIconButton(
                icon: CupertinoIcons.chevron_left,
                onPressed: () => Navigator.of(context).pop(_checkedToday),
              ),
            ),
            Positioned(
              top: courtlySafeTop(context, 20),
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
              top: courtlySafeTop(context, 68),
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
            top: courtlySafeTop(context, 8),
            left: 12,
            child: _RoundIconButton(
              icon: CupertinoIcons.chevron_left,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: courtlySafeTop(context, 68),
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
            top: courtlySafeTop(context, 158),
            child: _RankingPodium(entries: entries.take(3).toList()),
          ),
          Positioned(
            left: 22,
            right: 22,
            top: courtlySafeTop(context, 350),
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
            CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              onPressed: () => _openRankingProfile(context, entry),
              child: Image.asset(
                asset,
                width: isWinner ? 86 : 72,
                height: isWinner ? 94 : 82,
                fit: BoxFit.contain,
              ),
            ),
            CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              onPressed: () => _openRankingProfile(context, entry),
              child: _Avatar(
                assetPath: entry.avatarAsset,
                size: isWinner ? 42 : 34,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        CupertinoButton(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          onPressed: () => _openRankingProfile(context, entry),
          child: Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _postText(context).copyWith(
              color: CupertinoColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
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
              CupertinoButton(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                onPressed: () => _openRankingProfile(context, entry),
                child: _Avatar(assetPath: entry.avatarAsset, size: 30),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CupertinoButton(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  onPressed: () => _openRankingProfile(context, entry),
                  child: Align(
                    alignment: Alignment.centerLeft,
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

void _openRankingProfile(BuildContext context, PostRankingEntry entry) {
  final profile = CourtlyUserDirectory.fromIdentity(
    name: entry.name,
    avatarAsset: entry.avatarAsset,
  );
  Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => CourtlyUserProfilePage(
        profile: profile,
        videos: _profileSeedVideosFor(profile.id),
        posts: _profileSeedPostsFor(profile.id),
        onOpenChat: (profile) {
          unawaited(openClubChatForProfile(context, profile));
        },
      ),
    ),
  );
}

List<CourtlyProfileVideoItem> _profileSeedVideosFor(String userId) {
  return CourtReelSeed.openingFeed
      .where((reel) => reel.userId == userId)
      .map(
        (reel) => CourtlyProfileVideoItem(
          id: reel.id,
          thumbnailAsset: reel.backdropAsset,
        ),
      )
      .toList(growable: false);
}

List<CourtlyProfilePostItem> _profileSeedPostsFor(String userId) {
  return PostSharingSeed.openingPosts
      .where((post) => post.authorId == userId)
      .map(
        (post) => CourtlyProfilePostItem(
          id: post.id,
          imageAsset: post.imageAsset,
          body: post.body,
        ),
      )
      .toList(growable: false);
}

class _PostCommentRow extends StatelessWidget {
  const _PostCommentRow({
    required this.comment,
    required this.onOpenProfile,
    required this.onReport,
  });

  final PostSharingComment comment;
  final VoidCallback onOpenProfile;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoButton(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          onPressed: onOpenProfile,
          child: _Avatar(assetPath: comment.avatarAsset, size: 32),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      onPressed: onOpenProfile,
                      child: Align(
                        alignment: Alignment.centerLeft,
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
                  CupertinoButton(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    onPressed: onReport,
                    child: Icon(
                      CupertinoIcons.ellipsis_vertical,
                      color: CupertinoColors.white.withValues(alpha: 0.72),
                      size: 16,
                    ),
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

class _PostImage extends StatelessWidget {
  const _PostImage({
    required this.imagePath,
    required this.fit,
    required this.alignment,
  });

  final String imagePath;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(imagePath, fit: fit, alignment: alignment);
    }

    return Image.file(File(imagePath), fit: fit, alignment: alignment);
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
