import 'package:courtly/atelier/theme/courtly_ink_palette.dart';
import 'package:courtly/features/reception_docket/domain/reception_docket.dart';
import 'package:courtly/shared/presentation/courtly_surface.dart';
import 'package:flutter/cupertino.dart';

class RhythmChecklistPanel extends StatelessWidget {
  const RhythmChecklistPanel({required this.intervals, super.key});

  final List<CourtesyInterval> intervals;

  @override
  Widget build(BuildContext context) {
    return CourtlySurface(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final interval in intervals) ...[
            _RhythmLine(interval: interval),
            if (interval != intervals.last)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  height: 1,
                  child: ColoredBox(color: CourtlyInkPalette.hairline),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RhythmLine extends StatelessWidget {
  const _RhythmLine({required this.interval});

  final CourtesyInterval interval;

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;
    final accent = interval.isSettled
        ? CourtlyInkPalette.receptionGreen
        : CourtlyInkPalette.velvetRaspberry;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            interval.slotLabel,
            style: textTheme.textStyle.copyWith(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                interval.ritualName,
                style: textTheme.textStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                interval.stewardNote,
                style: textTheme.textStyle.copyWith(
                  color: CourtlyInkPalette.softInk,
                  fontSize: 14,
                  height: 1.35,
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
