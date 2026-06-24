import 'package:courtly/atelier/theme/courtly_ink_palette.dart';
import 'package:flutter/cupertino.dart';

class CourtlySurface extends StatelessWidget {
  const CourtlySurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.tint,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: tint ?? CourtlyInkPalette.paperWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CourtlyInkPalette.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
