class CourtClipDispatch {
  const CourtClipDispatch({
    required this.clipId,
    required this.playerHandle,
    required this.courtsideName,
    required this.playerSignal,
    required this.ageBandLabel,
    required this.rallyClockLabel,
    required this.rallyNote,
    required this.coverFrameAsset,
    required this.drillVideoAsset,
    required this.playerPortraitAsset,
    required this.applauseCount,
    required this.relayCount,
    required this.hasApplauded,
    required this.isInCourtCircle,
    required this.clipReplies,
  });

  final String clipId;
  final String playerHandle;
  final String courtsideName;
  final CourtClipPlayerSignal playerSignal;
  final String ageBandLabel;
  final String rallyClockLabel;
  final String rallyNote;
  final String coverFrameAsset;
  final String drillVideoAsset;
  final String playerPortraitAsset;
  final int applauseCount;
  final int relayCount;
  final bool hasApplauded;
  final bool isInCourtCircle;
  final List<CourtClipReply> clipReplies;

  CourtClipDispatch copyWith({
    String? clipId,
    String? playerHandle,
    String? courtsideName,
    CourtClipPlayerSignal? playerSignal,
    String? ageBandLabel,
    String? rallyClockLabel,
    String? rallyNote,
    String? coverFrameAsset,
    String? drillVideoAsset,
    String? playerPortraitAsset,
    int? applauseCount,
    int? relayCount,
    bool? hasApplauded,
    bool? isInCourtCircle,
    List<CourtClipReply>? clipReplies,
  }) {
    return CourtClipDispatch(
      clipId: clipId ?? this.clipId,
      playerHandle: playerHandle ?? this.playerHandle,
      courtsideName: courtsideName ?? this.courtsideName,
      playerSignal: playerSignal ?? this.playerSignal,
      ageBandLabel: ageBandLabel ?? this.ageBandLabel,
      rallyClockLabel: rallyClockLabel ?? this.rallyClockLabel,
      rallyNote: rallyNote ?? this.rallyNote,
      coverFrameAsset: coverFrameAsset ?? this.coverFrameAsset,
      drillVideoAsset: drillVideoAsset ?? this.drillVideoAsset,
      playerPortraitAsset: playerPortraitAsset ?? this.playerPortraitAsset,
      applauseCount: applauseCount ?? this.applauseCount,
      relayCount: relayCount ?? this.relayCount,
      hasApplauded: hasApplauded ?? this.hasApplauded,
      isInCourtCircle: isInCourtCircle ?? this.isInCourtCircle,
      clipReplies: clipReplies ?? this.clipReplies,
    );
  }
}

enum CourtClipPlayerSignal { female, male }

class CourtClipReply {
  const CourtClipReply({
    required this.replyId,
    required this.playerHandle,
    required this.courtsideName,
    required this.clockLabel,
    required this.rallyObservation,
    required this.playerPortraitAsset,
  });

  final String replyId;
  final String playerHandle;
  final String courtsideName;
  final String clockLabel;
  final String rallyObservation;
  final String playerPortraitAsset;
}

class CourtClipReleaseDraft {
  const CourtClipReleaseDraft({required this.mood, required this.videoPath});

  final String mood;
  final String videoPath;
}
