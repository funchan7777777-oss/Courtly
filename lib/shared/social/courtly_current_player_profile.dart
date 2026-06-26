import 'package:courtly/features/first_rally/data/rally_session_vault.dart';

class CourtlyCurrentPlayerProfile {
  const CourtlyCurrentPlayerProfile({
    required this.displayName,
    required this.avatarPath,
  });

  static const String playerHandle = 'you';
  static const String placeholderAvatarPath = '';

  final String displayName;
  final String avatarPath;

  static CourtlyCurrentPlayerProfile fallback() {
    return const CourtlyCurrentPlayerProfile(
      displayName: 'You',
      avatarPath: placeholderAvatarPath,
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
  if (path == null ||
      path.isEmpty ||
      path == 'assets/images/courtly_members/women/courtly_member_w_01.jpg') {
    return CourtlyCurrentPlayerProfile.placeholderAvatarPath;
  }

  return path;
}
