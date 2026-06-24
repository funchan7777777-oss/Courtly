import 'package:courtly/features/guest_courtesies/data/guest_registry_seed.dart';
import 'package:courtly/features/guest_courtesies/presentation/widgets/guest_presence_tile.dart';
import 'package:courtly/shared/presentation/courtly_page_frame.dart';
import 'package:courtly/shared/presentation/courtly_section_title.dart';
import 'package:flutter/cupertino.dart';

class GuestCourtesyView extends StatelessWidget {
  const GuestCourtesyView({super.key});

  @override
  Widget build(BuildContext context) {
    const guestNotes = GuestRegistrySeed.tableCourtesies;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(largeTitle: Text('Guests')),
          SliverToBoxAdapter(
            child: CourtlyPageFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CourtlySectionTitle(
                    title: 'Table courtesies',
                    detail: '3 notes',
                  ),
                  for (final note in guestNotes) GuestPresenceTile(note: note),
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
