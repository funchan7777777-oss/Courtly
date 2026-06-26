import 'dart:async';

import 'package:courtly/atelier/theme/courtly_font_families.dart';
import 'package:courtly/shared/presentation/courtly_profile_image.dart';
import 'package:courtly/shared/presentation/courtly_safe_layout.dart';
import 'package:courtly/shared/social/courtly_moderation.dart';
import 'package:courtly/shared/social/courtly_social_store.dart';
import 'package:courtly/shared/social/courtly_player_card.dart';
import 'package:flutter/cupertino.dart';

class CourtlyPlayerCardPage extends StatefulWidget {
  const CourtlyPlayerCardPage({
    required this.profile,
    this.videos = const [],
    this.moments = const [],
    this.onOpenChat,
    this.onModerated,
    this.onRelationshipChanged,
    super.key,
  });

  final CourtlyPlayerCard profile;
  final List<CourtlyProfileVideoItem> videos;
  final List<CourtlyProfileMomentItem> moments;
  final ValueChanged<CourtlyPlayerCard>? onOpenChat;
  final ValueChanged<CourtlyModerationResult>? onModerated;
  final VoidCallback? onRelationshipChanged;

  @override
  State<CourtlyPlayerCardPage> createState() => _CourtlyPlayerCardPageState();
}

class _CourtlyPlayerCardPageState extends State<CourtlyPlayerCardPage> {
  int _selectedTab = 0;
  bool _requestedFollow = false;
  bool _following = false;

  @override
  void initState() {
    super.initState();
    CourtlySocialStore.instance.relationshipVersion.addListener(
      _handleRelationshipChanged,
    );
    unawaited(_loadRelationship());
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
    final profile = widget.profile;

    return CupertinoPageScaffold(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CourtlyProfileImage(
            imagePath: profile.playerPortraitAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x11000000),
                  Color(0x771A004D),
                  Color(0xFF1A004D),
                ],
                stops: [0, 0.47, 1],
              ),
            ),
          ),
          Positioned(
            top: courtlySafeTop(context, 8),
            left: 12,
            child: _RoundProfileButton(
              icon: CupertinoIcons.chevron_left,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: courtlySafeTop(context, 8),
            right: 16,
            child: _RoundProfileButton(
              icon: CupertinoIcons.ellipsis,
              onPressed: _openModeration,
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            top: courtlySafeTop(context, 340),
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _ProfileIdentity(profile: profile)),
                    const SizedBox(width: 12),
                    _ProfileFollowButton(
                      requested: _requestedFollow,
                      following: _following,
                      onPressed: _requestFollow,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _ProfileBio(profile: profile)),
                    const SizedBox(width: 12),
                    _ChatButton(onPressed: _openChat),
                  ],
                ),
                const SizedBox(height: 18),
                _ProfileTabs(
                  selectedIndex: _selectedTab,
                  onChanged: (index) => setState(() => _selectedTab = index),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _selectedTab == 0
                      ? _ProfileVideoGrid(videos: widget.videos)
                      : _ProfileMomentList(moments: widget.moments),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadRelationship() async {
    final store = CourtlySocialStore.instance;
    final requested = await store.hasRequestedFollow(
      widget.profile.playerHandle,
    );
    final following = await store.isFollowing(widget.profile.playerHandle);
    if (!mounted) {
      return;
    }
    setState(() {
      _requestedFollow = requested;
      _following = following;
    });
  }

  void _handleRelationshipChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_loadRelationship());
  }

  Future<void> _requestFollow() async {
    if (_requestedFollow || _following) {
      return;
    }

    await CourtlySocialStore.instance.requestFollow(
      widget.profile.playerHandle,
    );
    if (!mounted) {
      return;
    }
    setState(() => _requestedFollow = true);
    widget.onRelationshipChanged?.call();
    await showCourtlyActionSuccess(
      context: context,
      title: 'Request sent',
      message:
          'Chat unlocks only after both players follow each other. No automatic mutual follow was created.',
    );
  }

  void _openChat() {
    widget.onOpenChat?.call(widget.profile);
  }

  Future<void> _openModeration() async {
    final result = await showCourtlyModerationSheet(
      context: context,
      targetId: 'player:${widget.profile.playerHandle}',
      targetType: 'player',
      title: widget.profile.courtsideName,
      playerHandle: widget.profile.playerHandle,
      summary: widget.profile.courtBio,
      playerPortraitAsset: widget.profile.playerPortraitAsset,
    );
    if (result == null || !mounted) {
      return;
    }

    widget.onModerated?.call(result);
    if (result.action == CourtlyModerationAction.block) {
      await showCourtlyActionSuccess(
        context: context,
        title: 'Player blocked',
        message:
            'This player and their content will no longer appear in your court.',
      );
      if (mounted) {
        Navigator.of(context).pop(result);
      }
      return;
    }

    await showCourtlyActionSuccess(
      context: context,
      title: 'Report sent',
      message: 'Thanks. This report was saved and the content was hidden.',
    );
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }
}

class CourtlyProfileVideoItem {
  const CourtlyProfileVideoItem({
    required this.clipId,
    required this.coverFrameAsset,
  });

  final String clipId;
  final String coverFrameAsset;
}

class CourtlyProfileMomentItem {
  const CourtlyProfileMomentItem({
    required this.momentId,
    required this.momentImageAsset,
    required this.courtNote,
  });

  final String momentId;
  final String momentImageAsset;
  final String courtNote;
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.profile});

  final CourtlyPlayerCard profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          profile.courtsideName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _profileTextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _ProfilePill(label: profile.divisionLabel),
            const SizedBox(width: 6),
            _ProfilePill(label: profile.ageBandLabel),
          ],
        ),
      ],
    );
  }
}

class _ProfileBio extends StatelessWidget {
  const _ProfileBio({required this.profile});

  final CourtlyPlayerCard profile;

  @override
  Widget build(BuildContext context) {
    return Text(
      profile.courtBio,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: _profileTextStyle(
        color: CupertinoColors.white.withValues(alpha: 0.84),
        fontSize: 13,
        height: 1.32,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFF70C8).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: _profileTextStyle(fontSize: 11, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _ProfileFollowButton extends StatelessWidget {
  const _ProfileFollowButton({
    required this.requested,
    required this.following,
    required this.onPressed,
  });

  final bool requested;
  final bool following;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = following
        ? 'Following'
        : requested
        ? 'Pending'
        : 'Follow';

    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: requested
              ? CupertinoColors.white.withValues(alpha: 0.2)
              : const Color(0xFFFF2DD2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.12),
          ),
          boxShadow: requested
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x55FF2DD2),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.star_fill,
              color: CupertinoColors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: _profileTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  const _ChatButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 54,
        height: 40,
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          CupertinoIcons.chat_bubble_2_fill,
          color: Color(0xFFFF2DD2),
          size: 22,
        ),
      ),
    );
  }
}

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProfileTab(
          label: 'Videos',
          selected: selectedIndex == 0,
          onPressed: () => onChanged(0),
        ),
        const SizedBox(width: 28),
        _ProfileTab(
          label: 'Moments',
          selected: selectedIndex == 1,
          onPressed: () => onChanged(1),
        ),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Text(
        label,
        style: _profileTextStyle(
          color: selected
              ? CupertinoColors.white
              : CupertinoColors.white.withValues(alpha: 0.4),
          fontSize: 17,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _ProfileVideoGrid extends StatelessWidget {
  const _ProfileVideoGrid({required this.videos});

  final List<CourtlyProfileVideoItem> videos;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const _ProfileEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.78,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                videos[index].coverFrameAsset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withValues(alpha: 0.32),
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

class _ProfileMomentList extends StatelessWidget {
  const _ProfileMomentList({required this.moments});

  final List<CourtlyProfileMomentItem> moments;

  @override
  Widget build(BuildContext context) {
    if (moments.isEmpty) {
      return const _ProfileEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: moments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final moment = moments[index];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF25005A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  moment.momentImageAsset,
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  moment.courtNote,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: _profileTextStyle(
                    color: CupertinoColors.white.withValues(alpha: 0.84),
                    fontSize: 13,
                    height: 1.35,
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

class _ProfileEmptyState extends StatelessWidget {
  const _ProfileEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/courtly_love.png',
        width: 180,
        height: 180,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _RoundProfileButton extends StatelessWidget {
  const _RoundProfileButton({required this.icon, required this.onPressed});

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
          color: CupertinoColors.black.withValues(alpha: 0.24),
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

TextStyle _profileTextStyle({
  Color color = CupertinoColors.white,
  double fontSize = 14,
  double height = 1.1,
  FontWeight fontWeight = FontWeight.w700,
  FontStyle? fontStyle,
}) {
  return TextStyle(
    color: color,
    fontFamily: CourtlyFontFamilies.ui,
    fontSize: fontSize,
    height: height,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );
}
