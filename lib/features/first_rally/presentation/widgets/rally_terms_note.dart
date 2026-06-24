import 'package:flutter/cupertino.dart';

class RallyTermsNote extends StatelessWidget {
  const RallyTermsNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Text(
        'By registering, you agree to all terms of service and confirm that you have read our privacy policy and cookie policy. Please refer to your privacy overview.',
        textAlign: TextAlign.center,
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
          color: CupertinoColors.white.withValues(alpha: 0.80),
          fontSize: 10,
          height: 1.35,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
