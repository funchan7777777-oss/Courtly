import 'package:courtly/features/reception_docket/domain/protocol_cue.dart';
import 'package:courtly/features/reception_docket/domain/reception_docket.dart';

abstract final class ReceptionDaybook {
  static const ReceptionDocket eveningSalon = ReceptionDocket(
    gatheringName: 'Juniper Room Reception',
    hostReference: 'Mara Ellison',
    venueSignature: 'North gallery, candlelit dinner setting',
    arrivalWindowLabel: '18:40 - 19:05',
    guestCadenceLabel: '28 guests, staggered arrival',
    attireSignal: 'Deep-toned formal with one quiet accent',
    tableTone: 'Warm introductions, no business-first seating',
    discretionNote: 'Keep dietary updates with the floor captain only.',
    preparationThreads: [
      'Confirm welcome tray timing',
      'Place reserved cards after final floral check',
      'Keep the east alcove open for late arrivals',
    ],
    intervals: [
      CourtesyInterval(
        slotLabel: '18:25',
        ritualName: 'Host arrival sweep',
        stewardNote: 'Check coat route, greeting line, and candle spacing.',
        isSettled: true,
      ),
      CourtesyInterval(
        slotLabel: '18:50',
        ritualName: 'First welcome pass',
        stewardNote: 'Introduce paired guests before room gets crowded.',
        isSettled: true,
      ),
      CourtesyInterval(
        slotLabel: '19:20',
        ritualName: 'Table transition',
        stewardNote: 'Move the west group first to keep the aisle calm.',
        isSettled: false,
      ),
    ],
    protocolCues: [
      ProtocolCue(
        cueName: 'Late arrival cover',
        socialSetting: 'Gallery entrance',
        gracefulMove: 'Offer a direct path to the alcove before greetings.',
        timingHint: 'Within two minutes',
        delicacy: CueDelicacy.attentive,
      ),
      ProtocolCue(
        cueName: 'Toast handoff',
        socialSetting: 'Dinner opening',
        gracefulMove: 'Let the host name the absent patron briefly.',
        timingHint: 'Before first pour',
        delicacy: CueDelicacy.formal,
      ),
      ProtocolCue(
        cueName: 'Conversation reset',
        socialSetting: 'East side table',
        gracefulMove: 'Shift from market talk toward travel and craft.',
        timingHint: 'After seating',
        delicacy: CueDelicacy.quiet,
      ),
    ],
  );
}
