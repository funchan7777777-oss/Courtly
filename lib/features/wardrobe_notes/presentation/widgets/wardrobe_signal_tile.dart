import 'package:courtly/atelier/theme/courtly_ink_palette.dart';
import 'package:courtly/features/wardrobe_notes/domain/wardrobe_readiness.dart';
import 'package:courtly/shared/presentation/courtly_fact_row.dart';
import 'package:courtly/shared/presentation/courtly_seal_pill.dart';
import 'package:courtly/shared/presentation/courtly_surface.dart';
import 'package:flutter/cupertino.dart';

class WardrobeSignalTile extends StatelessWidget {
  const WardrobeSignalTile({required this.readiness, super.key});

  final WardrobeReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;
    final normalizedRatio = readiness.completionRatio
        .clamp(0.0, 1.0)
        .toDouble();

    return CourtlySurface(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            readiness.readinessName,
            style: textTheme.navTitleTextStyle.copyWith(
              fontSize: 20,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 8,
              color: CourtlyInkPalette.linenMist,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: normalizedRatio,
                heightFactor: 1,
                child: const ColoredBox(
                  color: CourtlyInkPalette.receptionGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final flag in readiness.readinessFlags)
                CourtlySealPill(
                  label: flag,
                  accent: CourtlyInkPalette.velvetRaspberry,
                ),
            ],
          ),
          const SizedBox(height: 16),
          CourtlyFactRow(
            marker: CupertinoIcons.checkmark_seal_fill,
            label: 'Inspection focus',
            value: readiness.inspectionFocus,
          ),
          const SizedBox(height: 14),
          CourtlyFactRow(
            marker: CupertinoIcons.sparkles,
            label: 'Fabric cue',
            value: readiness.fabricCue,
          ),
          const SizedBox(height: 14),
          CourtlyFactRow(
            marker: CupertinoIcons.tag_fill,
            label: 'Accessory anchor',
            value: readiness.accessoryAnchor,
          ),
          const SizedBox(height: 14),
          CourtlyFactRow(
            marker: CupertinoIcons.cloud_sun_fill,
            label: 'Weather tact',
            value: readiness.weatherTact,
          ),
          const SizedBox(height: 14),
          Text(
            readiness.quietRisk,
            style: textTheme.textStyle.copyWith(
              color: CourtlyInkPalette.velvetRaspberry,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
