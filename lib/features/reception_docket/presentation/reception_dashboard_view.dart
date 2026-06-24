import 'package:courtly/atelier/theme/courtly_ink_palette.dart';
import 'package:courtly/features/reception_docket/data/reception_daybook.dart';
import 'package:courtly/features/reception_docket/presentation/widgets/docket_header_band.dart';
import 'package:courtly/features/reception_docket/presentation/widgets/protocol_cue_tile.dart';
import 'package:courtly/features/reception_docket/presentation/widgets/rhythm_checklist_panel.dart';
import 'package:courtly/shared/presentation/courtly_fact_row.dart';
import 'package:courtly/shared/presentation/courtly_page_frame.dart';
import 'package:courtly/shared/presentation/courtly_section_title.dart';
import 'package:courtly/shared/presentation/courtly_surface.dart';
import 'package:flutter/cupertino.dart';

class ReceptionDashboardView extends StatelessWidget {
  const ReceptionDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    const docket = ReceptionDaybook.eveningSalon;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(largeTitle: Text('Courtly')),
          SliverToBoxAdapter(
            child: CourtlyPageFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DocketHeaderBand(docket: docket),
                  CourtlySurface(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Column(
                      children: [
                        CourtlyFactRow(
                          marker: CupertinoIcons.person_crop_rectangle,
                          label: 'Attire signal',
                          value: docket.attireSignal,
                        ),
                        SizedBox(height: 14),
                        CourtlyFactRow(
                          marker: CupertinoIcons.table_badge_more,
                          label: 'Table tone',
                          value: docket.tableTone,
                        ),
                      ],
                    ),
                  ),
                  const CourtlySectionTitle(
                    title: 'Evening rhythm',
                    detail: '3 movements',
                  ),
                  RhythmChecklistPanel(intervals: docket.intervals),
                  const CourtlySectionTitle(
                    title: 'Preparation threads',
                    detail: 'quiet work',
                  ),
                  _PreparationThreadList(threads: docket.preparationThreads),
                  const CourtlySectionTitle(
                    title: 'Protocol cues',
                    detail: 'on hand',
                  ),
                  for (final cue in docket.protocolCues)
                    ProtocolCueTile(cue: cue),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreparationThreadList extends StatelessWidget {
  const _PreparationThreadList({required this.threads});

  final List<String> threads;

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;

    return CourtlySurface(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      tint: CourtlyInkPalette.linenMist,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final thread in threads) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  CupertinoIcons.smallcircle_fill_circle,
                  color: CourtlyInkPalette.velvetRaspberry,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    thread,
                    style: textTheme.textStyle.copyWith(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            if (thread != threads.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
