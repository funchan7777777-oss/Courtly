import 'package:courtly/atelier/theme/courtly_ink_palette.dart';
import 'package:courtly/features/reception_docket/domain/reception_docket.dart';
import 'package:courtly/shared/presentation/courtly_seal_pill.dart';
import 'package:flutter/cupertino.dart';

class DocketHeaderBand extends StatelessWidget {
  const DocketHeaderBand({required this.docket, super.key});

  final ReceptionDocket docket;

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CourtlyInkPalette.midnightSeal,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            docket.gatheringName,
            style: textTheme.navTitleTextStyle.copyWith(
              color: CourtlyInkPalette.paperWhite,
              fontSize: 24,
              height: 1.12,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${docket.hostReference} - ${docket.venueSignature}',
            style: textTheme.textStyle.copyWith(
              color: CourtlyInkPalette.linenMist,
              fontSize: 14,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CourtlySealPill(
                label: docket.arrivalWindowLabel,
                accent: CourtlyInkPalette.waxGold,
              ),
              CourtlySealPill(
                label: docket.guestCadenceLabel,
                accent: CourtlyInkPalette.receptionGreen,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            docket.discretionNote,
            style: textTheme.textStyle.copyWith(
              color: CourtlyInkPalette.paperWhite,
              fontSize: 14,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
