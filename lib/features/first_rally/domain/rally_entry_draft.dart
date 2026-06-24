class RallyCredentialDraft {
  const RallyCredentialDraft({
    required this.courtsideAddress,
    required this.privateServePhrase,
  });

  final String courtsideAddress;
  final String privateServePhrase;

  bool get hasUsableShape {
    return courtsideAddress.trim().contains('@') &&
        privateServePhrase.trim().length >= 6;
  }
}

class RallyProfileDraft {
  const RallyProfileDraft({
    required this.displayNameSignal,
    required this.countryCircuit,
    required this.personalCourtline,
    required this.birthdateMarker,
    required this.playStyleKey,
    this.avatarImagePath,
  });

  final String displayNameSignal;
  final String countryCircuit;
  final String personalCourtline;
  final DateTime birthdateMarker;
  final String playStyleKey;
  final String? avatarImagePath;
}
