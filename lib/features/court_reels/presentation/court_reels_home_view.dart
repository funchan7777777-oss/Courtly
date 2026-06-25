import 'dart:async';
import 'dart:io';

import 'package:courtly/features/club_chats/presentation/club_chats_view.dart';
import 'package:courtly/features/court_reels/data/court_reel_seed.dart';
import 'package:courtly/features/court_reels/domain/court_reel.dart';
import 'package:courtly/features/post_sharing/data/post_sharing_seed.dart';
import 'package:courtly/shared/data/courtly_media_assets.dart';
import 'package:courtly/shared/presentation/courtly_safe_layout.dart';
import 'package:courtly/shared/social/courtly_moderation.dart';
import 'package:courtly/shared/social/courtly_social_store.dart';
import 'package:courtly/shared/social/courtly_user_directory.dart';
import 'package:courtly/shared/social/courtly_user_profile.dart';
import 'package:courtly/shared/social/courtly_user_profile_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class CourtReelsHomeView extends StatefulWidget {
  const CourtReelsHomeView({super.key});

  @override
  State<CourtReelsHomeView> createState() => _CourtReelsHomeViewState();
}

class _CourtReelsHomeViewState extends State<CourtReelsHomeView> {
  final PageController _pageController = PageController();
  List<CourtReel> _reels = List<CourtReel>.of(CourtReelSeed.openingFeed);
  int _currentIndex = 0;
  bool _soundOn = true;
  bool _isPlaying = true;
  Set<String> _reportedContentIds = {};
  Set<String> _blockedUserIds = {};

  @override
  void initState() {
    super.initState();
    CourtlySocialStore.instance.relationshipVersion.addListener(
      _handleRelationshipChanged,
    );
    unawaited(_loadModerationState());
    unawaited(_loadRelationshipState());
  }

  @override
  void dispose() {
    CourtlySocialStore.instance.relationshipVersion.removeListener(
      _handleRelationshipChanged,
    );
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleReels = _visibleReels;

    return CupertinoPageScaffold(
      child: visibleReels.isEmpty
          ? _EmptyReelsView(
              onPublish: () {
                unawaited(_openComposer());
              },
            )
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: visibleReels.length,
              onPageChanged: (index) => setState(() {
                _currentIndex = index;
                _isPlaying = true;
              }),
              itemBuilder: (context, index) {
                final reel = visibleReels[index];

                return CourtReelStage(
                  reel: reel,
                  soundOn: _soundOn,
                  isActive: index == _currentIndex,
                  isPlaying: _isPlaying,
                  onSoundToggle: () => setState(() => _soundOn = !_soundOn),
                  onVideoToggle: () {
                    setState(() => _isPlaying = !_isPlaying);
                  },
                  onPublish: () {
                    unawaited(_openComposer());
                  },
                  onLike: () => _toggleLike(reel.id),
                  onFollow: () {
                    unawaited(_toggleFollow(reel.id));
                  },
                  onOpenProfile: () => _openProfile(reel),
                  onComment: () {
                    unawaited(_openComments(reel));
                  },
                  onModerate: () {
                    unawaited(_openModeration(reel));
                  },
                );
              },
            ),
    );
  }

  List<CourtReel> get _visibleReels {
    return _reels
        .where(
          (reel) =>
              !_hiddenUserIds.contains(reel.userId) &&
              !_reportedContentIds.contains('reel:${reel.id}'),
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
      _reels = _reels
          .map(
            (reel) => reel.copyWith(
              comments: reel.comments
                  .where(
                    (comment) =>
                        !reported.contains('reel-comment:${comment.id}') &&
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
    final nextReels = <CourtReel>[];
    for (final reel in _reels) {
      final requested = await store.hasRequestedFollow(reel.userId);
      final following = await store.isFollowing(reel.userId);
      nextReels.add(reel.copyWith(isFollowed: requested || following));
    }
    if (!mounted) {
      return;
    }
    setState(() => _reels = nextReels);
  }

  void _handleRelationshipChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_loadRelationshipState());
  }

  void _toggleLike(String reelId) {
    final index = _reels.indexWhere((reel) => reel.id == reelId);
    if (index == -1) {
      return;
    }

    final reel = _reels[index];
    final nextLiked = !reel.isLiked;
    final nextLikes = (reel.likes + (nextLiked ? 1 : -1))
        .clamp(0, 999999)
        .toInt();
    _replaceReelAt(index, reel.copyWith(isLiked: nextLiked, likes: nextLikes));
  }

  Future<void> _toggleFollow(String reelId) async {
    final index = _reels.indexWhere((reel) => reel.id == reelId);
    if (index == -1) {
      return;
    }

    final reel = _reels[index];
    if (reel.isFollowed) {
      return;
    }

    await CourtlySocialStore.instance.requestFollow(reel.userId);
    if (!mounted) {
      return;
    }
    _replaceReelsByUser(
      reel.userId,
      (entry) => entry.copyWith(isFollowed: true),
    );
  }

  Future<void> _openComposer() async {
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(builder: (_) => const CourtReelReleasePage()),
    );
  }

  Future<void> _openComments(CourtReel reel) async {
    await showCupertinoModalPopup<void>(
      context: context,
      barrierColor: CupertinoColors.black.withValues(alpha: 0.48),
      builder: (_) => CourtReelCommentsSheet(
        reel: reel,
        onOpenProfile: _openCommentProfile,
        onModerated: (result) {
          unawaited(_handleModerationResult(result));
        },
        onCommentsChanged: (comments) {
          if (!mounted) {
            return;
          }
          final index = _reels.indexWhere((entry) => entry.id == reel.id);
          if (index == -1) {
            return;
          }
          _replaceReelAt(index, _reels[index].copyWith(comments: comments));
        },
      ),
    );
  }

  Future<void> _openModeration(CourtReel reel) async {
    final result = await showCourtlyModerationSheet(
      context: context,
      targetId: 'reel:${reel.id}',
      targetType: 'reel',
      title: reel.playerName,
      userId: reel.userId,
      summary: reel.caption,
    );

    if (result == null || !mounted) {
      return;
    }

    await _handleModerationResult(result);
  }

  Future<void> _handleModerationResult(CourtlyModerationResult result) async {
    await _loadModerationState();
    if (!mounted) {
      return;
    }

    final visibleCount = _visibleReels.length;
    if (_currentIndex >= visibleCount) {
      _currentIndex = (visibleCount - 1).clamp(0, 999).toInt();
      if (_pageController.hasClients && visibleCount > 0) {
        _pageController.jumpToPage(_currentIndex);
      }
    }

    if (result.action == CourtlyModerationAction.block) {
      await showCourtlyActionSuccess(
        context: context,
        title: 'User blocked',
        message:
            'That player and their reels, comments, and chats will stay hidden.',
      );
      return;
    }

    await showCourtlyActionSuccess(
      context: context,
      title: 'Report sent',
      message: 'The report was saved locally and this item is now hidden.',
    );
  }

  void _openProfile(CourtReel reel) {
    unawaited(
      _openUserProfile(
        CourtlyUserDirectory.fromIdentity(
          id: reel.userId,
          name: reel.playerName,
          ageLabel: reel.ageLabel,
          genderLabel: reel.gender == CourtReelGender.female
              ? 'Female'
              : 'Male',
          avatarAsset: reel.avatarAsset,
          heroAsset: reel.backdropAsset,
        ),
      ),
    );
  }

  void _openCommentProfile(CourtReelComment comment) {
    unawaited(
      _openUserProfile(
        CourtlyUserDirectory.fromIdentity(
          id: comment.authorId,
          name: comment.author,
          avatarAsset: comment.avatarAsset,
        ),
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
    if (!mounted) {
      return;
    }
    await _loadModerationState();
    _settleVisibleReelIndex();
    unawaited(_loadRelationshipState());
  }

  void _settleVisibleReelIndex() {
    final visibleCount = _visibleReels.length;
    if (_currentIndex < visibleCount) {
      return;
    }
    setState(() {
      _currentIndex = (visibleCount - 1).clamp(0, 999).toInt();
    });
    if (_pageController.hasClients && visibleCount > 0) {
      _pageController.jumpToPage(_currentIndex);
    }
  }

  void _replaceReelAt(int index, CourtReel reel) {
    setState(() {
      final nextReels = List<CourtReel>.of(_reels);
      nextReels[index] = reel;
      _reels = nextReels;
    });
  }

  void _replaceReelsByUser(
    String userId,
    CourtReel Function(CourtReel reel) update,
  ) {
    setState(() {
      _reels = _reels
          .map((reel) => reel.userId == userId ? update(reel) : reel)
          .toList(growable: false);
    });
  }

  List<CourtlyProfileVideoItem> _profileVideosFor(String userId) {
    return _reels
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
    return PostSharingSeed.openingPosts
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

class CourtReelStage extends StatelessWidget {
  const CourtReelStage({
    required this.reel,
    required this.soundOn,
    required this.isActive,
    required this.isPlaying,
    required this.onSoundToggle,
    required this.onVideoToggle,
    required this.onPublish,
    required this.onLike,
    required this.onFollow,
    required this.onOpenProfile,
    required this.onComment,
    required this.onModerate,
    super.key,
  });

  final CourtReel reel;
  final bool soundOn;
  final bool isActive;
  final bool isPlaying;
  final VoidCallback onSoundToggle;
  final VoidCallback onVideoToggle;
  final VoidCallback onPublish;
  final VoidCallback onLike;
  final VoidCallback onFollow;
  final VoidCallback onOpenProfile;
  final VoidCallback onComment;
  final VoidCallback onModerate;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onVideoToggle,
          child: _ReelVideoBackdrop(
            videoPath: reel.videoAsset,
            fallbackAsset: reel.backdropAsset,
            soundOn: soundOn,
            isPlaying: isActive && isPlaying,
          ),
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x1A000000),
                  Color(0x00000000),
                  Color(0x4D000000),
                  Color(0xCC000000),
                ],
                stops: [0, 0.34, 0.64, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: courtlySafeTop(context, 8),
          left: 22,
          right: 20,
          child: _CourtReelsTopBar(onPublish: onPublish),
        ),
        Positioned(
          right: 18,
          top: height * 0.36,
          child: _ReelActionRail(
            reel: reel,
            soundOn: soundOn,
            onSoundToggle: onSoundToggle,
            onLike: onLike,
            onComment: onComment,
            onModerate: onModerate,
          ),
        ),
        if (isActive && !isPlaying)
          Center(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(
                  dimension: 78,
                  child: Icon(
                    CupertinoIcons.play_fill,
                    color: CupertinoColors.white,
                    size: 38,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: 22,
          right: 22,
          bottom: 104,
          child: _ReelCaptionBlock(
            reel: reel,
            onFollow: onFollow,
            onOpenProfile: onOpenProfile,
          ),
        ),
      ],
    );
  }
}

class _ReelVideoBackdrop extends StatefulWidget {
  const _ReelVideoBackdrop({
    required this.videoPath,
    required this.fallbackAsset,
    required this.soundOn,
    required this.isPlaying,
  });

  final String videoPath;
  final String fallbackAsset;
  final bool soundOn;
  final bool isPlaying;

  @override
  State<_ReelVideoBackdrop> createState() => _ReelVideoBackdropState();
}

class _ReelVideoBackdropState extends State<_ReelVideoBackdrop> {
  late VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = _makeController(widget.videoPath);
    unawaited(_prepare());
  }

  @override
  void didUpdateWidget(covariant _ReelVideoBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      unawaited(_controller.dispose());
      _ready = false;
      _controller = _makeController(widget.videoPath);
      unawaited(_prepare());
      return;
    }

    if (oldWidget.soundOn != widget.soundOn ||
        oldWidget.isPlaying != widget.isPlaying) {
      unawaited(_controller.setVolume(widget.soundOn ? 1 : 0));
      _syncPlayback();
    }
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          widget.fallbackAsset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        if (_ready)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
      ],
    );
  }

  VideoPlayerController _makeController(String path) {
    if (path.startsWith('assets/')) {
      return VideoPlayerController.asset(path);
    }

    return VideoPlayerController.file(File(path));
  }

  Future<void> _prepare() async {
    try {
      await _controller.initialize();
      if (!mounted) {
        return;
      }
      await _controller.setLooping(true);
      await _controller.setVolume(widget.soundOn ? 1 : 0);
      if (widget.isPlaying) {
        await _controller.play();
      }
      if (!mounted) {
        return;
      }
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _ready = false);
    }
  }

  void _syncPlayback() {
    if (!_controller.value.isInitialized) {
      return;
    }

    if (widget.isPlaying) {
      unawaited(_controller.play());
      return;
    }
    unawaited(_controller.pause());
  }
}

class _CourtReelsTopBar extends StatelessWidget {
  const _CourtReelsTopBar({required this.onPublish});

  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/Challenge.png',
          width: 168,
          height: 32,
          fit: BoxFit.contain,
        ),
        const Spacer(),
        CupertinoButton(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          onPressed: onPublish,
          child: Image.asset(
            'assets/images/Ranking.png',
            width: 52,
            height: 52,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

class _ReelActionRail extends StatelessWidget {
  const _ReelActionRail({
    required this.reel,
    required this.soundOn,
    required this.onSoundToggle,
    required this.onLike,
    required this.onComment,
    required this.onModerate,
  });

  final CourtReel reel;
  final bool soundOn;
  final VoidCallback onSoundToggle;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onModerate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RailIconButton(
          icon: soundOn
              ? CupertinoIcons.speaker_2_fill
              : CupertinoIcons.speaker_slash_fill,
          onPressed: onSoundToggle,
        ),
        const SizedBox(height: 18),
        _RailIconButton(
          icon: CupertinoIcons.exclamationmark_square_fill,
          onPressed: onModerate,
        ),
        const SizedBox(height: 18),
        _LikeRailButton(
          isLiked: reel.isLiked,
          label: _formatCount(reel.likes),
          onPressed: onLike,
        ),
        const SizedBox(height: 18),
        _RailIconButton(
          icon: CupertinoIcons.chat_bubble_text_fill,
          label: _formatCount(reel.comments.length),
          onPressed: onComment,
        ),
      ],
    );
  }

  String _formatCount(int value) {
    if (value >= 1000) {
      return '999+';
    }

    return '$value';
  }
}

class _RailIconButton extends StatelessWidget {
  const _RailIconButton({
    required this.icon,
    required this.onPressed,
    this.label,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _RailShell(
      label: label,
      onPressed: onPressed,
      child: Icon(icon, color: CupertinoColors.white, size: 28),
    );
  }
}

class _LikeRailButton extends StatelessWidget {
  const _LikeRailButton({
    required this.isLiked,
    required this.label,
    required this.onPressed,
  });

  final bool isLiked;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: 1,
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutBack,
            child: SizedBox.square(
              dimension: 50,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Image.asset(
                    isLiked
                        ? 'assets/images/Locker.png'
                        : 'assets/images/Hei.png',
                    key: ValueKey<bool>(isLiked),
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _AnimatedRailCount(label: label),
        ],
      ),
    );
  }
}

class _RailShell extends StatelessWidget {
  const _RailShell({required this.child, required this.onPressed, this.label});

  final Widget child;
  final String? label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(dimension: 48, child: Center(child: child)),
          if (label != null) ...[
            const SizedBox(height: 4),
            _AnimatedRailCount(label: label!),
          ],
        ],
      ),
    );
  }
}

class _AnimatedRailCount extends StatelessWidget {
  const _AnimatedRailCount({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 190),
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.36),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: Text(
        label,
        key: ValueKey<String>(label),
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
          color: CupertinoColors.white,
          fontSize: 12,
          height: 1,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _ReelCaptionBlock extends StatelessWidget {
  const _ReelCaptionBlock({
    required this.reel,
    required this.onFollow,
    required this.onOpenProfile,
  });

  final CourtReel reel;
  final VoidCallback onFollow;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _SignalPill(
                    color: reel.gender == CourtReelGender.female
                        ? const Color(0xFFFF70C8)
                        : const Color(0xFF8EC5FF),
                    label:
                        '${reel.gender == CourtReelGender.female ? '♀' : '♂'} ${reel.ageLabel}',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                onPressed: onOpenProfile,
                child: Text(
                  reel.playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle.copyWith(
                    color: CupertinoColors.white,
                    fontSize: 22,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                reel.createdAtLabel,
                style: textStyle.copyWith(
                  color: CupertinoColors.white.withValues(alpha: 0.62),
                  fontSize: 12,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                reel.caption,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textStyle.copyWith(
                  color: CupertinoColors.white.withValues(alpha: 0.82),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              onPressed: onOpenProfile,
              child: ClipOval(
                child: Image.asset(
                  reel.avatarAsset,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 10),
            CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              onPressed: onFollow,
              child: Image.asset(
                reel.isFollowed
                    ? 'assets/images/Chat.png'
                    : 'assets/images/Huddle.png',
                width: 97,
                height: 30,
                fit: BoxFit.fill,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            color: CupertinoColors.white,
            fontSize: 11,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class CourtReelReleasePage extends StatefulWidget {
  const CourtReelReleasePage({super.key});

  @override
  State<CourtReelReleasePage> createState() => _CourtReelReleasePageState();
}

class _CourtReelReleasePageState extends State<CourtReelReleasePage> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _moodController = TextEditingController();
  String? _videoPath;
  bool _isPickingVideo = false;

  @override
  void dispose() {
    _moodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle;

    return CupertinoPageScaffold(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/Arena.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF12002F).withValues(alpha: 0.9),
                  const Color(0xFF2A005F).withValues(alpha: 0.82),
                  const Color(0xFF090019).withValues(alpha: 0.94),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(26, 126, 26, 52 + keyboardInset),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _ReleaseUploadCard(
                    videoPath: _videoPath,
                    isPickingVideo: _isPickingVideo,
                    onPressed: _chooseVideoSource,
                  ),
                  const SizedBox(height: 22),
                  _ReleaseMoodField(controller: _moodController),
                  const SizedBox(height: 60),
                  CupertinoButton(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    onPressed: _releaseReel,
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
          Positioned(
            top: courtlySafeTop(context, 6),
            left: 14,
            child: _RoundIconButton(
              icon: CupertinoIcons.chevron_left,
              onPressed: _closeComposer,
            ),
          ),
          Positioned(
            top: courtlySafeTop(context, 17),
            left: 72,
            right: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Release Reel',
                  textAlign: TextAlign.center,
                  style: textStyle.copyWith(
                    color: CupertinoColors.white,
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'One clean rally. One courtside note.',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle.copyWith(
                    color: CupertinoColors.white.withValues(alpha: 0.62),
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _closeComposer() async {
    final navigator = Navigator.of(context);
    if (await navigator.maybePop()) {
      return;
    }
    if (!mounted) {
      return;
    }
    await Navigator.of(context, rootNavigator: true).maybePop();
  }

  Future<void> _chooseVideoSource() async {
    final source = await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Add a court video'),
          message: const Text('Choose a saved clip or record a new rally.'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              child: const Text('Choose from Library'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              child: const Text('Record Video'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
    if (source == null || !mounted) {
      return;
    }
    await _pickVideo(source);
  }

  Future<void> _pickVideo(ImageSource source) async {
    setState(() => _isPickingVideo = true);
    try {
      final pickedVideo = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 2),
      );
      if (pickedVideo != null && mounted) {
        setState(() => _videoPath = pickedVideo.path);
      }
    } catch (_) {
      if (mounted) {
        await _showDraftNotice(
          title: 'Video unavailable',
          message: 'Open your library again or record a fresh clip.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingVideo = false);
      }
    }
  }

  Future<void> _releaseReel() async {
    final mood = _moodController.text.trim();
    if (_videoPath == null) {
      await _showDraftNotice(
        title: 'Add a video',
        message: 'Choose a saved clip or record one before releasing.',
      );
      return;
    }
    if (mood.isEmpty) {
      await _showDraftNotice(
        title: 'Add a caption',
        message: 'Write a short courtside note for this reel.',
      );
      return;
    }

    if (!mounted) {
      return;
    }
    await showCourtlyReviewDialog(context, contentLabel: 'video reel');
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

class _ReleaseUploadCard extends StatelessWidget {
  const _ReleaseUploadCard({
    required this.videoPath,
    required this.isPickingVideo,
    required this.onPressed,
  });

  final String? videoPath;
  final bool isPickingVideo;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final selectedName = videoPath?.split('/').last;
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle;

    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        height: 318,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF7A38B8).withValues(alpha: 0.82),
              const Color(0xFF3B1276).withValues(alpha: 0.76),
            ],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.16),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
          child: Center(
            child: isPickingVideo
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Opening video picker',
                        style: textStyle.copyWith(
                          color: CupertinoColors.white.withValues(alpha: 0.76),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  )
                : selectedName == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/Ranking.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Add court video',
                        style: textStyle.copyWith(
                          color: CupertinoColors.white,
                          fontSize: 21,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Library or camera',
                        style: textStyle.copyWith(
                          color: CupertinoColors.white.withValues(alpha: 0.62),
                          fontSize: 13,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ReleaseSourceBadge(
                            icon: CupertinoIcons.photo_on_rectangle,
                            label: 'Album',
                          ),
                          SizedBox(width: 10),
                          _ReleaseSourceBadge(
                            icon: CupertinoIcons.video_camera_solid,
                            label: 'Camera',
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.check_mark_circled_solid,
                        color: CupertinoColors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Clip ready',
                        style: textStyle.copyWith(
                          color: CupertinoColors.white,
                          fontSize: 21,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        selectedName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle.copyWith(
                          color: CupertinoColors.white.withValues(alpha: 0.78),
                          fontSize: 13,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Tap to replace',
                        style: textStyle.copyWith(
                          color: const Color(0xFFFF70C8),
                          fontSize: 13,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ReleaseSourceBadge extends StatelessWidget {
  const _ReleaseSourceBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: CupertinoColors.white, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: CupertinoColors.white,
                fontSize: 12,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReleaseMoodField extends StatelessWidget {
  const _ReleaseMoodField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Caption',
          style: textStyle.copyWith(
            color: CupertinoColors.white,
            fontSize: 14,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6730A4).withValues(alpha: 0.72),
                const Color(0xFF42147A).withValues(alpha: 0.78),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: CupertinoColors.white.withValues(alpha: 0.12),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 148,
            child: CupertinoTextField(
              controller: controller,
              maxLines: null,
              expands: true,
              padding: const EdgeInsets.fromLTRB(22, 19, 22, 19),
              placeholder: 'Add a quick court note',
              placeholderStyle: textStyle.copyWith(
                color: CupertinoColors.white.withValues(alpha: 0.42),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                decoration: TextDecoration.none,
              ),
              style: textStyle.copyWith(
                color: CupertinoColors.white,
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                decoration: TextDecoration.none,
              ),
              decoration: const BoxDecoration(),
              cursorColor: CupertinoColors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class CourtReelCommentsSheet extends StatefulWidget {
  const CourtReelCommentsSheet({
    required this.reel,
    required this.onCommentsChanged,
    required this.onOpenProfile,
    required this.onModerated,
    super.key,
  });

  final CourtReel reel;
  final ValueChanged<List<CourtReelComment>> onCommentsChanged;
  final ValueChanged<CourtReelComment> onOpenProfile;
  final ValueChanged<CourtlyModerationResult> onModerated;

  @override
  State<CourtReelCommentsSheet> createState() => _CourtReelCommentsSheetState();
}

class _CourtReelCommentsSheetState extends State<CourtReelCommentsSheet> {
  late List<CourtReelComment> _comments = List<CourtReelComment>.of(
    widget.reel.comments,
  );
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height;
    final availableHeight =
        (height - keyboardInset - courtlySafeTop(context, 8))
            .clamp(320.0, 760.0)
            .toDouble();
    final sheetHeight = (availableHeight * 0.68).clamp(360.0, 560.0).toDouble();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: SizedBox(
          width: double.infinity,
          height: sheetHeight,
          child: Stack(
            children: [
              _CommentsPanel(
                comments: _comments,
                controller: _commentController,
                onSend: _sendComment,
                onOpenProfile: widget.onOpenProfile,
                onReportComment: _reportComment,
              ),
              Positioned(
                top: 12,
                right: 14,
                child: _RoundIconButton(
                  icon: CupertinoIcons.xmark,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendComment() {
    final message = _commentController.text.trim();
    if (message.isEmpty) {
      return;
    }

    final nextComments = [
      ..._comments,
      CourtReelComment(
        id: 'local-reel-comment-${DateTime.now().microsecondsSinceEpoch}',
        authorId: 'you',
        author: 'You',
        timeLabel: 'now',
        message: message,
        avatarAsset: CourtlyMediaAssets.womenHeads.first,
      ),
    ];

    setState(() {
      _comments = nextComments;
      _commentController.clear();
    });
    widget.onCommentsChanged(nextComments);
  }

  Future<void> _reportComment(CourtReelComment comment) async {
    final result = await showCourtlyModerationSheet(
      context: context,
      targetId: 'reel-comment:${comment.id}',
      targetType: 'comment',
      title: comment.author,
      userId: comment.authorId,
      summary: comment.message,
    );
    if (result == null || !mounted) {
      return;
    }

    final nextComments = _comments
        .where((entry) => entry.id != comment.id)
        .toList(growable: false);
    setState(() => _comments = nextComments);
    widget.onCommentsChanged(nextComments);
    widget.onModerated(result);
  }
}

class _CommentsPanel extends StatelessWidget {
  const _CommentsPanel({
    required this.comments,
    required this.controller,
    required this.onSend,
    required this.onOpenProfile,
    required this.onReportComment,
  });

  final List<CourtReelComment> comments;
  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<CourtReelComment> onOpenProfile;
  final ValueChanged<CourtReelComment> onReportComment;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF2B005F),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Image.asset(
              'assets/images/Badge.png',
              height: 102,
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final comment = comments[index];
                return _CommentRow(
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
                      color: CupertinoColors.white.withValues(alpha: 0.24),
                      child: const SizedBox(height: 1, width: double.infinity),
                    ),
                  ),
                );
              },
              itemCount: comments.length,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: _CommentComposer(controller: controller, onSend: onSend),
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.onOpenProfile,
    required this.onReport,
  });

  final CourtReelComment comment;
  final VoidCallback onOpenProfile;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoButton(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          onPressed: onOpenProfile,
          child: ClipOval(
            child: Image.asset(
              comment.avatarAsset,
              width: 34,
              height: 34,
              fit: BoxFit.cover,
            ),
          ),
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
                          comment.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle.copyWith(
                            color: CupertinoColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    comment.timeLabel,
                    style: textStyle.copyWith(
                      color: CupertinoColors.white.withValues(alpha: 0.48),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(width: 10),
                  CupertinoButton(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    onPressed: onReport,
                    child: Icon(
                      CupertinoIcons.ellipsis_vertical,
                      size: 18,
                      color: CupertinoColors.white.withValues(alpha: 0.76),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                comment.message,
                style: textStyle.copyWith(
                  color: CupertinoColors.white.withValues(alpha: 0.84),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF59308B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: controller,
                placeholder: 'Please enter...',
                padding: const EdgeInsets.only(left: 22, right: 10),
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  decoration: TextDecoration.none,
                ),
                placeholderStyle: CupertinoTheme.of(context).textTheme.textStyle
                    .copyWith(
                      color: CupertinoColors.white.withValues(alpha: 0.42),
                      fontSize: 14,
                      letterSpacing: 0,
                      decoration: TextDecoration.none,
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
                  dimension: 44,
                  child: Center(
                    child: Image.asset(
                      'assets/images/Streak.png',
                      width: 30,
                      height: 30,
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
          color: CupertinoColors.black.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: 42,
          child: Icon(icon, color: CupertinoColors.white, size: 22),
        ),
      ),
    );
  }
}

class _EmptyReelsView extends StatelessWidget {
  const _EmptyReelsView({required this.onPublish});

  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/Arena.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF12002F).withValues(alpha: 0.46),
          ),
        ),
        Positioned(
          top: courtlySafeTop(context, 8),
          left: 22,
          right: 20,
          child: _CourtReelsTopBar(onPublish: onPublish),
        ),
        Center(
          child: Image.asset(
            'assets/images/Love.png',
            width: 190,
            height: 190,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
