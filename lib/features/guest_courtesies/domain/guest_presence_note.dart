enum GuestCareWeight {
  closeCircle('Close circle'),
  warmBridge('Warm bridge'),
  newAcquaintance('New acquaintance');

  const GuestCareWeight(this.tableLabel);

  final String tableLabel;
}

class GuestPresenceNote {
  const GuestPresenceNote({
    required this.guestAlias,
    required this.relationshipContext,
    required this.seatingTexture,
    required this.welcomeGesture,
    required this.conversationOpening,
    required this.boundaryCare,
    required this.careWeight,
  });

  final String guestAlias;
  final String relationshipContext;
  final String seatingTexture;
  final String welcomeGesture;
  final String conversationOpening;
  final String boundaryCare;
  final GuestCareWeight careWeight;
}
