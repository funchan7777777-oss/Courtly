import 'dart:async';
import 'dart:io';

import 'package:courtly/features/club_chats/domain/club_chat.dart';
import 'package:courtly/features/club_chats/presentation/club_chats_view.dart';
import 'package:courtly/features/first_rally/data/rally_session_vault.dart';
import 'package:courtly/features/first_rally/domain/rally_entry_draft.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_welcome_choice_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

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
  _MyCourtProfile _profile = _MyCourtProfile.defaults();
  _GalleryMode _galleryMode = _GalleryMode.videos;
  int _walletCoins = 1231;

  List<_CourtPerson> _blacklist = _CourtPersonSeed.blacklist();
  List<_CourtPerson> _fans = _CourtPersonSeed.fans();
  List<_CourtPerson> _follows = _CourtPersonSeed.follows();
  List<_CourtPerson> _friends = _CourtPersonSeed.friends();

  @override
  void initState() {
    super.initState();
    unawaited(_loadStoredProfile());
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
                height: 354,
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
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                child: _GalleryTabs(
                  selected: _galleryMode,
                  onChanged: (mode) => setState(() => _galleryMode = mode),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 126),
              sliver: _galleryMode == _GalleryMode.videos
                  ? SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            childAspectRatio: 0.72,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return _VideoTile(assetPath: _videoAssets[index]);
                      }, childCount: _videoAssets.length),
                    )
                  : SliverList.separated(
                      itemCount: _postNotes.length,
                      itemBuilder: (context, index) {
                        return _PostNoteTile(note: _postNotes[index]);
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                    ),
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
        avatarImagePath: session.avatarImagePath,
      );
    });
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
    final updatedBlacklist = await Navigator.of(context)
        .push<List<_CourtPerson>>(
          CupertinoPageRoute<List<_CourtPerson>>(
            builder: (_) => _MyCourtSettingsPage(blacklist: _blacklist),
          ),
        );

    if (updatedBlacklist == null || !mounted) {
      return;
    }

    setState(() => _blacklist = updatedBlacklist);
  }

  Future<void> _openWallet() async {
    final nextBalance = await Navigator.of(context).push<int>(
      CupertinoPageRoute<int>(
        builder: (_) => _MyCourtWalletPage(initialCoins: _walletCoins),
      ),
    );

    if (nextBalance == null || !mounted) {
      return;
    }

    setState(() => _walletCoins = nextBalance);
  }

  Future<void> _openPeople(_PeopleListKind kind) async {
    final people = switch (kind) {
      _PeopleListKind.blacklist => _blacklist,
      _PeopleListKind.fans => _fans,
      _PeopleListKind.follows => _follows,
      _PeopleListKind.friends => _friends,
    };

    final updated = await Navigator.of(context).push<List<_CourtPerson>>(
      CupertinoPageRoute<List<_CourtPerson>>(
        builder: (_) => _MyCourtPeoplePage(kind: kind, people: people),
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    setState(() {
      switch (kind) {
        case _PeopleListKind.blacklist:
          _blacklist = updated;
        case _PeopleListKind.fans:
          _fans = updated;
        case _PeopleListKind.follows:
          _follows = updated;
        case _PeopleListKind.friends:
          _friends = updated;
      }
    });
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/Forehand.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _courtPurpleDeep.withValues(alpha: 0.18),
                _courtPurpleDeep.withValues(alpha: 0.08),
                _courtPurple.withValues(alpha: 0.98),
              ],
            ),
          ),
        ),
        Positioned(
          left: 22,
          right: 22,
          top: 44,
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
                child: Image.asset(
                  'assets/images/Draw.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 22,
          right: 22,
          bottom: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
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
                    child: Image.asset(
                      'assets/images/Bounce.png',
                      width: 88,
                      height: 38,
                      fit: BoxFit.contain,
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

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(assetPath, fit: BoxFit.cover),
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
        ],
      ),
    );
  }
}

class _PostNoteTile extends StatelessWidget {
  const _PostNoteTile({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: _courtPanel.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        note,
        style: _myTextStyle(
          color: _courtWhite.withValues(alpha: 0.82),
          fontSize: 13,
          height: 1.32,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MyCourtSettingsPage extends StatefulWidget {
  const _MyCourtSettingsPage({required this.blacklist});

  final List<_CourtPerson> blacklist;

  @override
  State<_MyCourtSettingsPage> createState() => _MyCourtSettingsPageState();
}

class _MyCourtSettingsPageState extends State<_MyCourtSettingsPage> {
  final RallySessionVault _sessionVault = const RallySessionVault();
  late List<_CourtPerson> _blacklist;

  @override
  void initState() {
    super.initState();
    _blacklist = List<_CourtPerson>.of(widget.blacklist);
  }

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
                    onPressed: () => _openPolicy('Privacy agreement'),
                  ),
                  _SettingRow(
                    icon: CupertinoIcons.doc_plaintext,
                    title: 'User agreement',
                    onPressed: () => _openPolicy('User agreement'),
                  ),
                  _SettingRow(
                    icon: CupertinoIcons.phone_fill,
                    title: 'Contact Us',
                    onPressed: _showContactSheet,
                  ),
                  _SettingRow(
                    icon: CupertinoIcons.doc_on_clipboard_fill,
                    title: 'Community guidelines',
                    onPressed: () => _openPolicy('Community guidelines'),
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
    final updated = await Navigator.of(context).push<List<_CourtPerson>>(
      CupertinoPageRoute<List<_CourtPerson>>(
        builder: (_) => _MyCourtPeoplePage(
          kind: _PeopleListKind.blacklist,
          people: _blacklist,
        ),
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    setState(() => _blacklist = updated);
  }

  void _openPolicy(String title) {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute<void>(builder: (_) => _PolicyPage(title: title)));
  }

  Future<void> _showContactSheet() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Contact Us'),
          message: const Text('courtly-support@example.com'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Copy support email'),
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

    await _sessionVault.deactivateActiveSession();
    if (!mounted) {
      return;
    }

    _goToWelcome();
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

    await _sessionVault.deleteLocalAccount();
    if (!mounted) {
      return;
    }

    _goToWelcome();
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

  void _close() {
    Navigator.of(context).pop(_blacklist);
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
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 20),
                  Text(
                    'Please fill in the basic information',
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
                  const SizedBox(height: 24),
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
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) {
      return;
    }

    setState(() => _draft = _draft.copyWith(avatarImagePath: image.path));
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
                          onPrimary: () => _handlePrimary(person),
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

  void _handlePrimary(_CourtPerson person) {
    final index = _people.indexWhere((entry) => entry.id == person.id);
    if (index == -1) {
      return;
    }

    switch (widget.kind) {
      case _PeopleListKind.blacklist:
        setState(() => _people.removeAt(index));
      case _PeopleListKind.fans:
        setState(() {
          _people[index] = person.copyWith(followed: !person.followed);
        });
      case _PeopleListKind.follows:
        setState(() {
          _people[index] = person.copyWith(followed: !person.followed);
        });
      case _PeopleListKind.friends:
        unawaited(_openChat(person));
    }
  }

  Future<void> _openChat(_CourtPerson person) {
    return Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        builder: (_) => ClubChatThreadPage(
          conversation: ClubConversation(
            id: '${person.id}-friend-chat',
            playerName: person.name,
            ageLabel: person.ageLabel,
            avatarAsset: person.avatarAsset,
            heroAsset: person.heroAsset,
            online: true,
            unreadCount: 0,
            lastTimeLabel: 'Now',
            messages: [
              ClubChatMessage(
                id: '${person.id}-hello',
                senderName: person.name,
                body: 'Ready to plan our next court session?',
                timeLabel: 'Now',
                isMine: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _close() {
    Navigator.of(context).pop(_people);
  }
}

class _MyCourtWalletPage extends StatefulWidget {
  const _MyCourtWalletPage({required this.initialCoins});

  final int initialCoins;

  @override
  State<_MyCourtWalletPage> createState() => _MyCourtWalletPageState();
}

class _MyCourtWalletPageState extends State<_MyCourtWalletPage> {
  late int _coins;

  @override
  void initState() {
    super.initState();
    _coins = widget.initialCoins;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _MyCourtBackdrop(
        useWalletBackdrop: true,
        child: Column(
          children: [
            _SimpleHeader(
              title: 'Wallet',
              onBack: () => Navigator.of(context).pop(_coins),
            ),
            const SizedBox(height: 34),
            Image.asset(
              'assets/images/Clinic.png',
              width: 172,
              height: 172,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              _formatCoins(_coins),
              style: _myTextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            Text(
              'balance',
              style: _myTextStyle(
                color: _courtWhite.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _WalletPackRow(
                coins: 1231,
                price: r'$9.99',
                onPressed: _buyPack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _buyPack() {
    setState(() => _coins += 1231);
  }
}

class _WalletPackRow extends StatelessWidget {
  const _WalletPackRow({
    required this.coins,
    required this.price,
    required this.onPressed,
  });

  final int coins;
  final String price;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: _courtPanel.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Image.asset(
              'assets/images/Clinic.png',
              width: 38,
              height: 38,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              '${_formatCoins(coins)} coins',
              style: _myTextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _courtPink,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  price,
                  style: _myTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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

class _SimpleHeader extends StatelessWidget {
  const _SimpleHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 44, 14, 0),
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

class _PolicyPage extends StatelessWidget {
  const _PolicyPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _MyCourtBackdrop(
        child: Column(
          children: [
            _SimpleHeader(
              title: title,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _courtPanel.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Courtly keeps tennis social, respectful, and easy to manage. Share authentic match moments, protect private conversations, and use reporting tools when a court circle feels unsafe.',
                      style: _myTextStyle(
                        color: _courtWhite.withValues(alpha: 0.8),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
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
    return Container(
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
          _PersonActionButton(kind: kind, person: person, onPressed: onPrimary),
        ],
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
    final label = isDelete
        ? 'Delete'
        : (person.followed ? 'Followed' : 'Follow');

    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 28,
        width: isDelete ? 76 : 82,
        decoration: BoxDecoration(
          color: isDelete
              ? _courtPink.withValues(alpha: 0.84)
              : (person.followed
                    ? _courtWhite.withValues(alpha: 0.22)
                    : _courtPink),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDelete ? CupertinoIcons.delete_solid : CupertinoIcons.star_fill,
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
      child: Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          color: _courtPanelSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _ProfileImage(
              path: avatarImagePath,
              fallbackAsset: 'assets/images/Clinic.png',
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: _courtPurpleDeep.withValues(alpha: 0.22),
              ),
            ),
            const Center(
              child: Icon(CupertinoIcons.plus, color: _courtWhite, size: 44),
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

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
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
      child: Image.asset(assetPath, fit: BoxFit.cover),
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
  const _ProfileImage({required this.path, required this.fallbackAsset});

  final String? path;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final imagePath = path;
    if (imagePath != null && imagePath.startsWith('assets/')) {
      return Image.asset(imagePath, fit: BoxFit.cover);
    }
    if (imagePath != null && imagePath.trim().isNotEmpty) {
      return Image.file(File(imagePath), fit: BoxFit.cover);
    }

    return Image.asset(fallbackAsset, fit: BoxFit.cover);
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
      fans: 125,
      follows: 125,
      friends: 125,
      avatarImagePath: 'assets/images/Story.png',
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

abstract final class _CourtPersonSeed {
  static List<_CourtPerson> blacklist() {
    return [
      const _CourtPerson(
        id: 'black-francis',
        name: 'Francis',
        ageLabel: '25',
        country: 'Colombia',
        avatarAsset: 'assets/images/Story.png',
        heroAsset: 'assets/images/Forehand.png',
        motto:
            'One ball, one racket, pure freedom. The racket catches the dusk wind.',
        followed: false,
      ),
    ];
  }

  static List<_CourtPerson> fans() {
    return [
      const _CourtPerson(
        id: 'fan-francis',
        name: 'Francis',
        ageLabel: '25',
        country: 'Colombia',
        avatarAsset: 'assets/images/Story.png',
        heroAsset: 'assets/images/Forehand.png',
        motto:
            'One ball, one racket, pure freedom. The racket catches the dusk wind.',
        followed: false,
      ),
    ];
  }

  static List<_CourtPerson> follows() {
    return [
      const _CourtPerson(
        id: 'follow-francis',
        name: 'Francis',
        ageLabel: '25',
        country: 'Colombia',
        avatarAsset: 'assets/images/Story.png',
        heroAsset: 'assets/images/Profile.png',
        motto:
            'One ball, one racket, pure freedom. The racket catches the dusk wind.',
        followed: true,
      ),
    ];
  }

  static List<_CourtPerson> friends() {
    return [
      const _CourtPerson(
        id: 'friend-francis',
        name: 'Francis',
        ageLabel: '25',
        country: 'Colombia',
        avatarAsset: 'assets/images/Story.png',
        heroAsset: 'assets/images/Surface.png',
        motto:
            'One ball, one racket, pure freedom. The racket catches the dusk wind.',
        followed: true,
      ),
    ];
  }
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

const List<String> _videoAssets = [
  'assets/images/Forehand.png',
  'assets/images/Profile.png',
  'assets/images/Surface.png',
  'assets/images/Arena.png',
  'assets/images/Backhand.png',
  'assets/images/Strings.png',
];

const List<String> _postNotes = [
  'Evening rally notes: serve placement felt cleaner after ten quiet minutes on the baseline.',
  'Saved a new doubles drill for the next court circle.',
  'A soft warmup, a sharp split step, and the whole match starts calmer.',
];

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
