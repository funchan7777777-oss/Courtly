class CourtlyUserProfile {
  const CourtlyUserProfile({
    required this.id,
    required this.name,
    required this.ageLabel,
    required this.genderLabel,
    required this.avatarAsset,
    required this.heroAsset,
    required this.bio,
    required this.videoAssets,
    required this.postAssets,
  });

  final String id;
  final String name;
  final String ageLabel;
  final String genderLabel;
  final String avatarAsset;
  final String heroAsset;
  final String bio;
  final List<String> videoAssets;
  final List<String> postAssets;
}

