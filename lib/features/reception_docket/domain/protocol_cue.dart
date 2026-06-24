enum CueDelicacy {
  quiet('Quiet'),
  attentive('Attentive'),
  formal('Formal');

  const CueDelicacy(this.presentationLabel);

  final String presentationLabel;
}

class ProtocolCue {
  const ProtocolCue({
    required this.cueName,
    required this.socialSetting,
    required this.gracefulMove,
    required this.timingHint,
    required this.delicacy,
  });

  final String cueName;
  final String socialSetting;
  final String gracefulMove;
  final String timingHint;
  final CueDelicacy delicacy;
}
