import 'dart:io';

import 'package:courtly/atelier/navigation/courtly_tabs.dart';
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
    this.initialDisplayName,
    super.key,
  });

  final String entryMethod;
  final String actionLabel;
  final RallyCredentialDraft? pendingCredentialDraft;
  final String? initialDisplayName;

  @override
  State<RallyProfileDetailPage> createState() => _RallyProfileDetailPageState();
}

class _RallyProfileDetailPageState extends State<RallyProfileDetailPage> {
  final RallySessionVault _sessionVault = const RallySessionVault();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();
  String? _avatarImagePath;
  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    _displayNameController.text = widget.initialDisplayName ?? '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _countryController.dispose();
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
              alignment: const Alignment(0, 0.23),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(38, 84, 38, 34),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CourtCardAvatar(
                      avatarImagePath: _avatarImagePath,
                      onPressed: _showAvatarSourceSheet,
                    ),
                    const SizedBox(height: 20),
                    RallyEntryField(
                      placeholder: 'Enter your court name',
                      controller: _displayNameController,
                    ),
                    const SizedBox(height: 15),
                    RallyEntryField(
                      placeholder: 'Choose your country circuit',
                      controller: _countryController,
                    ),
                    const SizedBox(height: 15),
                    RallyEntryField(
                      placeholder: 'Write a personal matchday signature',
                      controller: _signatureController,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 28),
                    RallyGlassActionButton(
                      label: widget.actionLabel,
                      isBusy: _isSavingProfile,
                      onPressed: _finishProfileSetup,
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
                _pickAvatar(ImageSource.photoLibrary);
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

  Future<void> _finishProfileSetup() async {
    final profileDraft = RallyProfileDraft(
      displayNameSignal: _displayNameController.text,
      countryCircuit: _countryController.text,
      personalCourtline: _signatureController.text,
      avatarImagePath: _avatarImagePath,
    );

    if (profileDraft.displayNameSignal.trim().isEmpty ||
        profileDraft.countryCircuit.trim().isEmpty ||
        profileDraft.personalCourtline.trim().isEmpty) {
      await RallyNoticeDialog.show(
        context,
        title: 'Finish your court card',
        message:
            'Add your court name, country circuit, and personal signature before entering.',
      );
      return;
    }

    setState(() => _isSavingProfile = true);

    final credentialDraft = widget.pendingCredentialDraft;
    if (credentialDraft != null) {
      await _sessionVault.rememberCredentialDraft(credentialDraft);
    }
    await _sessionVault.activateProfile(
      profileDraft: profileDraft,
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
              Image.file(
                File(path),
                fit: BoxFit.cover,
              )
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
