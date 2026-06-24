import 'dart:io';

import 'package:courtly/atelier/navigation/courtly_tabs.dart';
import 'package:courtly/features/first_rally/data/rally_asset_ledger.dart';
import 'package:courtly/features/first_rally/data/rally_session_vault.dart';
import 'package:courtly/features/first_rally/domain/rally_entry_draft.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_back_button.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_backdrop_layer.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_entry_field.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_glass_action_button.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_notice_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class RallyProfileDetailPage extends StatefulWidget {
  const RallyProfileDetailPage({
    required this.entryMethod,
    required this.actionLabel,
    this.pendingCredentialDraft,
    super.key,
  });

  final String entryMethod;
  final String actionLabel;
  final RallyCredentialDraft? pendingCredentialDraft;

  @override
  State<RallyProfileDetailPage> createState() => _RallyProfileDetailPageState();
}

class _RallyProfileDetailPageState extends State<RallyProfileDetailPage> {
  static const List<String> _countryCircuits = [
    'United States',
    'China',
    'Japan',
    'South Korea',
    'United Kingdom',
    'France',
    'Germany',
    'Canada',
    'Australia',
    'Singapore',
    'Spain',
  ];

  final RallySessionVault _sessionVault = const RallySessionVault();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();
  String? _avatarImagePath;
  String? _selectedCountryCircuit;
  String? _selectedGenderSignal;
  DateTime? _birthdateMarker;
  bool _isSavingProfile = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: RallyBackdropLayer(
        backdropPath: RallyBackdrop.profileForm,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const RallyBackButton(),
            Align(
              alignment: const Alignment(0, 0.08),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(38, 78, 38, 34),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: _CourtCardAvatar(
                        avatarImagePath: _avatarImagePath,
                        onPressed: _showAvatarSourceSheet,
                      ),
                    ),
                    const SizedBox(height: 18),
                    RallyEntryField(
                      placeholder: 'Enter your court name',
                      controller: _displayNameController,
                    ),
                    const SizedBox(height: 12),
                    _RallyChoiceRibbon(
                      label: _selectedCountryCircuit ?? 'Choose your country',
                      icon: CupertinoIcons.location_solid,
                      isPlaceholder: _selectedCountryCircuit == null,
                      onPressed: _showCountrySheet,
                    ),
                    const SizedBox(height: 16),
                    const _ProfilePromptText('Please select gender'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _GenderSignalCard(
                            assetPath: RallyAssetLedger.storyPlayerCard,
                            label: 'Female',
                            isSelected: _selectedGenderSignal == 'female',
                            onPressed: () {
                              setState(() => _selectedGenderSignal = 'female');
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _GenderSignalCard(
                            assetPath: RallyAssetLedger.invitePlayerCard,
                            label: 'Male',
                            isSelected: _selectedGenderSignal == 'male',
                            onPressed: () {
                              setState(() => _selectedGenderSignal = 'male');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _ProfilePromptText(
                      'Please select your date of birth',
                    ),
                    const SizedBox(height: 10),
                    _RallyChoiceRibbon(
                      label: _birthdateMarker == null
                          ? 'Select date of birth'
                          : _formatBirthdate(_birthdateMarker!),
                      icon: CupertinoIcons.calendar,
                      isPlaceholder: _birthdateMarker == null,
                      onPressed: _showBirthdatePicker,
                    ),
                    const SizedBox(height: 12),
                    RallyEntryField(
                      placeholder: 'Write a personal matchday signature',
                      controller: _signatureController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: RallyGlassActionButton(
                        label: widget.actionLabel,
                        isBusy: _isSavingProfile,
                        onPressed: _finishProfileSetup,
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

  Future<void> _showAvatarSourceSheet() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Set court card photo'),
          message: const Text('Choose a photo or take a new one.'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _pickAvatar(ImageSource.gallery);
              },
              child: const Text('Choose from Library'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _pickAvatar(ImageSource.camera);
              },
              child: const Text('Take Photo'),
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

  Future<void> _pickAvatar(ImageSource source) async {
    final pickedImage = await _imagePicker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1200,
    );

    if (pickedImage == null || !mounted) {
      return;
    }

    setState(() => _avatarImagePath = pickedImage.path);
  }

  Future<void> _showCountrySheet() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Choose your country circuit'),
          actions: [
            for (final country in _countryCircuits)
              CupertinoActionSheetAction(
                onPressed: () {
                  setState(() => _selectedCountryCircuit = country);
                  Navigator.of(context).pop();
                },
                child: Text(country),
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

  Future<void> _showBirthdatePicker() async {
    var stagedBirthdate = _birthdateMarker ?? DateTime(2000, 6, 23);

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return Container(
          height: 326,
          decoration: const BoxDecoration(
            color: Color(0xFF2C0B59),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date of birth',
                        style: CupertinoTheme.of(context).textTheme.textStyle
                            .copyWith(
                              color: CupertinoColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                              decoration: TextDecoration.none,
                            ),
                      ),
                    ),
                    CupertinoButton(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      onPressed: () {
                        setState(() => _birthdateMarker = stagedBirthdate);
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Color(0xFFFFD46E),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                    primaryColor: Color(0xFFFFD46E),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: stagedBirthdate,
                    minimumDate: DateTime(1940),
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (value) => stagedBirthdate = value,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _finishProfileSetup() async {
    final countryCircuit = _selectedCountryCircuit;
    final genderSignal = _selectedGenderSignal;
    final birthdateMarker = _birthdateMarker;

    if (_displayNameController.text.trim().isEmpty ||
        countryCircuit == null ||
        genderSignal == null ||
        birthdateMarker == null ||
        _signatureController.text.trim().isEmpty) {
      await RallyNoticeDialog.show(
        context,
        title: 'Finish your court card',
        message:
            'Add your name, country, gender, date of birth, and signature before entering.',
      );
      return;
    }

    setState(() => _isSavingProfile = true);

    final credentialDraft = widget.pendingCredentialDraft;
    if (credentialDraft != null) {
      await _sessionVault.rememberCredentialDraft(credentialDraft);
    }

    await _sessionVault.activateProfile(
      profileDraft: RallyProfileDraft(
        displayNameSignal: _displayNameController.text,
        countryCircuit: countryCircuit,
        personalCourtline: _signatureController.text,
        birthdateMarker: birthdateMarker,
        playStyleKey: genderSignal,
        avatarImagePath: _avatarImagePath,
      ),
      entryMethod: widget.entryMethod,
    );

    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute<void>(builder: (_) => const CourtlyTabs()),
      (_) => false,
    );
  }

  String _formatBirthdate(DateTime value) {
    return '${value.year}  ${value.month.toString().padLeft(2, '0')}  ${value.day.toString().padLeft(2, '0')}';
  }
}

class _CourtCardAvatar extends StatelessWidget {
  const _CourtCardAvatar({
    required this.avatarImagePath,
    required this.onPressed,
  });

  final String? avatarImagePath;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final path = avatarImagePath;

    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 118,
        height: 118,
        decoration: BoxDecoration(
          color: const Color(0xFF6E3CA1).withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFB733), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 22,
              offset: Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (path != null)
              Image.file(File(path), fit: BoxFit.cover)
            else
              Center(
                child: Icon(
                  CupertinoIcons.camera_fill,
                  color: CupertinoColors.white.withValues(alpha: 0.76),
                  size: 34,
                ),
              ),
            Positioned(
              right: 7,
              bottom: 7,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB733),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.plus,
                  color: Color(0xFF2D0A5A),
                  size: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RallyChoiceRibbon extends StatelessWidget {
  const _RallyChoiceRibbon({
    required this.label,
    required this.icon,
    required this.isPlaceholder,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isPlaceholder;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF6C42A0).withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: CupertinoColors.white.withValues(alpha: 0.52),
              size: 17,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoColors.white.withValues(
                    alpha: isPlaceholder ? 0.42 : 0.92,
                  ),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_down,
              color: CupertinoColors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderSignalCard extends StatelessWidget {
  const _GenderSignalCard({
    required this.assetPath,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String assetPath;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF6E3CA1).withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFB733)
                : CupertinoColors.white.withValues(alpha: 0.10),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(assetPath, width: 76, height: 76, fit: BoxFit.contain),
            Text(
              label,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: CupertinoColors.white.withValues(alpha: 0.82),
                fontSize: 11,
                fontWeight: FontWeight.w700,
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

class _ProfilePromptText extends StatelessWidget {
  const _ProfilePromptText(this.copy);

  final String copy;

  @override
  Widget build(BuildContext context) {
    return Text(
      copy,
      style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
        color: CupertinoColors.white.withValues(alpha: 0.66),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        decoration: TextDecoration.none,
      ),
    );
  }
}
