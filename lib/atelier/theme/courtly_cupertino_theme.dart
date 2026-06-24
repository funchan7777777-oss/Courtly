import 'package:courtly/atelier/theme/courtly_ink_palette.dart';
import 'package:flutter/cupertino.dart';

abstract final class CourtlyCupertinoTheme {
  static const CupertinoThemeData daybook = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: CourtlyInkPalette.velvetRaspberry,
    scaffoldBackgroundColor: CourtlyInkPalette.porcelain,
    barBackgroundColor: CourtlyInkPalette.paperWhite,
    textTheme: CupertinoTextThemeData(
      navLargeTitleTextStyle: TextStyle(
        color: CourtlyInkPalette.midnightSeal,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      navTitleTextStyle: TextStyle(
        color: CourtlyInkPalette.midnightSeal,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      textStyle: TextStyle(
        color: CourtlyInkPalette.midnightSeal,
        fontSize: 16,
        letterSpacing: 0,
      ),
    ),
  );
}
