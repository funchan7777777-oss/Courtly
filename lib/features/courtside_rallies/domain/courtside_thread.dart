class CourtsideRallyNote {
  const CourtsideRallyNote({
    required this.noteId,
    required this.speakerName,
    required this.rallyLine,
    required this.sentAtLabel,
    required this.isFromCurrentPlayer,
  });

  final String noteId;
  final String speakerName;
  final String rallyLine;
  final String sentAtLabel;
  final bool isFromCurrentPlayer;
}

class CourtsideRallyThread {
  const CourtsideRallyThread({
    required this.threadId,
    required this.playerHandle,
    required this.courtsideName,
    required this.ageBandLabel,
    required this.playerPortraitAsset,
    required this.courtCardAsset,
    required this.isCourtsideNow,
    required this.unreadRallyNotes,
    required this.lastExchangeLabel,
    required this.rallyNotes,
  });

  final String threadId;
  final String playerHandle;
  final String courtsideName;
  final String ageBandLabel;
  final String playerPortraitAsset;
  final String courtCardAsset;
  final bool isCourtsideNow;
  final int unreadRallyNotes;
  final String lastExchangeLabel;
  final List<CourtsideRallyNote> rallyNotes;

  String get preview {
    if (rallyNotes.isEmpty) {
      return 'Say hello before the next rally.';
    }

    return rallyNotes.last.rallyLine;
  }

  CourtsideRallyThread copyWith({
    String? threadId,
    String? playerHandle,
    String? courtsideName,
    String? ageBandLabel,
    String? playerPortraitAsset,
    String? courtCardAsset,
    bool? isCourtsideNow,
    int? unreadRallyNotes,
    String? lastExchangeLabel,
    List<CourtsideRallyNote>? rallyNotes,
  }) {
    return CourtsideRallyThread(
      threadId: threadId ?? this.threadId,
      playerHandle: playerHandle ?? this.playerHandle,
      courtsideName: courtsideName ?? this.courtsideName,
      ageBandLabel: ageBandLabel ?? this.ageBandLabel,
      playerPortraitAsset: playerPortraitAsset ?? this.playerPortraitAsset,
      courtCardAsset: courtCardAsset ?? this.courtCardAsset,
      isCourtsideNow: isCourtsideNow ?? this.isCourtsideNow,
      unreadRallyNotes: unreadRallyNotes ?? this.unreadRallyNotes,
      lastExchangeLabel: lastExchangeLabel ?? this.lastExchangeLabel,
      rallyNotes: rallyNotes ?? this.rallyNotes,
    );
  }
}

class CourtsideCircleInvitation {
  const CourtsideCircleInvitation({
    required this.invitationId,
    required this.playerHandle,
    required this.courtsideName,
    required this.ageBandLabel,
    required this.playerPortraitAsset,
    required this.courtMotto,
    required this.isInCourtCircle,
  });

  final String invitationId;
  final String playerHandle;
  final String courtsideName;
  final String ageBandLabel;
  final String playerPortraitAsset;
  final String courtMotto;
  final bool isInCourtCircle;

  CourtsideCircleInvitation copyWith({
    String? invitationId,
    String? playerHandle,
    String? courtsideName,
    String? ageBandLabel,
    String? playerPortraitAsset,
    String? courtMotto,
    bool? isInCourtCircle,
  }) {
    return CourtsideCircleInvitation(
      invitationId: invitationId ?? this.invitationId,
      playerHandle: playerHandle ?? this.playerHandle,
      courtsideName: courtsideName ?? this.courtsideName,
      ageBandLabel: ageBandLabel ?? this.ageBandLabel,
      playerPortraitAsset: playerPortraitAsset ?? this.playerPortraitAsset,
      courtMotto: courtMotto ?? this.courtMotto,
      isInCourtCircle: isInCourtCircle ?? this.isInCourtCircle,
    );
  }
}

class CourtsideCallSessionResult {
  const CourtsideCallSessionResult({required this.started});

  final bool started;
}
