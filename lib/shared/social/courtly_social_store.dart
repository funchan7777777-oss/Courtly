import 'dart:convert';
import 'dart:math';

import 'package:courtly/shared/social/courtly_content_safety.dart';
import 'package:courtly/shared/social/courtly_roster_book.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourtlyStoredMessage {
  const CourtlyStoredMessage({
    required this.noteId,
    required this.speakerName,
    required this.rallyLine,
    required this.sentAtLabel,
    required this.isFromCurrentPlayer,
  });

  final String noteId;
  final String speakerName;
  final String rallyLine;
  final String sentAtLabel;
  final bool isFromCurrentPlayer;

  Map<String, Object?> toJson() {
    return {
      'noteId': noteId,
      'speakerName': speakerName,
      'rallyLine': rallyLine,
      'sentAtLabel': sentAtLabel,
      'isFromCurrentPlayer': isFromCurrentPlayer,
    };
  }

  static CourtlyStoredMessage fromJson(Map<String, Object?> json) {
    return CourtlyStoredMessage(
      noteId: json['noteId'] as String? ?? json['id'] as String? ?? '',
      speakerName:
          json['speakerName'] as String? ?? json['senderName'] as String? ?? '',
      rallyLine: json['rallyLine'] as String? ?? json['body'] as String? ?? '',
      sentAtLabel:
          json['sentAtLabel'] as String? ?? json['timeLabel'] as String? ?? '',
      isFromCurrentPlayer:
          json['isFromCurrentPlayer'] as bool? ??
          json['isMine'] as bool? ??
          false,
    );
  }
}

class CourtlySystemMessage {
  const CourtlySystemMessage({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.timeLabel,
    this.playerHandle,
    this.targetId,
  });

  final String id;
  final String kind;
  final String title;
  final String body;
  final String timeLabel;
  final String? playerHandle;
  final String? targetId;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'kind': kind,
      'title': title,
      'body': body,
      'timeLabel': timeLabel,
      'playerHandle': playerHandle,
      'targetId': targetId,
    };
  }

  static CourtlySystemMessage fromJson(Map<String, Object?> json) {
    return CourtlySystemMessage(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? 'system',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
      playerHandle: json['playerHandle'] as String?,
      targetId: json['targetId'] as String?,
    );
  }
}

class CourtlyPublishedMoment {
  const CourtlyPublishedMoment({
    required this.momentId,
    required this.courtNote,
    required this.imagePath,
    required this.timeLabel,
  });

  final String momentId;
  final String courtNote;
  final String imagePath;
  final String timeLabel;

  Map<String, Object?> toJson() {
    return {
      'momentId': momentId,
      'courtNote': courtNote,
      'imagePath': imagePath,
      'timeLabel': timeLabel,
    };
  }

  static CourtlyPublishedMoment fromJson(Map<String, Object?> json) {
    return CourtlyPublishedMoment(
      momentId: json['momentId'] as String? ?? json['id'] as String? ?? '',
      courtNote: json['courtNote'] as String? ?? json['body'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
    );
  }
}

class CourtlyPublishedClip {
  const CourtlyPublishedClip({
    required this.clipId,
    required this.rallyNote,
    required this.videoPath,
    required this.timeLabel,
  });

  final String clipId;
  final String rallyNote;
  final String videoPath;
  final String timeLabel;

  Map<String, Object?> toJson() {
    return {
      'clipId': clipId,
      'rallyNote': rallyNote,
      'videoPath': videoPath,
      'timeLabel': timeLabel,
    };
  }

  static CourtlyPublishedClip fromJson(Map<String, Object?> json) {
    return CourtlyPublishedClip(
      clipId: json['clipId'] as String? ?? json['id'] as String? ?? '',
      rallyNote:
          json['rallyNote'] as String? ?? json['caption'] as String? ?? '',
      videoPath: json['videoPath'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
    );
  }
}

class CourtlyBlockedPlayer {
  const CourtlyBlockedPlayer({
    required this.playerHandle,
    required this.courtsideName,
    this.playerPortraitAsset,
  });

  final String playerHandle;
  final String courtsideName;
  final String? playerPortraitAsset;

  Map<String, Object?> toJson() {
    return {
      'playerHandle': playerHandle,
      'courtsideName': courtsideName,
      'playerPortraitAsset': playerPortraitAsset,
    };
  }

  static CourtlyBlockedPlayer fromJson(Map<String, Object?> json) {
    return CourtlyBlockedPlayer(
      playerHandle:
          json['playerHandle'] as String? ?? json['id'] as String? ?? '',
      courtsideName: json['courtsideName'] as String? ?? '',
      playerPortraitAsset: json['playerPortraitAsset'] as String?,
    );
  }
}

class CourtlySocialStore {
  const CourtlySocialStore._();

  static const instance = CourtlySocialStore._();
  static final ValueNotifier<int> _relationshipVersion = ValueNotifier<int>(0);
  static final ValueNotifier<int> _messageCenterVersion = ValueNotifier<int>(0);
  static final ValueNotifier<int> _publishedContentVersion = ValueNotifier<int>(
    0,
  );

  ValueNotifier<int> get relationshipVersion => _relationshipVersion;
  ValueNotifier<int> get messageCenterVersion => _messageCenterVersion;
  ValueNotifier<int> get publishedContentVersion => _publishedContentVersion;

  static const _reportedContentKey = 'courtly_reported_content_ids';
  static const _blockedPlayersKey = 'courtly_blocked_player_handles';
  static const _blockedPlayerCardsKey = 'courtly_blocked_player_cards';
  static const _courtCircleRequestsKey = 'courtly_court_circle_request_handles';
  static const _courtCircleFollowingKey = 'courtly_court_circle_following';
  static const _courtCircleFollowersKey = 'courtly_court_circle_followers';
  static const _rallyMessagePlayersKey = 'courtly_rally_message_players';
  static const _messagePrefix = 'courtly_messages_for_';
  static const _systemMessagesKey = 'courtly_system_messages';
  static const _legacyMessageCenterSeededKey = 'courtly_message_center_seeded';
  static const _legacyLoginFollowerBoostKey =
      'courtly_login_follower_boost_seeded';
  static const _openingFollowerNoticesKey =
      'courtly_opening_follower_notices_v2';
  static const _publishedMomentsKey = 'courtly_published_court_moments';
  static const _publishedClipsKey = 'courtly_published_training_clips';
  static const _reportPrefix = 'courtly_report_detail_';

  Future<Set<String>> reportedContentIds() async {
    return _loadStringSet(_reportedContentKey);
  }

  Future<Set<String>> blockedPlayerHandles() async {
    return _loadStringSet(_blockedPlayersKey);
  }

  Future<List<String>> followerPlayerHandles() async {
    return (await _loadStringSet(
      _courtCircleFollowersKey,
    )).toList(growable: false)..sort();
  }

  Future<List<String>> followingPlayerHandles() async {
    return (await _loadStringSet(
      _courtCircleFollowingKey,
    )).toList(growable: false)..sort();
  }

  Future<List<String>> outgoingFollowPlayerHandles() async {
    final following = await _loadStringSet(_courtCircleFollowingKey);
    final requests = await _loadStringSet(_courtCircleRequestsKey);
    final ids = {...following, ...requests}.toList(growable: false);
    return ids..sort();
  }

  Future<List<CourtlyBlockedPlayer>> loadBlockedPlayers() async {
    final preferences = await SharedPreferences.getInstance();
    final ids = _readStringList(preferences, _blockedPlayersKey);
    final summaries = _loadBlockedPlayerSummaryMap(preferences);

    return ids
        .map((id) {
          final stored = summaries[id];
          if (stored != null && stored.courtsideName.trim().isNotEmpty) {
            return stored;
          }

          final known = CourtlyRosterBook.knownByHandle(id);
          if (known != null) {
            return CourtlyBlockedPlayer(
              playerHandle: known.playerHandle,
              courtsideName: known.courtsideName,
              playerPortraitAsset: known.playerPortraitAsset,
            );
          }

          return CourtlyBlockedPlayer(
            playerHandle: id,
            courtsideName: 'Hidden player',
          );
        })
        .where((profile) => profile.playerHandle.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<bool> isContentReported(String contentId) async {
    return (await reportedContentIds()).contains(contentId);
  }

  Future<bool> isPlayerBlocked(String playerHandle) async {
    return (await blockedPlayerHandles()).contains(playerHandle);
  }

  Future<void> reportContent({
    required String contentId,
    required String type,
    required String reason,
    String? playerHandle,
    String? summary,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = _readStringList(preferences, _reportedContentKey);
    if (!ids.contains(contentId)) {
      ids.add(contentId);
      await preferences.setStringList(_reportedContentKey, ids);
    }
    await preferences.setString(
      '$_reportPrefix$contentId',
      jsonEncode({
        'contentId': contentId,
        'type': type,
        'reason': reason,
        'playerHandle': playerHandle,
        'summary': summary,
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );
    await addSystemMessage(
      CourtlySystemMessage(
        id: 'report-${contentId.hashCode}-${DateTime.now().microsecondsSinceEpoch}',
        kind: 'report',
        title: 'Report submitted',
        body:
            'We saved your report and hid the reported content locally. Safety concerns can also be sent to ${CourtlyContentSafety.supportEmail}.',
        timeLabel: _formatTime(DateTime.now()),
        playerHandle: playerHandle,
        targetId: 'report:$contentId',
      ),
    );
  }

  Future<void> blockPlayer(
    String playerHandle, {
    String? courtsideName,
    String? playerPortraitAsset,
  }) async {
    final cleanPlayerHandle = playerHandle.trim();
    if (cleanPlayerHandle.isEmpty) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final ids = _readStringList(preferences, _blockedPlayersKey);
    final summaryChanged = await _saveBlockedPlayerSummary(
      preferences,
      playerHandle: cleanPlayerHandle,
      courtsideName: courtsideName,
      playerPortraitAsset: playerPortraitAsset,
    );
    if (!ids.contains(cleanPlayerHandle)) {
      ids.add(cleanPlayerHandle);
      await _writeStringList(preferences, _blockedPlayersKey, ids);
      await addSystemMessage(
        CourtlySystemMessage(
          id: 'block-$cleanPlayerHandle-${DateTime.now().microsecondsSinceEpoch}',
          kind: 'block',
          title: 'Player blocked',
          body:
              'That player and their messages are hidden from courtside rallies.',
          timeLabel: _formatTime(DateTime.now()),
          playerHandle: cleanPlayerHandle,
          targetId: 'player:$cleanPlayerHandle',
        ),
      );
      _notifyRelationshipChanged();
    } else if (summaryChanged) {
      _notifyRelationshipChanged();
    }
  }

  Future<void> unblockPlayer(String playerHandle) async {
    final cleanPlayerHandle = playerHandle.trim();
    if (cleanPlayerHandle.isEmpty) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final ids = _readStringList(preferences, _blockedPlayersKey);
    if (!ids.remove(cleanPlayerHandle)) {
      return;
    }

    await _writeStringList(preferences, _blockedPlayersKey, ids);
    final summaries = _loadBlockedPlayerSummaryMap(preferences);
    if (summaries.remove(cleanPlayerHandle) != null) {
      await _storeBlockedPlayerSummaries(preferences, summaries);
    }
    _notifyRelationshipChanged();
  }

  Future<void> requestFollow(String playerHandle) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = _readStringList(preferences, _courtCircleRequestsKey);
    if (!ids.contains(playerHandle)) {
      ids.add(playerHandle);
      await _writeStringList(preferences, _courtCircleRequestsKey, ids);
      final followers = _readStringList(preferences, _courtCircleFollowersKey);
      if (followers.contains(playerHandle)) {
        final following = _readStringList(
          preferences,
          _courtCircleFollowingKey,
        );
        if (!following.contains(playerHandle)) {
          following.add(playerHandle);
          await _writeStringList(
            preferences,
            _courtCircleFollowingKey,
            following,
          );
        }
        await addSystemMessage(
          CourtlySystemMessage(
            id: 'mutual-$playerHandle-${DateTime.now().microsecondsSinceEpoch}',
            kind: 'mutual',
            title: 'Mutual follow unlocked',
            body:
                'You and this player follow each other. Private chat is open.',
            timeLabel: _formatTime(DateTime.now()),
            playerHandle: playerHandle,
            targetId: 'player:$playerHandle',
          ),
        );
      } else {
        await addSystemMessage(
          CourtlySystemMessage(
            id: 'follow-$playerHandle-${DateTime.now().microsecondsSinceEpoch}',
            kind: 'follow',
            title: 'Follow request sent',
            body: 'Chat unlocks after this player follows you back.',
            timeLabel: _formatTime(DateTime.now()),
            playerHandle: playerHandle,
            targetId: 'player:$playerHandle',
          ),
        );
      }
      _notifyRelationshipChanged();
    }
  }

  Future<void> followPlayerLocally(String playerHandle) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = _readStringList(preferences, _courtCircleFollowingKey);
    if (!ids.contains(playerHandle)) {
      ids.add(playerHandle);
      await _writeStringList(preferences, _courtCircleFollowingKey, ids);
      final followers = _readStringList(preferences, _courtCircleFollowersKey);
      await addSystemMessage(
        CourtlySystemMessage(
          id: followers.contains(playerHandle)
              ? 'mutual-$playerHandle-${DateTime.now().microsecondsSinceEpoch}'
              : 'follow-$playerHandle-${DateTime.now().microsecondsSinceEpoch}',
          kind: followers.contains(playerHandle) ? 'mutual' : 'follow',
          title: followers.contains(playerHandle)
              ? 'Mutual follow unlocked'
              : 'Following player',
          body: followers.contains(playerHandle)
              ? 'You and this player follow each other. Private chat is open.'
              : 'You are following this player.',
          timeLabel: _formatTime(DateTime.now()),
          playerHandle: playerHandle,
          targetId: 'player:$playerHandle',
        ),
      );
      _notifyRelationshipChanged();
    }
  }

  Future<void> unfollowPlayer(String playerHandle) async {
    final cleanPlayerHandle = playerHandle.trim();
    if (cleanPlayerHandle.isEmpty) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final following = _readStringList(preferences, _courtCircleFollowingKey);
    final requests = _readStringList(preferences, _courtCircleRequestsKey);
    final removedFollowing = following.remove(cleanPlayerHandle);
    final removedRequest = requests.remove(cleanPlayerHandle);
    if (!removedFollowing && !removedRequest) {
      return;
    }

    await _writeStringList(preferences, _courtCircleFollowingKey, following);
    await _writeStringList(preferences, _courtCircleRequestsKey, requests);
    _notifyRelationshipChanged();
  }

  Future<bool> hasRequestedFollow(String playerHandle) async {
    return (await _loadStringSet(
      _courtCircleRequestsKey,
    )).contains(playerHandle);
  }

  Future<bool> isFollowing(String playerHandle) async {
    return (await _loadStringSet(
      _courtCircleFollowingKey,
    )).contains(playerHandle);
  }

  Future<bool> isMutualFollow(String playerHandle) async {
    final following = await isFollowing(playerHandle);
    final followers = await _loadStringSet(_courtCircleFollowersKey);
    return following && followers.contains(playerHandle);
  }

  Future<List<String>> mutualFollowPlayerHandles() async {
    final following = await _loadStringSet(_courtCircleFollowingKey);
    final followers = await _loadStringSet(_courtCircleFollowersKey);
    return following.where(followers.contains).toList(growable: false)..sort();
  }

  Future<void> removeStarterSeedContent() async {
    final preferences = await SharedPreferences.getInstance();
    final changed = await _removeSyntheticStarterContent(preferences);
    if (changed) {
      _notifyRelationshipChanged();
      _notifyMessageCenterChanged();
    }
  }

  Future<void> ensureOpeningFollowerNotices() async {
    final preferences = await SharedPreferences.getInstance();
    final cleaned = await _removeSyntheticStarterContent(preferences);
    if (preferences.getBool(_openingFollowerNoticesKey) == true) {
      if (cleaned) {
        _notifyRelationshipChanged();
        _notifyMessageCenterChanged();
      }
      return;
    }

    final random = Random(DateTime.now().microsecondsSinceEpoch);
    final followers = _readStringList(preferences, _courtCircleFollowersKey);
    final blocked = _readStringList(preferences, _blockedPlayersKey).toSet();
    final candidates = CourtlyRosterBook.featuredCards(20)
        .where(
          (profile) =>
              !followers.contains(profile.playerHandle) &&
              !blocked.contains(profile.playerHandle),
        )
        .toList();
    candidates.shuffle(random);

    final followerCount = min(candidates.length, 2 + random.nextInt(2));
    final selectedProfiles = candidates.take(followerCount).toList();
    final now = DateTime.now();
    final messages = await loadSystemMessages();
    final followerMessages = <CourtlySystemMessage>[];

    for (final profile in selectedProfiles) {
      followers.add(profile.playerHandle);
      followerMessages.add(
        CourtlySystemMessage(
          id: 'opening-follower-${profile.playerHandle}-${now.microsecondsSinceEpoch}',
          kind: 'follow',
          title: 'New court follower',
          body:
              '${profile.courtsideName} followed your court profile. Follow back to unlock private chat.',
          timeLabel: _formatTime(now),
          playerHandle: profile.playerHandle,
          targetId: 'player:${profile.playerHandle}',
        ),
      );
    }

    await _writeStringList(preferences, _courtCircleFollowersKey, followers);
    if (followerMessages.isNotEmpty) {
      await preferences.setString(
        _systemMessagesKey,
        jsonEncode(
          [
            ...followerMessages,
            ...messages.where(
              (message) => !message.id.startsWith('opening-follower-'),
            ),
          ].take(60).map((message) => message.toJson()).toList(),
        ),
      );
    }
    await preferences.setBool(_openingFollowerNoticesKey, true);
    _notifyRelationshipChanged();
    _notifyMessageCenterChanged();
  }

  Future<List<CourtlySystemMessage>> loadSystemMessages() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_systemMessagesKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map((entry) => CourtlySystemMessage.fromJson(entry.cast()))
        .where((message) => message.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> saveSystemMessages(List<CourtlySystemMessage> messages) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _systemMessagesKey,
      jsonEncode(messages.map((message) => message.toJson()).toList()),
    );
    _notifyMessageCenterChanged();
  }

  Future<void> addSystemMessage(CourtlySystemMessage message) async {
    final messages = await loadSystemMessages();
    final next = [
      message,
      ...messages.where((entry) => entry.id != message.id),
    ].take(60).toList(growable: false);
    await saveSystemMessages(next);
  }

  Future<void> deleteSystemMessage(String messageId) async {
    final messages = await loadSystemMessages();
    await saveSystemMessages(
      messages.where((message) => message.id != messageId).toList(),
    );
  }

  Future<void> clearSystemMessages() async {
    await saveSystemMessages(const []);
  }

  Future<List<String>> messagePlayerHandles() async {
    return (await _loadStringSet(
      _rallyMessagePlayersKey,
    )).toList(growable: false);
  }

  Future<List<CourtlyStoredMessage>> loadMessages(String playerHandle) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('$_messagePrefix$playerHandle');
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map((entry) => CourtlyStoredMessage.fromJson(entry.cast()))
        .where(
          (message) =>
              message.noteId.isNotEmpty &&
              CourtlyContentSafety.isTextAllowed(
                message.rallyLine,
                surface: CourtlyContentSurface.chatMessage,
              ),
        )
        .toList(growable: false);
  }

  Future<void> saveMessages({
    required String playerHandle,
    required List<CourtlyStoredMessage> messages,
  }) async {
    final safeMessages = messages
        .where(
          (message) => CourtlyContentSafety.isTextAllowed(
            message.rallyLine,
            surface: CourtlyContentSurface.chatMessage,
          ),
        )
        .toList(growable: false);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      '$_messagePrefix$playerHandle',
      jsonEncode(safeMessages.map((message) => message.toJson()).toList()),
    );

    final ids = _readStringList(preferences, _rallyMessagePlayersKey);
    if (!ids.contains(playerHandle)) {
      ids.add(playerHandle);
      await _writeStringList(preferences, _rallyMessagePlayersKey, ids);
    }
    _notifyMessageCenterChanged();
  }

  Future<void> deleteMessages(String playerHandle) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('$_messagePrefix$playerHandle');
    final ids = _readStringList(preferences, _rallyMessagePlayersKey);
    ids.remove(playerHandle);
    await _writeStringList(preferences, _rallyMessagePlayersKey, ids);
    _notifyMessageCenterChanged();
  }

  Future<void> clearAllMessages() async {
    final preferences = await SharedPreferences.getInstance();
    final ids = _readStringList(preferences, _rallyMessagePlayersKey);
    for (final playerHandle in ids) {
      await preferences.remove('$_messagePrefix$playerHandle');
    }
    await _writeStringList(
      preferences,
      _rallyMessagePlayersKey,
      const <String>[],
    );
    await preferences.setString(_systemMessagesKey, jsonEncode(const []));
    _notifyMessageCenterChanged();
  }

  Future<List<CourtlyPublishedMoment>> loadPublishedMoments() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_publishedMomentsKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map((entry) => CourtlyPublishedMoment.fromJson(entry.cast()))
        .where(
          (moment) =>
              moment.momentId.isNotEmpty &&
              moment.imagePath.trim().isNotEmpty &&
              CourtlyContentSafety.isTextAllowed(
                moment.courtNote,
                surface: CourtlyContentSurface.moment,
              ),
        )
        .toList(growable: false);
  }

  Future<List<CourtlyPublishedClip>> loadPublishedClips() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_publishedClipsKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map((entry) => CourtlyPublishedClip.fromJson(entry.cast()))
        .where(
          (clip) =>
              clip.clipId.isNotEmpty &&
              clip.videoPath.trim().isNotEmpty &&
              CourtlyContentSafety.isTextAllowed(
                clip.rallyNote,
                surface: CourtlyContentSurface.clip,
              ),
        )
        .toList(growable: false);
  }

  Future<void> addPublishedMoment({
    required String courtNote,
    required String imagePath,
  }) async {
    final cleanBody = courtNote.trim();
    final cleanPath = imagePath.trim();
    if (cleanBody.isEmpty || cleanPath.isEmpty) {
      return;
    }
    if (!CourtlyContentSafety.isTextAllowed(
      cleanBody,
      surface: CourtlyContentSurface.moment,
    )) {
      return;
    }

    final now = DateTime.now();
    final moment = CourtlyPublishedMoment(
      momentId: 'local-moment-${now.microsecondsSinceEpoch}',
      courtNote: cleanBody,
      imagePath: cleanPath,
      timeLabel: _formatTime(now),
    );
    final moments = await loadPublishedMoments();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _publishedMomentsKey,
      jsonEncode(
        [
          moment,
          ...moments.where((entry) => entry.momentId != moment.momentId),
        ].take(80).map((entry) => entry.toJson()).toList(),
      ),
    );
    _notifyPublishedContentChanged();
  }

  Future<void> addPublishedClip({
    required String rallyNote,
    required String videoPath,
  }) async {
    final cleanCaption = rallyNote.trim();
    final cleanPath = videoPath.trim();
    if (cleanCaption.isEmpty || cleanPath.isEmpty) {
      return;
    }
    if (!CourtlyContentSafety.isTextAllowed(
      cleanCaption,
      surface: CourtlyContentSurface.clip,
    )) {
      return;
    }

    final now = DateTime.now();
    final clip = CourtlyPublishedClip(
      clipId: 'local-clip-${now.microsecondsSinceEpoch}',
      rallyNote: cleanCaption,
      videoPath: cleanPath,
      timeLabel: _formatTime(now),
    );
    final clips = await loadPublishedClips();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _publishedClipsKey,
      jsonEncode(
        [
          clip,
          ...clips.where((entry) => entry.clipId != clip.clipId),
        ].take(80).map((entry) => entry.toJson()).toList(),
      ),
    );
    _notifyPublishedContentChanged();
  }

  Future<void> prepareMessageCenter() async {
    await ensureOpeningFollowerNotices();
  }

  Future<bool> _removeSyntheticStarterContent(
    SharedPreferences preferences,
  ) async {
    var changed = false;
    final syntheticFollowerHandles = <String>{};
    final rawMessages = preferences.getString(_systemMessagesKey);

    if (rawMessages != null && rawMessages.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMessages);
        if (decoded is List) {
          final keptMessages = <CourtlySystemMessage>[];
          for (final entry in decoded.whereType<Map>()) {
            final message = CourtlySystemMessage.fromJson(entry.cast());
            if (message.id.isEmpty) {
              continue;
            }
            if (_isSyntheticStarterMessage(message)) {
              final playerHandle = message.playerHandle?.trim();
              if (playerHandle != null && playerHandle.isNotEmpty) {
                syntheticFollowerHandles.add(playerHandle);
              }
              changed = true;
              continue;
            }
            keptMessages.add(message);
          }

          if (changed) {
            if (keptMessages.isEmpty) {
              await preferences.remove(_systemMessagesKey);
            } else {
              await preferences.setString(
                _systemMessagesKey,
                jsonEncode(
                  keptMessages.map((message) => message.toJson()).toList(),
                ),
              );
            }
          }
        }
      } catch (_) {}
    }

    if (syntheticFollowerHandles.isNotEmpty) {
      final followers = _readStringList(preferences, _courtCircleFollowersKey);
      final nextFollowers = followers
          .where(
            (playerHandle) => !syntheticFollowerHandles.contains(playerHandle),
          )
          .toList();
      if (nextFollowers.length != followers.length) {
        await _writeStringList(
          preferences,
          _courtCircleFollowersKey,
          nextFollowers,
        );
        changed = true;
      }
    }

    final messagePlayers = _readStringList(
      preferences,
      _rallyMessagePlayersKey,
    );
    final seededThreadKey = '${_messagePrefix}mira-vale';
    final rawMiraMessages = preferences.getString(seededThreadKey);
    if (rawMiraMessages != null && rawMiraMessages.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMiraMessages);
        if (decoded is List) {
          final keptMessages = decoded
              .whereType<Map>()
              .map((entry) => CourtlyStoredMessage.fromJson(entry.cast()))
              .where(
                (message) =>
                    message.noteId.isNotEmpty &&
                    !message.noteId.startsWith('seed-rally-mira-'),
              )
              .toList(growable: false);
          if (keptMessages.length != decoded.whereType<Map>().length) {
            if (keptMessages.isEmpty) {
              await preferences.remove(seededThreadKey);
              messagePlayers.remove('mira-vale');
            } else {
              await preferences.setString(
                seededThreadKey,
                jsonEncode(
                  keptMessages.map((message) => message.toJson()).toList(),
                ),
              );
            }
            changed = true;
          }
        }
      } catch (_) {}
    } else if (messagePlayers.remove('mira-vale')) {
      changed = true;
    }

    if (changed) {
      await _writeStringList(
        preferences,
        _rallyMessagePlayersKey,
        messagePlayers,
      );
    }

    if (preferences.containsKey(_legacyLoginFollowerBoostKey)) {
      await preferences.remove(_legacyLoginFollowerBoostKey);
      changed = true;
    }
    if (preferences.containsKey(_legacyMessageCenterSeededKey)) {
      await preferences.remove(_legacyMessageCenterSeededKey);
      changed = true;
    }

    return changed;
  }

  bool _isSyntheticStarterMessage(CourtlySystemMessage message) {
    return message.id.startsWith('login-follower-') ||
        message.title == 'Starter court circle' ||
        message.body.contains('suggested local tennis profile');
  }

  Future<Set<String>> _loadStringSet(String key, {String? legacyKey}) async {
    final preferences = await SharedPreferences.getInstance();
    return _readStringList(preferences, key, legacyKey: legacyKey).toSet();
  }

  List<String> _readStringList(
    SharedPreferences preferences,
    String key, {
    String? legacyKey,
  }) {
    final values = <String>{
      ...?preferences.getStringList(key),
      if (legacyKey != null) ...?preferences.getStringList(legacyKey),
    }.where((value) => value.trim().isNotEmpty).toList();
    return values..sort();
  }

  Future<void> _writeStringList(
    SharedPreferences preferences,
    String key,
    List<String> values, {
    String? legacyKey,
  }) async {
    final cleaned =
        values
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    await preferences.setStringList(key, cleaned);
    if (legacyKey != null) {
      await preferences.remove(legacyKey);
    }
  }

  Future<bool> _saveBlockedPlayerSummary(
    SharedPreferences preferences, {
    required String playerHandle,
    String? courtsideName,
    String? playerPortraitAsset,
  }) async {
    final cleanPlayerHandle = playerHandle.trim();
    if (cleanPlayerHandle.isEmpty) {
      return false;
    }

    final known = CourtlyRosterBook.knownByHandle(cleanPlayerHandle);
    final cleanName = courtsideName?.trim();
    final cleanAvatar = playerPortraitAsset?.trim();
    final summary = CourtlyBlockedPlayer(
      playerHandle: cleanPlayerHandle,
      courtsideName: cleanName == null || cleanName.isEmpty
          ? known?.courtsideName ?? 'Hidden player'
          : cleanName,
      playerPortraitAsset: cleanAvatar == null || cleanAvatar.isEmpty
          ? known?.playerPortraitAsset
          : cleanAvatar,
    );
    final summaries = _loadBlockedPlayerSummaryMap(preferences);
    final current = summaries[cleanPlayerHandle];
    if (current != null &&
        current.courtsideName == summary.courtsideName &&
        current.playerPortraitAsset == summary.playerPortraitAsset) {
      return false;
    }

    summaries[cleanPlayerHandle] = summary;
    await _storeBlockedPlayerSummaries(preferences, summaries);
    return true;
  }

  Map<String, CourtlyBlockedPlayer> _loadBlockedPlayerSummaryMap(
    SharedPreferences preferences,
  ) {
    final raw = preferences.getString(_blockedPlayerCardsKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, CourtlyBlockedPlayer>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <String, CourtlyBlockedPlayer>{};
      }

      return {
        for (final entry in decoded.whereType<Map>())
          CourtlyBlockedPlayer.fromJson(entry.cast()).playerHandle:
              CourtlyBlockedPlayer.fromJson(entry.cast()),
      }..removeWhere(
        (id, blockedPlayer) =>
            id.trim().isEmpty || blockedPlayer.courtsideName.isEmpty,
      );
    } catch (_) {
      return <String, CourtlyBlockedPlayer>{};
    }
  }

  Future<void> _storeBlockedPlayerSummaries(
    SharedPreferences preferences,
    Map<String, CourtlyBlockedPlayer> summaries,
  ) async {
    await preferences.setString(
      _blockedPlayerCardsKey,
      jsonEncode(summaries.values.map((entry) => entry.toJson()).toList()),
    );
  }

  void _notifyRelationshipChanged() {
    _relationshipVersion.value += 1;
  }

  void _notifyMessageCenterChanged() {
    _messageCenterVersion.value += 1;
  }

  void _notifyPublishedContentChanged() {
    _publishedContentVersion.value += 1;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
