import 'package:flutter/cupertino.dart';

class CourtlyPageFrame extends StatelessWidget {
  const CourtlyPageFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: child,
      ),
    );
  }
}
