import 'package:courtly/features/first_rally/data/rally_asset_ledger.dart';
import 'package:flutter/cupertino.dart';

enum RallyBackdrop {
  surfaceSplash(RallyAssetLedger.surfaceSplash),
  forehandChoice(RallyAssetLedger.forehandChoiceBackdrop),
  profileForm(RallyAssetLedger.profileFormBackdrop);

  const RallyBackdrop(this.assetPath);

  final String assetPath;
}

class RallyBackdropLayer extends StatelessWidget {
  const RallyBackdropLayer({
    required this.backdropPath,
    this.child,
    super.key,
  });

  final RallyBackdrop backdropPath;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          backdropPath.assetPath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        if (child != null) child!,
      ],
    );
  }
}
