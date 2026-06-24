import 'package:courtly/atelier/navigation/courtly_tabs.dart';
import 'package:courtly/features/first_rally/data/rally_asset_ledger.dart';
import 'package:courtly/features/first_rally/domain/rally_entry_draft.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_asset_button.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_back_button.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_backdrop_layer.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_entry_field.dart';
import 'package:flutter/cupertino.dart';

class RallyProfileDetailPage extends StatefulWidget {
  const RallyProfileDetailPage({
    required this.courtStyleKey,
    required this.birthdateMarker,
    super.key,
  });

  final String courtStyleKey;
  final DateTime birthdateMarker;

  @override
  State<RallyProfileDetailPage> createState() => _RallyProfileDetailPageState();
}

class _RallyProfileDetailPageState extends State<RallyProfileDetailPage> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
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
              alignment: const Alignment(0, 0.33),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 38),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RallyEntryField(
                      placeholder: 'Choose a courtside nickname',
                      controller: _nicknameController,
                    ),
                    const SizedBox(height: 15),
                    RallyEntryField(
                      placeholder: 'Select your country circuit',
                      controller: _countryController,
                    ),
                    const SizedBox(height: 15),
                    RallyEntryField(
                      placeholder: 'Write a short matchday signature',
                      controller: _signatureController,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 34),
                    RallyAssetButton(
                      assetPath: RallyAssetLedger.submitSigninButton,
                      semanticLabel: 'Sign in',
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

  void _finishProfileSetup() {
    final profileDraft = RallyProfileDraft(
      nicknameSignal: _nicknameController.text,
      countryCircuit: _countryController.text,
      personalCourtline: _signatureController.text,
      birthdateMarker: widget.birthdateMarker,
      playStyleKey: widget.courtStyleKey,
    );

    if (profileDraft.nicknameSignal.trim().isEmpty ||
        profileDraft.countryCircuit.trim().isEmpty) {
      _showProfileNotice();
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute<void>(builder: (_) => const CourtlyTabs()),
      (_) => false,
    );
  }

  void _showProfileNotice() {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Finish your court card'),
          content: const Text(
            'Add a nickname and country circuit before entering.',
          ),
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
