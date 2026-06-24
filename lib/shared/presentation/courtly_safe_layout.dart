import 'package:flutter/cupertino.dart';

const double courtlyMaxPhoneWidth = 430;

double courtlySafeTop(BuildContext context, [double spacing = 0]) {
  return MediaQuery.paddingOf(context).top + spacing;
}

double courtlySafeBottom(BuildContext context, [double spacing = 0]) {
  return MediaQuery.paddingOf(context).bottom + spacing;
}

class CourtlyAppViewport extends StatelessWidget {
  const CourtlyAppViewport({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1A004D),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth
              .clamp(0.0, courtlyMaxPhoneWidth)
              .toDouble();

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              height: double.infinity,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
