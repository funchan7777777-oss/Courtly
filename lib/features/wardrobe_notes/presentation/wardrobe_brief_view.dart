import 'package:courtly/features/wardrobe_notes/data/wardrobe_readiness_seed.dart';
import 'package:courtly/features/wardrobe_notes/presentation/widgets/wardrobe_signal_tile.dart';
import 'package:courtly/shared/presentation/courtly_page_frame.dart';
import 'package:courtly/shared/presentation/courtly_section_title.dart';
import 'package:flutter/cupertino.dart';

class WardrobeBriefView extends StatelessWidget {
  const WardrobeBriefView({super.key});

  @override
  Widget build(BuildContext context) {
    const signals = WardrobeReadinessSeed.eveningSignals;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(largeTitle: Text('Wardrobe')),
          SliverToBoxAdapter(
            child: CourtlyPageFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CourtlySectionTitle(
                    title: 'Readiness signals',
                    detail: 'occasion fit',
                  ),
                  for (final signal in signals)
                    WardrobeSignalTile(readiness: signal),
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
