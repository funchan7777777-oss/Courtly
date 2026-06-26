import 'package:courtly/features/first_rally/domain/rally_entry_draft.dart';
import 'package:courtly/shared/social/courtly_social_store.dart';
import 'package:courtly/shared/wallet/courtly_wallet_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RallyStoredSession {
  const RallyStoredSession({
    required this.displayNameSignal,
    required this.countryCircuit,
    required this.personalCourtline,
    required this.entryMethod,
    required this.birthdateMarker,
    required this.playStyleKey,
    this.avatarImagePath,
  });

  final String displayNameSignal;
  final String countryCircuit;
  final String personalCourtline;
  final String entryMethod;
  final DateTime birthdateMarker;
  final String playStyleKey;
  final String? avatarImagePath;
}

class RallySessionVault {
  static const String _activeEntryKey = 'courtly_active_entry';
  static const String _credentialAddressKey = 'courtly_credential_address';
  static const String _credentialPhraseKey = 'courtly_credential_phrase';
  static const String _displayNameKey = 'courtly_display_name';
  static const String _countryCircuitKey = 'courtly_country_circuit';
  static const String _personalCourtlineKey = 'courtly_personal_courtline';
  static const String _entryMethodKey = 'courtly_entry_method';
  static const String _avatarImagePathKey = 'courtly_avatar_image_path';
  static const String _appleIdentityNameKey = 'courtly_apple_identity_name';
  static const String _birthdateMarkerKey = 'courtly_birthdate_marker';
  static const String _playStyleKey = 'courtly_play_style_key';

  const RallySessionVault();

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
      birthdateMarker:
          DateTime.tryParse(preferences.getString(_birthdateMarkerKey) ?? '') ??
          DateTime(2000, 1, 1),
      playStyleKey: preferences.getString(_playStyleKey) ?? 'unspecified',
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
    await preferences.setString(
      _birthdateMarkerKey,
      profileDraft.birthdateMarker.toIso8601String(),
    );
    await preferences.setString(_playStyleKey, profileDraft.playStyleKey);
    await preferences.setString(_entryMethodKey, entryMethod);

    final avatarPath = profileDraft.avatarImagePath;
    if (avatarPath != null && avatarPath.trim().isNotEmpty) {
      await preferences.setString(_avatarImagePathKey, avatarPath);
    }
    await CourtlySocialStore.instance.removeStarterSeedContent();
  }

  Future<void> reactivateLocalSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_activeEntryKey, true);
    await preferences.setString(_entryMethodKey, 'local');
    await CourtlySocialStore.instance.removeStarterSeedContent();
  }

  Future<void> activateCredentialEntry(RallyCredentialDraft draft) async {
    final preferences = await SharedPreferences.getInstance();
    await rememberCredentialDraft(draft);

    final existingDisplayName = preferences.getString(_displayNameKey);
    if (existingDisplayName == null || existingDisplayName.trim().isEmpty) {
      final addressName = draft.courtsideAddress.split('@').first.trim();
      await preferences.setString(
        _displayNameKey,
        addressName.isEmpty ? 'Mira Vale' : addressName,
      );
    }

    final existingCircuit = preferences.getString(_countryCircuitKey);
    if (existingCircuit == null || existingCircuit.trim().isEmpty) {
      await preferences.setString(_countryCircuitKey, 'Courtly Circuit');
    }

    final existingCourtline = preferences.getString(_personalCourtlineKey);
    if (existingCourtline == null || existingCourtline.trim().isEmpty) {
      await preferences.setString(
        _personalCourtlineKey,
        'Ready for the next friendly match.',
      );
    }

    await preferences.setString(
      _birthdateMarkerKey,
      (DateTime.tryParse(preferences.getString(_birthdateMarkerKey) ?? '') ??
              DateTime(2000, 1, 1))
          .toIso8601String(),
    );
    await preferences.setString(
      _playStyleKey,
      preferences.getString(_playStyleKey) ?? 'unspecified',
    );
    await preferences.setBool(_activeEntryKey, true);
    await preferences.setString(_entryMethodKey, 'local');
    await CourtlySocialStore.instance.removeStarterSeedContent();
  }

  Future<void> activateAppleEntry({required String displayNameSignal}) async {
    await activateProfile(
      profileDraft: RallyProfileDraft(
        displayNameSignal: displayNameSignal.trim().isEmpty
            ? 'Mira Vale'
            : displayNameSignal.trim(),
        countryCircuit: 'Courtly Circuit',
        personalCourtline: 'Ready for the next friendly match.',
        birthdateMarker: DateTime(2000, 1, 1),
        playStyleKey: 'unspecified',
      ),
      entryMethod: 'apple',
    );
  }

  Future<void> deactivateActiveSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_activeEntryKey, false);
  }

  Future<void> deleteLocalAccount() async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.remove(_activeEntryKey),
      preferences.remove(_credentialAddressKey),
      preferences.remove(_credentialPhraseKey),
      preferences.remove(_displayNameKey),
      preferences.remove(_countryCircuitKey),
      preferences.remove(_personalCourtlineKey),
      preferences.remove(_entryMethodKey),
      preferences.remove(_avatarImagePathKey),
      preferences.remove(_appleIdentityNameKey),
      preferences.remove(_birthdateMarkerKey),
      preferences.remove(_playStyleKey),
      CourtlyWalletStore.instance.clearLocalWallet(),
    ]);
  }
}
