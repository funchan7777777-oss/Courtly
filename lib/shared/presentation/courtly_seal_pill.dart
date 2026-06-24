import 'package:courtly/atelier/theme/courtly_ink_palette.dart';
import 'package:flutter/cupertino.dart';

class CourtlySealPill extends StatelessWidget {
  const CourtlySealPill({
    required this.label,
    this.accent = CourtlyInkPalette.correspondenceBlue,
    super.key,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
