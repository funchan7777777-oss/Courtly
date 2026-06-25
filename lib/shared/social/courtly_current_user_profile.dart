import 'package:courtly/features/first_rally/data/rally_session_vault.dart';
import 'package:courtly/shared/data/courtly_media_assets.dart';

class CourtlyCurrentUserProfile {
  const CourtlyCurrentUserProfile({
    required this.displayName,
    required this.avatarPath,
  });

  static const String userId = 'you';
  static const String fallbackAvatarPath =
      'assets/images/head/women/woman_head_01.jpg';

  final String displayName;
  final String avatarPath;

  static CourtlyCurrentUserProfile fallback() {
    return const CourtlyCurrentUserProfile(
      displayName: 'You',
      avatarPath: fallbackAvatarPath,
    );
  }
}

Future<CourtlyCurrentUserProfile> loadCourtlyCurrentUserProfile() async {
  final session = await const RallySessionVault().readActiveSession();
  if (session == null) {
    return CourtlyCurrentUserProfile.fallback();
  }

  final displayName = session.displayNameSignal.trim();
  final avatarPath = _currentUserAvatarPath(session.avatarImagePath);

  return CourtlyCurrentUserProfile(
    displayName: displayName.isEmpty ? 'You' : displayName,
    avatarPath: avatarPath,
  );
}

String _currentUserAvatarPath(String? avatarImagePath) {
  final path = avatarImagePath?.trim();
  if (path == null || path.isEmpty) {
    return CourtlyCurrentUserProfile.fallbackAvatarPath;
  }

  if (path.startsWith('assets/images/head/') &&
      !CourtlyMediaAssets.allHeads.contains(path)) {
    return CourtlyCurrentUserProfile.fallbackAvatarPath;
  }

  return path;
}
