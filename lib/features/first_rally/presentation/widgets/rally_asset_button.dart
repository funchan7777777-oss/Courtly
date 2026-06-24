import 'package:flutter/cupertino.dart';

class RallyAssetButton extends StatelessWidget {
  const RallyAssetButton({
    required this.assetPath,
    required this.onPressed,
    required this.semanticLabel,
    this.widthRatio = 0.74,
    super.key,
  });

  final String assetPath;
  final VoidCallback onPressed;
  final String semanticLabel;
  final double widthRatio;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final buttonWidth = (screenWidth * widthRatio).clamp(250.0, 310.0);
    final buttonHeight = buttonWidth / (580 / 110);

    return CupertinoButton(
      minSize: 0,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: Image.asset(
          assetPath,
          width: buttonWidth,
          height: buttonHeight,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
