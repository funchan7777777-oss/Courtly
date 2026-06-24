import 'package:courtly/atelier/navigation/courtly_tabs.dart';
import 'package:courtly/features/first_rally/data/rally_asset_ledger.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_signin_page.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_asset_button.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_backdrop_layer.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_terms_note.dart';
import 'package:flutter/cupertino.dart';

class RallyWelcomeChoicePage extends StatelessWidget {
  const RallyWelcomeChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: RallyBackdropLayer(
        backdropPath: RallyBackdrop.forehandChoice,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: const Alignment(0, 0.40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RallyAssetButton(
                    assetPath: RallyAssetLedger.applePassButton,
                    semanticLabel: 'Sign in with Apple',
                    onPressed: () => _enterCourtly(context),
                  ),
                  const SizedBox(height: 18),
                  RallyAssetButton(
                    assetPath: RallyAssetLedger.courtAccountButton,
                    semanticLabel: 'Sign up or log in',
                    onPressed: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute<void>(
                          builder: (_) => const RallySigninPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 25,
              child: RallyTermsNote(),
            ),
          ],
        ),
      ),
    );
  }

  void _enterCourtly(BuildContext context) {
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(builder: (_) => const CourtlyTabs()),
    );
  }
}
