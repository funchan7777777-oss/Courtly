import 'package:courtly/atelier/navigation/courtly_tabs.dart';
import 'package:courtly/features/first_rally/data/rally_asset_ledger.dart';
import 'package:courtly/features/first_rally/domain/rally_entry_draft.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_register_credentials_page.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_asset_button.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_back_button.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_backdrop_layer.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_entry_field.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_terms_note.dart';
import 'package:flutter/cupertino.dart';

class RallySigninPage extends StatefulWidget {
  const RallySigninPage({super.key});

  @override
  State<RallySigninPage> createState() => _RallySigninPageState();
}

class _RallySigninPageState extends State<RallySigninPage> {
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
                    const SizedBox(height: 8),
                    _AccountBridgeLine(
                      prompt: 'Don\'t have an account yet?',
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
                    RallyAssetButton(
                      assetPath: RallyAssetLedger.submitLoginButton,
                      semanticLabel: 'Log in',
                      onPressed: _tryEnterCourtly,
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: RallyTermsNote(),
            ),
          ],
        ),
      ),
    );
  }

  void _tryEnterCourtly() {
    final draft = RallyCredentialDraft(
      courtsideAddress: _addressController.text,
      privateServePhrase: _servePhraseController.text,
    );

    if (!draft.hasUsableShape) {
      _showEntryNotice(
        title: 'Check your details',
        message:
            'Use a valid email address and a password of at least 6 characters.',
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(builder: (_) => const CourtlyTabs()),
    );
  }

  void _showEntryNotice({required String title, required String message}) {
    showCupertinoDialog<void>(
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
