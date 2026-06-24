class WardrobeReadiness {
  const WardrobeReadiness({
    required this.readinessName,
    required this.inspectionFocus,
    required this.fabricCue,
    required this.accessoryAnchor,
    required this.weatherTact,
    required this.quietRisk,
    required this.completionRatio,
    required this.readinessFlags,
  });

  final String readinessName;
  final String inspectionFocus;
  final String fabricCue;
  final String accessoryAnchor;
  final String weatherTact;
  final String quietRisk;
  final double completionRatio;
  final List<String> readinessFlags;
}
