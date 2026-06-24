import 'package:courtly/features/reception_docket/domain/protocol_cue.dart';

class CourtesyInterval {
  const CourtesyInterval({
    required this.slotLabel,
    required this.ritualName,
    required this.stewardNote,
    required this.isSettled,
  });

  final String slotLabel;
  final String ritualName;
  final String stewardNote;
  final bool isSettled;
}

class ReceptionDocket {
  const ReceptionDocket({
    required this.gatheringName,
    required this.hostReference,
    required this.venueSignature,
    required this.arrivalWindowLabel,
    required this.guestCadenceLabel,
    required this.attireSignal,
    required this.tableTone,
    required this.discretionNote,
    required this.preparationThreads,
    required this.intervals,
    required this.protocolCues,
  });

  final String gatheringName;
  final String hostReference;
  final String venueSignature;
  final String arrivalWindowLabel;
  final String guestCadenceLabel;
  final String attireSignal;
  final String tableTone;
  final String discretionNote;
  final List<String> preparationThreads;
  final List<CourtesyInterval> intervals;
  final List<ProtocolCue> protocolCues;
}
