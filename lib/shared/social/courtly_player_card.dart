class CourtlyPlayerCard {
  const CourtlyPlayerCard({
    required this.playerHandle,
    required this.courtsideName,
    required this.ageBandLabel,
    required this.divisionLabel,
    required this.playerPortraitAsset,
    required this.courtCardAsset,
    required this.courtBio,
    required this.practiceClipAssets,
    required this.momentImageAssets,
  });

  final String playerHandle;
  final String courtsideName;
  final String ageBandLabel;
  final String divisionLabel;
  final String playerPortraitAsset;
  final String courtCardAsset;
  final String courtBio;
  final List<String> practiceClipAssets;
  final List<String> momentImageAssets;
}
