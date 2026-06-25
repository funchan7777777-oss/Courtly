import 'dart:async';
import 'dart:io';

import 'package:courtly/features/club_chats/presentation/club_chats_view.dart';
import 'package:courtly/features/court_reels/data/court_reel_seed.dart';
import 'package:courtly/features/court_reels/domain/court_reel.dart';
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
    unawaited(_loadModerationState());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _reels.isEmpty
          ? _EmptyReelsView(
              onPublish: () {
                unawaited(_openComposer());
              },
            )
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _visibleReels.length,
              onPageChanged: (index) => setState(() {
                _currentIndex = index;
                _isPlaying = true;
              }),
              itemBuilder: (context, index) {
                final reel = _visibleReels[index];

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
                  onFollow: () => _toggleFollow(reel.id),
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
              !_blockedUserIds.contains(reel.userId) &&
              !_reportedContentIds.contains('reel:${reel.id}'),
        )
        .toList(growable: false);
  }

  Future<void> _loadModerationState() async {
    final store = CourtlySocialStore.instance;
    final reported = await store.reportedContentIds();
    final blocked = await store.blockedUserIds();
    if (!mounted) {
      return;
    }
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
                        !blocked.contains(comment.authorId),
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false);
    });
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

  void _toggleFollow(String reelId) {
    final index = _reels.indexWhere((reel) => reel.id == reelId);
    if (index == -1) {
      return;
    }

    final reel = _reels[index];
    unawaited(CourtlySocialStore.instance.requestFollow(reel.userId));
    _replaceReelAt(index, reel.copyWith(isFollowed: !reel.isFollowed));
  }

  Future<void> _openComposer() async {
    final draft = await Navigator.of(context).push<CourtReelDraft>(
      CupertinoPageRoute<CourtReelDraft>(
        builder: (_) => const CourtReelReleasePage(),
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    await showCourtlyReviewDialog(context);
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
    _openUserProfile(
      CourtlyUserDirectory.fromIdentity(
        name: reel.playerName,
        avatarAsset: reel.avatarAsset,
        heroAsset: reel.backdropAsset,
      ),
    );
  }

  void _openCommentProfile(CourtReelComment comment) {
    _openUserProfile(
      CourtlyUserDirectory.fromIdentity(
        name: comment.author,
        avatarAsset: comment.avatarAsset,
      ),
    );
  }

  void _openUserProfile(CourtlyUserProfile profile) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => CourtlyUserProfilePage(
          profile: profile,
          onOpenChat: (profile) {
            unawaited(openClubChatForProfile(context, profile));
          },
          onModerated: (result) {
            unawaited(_handleModerationResult(result));
          },
        ),
      ),
    );
  }

  void _replaceReelAt(int index, CourtReel reel) {
    setState(() {
      final nextReels = List<CourtReel>.of(_reels);
      nextReels[index] = reel;
      _reels = nextReels;
    });
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
        const DecoratedBox(
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
            scale: isLiked ? 1.08 : 1,
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
                    width: 45,
                    height: 45,
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
              color: const Color(0xFF12002F).withValues(alpha: 0.54),
            ),
          ),
          Positioned(
            top: courtlySafeTop(context, 6),
            left: 14,
            child: _RoundIconButton(
              icon: CupertinoIcons.chevron_left,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: courtlySafeTop(context, 18),
            left: 72,
            right: 72,
            child: Text(
              'Video sharing',
              textAlign: TextAlign.center,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: CupertinoColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(28, 116, 28, 52 + keyboardInset),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _ReleaseUploadCard(
                    videoPath: _videoPath,
                    isPickingVideo: _isPickingVideo,
                    onPressed: _pickVideo,
                  ),
                  const SizedBox(height: 24),
                  _ReleaseMoodField(controller: _moodController),
                  const SizedBox(height: 72),
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
        ],
      ),
    );
  }

  Future<void> _pickVideo() async {
    setState(() => _isPickingVideo = true);
    try {
      final pickedVideo = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      if (pickedVideo != null && mounted) {
        setState(() => _videoPath = pickedVideo.path);
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
        title: 'Select a video',
        message: 'Add one rally clip before releasing your reel.',
      );
      return;
    }
    if (mood.isEmpty) {
      await _showDraftNotice(
        title: 'Add a caption',
        message: 'Share the mood or match detail for this reel.',
      );
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pop(CourtReelDraft(mood: mood, videoPath: _videoPath!));
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

    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 296,
        height: 326,
        decoration: BoxDecoration(
          color: const Color(0xFF59308B).withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.08),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: isPickingVideo
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : selectedName == null
              ? Icon(
                  CupertinoIcons.plus,
                  color: CupertinoColors.white.withValues(alpha: 0.36),
                  size: 72,
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.video_camera_solid,
                        color: CupertinoColors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        selectedName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CupertinoTheme.of(context).textTheme.textStyle
                            .copyWith(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.88,
                              ),
                              fontSize: 14,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
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

class _ReleaseMoodField extends StatelessWidget {
  const _ReleaseMoodField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF59308B).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
      ),
      child: SizedBox(
        height: 162,
        child: CupertinoTextField(
          controller: controller,
          maxLines: null,
          expands: true,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          placeholder: 'Please input your mood and feelings',
          placeholderStyle: CupertinoTheme.of(context).textTheme.textStyle
              .copyWith(
                color: CupertinoColors.white.withValues(alpha: 0.34),
                fontSize: 15,
                letterSpacing: 0,
                decoration: TextDecoration.none,
              ),
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            color: CupertinoColors.white,
            fontSize: 15,
            height: 1.35,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            decoration: TextDecoration.none,
          ),
          decoration: const BoxDecoration(),
          cursorColor: CupertinoColors.white,
        ),
      ),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.video_camera_solid,
                  color: CupertinoColors.white,
                  size: 56,
                ),
                const SizedBox(height: 18),
                Text(
                  'No reels in your court right now.',
                  textAlign: TextAlign.center,
                  style: CupertinoTheme.of(context).textTheme.textStyle
                      .copyWith(
                        color: CupertinoColors.white,
                        fontSize: 18,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        decoration: TextDecoration.none,
                      ),
                ),
                const SizedBox(height: 24),
                CupertinoButton(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  onPressed: onPublish,
                  child: Image.asset(
                    'assets/images/Lesson.png',
                    width: 240,
                    height: 46,
                    fit: BoxFit.fill,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
