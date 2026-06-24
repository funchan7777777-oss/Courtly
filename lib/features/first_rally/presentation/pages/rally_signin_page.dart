import 'dart:async';

import 'package:courtly/atelier/navigation/courtly_tabs.dart';
import 'package:courtly/features/first_rally/data/rally_session_vault.dart';
import 'package:courtly/features/first_rally/domain/rally_entry_draft.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_register_credentials_page.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_back_button.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_backdrop_layer.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_entry_field.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_glass_action_button.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_loading_layers.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_notice_dialog.dart';
import 'package:flutter/cupertino.dart';

class RallySigninPage extends StatefulWidget {
  const RallySigninPage({super.key});

  @override
  State<RallySigninPage> createState() => _RallySigninPageState();
}

class _RallySigninPageState extends State<RallySigninPage> {
  final RallySessionVault _sessionVault = const RallySessionVault();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _servePhraseController = TextEditingController();
  bool _isOpeningCourt = false;

  @override
  void dispose() {
    _addressController.dispose();
    _servePhraseController.dispose();
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
              alignment: const Alignment(0, 0.24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 38),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RallyEntryField(
                      placeholder: 'Email Address',
                      controller: _addressController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),
                    RallyEntryField(
                      placeholder: 'Password',
                      controller: _servePhraseController,
                      isPrivatePhrase: true,
                    ),
                    const SizedBox(height: 12),
                    _AccountBridgeLine(
                      prompt: 'No court card yet?',
                      actionLabel: 'Sign up',
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          CupertinoPageRoute<void>(
                            builder: (_) =>
                                const RallyRegisterCredentialsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    RallyGlassActionButton(
                      label: 'Start',
                      isBusy: _isOpeningCourt,
                      onPressed: _tryEnterCourtly,
                    ),
                  ],
                ),
              ),
            ),
            if (_isOpeningCourt)
              const RallyEntryLoadingCurtain(
                label: 'Opening your court circle',
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _tryEnterCourtly() async {
    final draft = RallyCredentialDraft(
      courtsideAddress: _addressController.text,
      privateServePhrase: _servePhraseController.text,
    );

    if (!draft.hasUsableShape) {
      await RallyNoticeDialog.show(
        context,
        title: 'Check your login',
        message:
            'Use a valid email address and a password of at least 6 characters.',
      );
      return;
    }

    final hasLocalCredential = await _sessionVault.hasLocalCredential();
    if (!hasLocalCredential) {
      if (!mounted) {
        return;
      }
      await RallyNoticeDialog.show(
        context,
        title: 'No saved court card',
        message:
            'Create a Courtly account first, then your login will stay on this device.',
      );
      return;
    }

    final credentialMatches = await _sessionVault.credentialMatches(draft);
    if (!credentialMatches) {
      if (!mounted) {
        return;
      }
      await RallyNoticeDialog.show(
        context,
        title: 'Login details do not match',
        message: 'Check the email and password you used when creating Courtly.',
      );
      return;
    }

    setState(() => _isOpeningCourt = true);
    await _sessionVault.reactivateLocalSession();
    await Future<void>.delayed(const Duration(milliseconds: 3400));

    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute<void>(builder: (_) => const CourtlyTabs()),
      (_) => false,
    );
  }
}

class _AccountBridgeLine extends StatelessWidget {
  const _AccountBridgeLine({
    required this.prompt,
    required this.actionLabel,
    required this.onPressed,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = CupertinoTheme.of(context).textTheme.textStyle.copyWith(
      color: CupertinoColors.white.withValues(alpha: 0.78),
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      decoration: TextDecoration.none,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prompt, style: style),
        CupertinoButton(
          minimumSize: Size.zero,
          padding: const EdgeInsets.only(left: 4),
          onPressed: onPressed,
          child: Text(
            actionLabel,
            style: style.copyWith(
              color: CupertinoColors.white,
              decoration: TextDecoration.underline,
              decorationColor: CupertinoColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
