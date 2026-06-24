import 'package:courtly/atelier/theme/courtly_ink_palette.dart';
import 'package:flutter/cupertino.dart';

class CourtlyFactRow extends StatelessWidget {
  const CourtlyFactRow({
    required this.marker,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData marker;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(marker, size: 19, color: CourtlyInkPalette.velvetRaspberry),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.textStyle.copyWith(
                  color: CourtlyInkPalette.softInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.textStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
