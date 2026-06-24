import 'package:courtly/features/first_rally/data/rally_asset_ledger.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_profile_media_page.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_signin_page.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_asset_button.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_back_button.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_backdrop_layer.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_entry_field.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_terms_note.dart';
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
                    const SizedBox(height: 8),
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
                    RallyAssetButton(
                      assetPath: RallyAssetLedger.continueSetupButton,
                      semanticLabel: 'Next',
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                            builder: (_) => const RallyProfileMediaPage(),
                          ),
                        );
                      },
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
