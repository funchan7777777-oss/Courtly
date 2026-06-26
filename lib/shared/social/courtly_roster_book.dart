import 'package:courtly/shared/data/courtly_media_assets.dart';
import 'package:courtly/shared/social/courtly_player_card.dart';

abstract final class CourtlyRosterBook {
  static String handleFromName(String courtsideName) {
    final normalized = courtsideName.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );
    return normalized.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static CourtlyPlayerCard fromCourtsideIdentity({
    String? playerHandle,
    required String courtsideName,
    String? ageBandLabel,
    String? divisionLabel,
    String? playerPortraitAsset,
    String? courtCardAsset,
    String? courtBio,
  }) {
    final resolvedHandle = playerHandle ?? handleFromName(courtsideName);
    final profile = _cardsByHandle[resolvedHandle];
    if (profile != null) {
      return CourtlyPlayerCard(
        playerHandle: profile.playerHandle,
        courtsideName: courtsideName,
        ageBandLabel: ageBandLabel ?? profile.ageBandLabel,
        divisionLabel: divisionLabel ?? profile.divisionLabel,
        playerPortraitAsset: playerPortraitAsset ?? profile.playerPortraitAsset,
        courtCardAsset: courtCardAsset ?? profile.courtCardAsset,
        courtBio: courtBio ?? profile.courtBio,
        practiceClipAssets: profile.practiceClipAssets,
        momentImageAssets: profile.momentImageAssets,
      );
    }

    return _buildProfile(
      playerHandle: resolvedHandle,
      index: resolvedHandle.hashCode.abs(),
      courtsideName: courtsideName,
      ageBandLabel: ageBandLabel,
      divisionLabel: divisionLabel,
      playerPortraitAsset: playerPortraitAsset,
      courtCardAsset: courtCardAsset,
      courtBio: courtBio,
    );
  }

  static CourtlyPlayerCard byHandle(String playerHandle) {
    return _cardsByHandle[playerHandle] ??
        _buildProfile(
          index: playerHandle.hashCode.abs(),
          courtsideName: _titleFromHandle(playerHandle),
        );
  }

  static CourtlyPlayerCard? knownByHandle(String playerHandle) {
    return _cardsByHandle[playerHandle];
  }

  static List<CourtlyPlayerCard> featuredCards(int count) {
    return _featuredProfiles.take(count).toList(growable: false);
  }

  static final List<CourtlyPlayerCard> _featuredProfiles = [
    for (var index = 0; index < _names.length; index++)
      _buildProfile(index: index, courtsideName: _names[index]),
  ];

  static final Map<String, CourtlyPlayerCard> _cardsByHandle = {
    for (final profile in _featuredProfiles) profile.playerHandle: profile,
  };

  static CourtlyPlayerCard _buildProfile({
    String? playerHandle,
    required int index,
    required String courtsideName,
    String? ageBandLabel,
    String? divisionLabel,
    String? playerPortraitAsset,
    String? courtCardAsset,
    String? courtBio,
  }) {
    final female = _femaleNames.contains(courtsideName);
    final heads = female
        ? CourtlyMediaAssets.womenHeads
        : CourtlyMediaAssets.menHeads;
    final safeHead = heads[index % heads.length];
    final safeHero = CourtlyMediaAssets
        .momentImages[index % CourtlyMediaAssets.momentImages.length];

    return CourtlyPlayerCard(
      playerHandle: playerHandle ?? handleFromName(courtsideName),
      courtsideName: courtsideName,
      ageBandLabel: ageBandLabel ?? '${23 + (index % 8)}',
      divisionLabel: divisionLabel ?? (female ? 'Female' : 'Male'),
      playerPortraitAsset: playerPortraitAsset ?? safeHead,
      courtCardAsset: courtCardAsset ?? safeHero,
      courtBio: courtBio ?? _bios[index % _bios.length],
      practiceClipAssets: [
        for (var offset = 0; offset < 6; offset++)
          CourtlyMediaAssets.momentImages[(index + offset) %
              CourtlyMediaAssets.momentImages.length],
      ],
      momentImageAssets: [
        CourtlyMediaAssets.momentImages[index %
            CourtlyMediaAssets.momentImages.length],
        CourtlyMediaAssets.momentImages[(index + 3) %
            CourtlyMediaAssets.momentImages.length],
      ],
    );
  }

  static String _titleFromHandle(String playerHandle) {
    return playerHandle
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static const List<String> _names = [
    'Mira Vale',
    'Jonas Keir',
    'Noemi Ashford',
    'Theo Marlow',
    'Siena Brooks',
    'Harlan Voss',
    'Lina Sato',
    'Rowan Ellis',
    'Ivy Calder',
    'Leon Ward',
    'Camden Rhys',
    'Rina Sol',
    'Miles Aoki',
    'Grace Lin',
    'Mara Ives',
    'Owen Lark',
    'Kai Arden',
    'Tessa Vale',
    'Elena Cruz',
    'Avery Stone',
  ];

  static const Set<String> _femaleNames = {
    'Mira Vale',
    'Noemi Ashford',
    'Siena Brooks',
    'Lina Sato',
    'Ivy Calder',
    'Rina Sol',
    'Grace Lin',
    'Mara Ives',
    'Tessa Vale',
    'Elena Cruz',
    'Avery Stone',
  };

  static const List<String> _bios = [
    'Collects footwork notes after every evening rally.',
    'Baseline rhythm, quick recovery, and clean court signals.',
    'Keeps patient rallies, sharper split steps, and calm match days.',
    'Night tennis, warmup ladders, and a quiet finish through every point.',
  ];
}
