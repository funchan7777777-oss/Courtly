import 'package:flutter/cupertino.dart';

class RallyBackButton extends StatelessWidget {
  const RallyBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 14,
      top: MediaQuery.sizeOf(context).height * 0.058,
      child: CupertinoButton(
        minimumSize: Size.zero,
        padding: const EdgeInsets.all(8),
        onPressed: () => Navigator.of(context).maybePop(),
        child: const Icon(
          CupertinoIcons.chevron_left,
          color: CupertinoColors.white,
          size: 22,
        ),
      ),
    );
  }
}
