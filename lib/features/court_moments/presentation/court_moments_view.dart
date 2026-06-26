import 'dart:async';
import 'dart:io';

import 'package:courtly/features/courtside_rallies/presentation/courtside_rallies_view.dart';
import 'package:courtly/features/court_clips/data/court_clip_program.dart';
import 'package:courtly/features/court_moments/data/court_moment_chronicle.dart';
import 'package:courtly/features/court_moments/domain/court_moment_entry.dart';
import 'package:courtly/shared/data/courtly_media_assets.dart';
import 'package:courtly/shared/presentation/courtly_profile_image.dart';
import 'package:courtly/shared/presentation/courtly_safe_layout.dart';
import 'package:courtly/shared/social/courtly_content_safety.dart';
import 'package:courtly/shared/social/courtly_current_player_profile.dart';
import 'package:courtly/shared/social/courtly_moderation.dart';
import 'package:courtly/shared/social/courtly_social_store.dart';
import 'package:courtly/shared/social/courtly_roster_book.dart';
import 'package:courtly/shared/social/courtly_player_card.dart';
import 'package:courtly/shared/social/courtly_player_card_page.dart';
import 'package:courtly/shared/wallet/courtly_coin_gate.dart';
import 'package:courtly/shared/wallet/courtly_wallet_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

const Color _momentPurple = Color(0xFF1A004D);
const Color _momentPanel = Color(0xFF2B0067);
const Color _momentPanelSoft = Color(0xFF59308B);
const Color _momentPink = Color(0xFFFF2DD2);

class CourtMomentsView extends StatefulWidget {
  const CourtMomentsView({super.key});

  @override
  State<CourtMomentsView> createState() => _CourtMomentsViewState();
}

class _CourtMomentsViewState extends State<CourtMomentsView> {
  List<CourtMomentEntry> _moments = List<CourtMomentEntry>.of(
    CourtMomentChronicle.openingCourtMoments,
  );
  int _practiceRhythmDays = 213;
  final Set<int> _loggedPracticeDays = {2, 8, 14, 21};
  Set<String> _reportedContentIds = {};
  Set<String> _blockedPlayerHandles = {};

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleMoments = _visibleMoments;

    return CupertinoPageScaffold(
      child: _MomentBackground(
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
                child: _MomentTopBar(onCompose: _openComposer),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                child: _ShortcutRow(
                  onPracticePulse: _openPracticePulse,
                  onRanking: _openRanking,
                ),
              ),
            ),
            if (visibleMoments.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _MomentEmptyState(),
              )
            else
              SliverList.separated(
                itemCount: visibleMoments.length,
                itemBuilder: (context, index) {
                  final moment = visibleMoments[index];

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      index == 0 ? 0 : 4,
                      22,
                      index == visibleMoments.length - 1 ? 120 : 0,
                    ),
                    child: _MomentCard(
                      moment: moment,
                      onOpenDetail: () => _openDetail(moment),
                      onOpenProfile: () => _openProfile(moment),
                      onToggleLike: () => _toggleLike(moment.momentId),
                      onToggleFollow: () {
                        unawaited(_toggleFollow(moment.momentId));
                      },
                      onMore: () => _showMomentActions(moment),
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

  List<CourtMomentEntry> get _visibleMoments {
    return _moments
        .where(
          (moment) =>
              !_hiddenPlayerHandles.contains(moment.playerHandle) &&
              !_reportedContentIds.contains('moment:${moment.momentId}'),
        )
        .toList(growable: false);
  }

  Set<String> get _hiddenPlayerHandles {
    return _hiddenPlayerHandlesFor(_reportedContentIds, _blockedPlayerHandles);
  }

  Future<void> _loadModerationState() async {
    final store = CourtlySocialStore.instance;
    final reported = await store.reportedContentIds();
    final blocked = await store.blockedPlayerHandles();
    if (!mounted) {
      return;
    }
    final hiddenPlayers = _hiddenPlayerHandlesFor(reported, blocked);
    setState(() {
      _reportedContentIds = reported;
      _blockedPlayerHandles = blocked;
      _moments = _moments
          .map(
            (moment) => moment.copyWith(
              rallyReplies: moment.rallyReplies
                  .where(
                    (comment) =>
                        !reported.contains('moment-reply:${comment.replyId}') &&
                        !hiddenPlayers.contains(comment.playerHandle),
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false);
    });
  }

  Future<void> _loadRelationshipState() async {
    final store = CourtlySocialStore.instance;
    final nextMoments = <CourtMomentEntry>[];
    for (final moment in _moments) {
      final requested = await store.hasRequestedFollow(moment.playerHandle);
      final following = await store.isFollowing(moment.playerHandle);
      nextMoments.add(moment.copyWith(isInCourtCircle: requested || following));
    }
    if (!mounted) {
      return;
    }
    setState(() => _moments = nextMoments);
  }

  void _handleRelationshipChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_loadRelationshipState());
  }

  Future<void> _openComposer() async {
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(builder: (_) => const CourtMomentComposerPage()),
    );
  }

  Future<void> _openDetail(CourtMomentEntry moment) async {
    final updated = await Navigator.of(context).push<CourtMomentEntry>(
      CupertinoPageRoute<CourtMomentEntry>(
        builder: (_) => CourtMomentDetailPage(
          moment: moment,
          onOpenProfile: _openPlayerCard,
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

    _replaceMomentsByPlayer(
      updated.playerHandle,
      (moment) => moment.momentId == updated.momentId
          ? updated
          : moment.copyWith(isInCourtCircle: updated.isInCourtCircle),
    );
  }

  Future<void> _openProfile(CourtMomentEntry moment) async {
    await _openPlayerCard(
      CourtlyRosterBook.fromCourtsideIdentity(
        playerHandle: moment.playerHandle,
        courtsideName: moment.courtsideName,
        playerPortraitAsset: moment.playerPortraitAsset,
        courtCardAsset: moment.momentImageAsset,
      ),
    );
  }

  Future<void> _openPlayerCard(CourtlyPlayerCard profile) async {
    await Navigator.of(context).push<CourtlyModerationResult>(
      CupertinoPageRoute<CourtlyModerationResult>(
        builder: (_) => CourtlyPlayerCardPage(
          profile: profile,
          videos: _profileVideosFor(profile.playerHandle),
          moments: _profileMomentsFor(profile.playerHandle),
          onOpenChat: (profile) {
            unawaited(openCourtsideRallyForCard(context, profile));
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

  Future<void> _openPracticePulse() async {
    final practiceLogged = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        builder: (_) => PracticePulsePage(
          practiceDays: _loggedPracticeDays,
          rallyRhythmDays: _practiceRhythmDays,
        ),
      ),
    );

    if (practiceLogged == true && mounted) {
      setState(() {
        _loggedPracticeDays.add(24);
        _practiceRhythmDays += 1;
      });
    }
  }

  void _openRanking() {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute<void>(builder: (_) => const TennisRankingPage()));
  }

  void _toggleLike(String momentId) {
    final index = _moments.indexWhere((moment) => moment.momentId == momentId);
    if (index == -1) {
      return;
    }

    final moment = _moments[index];
    final nextLiked = !moment.hasApplauded;
    final nextLikes = (moment.applauseCount + (nextLiked ? 1 : -1))
        .clamp(0, 999999)
        .toInt();
    _replaceMomentAt(
      index,
      moment.copyWith(hasApplauded: nextLiked, applauseCount: nextLikes),
    );
  }

  Future<void> _toggleFollow(String momentId) async {
    final index = _moments.indexWhere((moment) => moment.momentId == momentId);
    if (index == -1) {
      return;
    }

    final moment = _moments[index];
    if (moment.isInCourtCircle) {
      return;
    }

    await CourtlySocialStore.instance.requestFollow(moment.playerHandle);
    if (!mounted) {
      return;
    }
    _replaceMomentsByPlayer(
      moment.playerHandle,
      (entry) => entry.copyWith(isInCourtCircle: true),
    );
  }

  Future<void> _showMomentActions(CourtMomentEntry moment) async {
    final result = await showCourtlyModerationSheet(
      context: context,
      targetId: 'moment:${moment.momentId}',
      targetType: 'moment',
      title: moment.courtsideName,
      playerHandle: moment.playerHandle,
      summary: moment.courtNote,
      playerPortraitAsset: moment.playerPortraitAsset,
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
        title: 'Player blocked',
        message:
            'That player and their moments, replies, and chats will stay hidden.',
      );
      return;
    }

    await showCourtlyActionSuccess(
      context: context,
      title: 'Report sent',
      message: 'The report was saved locally and this item is now hidden.',
    );
  }

  void _replaceMoment(String momentId, CourtMomentEntry moment) {
    final index = _moments.indexWhere((entry) => entry.momentId == momentId);
    if (index == -1) {
      return;
    }
    _replaceMomentAt(index, moment);
  }

  void _replaceMomentAt(int index, CourtMomentEntry moment) {
    setState(() {
      final nextMoments = List<CourtMomentEntry>.of(_moments);
      nextMoments[index] = moment;
      _moments = nextMoments;
    });
  }

  void _replaceMomentsByPlayer(
    String playerHandle,
    CourtMomentEntry Function(CourtMomentEntry moment) update,
  ) {
    setState(() {
      _moments = _moments
          .map(
            (moment) =>
                moment.playerHandle == playerHandle ? update(moment) : moment,
          )
          .toList(growable: false);
    });
  }

  List<CourtlyProfileVideoItem> _profileVideosFor(String playerHandle) {
    return CourtClipProgram.trainingClipDispatches
        .where(
          (clip) =>
              clip.playerHandle == playerHandle &&
              !_hiddenPlayerHandles.contains(clip.playerHandle) &&
              !_reportedContentIds.contains('clip:${clip.clipId}'),
        )
        .map(
          (clip) => CourtlyProfileVideoItem(
            clipId: clip.clipId,
            coverFrameAsset: clip.coverFrameAsset,
          ),
        )
        .toList(growable: false);
  }

  List<CourtlyProfileMomentItem> _profileMomentsFor(String playerHandle) {
    return _moments
        .where(
          (moment) =>
              moment.playerHandle == playerHandle &&
              !_hiddenPlayerHandles.contains(moment.playerHandle) &&
              !_reportedContentIds.contains('moment:${moment.momentId}'),
        )
        .map(
          (moment) => CourtlyProfileMomentItem(
            momentId: moment.momentId,
            momentImageAsset: moment.momentImageAsset,
            courtNote: moment.courtNote,
          ),
        )
        .toList(growable: false);
  }

  Set<String> _hiddenPlayerHandlesFor(
    Set<String> reported,
    Set<String> blocked,
  ) {
    return {
      ...blocked,
      for (final contentId in reported)
        if (contentId.startsWith('player:')) contentId.substring(7),
    };
  }
}

class _MomentBackground extends StatelessWidget {
  const _MomentBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/courtly_strings.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: _momentPurple.withValues(alpha: 0.72),
          ),
        ),
        child,
      ],
    );
  }
}

class _MomentEmptyState extends StatelessWidget {
  const _MomentEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/courtly_love.png',
        width: 190,
        height: 190,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _MomentTopBar extends StatelessWidget {
  const _MomentTopBar({required this.onCompose});

  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/courtly_spin.png',
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
                  'assets/images/courtly_singles.png',
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
  const _ShortcutRow({required this.onPracticePulse, required this.onRanking});

  final VoidCallback onPracticePulse;
  final VoidCallback onRanking;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ShortcutCard(
            title: 'Practice\npulse',
            momentImageAsset: 'assets/images/courtly_rally_clock.png',
            onPressed: onPracticePulse,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ShortcutCard(
            title: 'Ranking\nlist',
            momentImageAsset: 'assets/images/courtly_ranking_list.png',
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
    required this.momentImageAsset,
    required this.onPressed,
  });

  final String title;
  final String momentImageAsset;
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
            momentImageAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            semanticLabel: title,
          ),
        ),
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({
    required this.moment,
    required this.onOpenDetail,
    required this.onOpenProfile,
    required this.onToggleLike,
    required this.onToggleFollow,
    required this.onMore,
  });

  final CourtMomentEntry moment;
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
              _momentPanel.withValues(alpha: 0.98),
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
                        child: _Avatar(
                          assetPath: moment.playerPortraitAsset,
                          size: 44,
                        ),
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
                            moment.courtsideName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _momentText(context).copyWith(
                              color: CupertinoColors.white,
                              fontSize: 16,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _momentDisplayTimeLabel(moment.rallyClockLabel),
                            style: _momentText(context).copyWith(
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
                    isInCourtCircle: moment.isInCourtCircle,
                    onPressed: onToggleFollow,
                  ),
                  const SizedBox(width: 8),
                  _MomentMoreButton(onPressed: onMore),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                moment.courtNote,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: _momentText(context).copyWith(
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
                        _MomentImage(
                          imagePath: moment.momentImageAsset,
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
                  _MomentMetricButton(
                    iconAsset: moment.hasApplauded
                        ? 'assets/images/courtly_locker.png'
                        : 'assets/images/courtly_like_idle.png',
                    label: _countLabel(moment.applauseCount),
                    onPressed: onToggleLike,
                  ),
                  const SizedBox(width: 10),
                  _MomentMetricButton(
                    iconData: CupertinoIcons.chat_bubble_fill,
                    label: _countLabel(moment.rallyReplies.length),
                    onPressed: onOpenDetail,
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

class _MomentMoreButton extends StatelessWidget {
  const _MomentMoreButton({required this.onPressed});

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

class _MomentMetricButton extends StatelessWidget {
  const _MomentMetricButton({
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
                style: _momentText(context).copyWith(
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
  const _FollowButton({
    required this.isInCourtCircle,
    required this.onPressed,
    this.width = 96,
    this.height = 30,
  });

  final bool isInCourtCircle;
  final VoidCallback onPressed;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Image.asset(
        isInCourtCircle
            ? 'assets/images/courtly_chat.png'
            : 'assets/images/courtly_huddle.png',
        width: width,
        height: height,
        fit: BoxFit.fill,
      ),
    );
  }
}

class _DetailTopActionButton extends StatelessWidget {
  const _DetailTopActionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: CupertinoColors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.ellipsis,
          color: _momentPanel,
          size: 24,
        ),
      ),
    );
  }
}

class CourtMomentDetailPage extends StatefulWidget {
  const CourtMomentDetailPage({
    required this.moment,
    required this.onCompose,
    required this.onOpenProfile,
    required this.onModerated,
    super.key,
  });

  final CourtMomentEntry moment;
  final VoidCallback onCompose;
  final ValueChanged<CourtlyPlayerCard> onOpenProfile;
  final ValueChanged<CourtlyModerationResult> onModerated;

  @override
  State<CourtMomentDetailPage> createState() => _CourtMomentDetailPageState();
}

class _CourtMomentDetailPageState extends State<CourtMomentDetailPage> {
  late CourtMomentEntry _moment = widget.moment;
  final TextEditingController _commentController = TextEditingController();
  CourtlyCurrentPlayerProfile _currentPlayer =
      CourtlyCurrentPlayerProfile.fallback();

  @override
  void initState() {
    super.initState();
    CourtlySocialStore.instance.relationshipVersion.addListener(
      _handleRelationshipChanged,
    );
    unawaited(_syncRelationshipState());
    unawaited(_loadCurrentPlayer());
  }

  @override
  void dispose() {
    CourtlySocialStore.instance.relationshipVersion.removeListener(
      _handleRelationshipChanged,
    );
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return CupertinoPageScaffold(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: _momentPanel),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height;
            final heroHeight = (screenHeight * 0.6)
                .clamp(mediaPadding.top + 360, 540)
                .toDouble();
            final composerBottom = keyboardInset > 0
                ? keyboardInset + 12
                : mediaPadding.bottom + 18;
            const composerHeight = 58.0;
            final commentsBottomPadding = composerBottom + composerHeight + 18;

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: heroHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _MomentImage(
                        imagePath: _moment.momentImageAsset,
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
                              Color(0x00000000),
                              Color(0x551A004D),
                              Color(0xEE1A004D),
                              _momentPanel,
                            ],
                            stops: [0, 0.28, 0.55, 0.84, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        top: courtlySafeTop(context, 8),
                        left: 16,
                        child: _RoundIconButton(
                          icon: CupertinoIcons.chevron_left,
                          onPressed: () => Navigator.of(context).pop(_moment),
                        ),
                      ),
                      Positioned(
                        top: courtlySafeTop(context, 10),
                        right: 18,
                        child: _DetailTopActionButton(
                          onPressed: widget.onCompose,
                        ),
                      ),
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 16,
                        child: _DetailAuthorBlock(
                          moment: _moment,
                          followWidth: 108,
                          followHeight: 34,
                          titleSize: 22,
                          onFollow: () {
                            unawaited(_toggleFollow());
                          },
                          onLike: _toggleLike,
                          onOpenProfile: _openAuthorProfile,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: heroHeight,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _DetailCommentsPanel(
                    moment: _moment,
                    bottomPadding: commentsBottomPadding,
                    currentPlayer: _currentPlayer,
                    onOpenProfile: _openCommentProfile,
                    onReportComment: _reportComment,
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: composerBottom,
                  child: _MomentCommentComposer(
                    controller: _commentController,
                    onSend: _sendComment,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _toggleFollow() async {
    if (_moment.isInCourtCircle) {
      return;
    }

    await CourtlySocialStore.instance.requestFollow(_moment.playerHandle);
    if (!mounted) {
      return;
    }
    setState(() => _moment = _moment.copyWith(isInCourtCircle: true));
  }

  void _toggleLike() {
    final nextLiked = !_moment.hasApplauded;
    final nextLikes = (_moment.applauseCount + (nextLiked ? 1 : -1))
        .clamp(0, 999999)
        .toInt();

    setState(() {
      _moment = _moment.copyWith(
        hasApplauded: nextLiked,
        applauseCount: nextLikes,
      );
    });
  }

  void _handleRelationshipChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_syncRelationshipState());
  }

  Future<void> _syncRelationshipState() async {
    final store = CourtlySocialStore.instance;
    final requested = await store.hasRequestedFollow(_moment.playerHandle);
    final following = await store.isFollowing(_moment.playerHandle);
    if (!mounted) {
      return;
    }
    setState(() {
      _moment = _moment.copyWith(isInCourtCircle: requested || following);
    });
  }

  Future<void> _loadCurrentPlayer() async {
    final currentPlayer = await loadCourtlyCurrentPlayerProfile();
    if (!mounted) {
      return;
    }

    setState(() => _currentPlayer = currentPlayer);
  }

  void _sendComment() {
    unawaited(_sendCommentSafely());
  }

  Future<void> _sendCommentSafely() async {
    final courtNote = _commentController.text.trim();
    if (courtNote.isEmpty) {
      return;
    }

    final safety = CourtlyContentSafety.validateText(
      courtNote,
      surface: CourtlyContentSurface.momentReply,
    );
    if (!safety.allowed) {
      await showCourtlyContentSafetyNotice(context: context, result: safety);
      return;
    }

    final commentId =
        'local-moment-reply-${DateTime.now().microsecondsSinceEpoch}';
    final momentAuthorHandle = _moment.playerHandle;
    final momentAuthorName = _moment.courtsideName;

    setState(() {
      _moment = _moment.copyWith(
        rallyReplies: [
          ..._moment.rallyReplies,
          CourtMomentReply(
            replyId: commentId,
            playerHandle: CourtlyCurrentPlayerProfile.playerHandle,
            courtsideName: _currentPlayer.displayName,
            rallyClockLabel: 'now',
            courtNote: courtNote,
            playerPortraitAsset: _currentPlayer.avatarPath,
          ),
        ],
      );
      _commentController.clear();
    });
    unawaited(
      CourtlySocialStore.instance.addSystemMessage(
        CourtlySystemMessage(
          id: 'comment-$commentId',
          kind: 'comment',
          title: 'Reply added',
          body: 'Your reply was added to $momentAuthorName\'s court moment.',
          timeLabel: 'now',
          playerHandle: momentAuthorHandle,
          targetId: 'moment-reply:$commentId',
        ),
      ),
    );
  }

  void _openAuthorProfile() {
    widget.onOpenProfile(
      CourtlyRosterBook.fromCourtsideIdentity(
        playerHandle: _moment.playerHandle,
        courtsideName: _moment.courtsideName,
        playerPortraitAsset: _moment.playerPortraitAsset,
        courtCardAsset: _moment.momentImageAsset,
      ),
    );
  }

  void _openCommentProfile(CourtMomentReply comment) {
    final isCurrentPlayer =
        comment.playerHandle == CourtlyCurrentPlayerProfile.playerHandle;
    widget.onOpenProfile(
      CourtlyRosterBook.fromCourtsideIdentity(
        playerHandle: comment.playerHandle,
        courtsideName: isCurrentPlayer
            ? _currentPlayer.displayName
            : comment.courtsideName,
        playerPortraitAsset: isCurrentPlayer
            ? _currentPlayer.avatarPath
            : comment.playerPortraitAsset,
      ),
    );
  }

  Future<void> _reportComment(CourtMomentReply comment) async {
    final isCurrentPlayer =
        comment.playerHandle == CourtlyCurrentPlayerProfile.playerHandle;
    final result = await showCourtlyModerationSheet(
      context: context,
      targetId: 'moment-reply:${comment.replyId}',
      targetType: 'comment',
      title: isCurrentPlayer
          ? _currentPlayer.displayName
          : comment.courtsideName,
      playerHandle: comment.playerHandle,
      summary: comment.courtNote,
      playerPortraitAsset: isCurrentPlayer
          ? _currentPlayer.avatarPath
          : comment.playerPortraitAsset,
    );
    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _moment = _moment.copyWith(
        rallyReplies: _moment.rallyReplies
            .where((entry) => entry.replyId != comment.replyId)
            .toList(growable: false),
      );
    });
    widget.onModerated(result);
  }
}

class _DetailAuthorBlock extends StatelessWidget {
  const _DetailAuthorBlock({
    required this.moment,
    required this.onFollow,
    required this.onOpenProfile,
    this.onLike,
    this.followWidth = 96,
    this.followHeight = 30,
    this.titleSize = 21,
  });

  final CourtMomentEntry moment;
  final VoidCallback onFollow;
  final VoidCallback onOpenProfile;
  final VoidCallback? onLike;
  final double followWidth;
  final double followHeight;
  final double titleSize;

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
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    moment.courtsideName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _momentText(context).copyWith(
                      color: CupertinoColors.white,
                      fontSize: titleSize,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _FollowButton(
              isInCourtCircle: moment.isInCourtCircle,
              width: followWidth,
              height: followHeight,
              onPressed: onFollow,
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          _momentDisplayTimeLabel(moment.rallyClockLabel),
          style: _momentText(context).copyWith(
            color: CupertinoColors.white.withValues(alpha: 0.58),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          moment.courtNote,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: _momentText(context).copyWith(
            color: CupertinoColors.white.withValues(alpha: 0.9),
            fontSize: 14,
            height: 1.32,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (onLike != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              _MomentMetricButton(
                iconAsset: moment.hasApplauded
                    ? 'assets/images/courtly_locker.png'
                    : 'assets/images/courtly_like_idle.png',
                label: _countLabel(moment.applauseCount),
                onPressed: onLike!,
              ),
              const SizedBox(width: 10),
              _MomentMetricButton(
                iconData: CupertinoIcons.chat_bubble_fill,
                label: _countLabel(moment.rallyReplies.length),
                onPressed: () {},
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Text(
          'Discuss',
          style: _momentText(context).copyWith(
            color: CupertinoColors.white,
            fontSize: 17,
            height: 1,
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
    required this.moment,
    required this.bottomPadding,
    required this.currentPlayer,
    required this.onOpenProfile,
    required this.onReportComment,
  });

  final CourtMomentEntry moment;
  final double bottomPadding;
  final CourtlyCurrentPlayerProfile currentPlayer;
  final ValueChanged<CourtMomentReply> onOpenProfile;
  final ValueChanged<CourtMomentReply> onReportComment;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: _momentPanel),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(24, 18, 24, bottomPadding),
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: moment.rallyReplies.length,
        itemBuilder: (context, index) {
          final comment = moment.rallyReplies[index];
          final avatarPath =
              comment.playerHandle == CourtlyCurrentPlayerProfile.playerHandle
              ? currentPlayer.avatarPath
              : comment.playerPortraitAsset;
          return _MomentCommentRow(
            comment: comment,
            avatarPath: avatarPath,
            onOpenProfile: () => onOpenProfile(comment),
            onReport: () => onReportComment(comment),
          );
        },
        separatorBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(44, 16, 0, 16),
            child: ColoredBox(
              color: CupertinoColors.white.withValues(alpha: 0.24),
              child: const SizedBox(height: 1, width: double.infinity),
            ),
          );
        },
      ),
    );
  }
}

class CourtMomentComposerPage extends StatefulWidget {
  const CourtMomentComposerPage({super.key});

  @override
  State<CourtMomentComposerPage> createState() =>
      _CourtMomentComposerPageState();
}

class _CourtMomentComposerPageState extends State<CourtMomentComposerPage> {
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
      child: _MomentBackground(
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
                      style: _momentText(context).copyWith(
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
                      style: _momentText(context).copyWith(
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
                    _ComposerReleaseButton(onPressed: _releaseMoment),
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
                'Create moment',
                textAlign: TextAlign.center,
                style: _momentText(context).copyWith(
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

  Future<void> _releaseMoment() async {
    final courtNote = _bodyController.text.trim();
    if (_imagePath == null) {
      await _showDraftNotice(
        title: 'Add a court photo',
        message: 'Pick one image from your album or take a fresh court shot.',
      );
      return;
    }

    if (courtNote.isEmpty) {
      await _showDraftNotice(
        title: 'Write a caption',
        message: 'Add a short note so the moment has context.',
      );
      return;
    }

    final safety = CourtlyContentSafety.validateText(
      courtNote,
      surface: CourtlyContentSurface.moment,
    );
    if (!safety.allowed) {
      await showCourtlyContentSafetyNotice(context: context, result: safety);
      return;
    }

    await showCourtlyReviewDialog(context, contentLabel: 'photo moment');
    if (!mounted) {
      return;
    }
    await CourtlySocialStore.instance.addPublishedMoment(
      courtNote: courtNote,
      imagePath: _imagePath!,
    );
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
          color: _momentPanelSoft.withValues(alpha: 0.5),
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
                        style: _momentText(context).copyWith(
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
                        style: _momentText(context).copyWith(
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
              style: _momentText(context).copyWith(
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
        color: _momentPanelSoft.withValues(alpha: 0.52),
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
          placeholderStyle: _momentText(context).copyWith(
            color: CupertinoColors.white.withValues(alpha: 0.42),
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w800,
          ),
          style: _momentText(context).copyWith(
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
          color: _momentPink,
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
              'Publish moment',
              style: _momentText(context).copyWith(
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

class CourtMomentPlayerPage extends StatefulWidget {
  const CourtMomentPlayerPage({required this.moment, super.key});

  final CourtMomentEntry moment;

  @override
  State<CourtMomentPlayerPage> createState() => _CourtMomentPlayerPageState();
}

class _CourtMomentPlayerPageState extends State<CourtMomentPlayerPage> {
  late CourtMomentEntry _moment = widget.moment;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    CourtlySocialStore.instance.relationshipVersion.addListener(
      _handleRelationshipChanged,
    );
    unawaited(_syncRelationshipState());
  }

  @override
  void dispose() {
    CourtlySocialStore.instance.relationshipVersion.removeListener(
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
          _MomentImage(
            imagePath: _moment.momentImageAsset,
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
              onPressed: () => Navigator.of(context).pop(_moment),
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
                  moment: _moment,
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
                      ? _VideoGrid(
                          practiceClipAssets: _moment.practiceClipAssets,
                        )
                      : _ProfileMomentPreview(moment: _moment),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFollow() async {
    if (_moment.isInCourtCircle) {
      return;
    }

    await CourtlySocialStore.instance.requestFollow(_moment.playerHandle);
    if (!mounted) {
      return;
    }
    setState(() => _moment = _moment.copyWith(isInCourtCircle: true));
  }

  void _handleRelationshipChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_syncRelationshipState());
  }

  Future<void> _syncRelationshipState() async {
    final store = CourtlySocialStore.instance;
    final requested = await store.hasRequestedFollow(_moment.playerHandle);
    final following = await store.isFollowing(_moment.playerHandle);
    if (!mounted) {
      return;
    }
    setState(() {
      _moment = _moment.copyWith(isInCourtCircle: requested || following);
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
          label: 'Moments',
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
        style: _momentText(context).copyWith(
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
  const _VideoGrid({required this.practiceClipAssets});

  final List<String> practiceClipAssets;

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
      itemCount: practiceClipAssets.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _MomentImage(
                imagePath: practiceClipAssets[index],
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

class _ProfileMomentPreview extends StatelessWidget {
  const _ProfileMomentPreview({required this.moment});

  final CourtMomentEntry moment;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: _MomentCard(
        moment: moment,
        onOpenDetail: () {},
        onOpenProfile: () {},
        onToggleLike: () {},
        onToggleFollow: () {},
        onMore: () {},
      ),
    );
  }
}

class PracticePulsePage extends StatefulWidget {
  const PracticePulsePage({
    required this.practiceDays,
    required this.rallyRhythmDays,
    super.key,
  });

  final Set<int> practiceDays;
  final int rallyRhythmDays;

  @override
  State<PracticePulsePage> createState() => _PracticePulsePageState();
}

class _PracticePulsePageState extends State<PracticePulsePage> {
  late final Set<int> _loggedPracticeDays = Set<int>.of(widget.practiceDays);
  late int _practiceRhythmDays = widget.rallyRhythmDays;
  bool _loggedToday = false;

  @override
  Widget build(BuildContext context) {
    final safeTop = courtlySafeTop(context);
    final safeBottom = courtlySafeBottom(context);

    return CupertinoPageScaffold(
      child: _MomentBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: courtlySafeTop(context, 8),
              left: 12,
              child: _RoundIconButton(
                icon: CupertinoIcons.chevron_left,
                onPressed: () => Navigator.of(context).pop(_loggedToday),
              ),
            ),
            Positioned(
              top: courtlySafeTop(context, 20),
              left: 74,
              right: 74,
              child: Text(
                'Practice Pulse',
                textAlign: TextAlign.center,
                style: _momentText(context).copyWith(
                  color: CupertinoColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Positioned.fill(
              top: safeTop + 76,
              left: 24,
              right: 24,
              bottom: 0,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: safeBottom + 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DiaryBoard(days: _practiceRhythmDays),
                    const SizedBox(height: 10),
                    _CalendarCard(
                      practiceDays: _loggedPracticeDays,
                      onLogPractice: _logPractice,
                    ),
                    const SizedBox(height: 18),
                    _PracticeReflectionCard(
                      onPressed: () => unawaited(_savePracticeReflection()),
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

  void _logPractice() {
    if (_loggedToday) {
      return;
    }

    setState(() {
      _loggedToday = true;
      _loggedPracticeDays.add(24);
      _practiceRhythmDays += 1;
    });
  }

  Future<void> _savePracticeReflection() async {
    if (_loggedPracticeDays.contains(1)) {
      return;
    }

    final paid = await showCourtlyCoinSpendGate(
      context: context,
      feature: CourtlyCoinFeature.practiceReflection,
    );
    if (!paid || !mounted) {
      return;
    }

    setState(() => _loggedPracticeDays.add(1));
  }
}

class _DiaryBoard extends StatelessWidget {
  const _DiaryBoard({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.78,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 10,
            child: Container(
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/courtly_backhand.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF44D98F).withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            top: 0,
            left: 22,
            right: 22,
            child: _NotebookRings(),
          ),
          Positioned(
            left: 24,
            top: 42,
            child: Text(
              '$days',
              style: _momentText(context).copyWith(
                color: CupertinoColors.white,
                fontSize: 44,
                height: 0.92,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: 94,
            width: 150,
            child: Text(
              'Practice rhythm\non record',
              style: _momentText(context).copyWith(
                color: CupertinoColors.white.withValues(alpha: 0.92),
                fontSize: 13,
                height: 1.18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.practiceDays,
    required this.onLogPractice,
  });

  final Set<int> practiceDays;
  final VoidCallback onLogPractice;

  @override
  Widget build(BuildContext context) {
    const days = <int>[
      31,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      27,
      28,
      29,
      30,
      1,
      2,
      3,
      4,
      5,
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.chevron_left_circle_fill,
                color: _momentPink,
                size: 14,
              ),
              const SizedBox(width: 14),
              Text(
                '2026/06',
                style: _momentText(context).copyWith(
                  color: const Color(0xFF36313D),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 14),
              Icon(
                CupertinoIcons.chevron_right_circle_fill,
                color: const Color(0xFFBFB9C6).withValues(alpha: 0.9),
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 18),
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
                    style: _momentText(context).copyWith(
                      color: const Color(0xFFC4BECF),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final belongsToMonth = index > 0 && index < 30;
              final active = belongsToMonth && practiceDays.contains(day);
              final highlighted = belongsToMonth && day == 1;

              return DecoratedBox(
                decoration: BoxDecoration(
                  color: active
                      ? _momentPink
                      : highlighted
                      ? const Color(0xFFFFDCEB)
                      : const Color(0xFFF3F1F4),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: active
                      ? const DecoratedBox(
                          decoration: BoxDecoration(
                            color: _momentPink,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox.square(
                            dimension: 18,
                            child: Icon(
                              CupertinoIcons.check_mark,
                              color: CupertinoColors.white,
                              size: 12,
                            ),
                          ),
                        )
                      : Text(
                          '$day',
                          style: _momentText(context).copyWith(
                            color: belongsToMonth
                                ? const Color(0xFF25212B)
                                : const Color(0xFFC9C4CD),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 26),
          CupertinoButton(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            onPressed: onLogPractice,
            child: Image.asset(
              'assets/images/courtly_footwork.png',
              width: double.infinity,
              height: 55,
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotebookRings extends StatelessWidget {
  const _NotebookRings();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        7,
        (index) => Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _NotebookRing(),
            SizedBox(width: 6),
            _NotebookRing(),
          ],
        ),
      ),
    );
  }
}

class _NotebookRing extends StatelessWidget {
  const _NotebookRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFF5B5662),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 2,
          height: 10,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: CupertinoColors.white.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _PracticeReflectionCard extends StatelessWidget {
  const _PracticeReflectionCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final rule = CourtlyWalletStore.spendRuleFor(
      CourtlyCoinFeature.practiceReflection,
    );

    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFA8F2E5),
              borderRadius: BorderRadius.circular(9),
            ),
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add one missed practice note',
                    textAlign: TextAlign.center,
                    style: _momentText(context).copyWith(
                      color: const Color(0xFF2E9F94),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF20A89A),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Center(
                    child: Text(
                      '${rule.cost} coins',
                      style: _momentText(context).copyWith(
                        color: CupertinoColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: -16,
            child: Image.asset(
              'assets/images/courtly_tiebreak.png',
              width: 116,
              height: 30,
              fit: BoxFit.fill,
            ),
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
    final entries = CourtMomentChronicle.courtRhythmStandings;
    final safeTop = courtlySafeTop(context);

    return CupertinoPageScaffold(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/courtly_strings.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x221B0D2F),
                  Color(0x332F154B),
                  Color(0xDD070910),
                ],
                stops: [0, 0.52, 1],
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
              'Court Rhythm',
              textAlign: TextAlign.center,
              style: _momentText(context).copyWith(
                color: CupertinoColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Positioned.fill(
            top: safeTop + 78,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                courtlySafeBottom(context, 34),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tennis Rankings',
                    style: _momentText(context).copyWith(
                      color: const Color(0xFFE3FFFF),
                      fontSize: 28,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(
                          color: Color(0x66000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'THE CHARTS',
                    style: _momentText(context).copyWith(
                      color: CupertinoColors.white,
                      fontSize: 15,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(
                          color: Color(0x66000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 42),
                  _RankingPodium(entries: entries.take(3).toList()),
                  const SizedBox(height: 4),
                  _RankingList(entries: entries.skip(3).toList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingPodium extends StatelessWidget {
  const _RankingPodium({required this.entries});

  final List<CourtRhythmStanding> entries;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumPerson(
              entry: entries[1],
              ringAsset: 'assets/images/courtly_drop.png',
              pedestalAsset: 'assets/images/courtly_podium_second.png',
              place: 2,
            ),
          ),
          Expanded(
            child: _PodiumPerson(
              entry: entries[0],
              ringAsset: 'assets/images/courtly_advantage.png',
              pedestalAsset: 'assets/images/courtly_podium_first.png',
              place: 1,
              isWinner: true,
            ),
          ),
          Expanded(
            child: _PodiumPerson(
              entry: entries[2],
              ringAsset: 'assets/images/courtly_deuce.png',
              pedestalAsset: 'assets/images/courtly_podium_third.png',
              place: 3,
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
    required this.ringAsset,
    required this.pedestalAsset,
    required this.place,
    this.isWinner = false,
  });

  final CourtRhythmStanding entry;
  final String ringAsset;
  final String pedestalAsset;
  final int place;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final ringSize = isWinner ? 108.0 : 86.0;
    final avatarSize = isWinner ? 62.0 : 50.0;
    final pedestalWidth = isWinner ? 124.0 : 94.0;
    final pedestalHeight = isWinner ? 140.0 : 106.0;
    final slotHeight = isWinner ? 250.0 : 214.0;
    final textColor = place == 1
        ? const Color(0xFF8E6500)
        : place == 2
        ? const Color(0xFF667486)
        : const Color(0xFF9B4F35);

    return SizedBox(
      height: slotHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              onPressed: () => _openRankingProfile(context, entry),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    pedestalAsset,
                    width: pedestalWidth,
                    height: pedestalHeight,
                    fit: BoxFit.fill,
                  ),
                  Positioned(
                    top: isWinner ? 45 : 31,
                    left: 4,
                    right: 4,
                    child: Column(
                      children: [
                        Text(
                          entry.courtsideName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _momentText(context).copyWith(
                            color: textColor,
                            fontSize: isWinner ? 13 : 11,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 11),
                        Text(
                          'Rhythm days',
                          style: _momentText(context).copyWith(
                            color: textColor.withValues(alpha: 0.76),
                            fontSize: isWinner ? 10 : 8,
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${entry.rallyRhythmDays}',
                          style: _momentText(context).copyWith(
                            color: textColor,
                            fontSize: isWinner ? 18 : 15,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: pedestalHeight - (isWinner ? 18 : 12),
            child: CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              onPressed: () => _openRankingProfile(context, entry),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    ringAsset,
                    width: ringSize,
                    height: ringSize,
                    fit: BoxFit.contain,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _Avatar(
                      assetPath: entry.playerPortraitAsset,
                      size: avatarSize,
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
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.entries});

  final List<CourtRhythmStanding> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10131C).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.06),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 64,
                child: Text('Ranking', style: _rankingHeaderText(context)),
              ),
              Expanded(
                child: Text('Nickname', style: _rankingHeaderText(context)),
              ),
              SizedBox(
                width: 92,
                child: Text(
                  'Rhythm days',
                  textAlign: TextAlign.right,
                  style: _rankingHeaderText(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < entries.length; index++) ...[
            _RankingListRow(entry: entries[index]),
            if (index != entries.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ColoredBox(
                  color: CupertinoColors.white.withValues(alpha: 0.07),
                  child: const SizedBox(height: 1, width: double.infinity),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RankingListRow extends StatelessWidget {
  const _RankingListRow({required this.entry});

  final CourtRhythmStanding entry;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: () => _openRankingProfile(context, entry),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            SizedBox(
              width: 54,
              child: Text(
                entry.standingRank.toString().padLeft(2, '0'),
                style: _momentText(context).copyWith(
                  color: CupertinoColors.white.withValues(alpha: 0.48),
                  fontSize: 16,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _Avatar(assetPath: entry.playerPortraitAsset, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                entry.courtsideName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _momentText(context).copyWith(
                  color: CupertinoColors.white.withValues(alpha: 0.62),
                  fontSize: 15,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 58,
              child: Text(
                '${entry.rallyRhythmDays}',
                textAlign: TextAlign.right,
                style: _momentText(context).copyWith(
                  color: CupertinoColors.white.withValues(alpha: 0.58),
                  fontSize: 15,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _rankingHeaderText(BuildContext context) {
  return _momentText(context).copyWith(
    color: CupertinoColors.white.withValues(alpha: 0.62),
    fontSize: 12,
    height: 1,
    fontWeight: FontWeight.w700,
  );
}

void _openRankingProfile(BuildContext context, CourtRhythmStanding entry) {
  final profile = CourtlyRosterBook.fromCourtsideIdentity(
    courtsideName: entry.courtsideName,
    playerPortraitAsset: entry.playerPortraitAsset,
  );
  Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => CourtlyPlayerCardPage(
        profile: profile,
        videos: _profileSeedVideosFor(profile.playerHandle),
        moments: _profileSeedMomentsFor(profile.playerHandle),
        onOpenChat: (profile) {
          unawaited(openCourtsideRallyForCard(context, profile));
        },
      ),
    ),
  );
}

List<CourtlyProfileVideoItem> _profileSeedVideosFor(String playerHandle) {
  return CourtClipProgram.trainingClipDispatches
      .where((clip) => clip.playerHandle == playerHandle)
      .map(
        (clip) => CourtlyProfileVideoItem(
          clipId: clip.clipId,
          coverFrameAsset: clip.coverFrameAsset,
        ),
      )
      .toList(growable: false);
}

List<CourtlyProfileMomentItem> _profileSeedMomentsFor(String playerHandle) {
  return CourtMomentChronicle.openingCourtMoments
      .where((moment) => moment.playerHandle == playerHandle)
      .map(
        (moment) => CourtlyProfileMomentItem(
          momentId: moment.momentId,
          momentImageAsset: moment.momentImageAsset,
          courtNote: moment.courtNote,
        ),
      )
      .toList(growable: false);
}

class _MomentCommentRow extends StatelessWidget {
  const _MomentCommentRow({
    required this.comment,
    required this.avatarPath,
    required this.onOpenProfile,
    required this.onReport,
  });

  final CourtMomentReply comment;
  final String avatarPath;
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _momentPink.withValues(alpha: 0.86),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.5),
              child: _Avatar(assetPath: avatarPath, size: 32),
            ),
          ),
        ),
        const SizedBox(width: 12),
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
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              comment.courtsideName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _momentText(context).copyWith(
                                color: CupertinoColors.white,
                                fontSize: 14,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            comment.rallyClockLabel,
                            style: _momentText(context).copyWith(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.58,
                              ),
                              fontSize: 12,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CupertinoButton(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    onPressed: onReport,
                    child: SizedBox(
                      width: 22,
                      height: 24,
                      child: Icon(
                        CupertinoIcons.ellipsis_vertical,
                        color: CupertinoColors.white.withValues(alpha: 0.76),
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                comment.courtNote,
                style: _momentText(context).copyWith(
                  color: CupertinoColors.white.withValues(alpha: 0.84),
                  fontSize: 14,
                  height: 1.4,
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

class _MomentCommentComposer extends StatelessWidget {
  const _MomentCommentComposer({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF542686).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: controller,
                placeholder: 'Add a court reply',
                padding: const EdgeInsets.only(left: 22, right: 12),
                style: _momentText(context).copyWith(
                  color: CupertinoColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                placeholderStyle: _momentText(context).copyWith(
                  color: CupertinoColors.white.withValues(alpha: 0.38),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const BoxDecoration(),
                cursorColor: CupertinoColors.white,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
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
                  dimension: 48,
                  child: Center(
                    child: Image.asset(
                      'assets/images/courtly_singles.png',
                      width: 31,
                      height: 31,
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
      child: CourtlyProfileImage(
        imagePath: assetPath,
        width: size,
        height: size,
      ),
    );
  }
}

class _MomentImage extends StatelessWidget {
  const _MomentImage({
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

TextStyle _momentText(BuildContext context) {
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

String _momentDisplayTimeLabel(String label) {
  final cleanLabel = label.trim();
  final absoluteDate = RegExp(
    r'^\d{4}[/-]\d{1,2}[/-]\d{1,2}\s+(\d{1,2}:\d{2})',
  ).firstMatch(cleanLabel);
  if (absoluteDate != null) {
    return 'Today ${absoluteDate.group(1)}';
  }

  return cleanLabel;
}
