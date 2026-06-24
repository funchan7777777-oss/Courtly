import 'package:courtly/features/first_rally/domain/rally_entry_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RallyStoredSession {
  const RallyStoredSession({
    required this.displayNameSignal,
    required this.countryCircuit,
    required this.personalCourtline,
    required this.entryMethod,
    this.avatarImagePath,
  });

  final String displayNameSignal;
  final String countryCircuit;
  final String personalCourtline;
  final String entryMethod;
  final String? avatarImagePath;
}

class RallySessionVault {
  static const String _onboardingSettledKey = 'courtly_onboarding_settled';
  static const String _activeEntryKey = 'courtly_active_entry';
  static const String _credentialAddressKey = 'courtly_credential_address';
  static const String _credentialPhraseKey = 'courtly_credential_phrase';
  static const String _displayNameKey = 'courtly_display_name';
  static const String _countryCircuitKey = 'courtly_country_circuit';
  static const String _personalCourtlineKey = 'courtly_personal_courtline';
  static const String _entryMethodKey = 'courtly_entry_method';
  static const String _avatarImagePathKey = 'courtly_avatar_image_path';
  static const String _appleIdentityNameKey = 'courtly_apple_identity_name';

  const RallySessionVault();

  Future<bool> hasFinishedOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_onboardingSettledKey) ?? false;
  }

  Future<void> markOnboardingSettled() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingSettledKey, true);
  }

  Future<RallyStoredSession?> readActiveSession() async {
    final preferences = await SharedPreferences.getInstance();
    final isActive = preferences.getBool(_activeEntryKey) ?? false;
    final displayName = preferences.getString(_displayNameKey);

    if (!isActive || displayName == null || displayName.trim().isEmpty) {
      return null;
    }

    return RallyStoredSession(
      displayNameSignal: displayName,
      countryCircuit: preferences.getString(_countryCircuitKey) ?? '',
      personalCourtline: preferences.getString(_personalCourtlineKey) ?? '',
      entryMethod: preferences.getString(_entryMethodKey) ?? 'local',
      avatarImagePath: preferences.getString(_avatarImagePathKey),
    );
  }

  Future<void> rememberCredentialDraft(RallyCredentialDraft draft) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _credentialAddressKey,
      draft.courtsideAddress.trim().toLowerCase(),
    );
    await preferences.setString(
      _credentialPhraseKey,
      draft.privateServePhrase.trim(),
    );
  }

  Future<bool> credentialMatches(RallyCredentialDraft draft) async {
    final preferences = await SharedPreferences.getInstance();
    final storedAddress = preferences.getString(_credentialAddressKey);
    final storedPhrase = preferences.getString(_credentialPhraseKey);

    return storedAddress == draft.courtsideAddress.trim().toLowerCase() &&
        storedPhrase == draft.privateServePhrase.trim();
  }

  Future<bool> hasLocalCredential() async {
    final preferences = await SharedPreferences.getInstance();
    final storedAddress = preferences.getString(_credentialAddressKey);
    final storedPhrase = preferences.getString(_credentialPhraseKey);
    return storedAddress != null &&
        storedAddress.isNotEmpty &&
        storedPhrase != null &&
        storedPhrase.isNotEmpty;
  }

  Future<void> rememberAppleIdentityName(String? displayName) async {
    final cleanName = displayName?.trim();
    if (cleanName == null || cleanName.isEmpty) {
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_appleIdentityNameKey, cleanName);
  }

  Future<String?> readAppleIdentityName() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_appleIdentityNameKey);
  }

  Future<void> activateProfile({
    required RallyProfileDraft profileDraft,
    required String entryMethod,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_activeEntryKey, true);
    await preferences.setString(
      _displayNameKey,
      profileDraft.displayNameSignal.trim(),
    );
    await preferences.setString(
      _countryCircuitKey,
      profileDraft.countryCircuit.trim(),
    );
    await preferences.setString(
      _personalCourtlineKey,
      profileDraft.personalCourtline.trim(),
    );
    await preferences.setString(_entryMethodKey, entryMethod);

    final avatarPath = profileDraft.avatarImagePath;
    if (avatarPath != null && avatarPath.trim().isNotEmpty) {
      await preferences.setString(_avatarImagePathKey, avatarPath);
    }
  }

  Future<void> reactivateLocalSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_activeEntryKey, true);
    await preferences.setString(_entryMethodKey, 'local');
  }
}
