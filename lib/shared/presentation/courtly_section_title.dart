import 'package:courtly/atelier/theme/courtly_ink_palette.dart';
import 'package:flutter/cupertino.dart';

class CourtlySectionTitle extends StatelessWidget {
  const CourtlySectionTitle({required this.title, this.detail, super.key});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: textTheme.navTitleTextStyle.copyWith(
                fontSize: 19,
                letterSpacing: 0,
              ),
            ),
          ),
          if (detail != null)
            Text(
              detail!,
              style: textTheme.textStyle.copyWith(
                color: CourtlyInkPalette.softInk,
                fontSize: 13,
                letterSpacing: 0,
              ),
            ),
        ],
      ),
    );
  }
}
