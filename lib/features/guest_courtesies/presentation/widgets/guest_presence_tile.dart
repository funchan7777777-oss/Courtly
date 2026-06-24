import 'package:courtly/atelier/theme/courtly_ink_palette.dart';
import 'package:courtly/features/guest_courtesies/domain/guest_presence_note.dart';
import 'package:courtly/shared/presentation/courtly_fact_row.dart';
import 'package:courtly/shared/presentation/courtly_seal_pill.dart';
import 'package:courtly/shared/presentation/courtly_surface.dart';
import 'package:flutter/cupertino.dart';

class GuestPresenceTile extends StatelessWidget {
  const GuestPresenceTile({required this.note, super.key});

  final GuestPresenceNote note;

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;

    return CourtlySurface(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.guestAlias,
                      style: textTheme.navTitleTextStyle.copyWith(
                        fontSize: 20,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.relationshipContext,
                      style: textTheme.textStyle.copyWith(
                        color: CourtlyInkPalette.softInk,
                        fontSize: 13,
                        height: 1.3,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              CourtlySealPill(
                label: note.careWeight.tableLabel,
                accent: CourtlyInkPalette.correspondenceBlue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          CourtlyFactRow(
            marker: CupertinoIcons.location_solid,
            label: 'Seating texture',
            value: note.seatingTexture,
          ),
          const SizedBox(height: 14),
          CourtlyFactRow(
            marker: CupertinoIcons.hand_raised_fill,
            label: 'Welcome gesture',
            value: note.welcomeGesture,
          ),
          const SizedBox(height: 14),
          CourtlyFactRow(
            marker: CupertinoIcons.chat_bubble_text_fill,
            label: 'Opening line',
            value: note.conversationOpening,
          ),
          const SizedBox(height: 14),
          CourtlyFactRow(
            marker: CupertinoIcons.lock_shield_fill,
            label: 'Care boundary',
            value: note.boundaryCare,
          ),
        ],
      ),
    );
  }
}
