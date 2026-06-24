import 'package:courtly/features/guest_courtesies/domain/guest_presence_note.dart';

abstract final class GuestRegistrySeed {
  static const List<GuestPresenceNote> tableCourtesies = [
    GuestPresenceNote(
      guestAlias: 'Lenora Pike',
      relationshipContext: 'Longtime patron of the gallery wing',
      seatingTexture: 'Keep near the host, away from the music corner.',
      welcomeGesture: 'Offer sparkling water before coat check.',
      conversationOpening: 'Ask about the restoration notes she shared.',
      boundaryCare: 'Avoid asking about winter travel plans.',
      careWeight: GuestCareWeight.closeCircle,
    ),
    GuestPresenceNote(
      guestAlias: 'Theo Maren',
      relationshipContext: 'First dinner with the foundation circle',
      seatingTexture: 'Seat beside a steady conversational anchor.',
      welcomeGesture: 'Name one shared interest before introductions.',
      conversationOpening: 'Open with printmaking, not fundraising.',
      boundaryCare: 'Let him volunteer professional details.',
      careWeight: GuestCareWeight.newAcquaintance,
    ),
    GuestPresenceNote(
      guestAlias: 'Sabine Vale',
      relationshipContext: 'Bridge guest between two donor families',
      seatingTexture: 'Place where she can see both table ends.',
      welcomeGesture: 'Acknowledge the blue-room preview she arranged.',
      conversationOpening: 'Mention the ceramic commission quietly.',
      boundaryCare: 'Keep seating change requests private.',
      careWeight: GuestCareWeight.warmBridge,
    ),
  ];
}
