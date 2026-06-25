import 'package:courtly/shared/data/courtly_media_assets.dart';
import 'package:courtly/shared/social/courtly_user_profile.dart';

abstract final class CourtlyUserDirectory {
  static String idFromName(String name) {
    final normalized = name.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );
    return normalized.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static CourtlyUserProfile fromIdentity({
    String? id,
    required String name,
    String? ageLabel,
    String? genderLabel,
    String? avatarAsset,
    String? heroAsset,
    String? bio,
  }) {
    final resolvedId = id ?? idFromName(name);
    final profile = _profilesById[resolvedId];
    if (profile != null) {
      return CourtlyUserProfile(
        id: profile.id,
        name: name,
        ageLabel: ageLabel ?? profile.ageLabel,
        genderLabel: genderLabel ?? profile.genderLabel,
        avatarAsset: avatarAsset ?? profile.avatarAsset,
        heroAsset: heroAsset ?? profile.heroAsset,
        bio: bio ?? profile.bio,
        videoAssets: profile.videoAssets,
        postAssets: profile.postAssets,
      );
    }

    return _buildProfile(
      id: resolvedId,
      index: resolvedId.hashCode.abs(),
      name: name,
      ageLabel: ageLabel,
      genderLabel: genderLabel,
      avatarAsset: avatarAsset,
      heroAsset: heroAsset,
      bio: bio,
    );
  }

  static CourtlyUserProfile byId(String id) {
    return _profilesById[id] ??
        _buildProfile(index: id.hashCode.abs(), name: _titleFromId(id));
  }

  static CourtlyUserProfile? knownById(String id) {
    return _profilesById[id];
  }

  static List<CourtlyUserProfile> featuredProfiles(int count) {
    return _featuredProfiles.take(count).toList(growable: false);
  }

  static final List<CourtlyUserProfile> _featuredProfiles = [
    for (var index = 0; index < _names.length; index++)
      _buildProfile(index: index, name: _names[index]),
  ];

  static final Map<String, CourtlyUserProfile> _profilesById = {
    for (final profile in _featuredProfiles) profile.id: profile,
  };

  static CourtlyUserProfile _buildProfile({
    String? id,
    required int index,
    required String name,
    String? ageLabel,
    String? genderLabel,
    String? avatarAsset,
    String? heroAsset,
    String? bio,
  }) {
    final female = _femaleNames.contains(name);
    final heads = female
        ? CourtlyMediaAssets.womenHeads
        : CourtlyMediaAssets.menHeads;
    final safeHead = heads[index % heads.length];
    final safeHero = CourtlyMediaAssets
        .postImages[index % CourtlyMediaAssets.postImages.length];

    return CourtlyUserProfile(
      id: id ?? idFromName(name),
      name: name,
      ageLabel: ageLabel ?? '${23 + (index % 8)}',
      genderLabel: genderLabel ?? (female ? 'Female' : 'Male'),
      avatarAsset: avatarAsset ?? safeHead,
      heroAsset: heroAsset ?? safeHero,
      bio: bio ?? _bios[index % _bios.length],
      videoAssets: [
        for (var offset = 0; offset < 6; offset++)
          CourtlyMediaAssets.postImages[(index + offset) %
              CourtlyMediaAssets.postImages.length],
      ],
      postAssets: [
        CourtlyMediaAssets.postImages[index %
            CourtlyMediaAssets.postImages.length],
        CourtlyMediaAssets.postImages[(index + 3) %
            CourtlyMediaAssets.postImages.length],
      ],
    );
  }

  static String _titleFromId(String id) {
    return id
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static const List<String> _names = [
    'Bettie Norton',
    'Francis Aguilar',
    'Claire West',
    'Noah Hart',
    'Mina Cross',
    'Hollis Park',
    'Sofia Lane',
    'Arden Cole',
    'Iris Stone',
    'Leo Grant',
    'Evan Perkins',
    'Rina Holt',
    'Miles Young',
    'Grace Liu',
    'Mara Cole',
    'Owen Reed',
    'Kai Fox',
    'Tessa Ward',
    'Elena Cruz',
    'Avery Stone',
  ];

  static const Set<String> _femaleNames = {
    'Bettie Norton',
    'Francis Aguilar',
    'Claire West',
    'Mina Cross',
    'Hollis Park',
    'Sofia Lane',
    'Iris Stone',
    'Grace Liu',
    'Mara Cole',
    'Tessa Ward',
    'Elena Cruz',
    'Avery Stone',
  };

  static const List<String> _bios = [
    'The racket catches the dusk wind, all worries fade with every hit.',
    'Baseline rhythm, quick recovery, and steady court notes.',
    'Looking for patient rallies, sharper footwork, and clean match days.',
    'Night tennis, warmup ladders, and a calm finish through every point.',
  ];
}
