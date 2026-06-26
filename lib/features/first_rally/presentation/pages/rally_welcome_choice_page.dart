import 'package:courtly/atelier/navigation/courtly_tabs.dart';
import 'package:courtly/features/first_rally/data/rally_asset_ledger.dart';
import 'package:courtly/features/first_rally/data/rally_session_vault.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_signin_page.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_agreement_panel.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_asset_button.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_backdrop_layer.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_notice_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class RallyWelcomeChoicePage extends StatefulWidget {
  const RallyWelcomeChoicePage({super.key});

  @override
  State<RallyWelcomeChoicePage> createState() => _RallyWelcomeChoicePageState();
}

class _RallyWelcomeChoicePageState extends State<RallyWelcomeChoicePage> {
  final RallySessionVault _sessionVault = const RallySessionVault();
  bool _acceptedCourtlyPolicy = false;
  bool _isAppleSigning = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: RallyBackdropLayer(
        backdropPath: RallyBackdrop.forehandChoice,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: const Alignment(0, 0.30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RallyAssetButton(
                    assetPath: RallyAssetLedger.applePassButton,
                    semanticLabel: 'Sign in with Apple',
                    onPressed: _beginAppleEntry,
                  ),
                  const SizedBox(height: 18),
                  RallyAssetButton(
                    assetPath: RallyAssetLedger.courtAccountButton,
                    semanticLabel: 'Account log in',
                    onPressed: _openAccountEntry,
                  ),
                  if (_isAppleSigning) ...[
                    const SizedBox(height: 18),
                    const CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: RallyAgreementPanel(
                isAccepted: _acceptedCourtlyPolicy,
                onChanged: (value) {
                  setState(() => _acceptedCourtlyPolicy = value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAccountEntry() {
    if (!_acceptedCourtlyPolicy) {
      _showAgreementNotice();
      return;
    }

    Navigator.of(
      context,
    ).push(CupertinoPageRoute<void>(builder: (_) => const RallySigninPage()));
  }

  Future<void> _beginAppleEntry() async {
    if (!_acceptedCourtlyPolicy) {
      _showAgreementNotice();
      return;
    }

    setState(() => _isAppleSigning = true);
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        if (!mounted) {
          return;
        }
        await RallyNoticeDialog.show(
          context,
          title: 'Apple sign-in unavailable',
          message:
              'This device cannot start Apple sign-in right now. Try account login instead.',
        );
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final appleName = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().where((piece) => piece.trim().isNotEmpty).join(' ');

      final storedAppleName = await _sessionVault.readAppleIdentityName();
      final fallbackName = credential.email?.split('@').first;
      final preferredName = appleName.isNotEmpty
          ? appleName
          : storedAppleName ?? fallbackName ?? 'Mira Vale';

      await _sessionVault.rememberAppleIdentityName(preferredName);
      await _sessionVault.activateAppleEntry(displayNameSignal: preferredName);

      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        CupertinoPageRoute<void>(builder: (_) => const CourtlyTabs()),
        (_) => false,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (!mounted || error.code == AuthorizationErrorCode.canceled) {
        return;
      }
      await RallyNoticeDialog.show(
        context,
        title: 'Apple sign-in paused',
        message: 'Courtly could not finish Apple sign-in. Please try again.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      await RallyNoticeDialog.show(
        context,
        title: 'Apple sign-in paused',
        message: 'Courtly could not finish Apple sign-in. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isAppleSigning = false);
      }
    }
  }

  void _showAgreementNotice() {
    RallyNoticeDialog.show(
      context,
      title: 'Agreement required',
      message:
          'Please review and accept the Terms of Service and Privacy Policy before continuing.',
    );
  }
}
