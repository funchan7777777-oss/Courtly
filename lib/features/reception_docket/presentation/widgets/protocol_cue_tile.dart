import 'package:courtly/atelier/theme/courtly_ink_palette.dart';
import 'package:courtly/features/reception_docket/domain/protocol_cue.dart';
import 'package:courtly/shared/presentation/courtly_seal_pill.dart';
import 'package:courtly/shared/presentation/courtly_surface.dart';
import 'package:flutter/cupertino.dart';

class ProtocolCueTile extends StatelessWidget {
  const ProtocolCueTile({required this.cue, super.key});

  final ProtocolCue cue;

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;
    final accent = switch (cue.delicacy) {
      CueDelicacy.quiet => CourtlyInkPalette.correspondenceBlue,
      CueDelicacy.attentive => CourtlyInkPalette.receptionGreen,
      CueDelicacy.formal => CourtlyInkPalette.velvetRaspberry,
    };

    return CourtlySurface(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  cue.cueName,
                  style: textTheme.textStyle.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              CourtlySealPill(
                label: cue.delicacy.presentationLabel,
                accent: accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cue.socialSetting,
            style: textTheme.textStyle.copyWith(
              color: CourtlyInkPalette.softInk,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            cue.gracefulMove,
            style: textTheme.textStyle.copyWith(
              fontSize: 15,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(CupertinoIcons.clock, color: accent, size: 16),
              const SizedBox(width: 6),
              Text(
                cue.timingHint,
                style: textTheme.textStyle.copyWith(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
