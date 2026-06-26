class CourtMomentEntry {
  const CourtMomentEntry({
    required this.momentId,
    required this.playerHandle,
    required this.courtsideName,
    required this.rallyClockLabel,
    required this.courtNote,
    required this.momentImageAsset,
    required this.playerPortraitAsset,
    required this.applauseCount,
    required this.hasApplauded,
    required this.isInCourtCircle,
    required this.rallyReplies,
    required this.practiceClipAssets,
  });

  final String momentId;
  final String playerHandle;
  final String courtsideName;
  final String rallyClockLabel;
  final String courtNote;
  final String momentImageAsset;
  final String playerPortraitAsset;
  final int applauseCount;
  final bool hasApplauded;
  final bool isInCourtCircle;
  final List<CourtMomentReply> rallyReplies;
  final List<String> practiceClipAssets;

  CourtMomentEntry copyWith({
    String? momentId,
    String? playerHandle,
    String? courtsideName,
    String? rallyClockLabel,
    String? courtNote,
    String? momentImageAsset,
    String? playerPortraitAsset,
    int? applauseCount,
    bool? hasApplauded,
    bool? isInCourtCircle,
    List<CourtMomentReply>? rallyReplies,
    List<String>? practiceClipAssets,
  }) {
    return CourtMomentEntry(
      momentId: momentId ?? this.momentId,
      playerHandle: playerHandle ?? this.playerHandle,
      courtsideName: courtsideName ?? this.courtsideName,
      rallyClockLabel: rallyClockLabel ?? this.rallyClockLabel,
      courtNote: courtNote ?? this.courtNote,
      momentImageAsset: momentImageAsset ?? this.momentImageAsset,
      playerPortraitAsset: playerPortraitAsset ?? this.playerPortraitAsset,
      applauseCount: applauseCount ?? this.applauseCount,
      hasApplauded: hasApplauded ?? this.hasApplauded,
      isInCourtCircle: isInCourtCircle ?? this.isInCourtCircle,
      rallyReplies: rallyReplies ?? this.rallyReplies,
      practiceClipAssets: practiceClipAssets ?? this.practiceClipAssets,
    );
  }
}

class CourtMomentReply {
  const CourtMomentReply({
    required this.replyId,
    required this.playerHandle,
    required this.courtsideName,
    required this.rallyClockLabel,
    required this.courtNote,
    required this.playerPortraitAsset,
  });

  final String replyId;
  final String playerHandle;
  final String courtsideName;
  final String rallyClockLabel;
  final String courtNote;
  final String playerPortraitAsset;
}

class CourtMomentDraft {
  const CourtMomentDraft({required this.courtNote, required this.imagePath});

  final String courtNote;
  final String imagePath;
}

class CourtRhythmStanding {
  const CourtRhythmStanding({
    required this.standingRank,
    required this.courtsideName,
    required this.playerPortraitAsset,
    required this.rallyStreakDays,
  });

  final int standingRank;
  final String courtsideName;
  final String playerPortraitAsset;
  final int rallyStreakDays;
}
