import 'dart:async';
import 'dart:io';

import 'package:courtly/features/club_chats/presentation/club_chats_view.dart';
import 'package:courtly/features/first_rally/data/rally_asset_ledger.dart';
import 'package:courtly/features/first_rally/data/rally_policy_links.dart';
import 'package:courtly/features/first_rally/data/rally_session_vault.dart';
import 'package:courtly/features/first_rally/domain/rally_entry_draft.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_policy_webview_page.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_signin_page.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_welcome_choice_page.dart';
import 'package:courtly/features/my_court/presentation/courtly_wallet_page.dart';
import 'package:courtly/shared/presentation/courtly_safe_layout.dart';
import 'package:courtly/shared/social/courtly_social_store.dart';
import 'package:courtly/shared/social/courtly_user_directory.dart';
import 'package:courtly/shared/wallet/courtly_wallet_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

const Color _courtPurple = Color(0xFF1A004D);
const Color _courtPurpleDeep = Color(0xFF120034);
const Color _courtPanel = Color(0xFF26005F);
const Color _courtPanelSoft = Color(0xFF56308A);
const Color _courtPink = Color(0xFFFF2DD2);
const Color _courtPinkSoft = Color(0xFFFF72DB);
const Color _courtGold = Color(0xFFFFC934);
const Color _courtWhite = Color(0xFFFFFFFF);

class MyCourtView extends StatefulWidget {
  const MyCourtView({super.key});

  @override
  State<MyCourtView> createState() => _MyCourtViewState();
}

class _MyCourtViewState extends State<MyCourtView> {
  final RallySessionVault _sessionVault = const RallySessionVault();
  final CourtlyWalletStore _walletStore = CourtlyWalletStore.instance;
  _MyCourtProfile _profile = _MyCourtProfile.defaults();
  _GalleryMode _galleryMode = _GalleryMode.videos;
  int _walletCoins = 0;
  List<CourtlyPublishedReel> _publishedReels = const [];
  List<CourtlyPublishedPost> _publishedPosts = const [];
  List<_CourtPerson> _fans = const [];
  List<_CourtPerson> _follows = const [];
  List<_CourtPerson> _friends = const [];

  @override
  void initState() {
    super.initState();
    CourtlySocialStore.instance.publishedContentVersion.addListener(
      _handlePublishedContentChanged,
    );
    CourtlySocialStore.instance.relationshipVersion.addListener(
      _handleRelationshipChanged,
    );
    _walletStore.balanceVersion.addListener(_handleWalletBalanceChanged);
    unawaited(_loadStoredProfile());
    unawaited(_loadRelationships());
    unawaited(_loadPublishedContent());
    unawaited(_loadWalletBalance());
  }

  @override
  void dispose() {
    CourtlySocialStore.instance.publishedContentVersion.removeListener(
      _handlePublishedContentChanged,
    );
    CourtlySocialStore.instance.relationshipVersion.removeListener(
      _handleRelationshipChanged,
    );
    _walletStore.balanceVersion.removeListener(_handleWalletBalanceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _MyCourtBackdrop(
        useProfileBackdrop: true,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 510,
                child: _ProfileHero(
                  profile: _profile,
                  walletCoins: _walletCoins,
                  onSettings: () => unawaited(_openSettings()),
                  onEdit: () => unawaited(_openEdit()),
                  onWallet: () => unawaited(_openWallet()),
                  onFans: () => unawaited(_openPeople(_PeopleListKind.fans)),
                  onFollows: () =>
                      unawaited(_openPeople(_PeopleListKind.follows)),
                  onFriends: () =>
                      unawaited(_openPeople(_PeopleListKind.friends)),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: _GalleryTabs(
                  selected: _galleryMode,
                  onChanged: (mode) => setState(() => _galleryMode = mode),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 126),
              sliver: _buildGallerySliver(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadStoredProfile() async {
    final session = await _sessionVault.readActiveSession();
    if (!mounted || session == null) {
      return;
    }

    setState(() {
      _profile = _profile.copyWith(
        name: session.displayNameSignal.trim().isEmpty
            ? _profile.name
            : session.displayNameSignal.trim(),
        country: session.countryCircuit.trim().isEmpty
            ? _profile.country
            : session.countryCircuit.trim(),
        signature: session.personalCourtline.trim().isEmpty
            ? _profile.signature
            : session.personalCourtline.trim(),
        birthdate: session.birthdateMarker,
        playStyleKey: session.playStyleKey,
        entryMethod: session.entryMethod,
        avatarImagePath: _usableProfileImagePath(session.avatarImagePath),
      );
    });
  }

  Future<void> _loadPublishedContent() async {
    final store = CourtlySocialStore.instance;
    final reels = await store.loadPublishedReels();
    final posts = await store.loadPublishedPosts();
    if (!mounted) {
      return;
    }

    setState(() {
      _publishedReels = reels;
      _publishedPosts = posts;
    });
  }

  Future<void> _loadWalletBalance() async {
    final balance = await _walletStore.loadBalance();
    if (!mounted) {
      return;
    }
    setState(() => _walletCoins = balance);
  }

  Future<void> _loadRelationships() async {
    final store = CourtlySocialStore.instance;
    await store.ensureLoginFollowerBoost();
    final blockedIds = await store.blockedUserIds();
    final followerIds = await store.followerUserIds();
    final followingIds = await store.followingUserIds();
    final followingSet = followingIds.toSet();
    final followerSet = followerIds.toSet();
    final fans = _courtPeopleForIds(
      followerIds,
      followingIds: followingSet,
      blockedIds: blockedIds,
    );
    final follows = _courtPeopleForIds(
      followingIds,
      followingIds: followingSet,
      blockedIds: blockedIds,
    );
    final friends = _courtPeopleForIds(
      followingIds.where(followerSet.contains),
      followingIds: followingSet,
      blockedIds: blockedIds,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _fans = fans;
      _follows = follows;
      _friends = friends;
      _profile = _profile.copyWith(
        fans: fans.length,
        follows: follows.length,
        friends: friends.length,
      );
    });
  }

  void _handleWalletBalanceChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_loadWalletBalance());
  }

  void _handleRelationshipChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_loadRelationships());
  }

  void _handlePublishedContentChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_loadPublishedContent());
  }

  Widget _buildGallerySliver() {
    if (_galleryMode == _GalleryMode.videos) {
      if (_publishedReels.isEmpty) {
        return const SliverToBoxAdapter(
          child: _GalleryEmptyState(
            title: 'No videos yet',
            message: 'Released court videos will appear here.',
          ),
        );
      }

      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return _VideoTile(reel: _publishedReels[index]);
        }, childCount: _publishedReels.length),
      );
    }

    if (_publishedPosts.isEmpty) {
      return const SliverToBoxAdapter(
        child: _GalleryEmptyState(
          title: 'No posts yet',
          message: 'Published court moments will appear here.',
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        childAspectRatio: 0.72,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        return _PostTile(post: _publishedPosts[index]);
      }, childCount: _publishedPosts.length),
    );
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).push<_MyCourtProfile>(
      CupertinoPageRoute<_MyCourtProfile>(
        builder: (_) => _MyCourtEditPage(profile: _profile),
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    setState(() => _profile = updated);
    await _persistProfile(updated);
  }

  Future<void> _persistProfile(_MyCourtProfile profile) {
    return _sessionVault.activateProfile(
      profileDraft: RallyProfileDraft(
        displayNameSignal: profile.name,
        countryCircuit: profile.country,
        personalCourtline: profile.signature,
        birthdateMarker: profile.birthdate,
        playStyleKey: profile.playStyleKey,
        avatarImagePath: profile.avatarImagePath,
      ),
      entryMethod: profile.entryMethod,
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(builder: (_) => const _MyCourtSettingsPage()),
    );
    if (mounted) {
      unawaited(_loadRelationships());
    }
  }

  Future<void> _openWallet() async {
    await Navigator.of(context).push<int>(
      CupertinoPageRoute<int>(builder: (_) => const CourtlyWalletPage()),
    );
    if (mounted) {
      unawaited(_loadWalletBalance());
    }
  }

  Future<void> _openPeople(_PeopleListKind kind) async {
    await _loadRelationships();
    if (!mounted) {
      return;
    }

    final people = switch (kind) {
      _PeopleListKind.blacklist => const <_CourtPerson>[],
      _PeopleListKind.fans => _fans,
      _PeopleListKind.follows => _follows,
      _PeopleListKind.friends => _friends,
    };

    await Navigator.of(context).push<List<_CourtPerson>>(
      CupertinoPageRoute<List<_CourtPerson>>(
        builder: (_) => _MyCourtPeoplePage(kind: kind, people: people),
      ),
    );

    if (mounted) {
      unawaited(_loadRelationships());
    }
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.walletCoins,
    required this.onSettings,
    required this.onEdit,
    required this.onWallet,
    required this.onFans,
    required this.onFollows,
    required this.onFriends,
  });

  final _MyCourtProfile profile;
  final int walletCoins;
  final VoidCallback onSettings;
  final VoidCallback onEdit;
  final VoidCallback onWallet;
  final VoidCallback onFans;
  final VoidCallback onFollows;
  final VoidCallback onFriends;

  @override
  Widget build(BuildContext context) {
    final profileImagePath = _usableProfileImagePath(profile.avatarImagePath);

    return Stack(
      fit: StackFit.expand,
      children: [
        _ProfileImage(path: profileImagePath),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _courtPurpleDeep.withValues(alpha: 0.12),
                _courtPurpleDeep.withValues(alpha: 0.04),
                _courtPurpleDeep.withValues(alpha: 0.72),
                _courtPurple.withValues(alpha: 0.98),
              ],
              stops: const [0, 0.45, 0.78, 1],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                CupertinoColors.black.withValues(alpha: 0.18),
                CupertinoColors.black.withValues(alpha: 0),
                CupertinoColors.black.withValues(alpha: 0.16),
              ],
            ),
          ),
        ),
        Positioned(
          left: 22,
          right: 22,
          top: courtlySafeTop(context, 10),
          child: Row(
            children: [
              Image.asset(
                'assets/images/Pickup.png',
                width: 148,
                height: 34,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
              const Spacer(),
              CupertinoButton(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                onPressed: onSettings,
                child: const SizedBox.square(
                  dimension: 42,
                  child: Icon(
                    CupertinoIcons.gear_solid,
                    color: _courtPink,
                    size: 27,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 22,
          right: 22,
          bottom: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                profile.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _myTextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _AgeTag(age: profile.age),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _StatButton(
                              value: profile.fans,
                              label: 'Fans',
                              onPressed: onFans,
                            ),
                            _StatButton(
                              value: profile.follows,
                              label: 'Follow',
                              onPressed: onFollows,
                            ),
                            _StatButton(
                              value: profile.friends,
                              label: 'Friends',
                              onPressed: onFriends,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    onPressed: onEdit,
                    child: Container(
                      width: 88,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _courtPink,
                        borderRadius: BorderRadius.circular(19),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55FF2DD2),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.pencil,
                            color: _courtWhite,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Edit',
                            style: _myTextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                profile.signature,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _myTextStyle(
                  color: _courtWhite.withValues(alpha: 0.82),
                  fontSize: 12,
                  height: 1.28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              CupertinoButton(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                onPressed: onWallet,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Image.asset(
                      'assets/images/Mixer.png',
                      width: double.infinity,
                      height: 54,
                      fit: BoxFit.fill,
                    ),
                    Positioned(
                      right: 52,
                      child: Text(
                        _formatCoins(walletCoins),
                        style: _myTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GalleryTabs extends StatelessWidget {
  const _GalleryTabs({required this.selected, required this.onChanged});

  final _GalleryMode selected;
  final ValueChanged<_GalleryMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GalleryTabButton(
          label: 'Videos',
          selected: selected == _GalleryMode.videos,
          onPressed: () => onChanged(_GalleryMode.videos),
        ),
        const SizedBox(width: 22),
        _GalleryTabButton(
          label: 'Post',
          selected: selected == _GalleryMode.posts,
          onPressed: () => onChanged(_GalleryMode.posts),
        ),
      ],
    );
  }
}

class _GalleryTabButton extends StatelessWidget {
  const _GalleryTabButton({
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
        style: _myTextStyle(
          color: selected ? _courtWhite : _courtWhite.withValues(alpha: 0.34),
          fontSize: 16,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _GalleryEmptyState extends StatelessWidget {
  const _GalleryEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
      decoration: BoxDecoration(
        color: _courtPanel.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _courtWhite.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _courtWhite.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.tray,
              color: _courtPinkSoft,
              size: 25,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: _myTextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: _myTextStyle(
              color: _courtWhite.withValues(alpha: 0.62),
              fontSize: 12,
              height: 1.28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.reel});

  final CourtlyPublishedReel reel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _VideoThumbnail(videoPath: reel.videoPath),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  CupertinoColors.black.withValues(alpha: 0.04),
                  CupertinoColors.black.withValues(alpha: 0.32),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _courtWhite.withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.play_fill,
                color: _courtPink,
                size: 18,
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Text(
              reel.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _myTextStyle(
                color: _courtWhite.withValues(alpha: 0.92),
                fontSize: 10,
                height: 1.16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  const _VideoThumbnail({required this.videoPath});

  final String videoPath;

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadController());
  }

  @override
  void didUpdateWidget(covariant _VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      unawaited(_loadController());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_ready || controller == null || !controller.value.isInitialized) {
      return const _MediaPlaceholder(icon: CupertinoIcons.video_camera_solid);
    }

    final size = controller.value.size;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(controller),
      ),
    );
  }

  Future<void> _loadController() async {
    final oldController = _controller;
    _controller = null;
    _ready = false;
    await oldController?.dispose();

    final path = widget.videoPath.trim();
    if (path.isEmpty) {
      if (mounted) {
        setState(() {});
      }
      return;
    }

    final controller = path.startsWith('assets/')
        ? VideoPlayerController.asset(path)
        : VideoPlayerController.file(File(path));

    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.pause();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() {});
      }
    }
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});

  final CourtlyPublishedPost post;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _MediaImage(path: post.imagePath),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  CupertinoColors.black.withValues(alpha: 0.02),
                  CupertinoColors.black.withValues(alpha: 0.42),
                ],
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Text(
              post.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _myTextStyle(
                color: _courtWhite.withValues(alpha: 0.92),
                fontSize: 10,
                height: 1.16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaImage extends StatelessWidget {
  const _MediaImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final imagePath = path.trim();
    if (imagePath.startsWith('assets/')) {
      return Image.asset(imagePath, fit: BoxFit.cover);
    }

    if (imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    return const _MediaPlaceholder(icon: CupertinoIcons.photo_fill);
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: _courtPanel),
      child: Center(child: Icon(icon, color: _courtPinkSoft, size: 28)),
    );
  }
}

class _MyCourtSettingsPage extends StatefulWidget {
  const _MyCourtSettingsPage();

  @override
  State<_MyCourtSettingsPage> createState() => _MyCourtSettingsPageState();
}

class _MyCourtSettingsPageState extends State<_MyCourtSettingsPage> {
  final RallySessionVault _sessionVault = const RallySessionVault();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _MyCourtBackdrop(
        child: Column(
          children: [
            _SimpleHeader(title: 'Setting', onBack: _close),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                children: [
                  _SettingRow(
                    icon: CupertinoIcons.person_crop_circle_badge_xmark,
                    title: 'Blacklist',
                    onPressed: () => unawaited(_openBlacklist()),
                  ),
                  _SettingRow(
                    icon: CupertinoIcons.doc_text_fill,
                    title: 'Privacy agreement',
                    onPressed: _openPrivacyPolicy,
                  ),
                  _SettingRow(
                    icon: CupertinoIcons.doc_plaintext,
                    title: 'User agreement',
                    onPressed: _openUserAgreement,
                  ),
                  _SettingRow(
                    icon: CupertinoIcons.doc_on_clipboard_fill,
                    title: 'Community guidelines',
                    onPressed: _openCommunityGuidelines,
                  ),
                  _SettingRow(
                    icon: CupertinoIcons.delete_solid,
                    title: 'Deletion of account',
                    destructive: true,
                    onPressed: () => unawaited(_confirmDeleteAccount()),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 0, 48, 80),
              child: CupertinoButton(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                onPressed: () => unawaited(_confirmLogout()),
                child: Image.asset(
                  'assets/images/Contact.png',
                  width: double.infinity,
                  height: 52,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBlacklist() async {
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        builder: (_) => const _MyCourtBlockedUsersPage(),
      ),
    );
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => RallyPolicyWebViewPage(
          title: 'Privacy Policy',
          policyUri: RallyPolicyLinks.privacyNotice,
        ),
      ),
    );
  }

  void _openUserAgreement() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => RallyPolicyWebViewPage(
          title: 'Terms of Service',
          policyUri: RallyPolicyLinks.serviceTerms,
        ),
      ),
    );
  }

  void _openCommunityGuidelines() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => const _CommunityGuidelinesPage(),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await _askForConfirmation(
      title: 'Log out?',
      message: 'You can sign back in from the opening screen.',
      action: 'Log Out',
      destructive: false,
    );

    if (!confirmed || !mounted) {
      return;
    }

    await _runAccountAction(
      loadingLabel: 'Logging out',
      successTitle: 'Logged out',
      successMessage: 'You have been signed out successfully.',
      action: _sessionVault.deactivateActiveSession,
      destination: _goToSignin,
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await _askForConfirmation(
      title: 'Delete account?',
      message: 'This clears your local Courtly profile from this device.',
      action: 'Delete',
      destructive: true,
    );

    if (!confirmed || !mounted) {
      return;
    }

    await _runAccountAction(
      loadingLabel: 'Deleting account',
      successTitle: 'Account deleted',
      successMessage: 'Your local Courtly account has been deleted.',
      action: _sessionVault.deleteLocalAccount,
      destination: _goToWelcome,
    );
  }

  Future<void> _runAccountAction({
    required String loadingLabel,
    required String successTitle,
    required String successMessage,
    required Future<void> Function() action,
    required VoidCallback destination,
  }) async {
    _showLoadingDialog(loadingLabel);
    await action();
    await Future<void>.delayed(const Duration(milliseconds: 620));
    if (!mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();

    await _showSuccessDialog(title: successTitle, message: successMessage);
    if (!mounted) {
      return;
    }

    destination();
  }

  Future<bool> _askForConfirmation({
    required String title,
    required String message,
    required String action,
    required bool destructive,
  }) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: destructive,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(action),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  void _goToWelcome() {
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute<void>(builder: (_) => const RallyWelcomeChoicePage()),
      (route) => false,
    );
  }

  void _goToSignin() {
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute<void>(builder: (_) => const RallySigninPage()),
      (route) => false,
    );
  }

  void _showLoadingDialog(String label) {
    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _AccountProgressDialog(label: label);
      },
    );
  }

  Future<void> _showSuccessDialog({
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

  void _close() {
    Navigator.of(context).pop();
  }
}

class _AccountProgressDialog extends StatelessWidget {
  const _AccountProgressDialog({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 210,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        decoration: BoxDecoration(
          color: _courtPurpleDeep.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _courtWhite.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(color: _courtWhite, radius: 14),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: _myTextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyCourtBlockedUsersPage extends StatefulWidget {
  const _MyCourtBlockedUsersPage();

  @override
  State<_MyCourtBlockedUsersPage> createState() =>
      _MyCourtBlockedUsersPageState();
}

class _MyCourtBlockedUsersPageState extends State<_MyCourtBlockedUsersPage> {
  List<CourtlyBlockedUser> _blockedUsers = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBlockedUsers());
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _MyCourtBackdrop(
        child: Column(
          children: [
            _SimpleHeader(
              title: 'Blacklist',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CupertinoActivityIndicator(color: _courtWhite),
                    )
                  : _blockedUsers.isEmpty
                  ? const _BlockedUsersEmptyState()
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                      itemCount: _blockedUsers.length,
                      itemBuilder: (context, index) {
                        final profile = _blockedUsers[index];
                        return _BlockedUserRow(
                          profile: profile,
                          onUnblock: () => unawaited(_unblock(profile.id)),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadBlockedUsers() async {
    final profiles = await CourtlySocialStore.instance.loadBlockedUsers();
    profiles.sort((left, right) => left.name.compareTo(right.name));
    if (!mounted) {
      return;
    }

    setState(() {
      _blockedUsers = profiles;
      _loading = false;
    });
  }

  Future<void> _unblock(String userId) async {
    await CourtlySocialStore.instance.unblockUser(userId);
    if (!mounted) {
      return;
    }

    setState(() {
      _blockedUsers = _blockedUsers
          .where((profile) => profile.id != userId)
          .toList(growable: false);
    });
  }
}

class _BlockedUserRow extends StatelessWidget {
  const _BlockedUserRow({required this.profile, required this.onUnblock});

  final CourtlyBlockedUser profile;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: _courtPanel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          _RoundAvatar(assetPath: profile.avatarAsset, size: 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _myTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Messages and posts from this player are hidden.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _myTextStyle(
                    color: _courtWhite.withValues(alpha: 0.62),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CupertinoButton(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            onPressed: onUnblock,
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: _courtWhite.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _courtWhite.withValues(alpha: 0.12)),
              ),
              child: Center(
                child: Text(
                  'Unblock',
                  style: _myTextStyle(
                    color: _courtWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedUsersEmptyState extends StatelessWidget {
  const _BlockedUsersEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 30, 18, 30),
        decoration: BoxDecoration(
          color: _courtPanel.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _courtWhite.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.person_crop_circle_badge_checkmark,
              color: _courtPinkSoft,
              size: 34,
            ),
            const SizedBox(height: 14),
            Text(
              'No blocked users',
              style: _myTextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              'Players you block from profiles or reports will appear here.',
              textAlign: TextAlign.center,
              style: _myTextStyle(
                color: _courtWhite.withValues(alpha: 0.62),
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyCourtEditPage extends StatefulWidget {
  const _MyCourtEditPage({required this.profile});

  final _MyCourtProfile profile;

  @override
  State<_MyCourtEditPage> createState() => _MyCourtEditPageState();
}

class _MyCourtEditPageState extends State<_MyCourtEditPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  late _MyCourtProfile _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.profile;
    _nameController.text = _draft.name;
    _countryController.text = _draft.country;
    _signatureController.text = _draft.signature;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _MyCourtBackdrop(
        child: Column(
          children: [
            _SimpleHeader(
              title: 'Edit',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 28),
                children: [
                  Center(
                    child: _EditAvatar(
                      avatarImagePath: _draft.avatarImagePath,
                      onPressed: () => unawaited(_pickAvatar()),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Please select gender',
                    style: _myTextStyle(
                      color: _courtWhite.withValues(alpha: 0.42),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _GenderChoice(
                          assetPath: 'assets/images/Story.png',
                          selected: _draft.playStyleKey == 'balanced',
                          onPressed: () => setState(
                            () => _draft = _draft.copyWith(
                              playStyleKey: 'balanced',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _GenderChoice(
                          assetPath: 'assets/images/Invite.png',
                          selected: _draft.playStyleKey == 'aggressive',
                          onPressed: () => setState(
                            () => _draft = _draft.copyWith(
                              playStyleKey: 'aggressive',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Basic information',
                    style: _myTextStyle(
                      color: _courtWhite.withValues(alpha: 0.42),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _EditField(
                    controller: _nameController,
                    placeholder: 'Please choose a nickname',
                    icon: CupertinoIcons.person_fill,
                  ),
                  const SizedBox(height: 12),
                  _EditField(
                    controller: _countryController,
                    placeholder: 'Please select a country',
                    icon: CupertinoIcons.location_solid,
                  ),
                  const SizedBox(height: 12),
                  _DateField(
                    date: _draft.birthdate,
                    onPressed: () => unawaited(_chooseBirthdate()),
                  ),
                  const SizedBox(height: 12),
                  _EditField(
                    controller: _signatureController,
                    placeholder: 'Please enter a personalized signature',
                    icon: CupertinoIcons.pencil,
                    minLines: 5,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 22),
                  CupertinoButton(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    onPressed: _save,
                    child: Image.asset(
                      'assets/images/Setpoint.png',
                      width: double.infinity,
                      height: 56,
                      fit: BoxFit.fill,
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

  Future<void> _pickAvatar() async {
    final source = await _chooseAvatarSource();
    if (source == null || !mounted) {
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1600,
      );
      if (image == null || !mounted) {
        return;
      }

      setState(() => _draft = _draft.copyWith(avatarImagePath: image.path));
    } catch (_) {
      if (!mounted) {
        return;
      }

      await _showAvatarNotice(
        title: 'Photo unavailable',
        message:
            'Courtly could not open this photo source. Check photo or camera permission and try again.',
      );
    }
  }

  Future<ImageSource?> _chooseAvatarSource() {
    return showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Update profile photo'),
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

  Future<void> _showAvatarNotice({
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

  Future<void> _chooseBirthdate() async {
    var nextDate = _draft.birthdate;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return Container(
          height: 302,
          color: _courtWhite,
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    const Spacer(),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _draft.birthdate,
                  minimumYear: 1950,
                  maximumYear: DateTime.now().year,
                  onDateTimeChanged: (value) => nextDate = value,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() => _draft = _draft.copyWith(birthdate: nextDate));
  }

  void _save() {
    final name = _nameController.text.trim();
    final country = _countryController.text.trim();
    final signature = _signatureController.text.trim();

    Navigator.of(context).pop(
      _draft.copyWith(
        name: name.isEmpty ? 'Courtly Player' : name,
        country: country.isEmpty ? 'Courtly Circuit' : country,
        signature: signature.isEmpty
            ? 'The racket catches the dusk wind, all worries fade with every hit'
            : signature,
      ),
    );
  }
}

class _MyCourtPeoplePage extends StatefulWidget {
  const _MyCourtPeoplePage({required this.kind, required this.people});

  final _PeopleListKind kind;
  final List<_CourtPerson> people;

  @override
  State<_MyCourtPeoplePage> createState() => _MyCourtPeoplePageState();
}

class _MyCourtPeoplePageState extends State<_MyCourtPeoplePage> {
  late List<_CourtPerson> _people;
  final Set<String> _busyPeople = {};

  @override
  void initState() {
    super.initState();
    _people = List<_CourtPerson>.of(widget.people);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _MyCourtBackdrop(
        child: Column(
          children: [
            _SimpleHeader(title: widget.kind.title, onBack: _close),
            Expanded(
              child: _people.isEmpty
                  ? const _EmptyPeopleState()
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                      itemCount: _people.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _people.length) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 76),
                            child: _InlineEmptyState(),
                          );
                        }

                        final person = _people[index];
                        return _PersonRow(
                          person: person,
                          kind: widget.kind,
                          onPrimary: () => unawaited(_handlePrimary(person)),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePrimary(_CourtPerson person) async {
    final index = _people.indexWhere((entry) => entry.id == person.id);
    if (index == -1) {
      return;
    }

    switch (widget.kind) {
      case _PeopleListKind.blacklist:
        await _runPersonAction(person.id, () async {
          await CourtlySocialStore.instance.unblockUser(person.id);
          if (!mounted) {
            return;
          }
          setState(() {
            _people.removeWhere((entry) => entry.id == person.id);
          });
        });
      case _PeopleListKind.fans:
        if (person.followed) {
          return;
        }
        await _runPersonAction(person.id, () async {
          await CourtlySocialStore.instance.followUserLocally(person.id);
          if (!mounted) {
            return;
          }
          setState(() {
            final nextIndex = _people.indexWhere(
              (entry) => entry.id == person.id,
            );
            if (nextIndex != -1) {
              _people[nextIndex] = person.copyWith(followed: true);
            }
          });
        });
      case _PeopleListKind.follows:
        await _runPersonAction(person.id, () async {
          await CourtlySocialStore.instance.unfollowUser(person.id);
          if (!mounted) {
            return;
          }
          setState(() {
            _people.removeWhere((entry) => entry.id == person.id);
          });
        });
      case _PeopleListKind.friends:
        unawaited(_openChat(person));
    }
  }

  Future<void> _runPersonAction(
    String personId,
    Future<void> Function() action,
  ) async {
    if (_busyPeople.contains(personId)) {
      return;
    }

    setState(() => _busyPeople.add(personId));
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busyPeople.remove(personId));
      }
    }
  }

  Future<void> _openChat(_CourtPerson person) {
    return openClubChatForProfile(
      context,
      CourtlyUserDirectory.fromIdentity(
        id: person.id,
        name: person.name,
        avatarAsset: person.avatarAsset,
        heroAsset: person.heroAsset,
      ),
    );
  }

  void _close() {
    Navigator.of(context).pop(_people);
  }
}

class _SimpleHeader extends StatelessWidget {
  const _SimpleHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, courtlySafeTop(context, 10), 14, 0),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            _HeaderIconButton(
              icon: CupertinoIcons.chevron_left,
              onPressed: onBack,
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _myTextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 42),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFFF2A2A) : _courtWhite;

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: CupertinoButton(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: _courtPanel.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: _myTextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: color.withValues(alpha: destructive ? 0.7 : 0.34),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityGuidelinesPage extends StatelessWidget {
  const _CommunityGuidelinesPage();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _MyCourtBackdrop(
        child: Column(
          children: [
            _SimpleHeader(
              title: 'Community guidelines',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
                children: const [
                  _GuidelineSection(
                    title: 'Courtly community standards',
                    body:
                        'Courtly is for real tennis moments, friendly match circles, practice clips, and respectful player connection. Keep every post, reel, message, profile, and comment suitable for a broad sports community.',
                  ),
                  _GuidelineSection(
                    title: 'Respect other players',
                    body:
                        'Do not harass, threaten, bully, shame, or target another person. Hate speech, slurs, degrading remarks, sexual harassment, stalking, impersonation, and attempts to intimidate other users are not allowed.',
                  ),
                  _GuidelineSection(
                    title: 'Share authentic court content',
                    body:
                        'Only upload photos, videos, captions, and comments that you have the right to share. Do not post misleading identity information, stolen media, private conversations, spam, scams, paid manipulation, or content that pretends to be another player.',
                  ),
                  _GuidelineSection(
                    title: 'Keep content safe and lawful',
                    body:
                        'Do not share nudity, sexually explicit material, sexual content involving minors, graphic violence, illegal activity, weapon threats, self-harm encouragement, dangerous challenges, or content that violates someone else\'s privacy or intellectual property.',
                  ),
                  _GuidelineSection(
                    title: 'Protect privacy',
                    body:
                        'Avoid posting another person\'s phone number, address, private location, payment details, identity documents, or sensitive personal information. Ask permission before posting identifiable images or videos of other players in private settings.',
                  ),
                  _GuidelineSection(
                    title: 'Use reporting and blocking',
                    body:
                        'If a post, video, profile, comment, or message feels unsafe, use Report or Block. Reports hide the content locally while review is pending. Blocking hides that player from your experience and can be reversed from Settings > Blacklist.',
                  ),
                  _GuidelineSection(
                    title: 'Moderation and enforcement',
                    body:
                        'Courtly may remove content, restrict features, suspend access, or delete accounts when community rules, safety requirements, platform policies, or applicable law are violated. Repeated or severe violations may lead to permanent removal.',
                  ),
                  _GuidelineSection(
                    title: 'Apple platform safety',
                    body:
                        'Courtly provides user reporting, blocking, and moderation pathways for user-generated content. Help keep the app safe by reporting abusive material, respecting consent, and keeping all shared content appropriate for the App Store audience.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidelineSection extends StatelessWidget {
  const _GuidelineSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: _courtPanel.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _courtWhite.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _myTextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: _myTextStyle(
              color: _courtWhite.withValues(alpha: 0.78),
              fontSize: 12,
              height: 1.38,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.person,
    required this.kind,
    required this.onPrimary,
  });

  final _CourtPerson person;
  final _PeopleListKind kind;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: kind == _PeopleListKind.friends ? onPrimary : null,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: _courtPanel.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            _RoundAvatar(assetPath: person.avatarAsset, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          person.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _myTextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      _AgePill(ageLabel: person.ageLabel),
                      const SizedBox(width: 5),
                      Text(
                        person.country,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _myTextStyle(
                          color: _courtWhite.withValues(alpha: 0.72),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    person.motto,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _myTextStyle(
                      color: _courtWhite.withValues(alpha: 0.76),
                      fontSize: 10,
                      height: 1.18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _PersonActionButton(
              kind: kind,
              person: person,
              onPressed: onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonActionButton extends StatelessWidget {
  const _PersonActionButton({
    required this.kind,
    required this.person,
    required this.onPressed,
  });

  final _PeopleListKind kind;
  final _CourtPerson person;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (kind == _PeopleListKind.friends) {
      return CupertinoButton(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Image.asset(
          'assets/images/Roster.png',
          width: 84,
          height: 30,
          fit: BoxFit.contain,
        ),
      );
    }

    final isDelete = kind == _PeopleListKind.blacklist;
    final isUnfollow = kind == _PeopleListKind.follows;
    final label = isDelete
        ? 'Delete'
        : isUnfollow
        ? 'Unfollow'
        : (person.followed ? 'Followed' : 'Follow');

    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 28,
        width: isDelete || isUnfollow ? 86 : 82,
        decoration: BoxDecoration(
          color: isDelete
              ? _courtPink.withValues(alpha: 0.84)
              : isUnfollow
              ? _courtWhite.withValues(alpha: 0.16)
              : (person.followed
                    ? _courtWhite.withValues(alpha: 0.22)
                    : _courtPink),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDelete
                  ? CupertinoIcons.delete_solid
                  : isUnfollow
                  ? CupertinoIcons.minus_circle_fill
                  : CupertinoIcons.star_fill,
              color: _courtWhite,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _myTextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPeopleState extends StatelessWidget {
  const _EmptyPeopleState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: _InlineEmptyState());
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/Love.png',
          width: 196,
          height: 196,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

class _EditAvatar extends StatelessWidget {
  const _EditAvatar({required this.avatarImagePath, required this.onPressed});

  final String? avatarImagePath;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: SizedBox(
        width: 156,
        height: 156,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _courtPink.withValues(alpha: 0.85),
                      _courtGold.withValues(alpha: 0.55),
                      _courtWhite.withValues(alpha: 0.12),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _courtPink.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ProfileImage(path: avatarImagePath),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _courtPurpleDeep.withValues(alpha: 0.08),
                              _courtPurpleDeep.withValues(alpha: 0.28),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: _courtPurpleDeep.withValues(alpha: 0.52),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _courtWhite.withValues(alpha: 0.22),
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.camera_fill,
                            color: _courtWhite,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _courtPink,
                  shape: BoxShape.circle,
                  border: Border.all(color: _courtPurpleDeep, width: 4),
                ),
                child: const Icon(
                  CupertinoIcons.plus,
                  color: _courtWhite,
                  size: 23,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: _courtPurpleDeep.withValues(alpha: 0.56),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Profile photo',
                    style: _myTextStyle(
                      color: _courtWhite.withValues(alpha: 0.82),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _courtWhite.withValues(alpha: 0.12),
                    width: 1,
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

class _GenderChoice extends StatelessWidget {
  const _GenderChoice({
    required this.assetPath,
    required this.selected,
    required this.onPressed,
  });

  final String assetPath;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          color: _courtPanelSoft.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? _courtGold : _courtWhite.withValues(alpha: 0.1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: 66,
            height: 66,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final isTall = maxLines > 1;

    return Container(
      constraints: BoxConstraints(minHeight: isTall ? 112 : 52),
      decoration: BoxDecoration(
        color: _courtPanelSoft.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(26),
      ),
      padding: EdgeInsets.fromLTRB(16, isTall ? 12 : 0, 16, isTall ? 12 : 0),
      child: Row(
        crossAxisAlignment: isTall
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: isTall ? 4 : 0),
            child: Icon(
              icon,
              color: _courtWhite.withValues(alpha: 0.36),
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoTextField.borderless(
              controller: controller,
              padding: EdgeInsets.zero,
              placeholder: placeholder,
              placeholderStyle: _myTextStyle(
                color: _courtWhite.withValues(alpha: 0.36),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              style: _myTextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              minLines: minLines,
              maxLines: maxLines,
              cursorColor: _courtPink,
              textInputAction: isTall
                  ? TextInputAction.newline
                  : TextInputAction.next,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onPressed});

  final DateTime date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _courtPanelSoft.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(26),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.calendar,
              color: _courtWhite.withValues(alpha: 0.36),
              size: 17,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatDate(date),
                style: _myTextStyle(
                  color: _courtWhite.withValues(alpha: 0.76),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: _courtWhite,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeTag extends StatelessWidget {
  const _AgeTag({required this.age});

  final int age;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 19,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: _courtPinkSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          age.toString(),
          style: _myTextStyle(fontSize: 10, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _AgePill extends StatelessWidget {
  const _AgePill({required this.ageLabel});

  final String ageLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _courtPinkSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: Text(
          ageLabel,
          style: _myTextStyle(fontSize: 9, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _StatButton extends StatelessWidget {
  const _StatButton({
    required this.value,
    required this.label,
    required this.onPressed,
  });

  final int value;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: const EdgeInsets.only(right: 8),
      onPressed: onPressed,
      child: Text(
        '$value $label',
        style: _myTextStyle(
          color: _courtWhite.withValues(alpha: 0.64),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoundAvatar extends StatelessWidget {
  const _RoundAvatar({required this.assetPath, required this.size});

  final String? assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imagePath = assetPath?.trim();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _courtWhite.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _roundAvatarChild(imagePath),
    );
  }

  Widget _roundAvatarChild(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const _RoundAvatarPlaceholder();
    }
    if (imagePath.startsWith('assets/')) {
      return Image.asset(imagePath, fit: BoxFit.cover);
    }

    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }

    return const _RoundAvatarPlaceholder();
  }
}

class _RoundAvatarPlaceholder extends StatelessWidget {
  const _RoundAvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _courtWhite.withValues(alpha: 0.12),
      child: const Center(
        child: Icon(
          CupertinoIcons.person_crop_circle,
          color: _courtWhite,
          size: 28,
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: SizedBox.square(
        dimension: 42,
        child: Icon(icon, color: _courtWhite, size: 22),
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final imagePath = _usableProfileImagePath(path);
    if (imagePath != null && imagePath.startsWith('assets/')) {
      return Image.asset(imagePath, fit: BoxFit.cover);
    }
    if (imagePath != null) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    return const _ProfilePlaceholder();
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_courtPanelSoft.withValues(alpha: 0.95), _courtPurpleDeep],
        ),
      ),
      child: Center(
        child: Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: _courtWhite.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: _courtWhite.withValues(alpha: 0.18)),
          ),
          child: const Icon(
            CupertinoIcons.person_crop_circle,
            color: _courtWhite,
            size: 58,
          ),
        ),
      ),
    );
  }
}

class _MyCourtBackdrop extends StatelessWidget {
  const _MyCourtBackdrop({
    required this.child,
    this.useProfileBackdrop = false,
    this.useWalletBackdrop = false,
  });

  final Widget child;
  final bool useProfileBackdrop;
  final bool useWalletBackdrop;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          useWalletBackdrop
              ? 'assets/images/Tournament.png'
              : 'assets/images/Swing.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        if (!useProfileBackdrop)
          DecoratedBox(
            decoration: BoxDecoration(
              color: _courtPurple.withValues(
                alpha: useWalletBackdrop ? 0.08 : 0.12,
              ),
            ),
          ),
        if (useProfileBackdrop)
          Positioned.fill(
            top: 310,
            child: ColoredBox(color: _courtPurple.withValues(alpha: 0.96)),
          ),
        child,
      ],
    );
  }
}

class _MyCourtProfile {
  const _MyCourtProfile({
    required this.name,
    required this.country,
    required this.signature,
    required this.birthdate,
    required this.playStyleKey,
    required this.entryMethod,
    required this.fans,
    required this.follows,
    required this.friends,
    this.avatarImagePath,
  });

  final String name;
  final String country;
  final String signature;
  final DateTime birthdate;
  final String playStyleKey;
  final String entryMethod;
  final int fans;
  final int follows;
  final int friends;
  final String? avatarImagePath;

  int get age {
    final now = DateTime.now();
    var years = now.year - birthdate.year;
    if (DateTime(now.year, birthdate.month, birthdate.day).isAfter(now)) {
      years -= 1;
    }
    return years.clamp(18, 99);
  }

  static _MyCourtProfile defaults() {
    return _MyCourtProfile(
      name: 'Bettie Norton',
      country: 'Colombia',
      signature:
          'The racket catches the dusk wind, all worries fade with every hit',
      birthdate: DateTime(2000, 6, 23),
      playStyleKey: 'balanced',
      entryMethod: 'local',
      fans: 0,
      follows: 0,
      friends: 0,
    );
  }

  _MyCourtProfile copyWith({
    String? name,
    String? country,
    String? signature,
    DateTime? birthdate,
    String? playStyleKey,
    String? entryMethod,
    int? fans,
    int? follows,
    int? friends,
    String? avatarImagePath,
  }) {
    return _MyCourtProfile(
      name: name ?? this.name,
      country: country ?? this.country,
      signature: signature ?? this.signature,
      birthdate: birthdate ?? this.birthdate,
      playStyleKey: playStyleKey ?? this.playStyleKey,
      entryMethod: entryMethod ?? this.entryMethod,
      fans: fans ?? this.fans,
      follows: follows ?? this.follows,
      friends: friends ?? this.friends,
      avatarImagePath: avatarImagePath ?? this.avatarImagePath,
    );
  }
}

class _CourtPerson {
  const _CourtPerson({
    required this.id,
    required this.name,
    required this.ageLabel,
    required this.country,
    required this.avatarAsset,
    required this.heroAsset,
    required this.motto,
    required this.followed,
  });

  final String id;
  final String name;
  final String ageLabel;
  final String country;
  final String avatarAsset;
  final String heroAsset;
  final String motto;
  final bool followed;

  _CourtPerson copyWith({bool? followed}) {
    return _CourtPerson(
      id: id,
      name: name,
      ageLabel: ageLabel,
      country: country,
      avatarAsset: avatarAsset,
      heroAsset: heroAsset,
      motto: motto,
      followed: followed ?? this.followed,
    );
  }
}

List<_CourtPerson> _courtPeopleForIds(
  Iterable<String> userIds, {
  required Set<String> followingIds,
  required Set<String> blockedIds,
}) {
  final seen = <String>{};
  final people = <_CourtPerson>[];

  for (final userId in userIds) {
    if (userId.trim().isEmpty ||
        blockedIds.contains(userId) ||
        !seen.add(userId)) {
      continue;
    }

    final profile = CourtlyUserDirectory.byId(userId);
    people.add(
      _CourtPerson(
        id: profile.id,
        name: profile.name,
        ageLabel: profile.ageLabel,
        country: profile.genderLabel,
        avatarAsset: profile.avatarAsset,
        heroAsset: profile.heroAsset,
        motto: profile.bio,
        followed: followingIds.contains(userId),
      ),
    );
  }

  return people..sort((left, right) => left.name.compareTo(right.name));
}

enum _GalleryMode { videos, posts }

enum _PeopleListKind {
  blacklist,
  fans,
  follows,
  friends;

  String get title {
    return switch (this) {
      _PeopleListKind.blacklist => 'Blacklist',
      _PeopleListKind.fans => 'Fans',
      _PeopleListKind.follows => 'Follow',
      _PeopleListKind.friends => 'Friends',
    };
  }
}

String? _usableProfileImagePath(String? path) {
  final imagePath = path?.trim();
  if (imagePath == null ||
      imagePath.isEmpty ||
      imagePath == RallyAssetLedger.spotlightMark ||
      imagePath.startsWith('assets/images/head/')) {
    return null;
  }

  return imagePath;
}

String _formatCoins(int coins) {
  final text = coins.toString();
  if (text.length <= 3) {
    return text;
  }

  final head = text.substring(0, text.length - 3);
  final tail = text.substring(text.length - 3);
  return '$head,$tail';
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year  $month  $day';
}

TextStyle _myTextStyle({
  Color color = _courtWhite,
  double fontSize = 14,
  double? height,
  FontWeight fontWeight = FontWeight.w600,
  FontStyle fontStyle = FontStyle.normal,
}) {
  return TextStyle(
    color: color,
    fontSize: fontSize,
    height: height,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );
}
