import 'package:courtly/features/first_rally/domain/rally_entry_draft.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_profile_detail_page.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_signin_page.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_back_button.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_backdrop_layer.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_entry_field.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_glass_action_button.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_notice_dialog.dart';
import 'package:flutter/cupertino.dart';

class RallyRegisterCredentialsPage extends StatefulWidget {
  const RallyRegisterCredentialsPage({super.key});

  @override
  State<RallyRegisterCredentialsPage> createState() =>
      _RallyRegisterCredentialsPageState();
}

class _RallyRegisterCredentialsPageState
    extends State<RallyRegisterCredentialsPage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _servePhraseController = TextEditingController();

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
                    _RegisterBridgeLine(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          CupertinoPageRoute<void>(
                            builder: (_) => const RallySigninPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    RallyGlassActionButton(
                      label: 'Sign up',
                      onPressed: _continueToProfile,
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

  Future<void> _continueToProfile() async {
    final draft = RallyCredentialDraft(
      courtsideAddress: _addressController.text,
      privateServePhrase: _servePhraseController.text,
    );

    if (!draft.hasUsableShape) {
      await RallyNoticeDialog.show(
        context,
        title: 'Complete your signup',
        message:
            'Use a valid email address and a password of at least 6 characters.',
      );
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => RallyProfileDetailPage(
          entryMethod: 'local',
          pendingCredentialDraft: draft,
          actionLabel: 'Next',
        ),
      ),
    );
  }
}

class _RegisterBridgeLine extends StatelessWidget {
  const _RegisterBridgeLine({required this.onPressed});

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
        Text('Already on Courtly?', style: style),
        CupertinoButton(
          minimumSize: Size.zero,
          padding: const EdgeInsets.only(left: 4),
          onPressed: onPressed,
          child: Text(
            'Log in',
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
