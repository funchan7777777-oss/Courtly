import 'package:courtly/features/first_rally/data/rally_session_vault.dart';
import 'package:courtly/shared/data/courtly_media_assets.dart';

class CourtlyCurrentPlayerProfile {
  const CourtlyCurrentPlayerProfile({
    required this.displayName,
    required this.avatarPath,
  });

  static const String playerHandle = 'you';
  static const String fallbackAvatarPath =
      'assets/images/courtly_members/women/courtly_member_w_01.jpg';

  final String displayName;
  final String avatarPath;

  static CourtlyCurrentPlayerProfile fallback() {
    return const CourtlyCurrentPlayerProfile(
      displayName: 'You',
      avatarPath: fallbackAvatarPath,
    );
  }
}

Future<CourtlyCurrentPlayerProfile> loadCourtlyCurrentPlayerProfile() async {
  final session = await const RallySessionVault().readActiveSession();
  if (session == null) {
    return CourtlyCurrentPlayerProfile.fallback();
  }

  final displayName = session.displayNameSignal.trim();
  final avatarPath = _currentPlayerAvatarPath(session.avatarImagePath);

  return CourtlyCurrentPlayerProfile(
    displayName: displayName.isEmpty ? 'You' : displayName,
    avatarPath: avatarPath,
  );
}

String _currentPlayerAvatarPath(String? avatarImagePath) {
  final path = avatarImagePath?.trim();
  if (path == null || path.isEmpty) {
    return CourtlyCurrentPlayerProfile.fallbackAvatarPath;
  }

  if (path.startsWith('assets/images/courtly_members/') &&
      !CourtlyMediaAssets.allHeads.contains(path)) {
    return CourtlyCurrentPlayerProfile.fallbackAvatarPath;
  }

  return path;
}
