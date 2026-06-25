import 'dart:convert';
import 'dart:math';

import 'package:courtly/shared/social/courtly_user_directory.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourtlyStoredMessage {
  const CourtlyStoredMessage({
    required this.id,
    required this.senderName,
    required this.body,
    required this.timeLabel,
    required this.isMine,
  });

  final String id;
  final String senderName;
  final String body;
  final String timeLabel;
  final bool isMine;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'senderName': senderName,
      'body': body,
      'timeLabel': timeLabel,
      'isMine': isMine,
    };
  }

  static CourtlyStoredMessage fromJson(Map<String, Object?> json) {
    return CourtlyStoredMessage(
      id: json['id'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      body: json['body'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
      isMine: json['isMine'] as bool? ?? false,
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
    this.userId,
    this.targetId,
  });

  final String id;
  final String kind;
  final String title;
  final String body;
  final String timeLabel;
  final String? userId;
  final String? targetId;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'kind': kind,
      'title': title,
      'body': body,
      'timeLabel': timeLabel,
      'userId': userId,
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
      userId: json['userId'] as String?,
      targetId: json['targetId'] as String?,
    );
  }
}

class CourtlyPublishedPost {
  const CourtlyPublishedPost({
    required this.id,
    required this.body,
    required this.imagePath,
    required this.timeLabel,
  });

  final String id;
  final String body;
  final String imagePath;
  final String timeLabel;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'body': body,
      'imagePath': imagePath,
      'timeLabel': timeLabel,
    };
  }

  static CourtlyPublishedPost fromJson(Map<String, Object?> json) {
    return CourtlyPublishedPost(
      id: json['id'] as String? ?? '',
      body: json['body'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
    );
  }
}

class CourtlyPublishedReel {
  const CourtlyPublishedReel({
    required this.id,
    required this.caption,
    required this.videoPath,
    required this.timeLabel,
  });

  final String id;
  final String caption;
  final String videoPath;
  final String timeLabel;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'caption': caption,
      'videoPath': videoPath,
      'timeLabel': timeLabel,
    };
  }

  static CourtlyPublishedReel fromJson(Map<String, Object?> json) {
    return CourtlyPublishedReel(
      id: json['id'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      videoPath: json['videoPath'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
    );
  }
}

class CourtlyBlockedUser {
  const CourtlyBlockedUser({
    required this.id,
    required this.name,
    this.avatarAsset,
  });

  final String id;
  final String name;
  final String? avatarAsset;

  Map<String, Object?> toJson() {
    return {'id': id, 'name': name, 'avatarAsset': avatarAsset};
  }

  static CourtlyBlockedUser fromJson(Map<String, Object?> json) {
    return CourtlyBlockedUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarAsset: json['avatarAsset'] as String?,
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
  static const _blockedUsersKey = 'courtly_blocked_user_ids';
  static const _blockedUserProfilesKey = 'courtly_blocked_user_profiles';
  static const _followRequestsKey = 'courtly_follow_request_user_ids';
  static const _followingKey = 'courtly_following_user_ids';
  static const _followersKey = 'courtly_follower_user_ids';
  static const _messageUsersKey = 'courtly_message_user_ids';
  static const _messagePrefix = 'courtly_messages_for_';
  static const _systemMessagesKey = 'courtly_system_messages';
  static const _messageCenterSeededKey = 'courtly_message_center_seeded';
  static const _loginFollowerBoostKey = 'courtly_login_follower_boost_seeded';
  static const _publishedPostsKey = 'courtly_published_posts';
  static const _publishedReelsKey = 'courtly_published_reels';
  static const _reportPrefix = 'courtly_report_detail_';

  Future<Set<String>> reportedContentIds() async {
    return _loadStringSet(_reportedContentKey);
  }

  Future<Set<String>> blockedUserIds() async {
    return _loadStringSet(_blockedUsersKey);
  }

  Future<List<String>> followerUserIds() async {
    return (await _loadStringSet(_followersKey)).toList(growable: false)
      ..sort();
  }

  Future<List<String>> followingUserIds() async {
    return (await _loadStringSet(_followingKey)).toList(growable: false)
      ..sort();
  }

  Future<List<String>> outgoingFollowUserIds() async {
    final ids = {
      ...await _loadStringSet(_followingKey),
      ...await _loadStringSet(_followRequestsKey),
    }.toList(growable: false);
    return ids..sort();
  }

  Future<List<CourtlyBlockedUser>> loadBlockedUsers() async {
    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(_blockedUsersKey) ?? <String>[];
    final summaries = _loadBlockedUserSummaryMap(preferences);

    return ids
        .map((id) {
          final stored = summaries[id];
          if (stored != null && stored.name.trim().isNotEmpty) {
            return stored;
          }

          final known = CourtlyUserDirectory.knownById(id);
          if (known != null) {
            return CourtlyBlockedUser(
              id: known.id,
              name: known.name,
              avatarAsset: known.avatarAsset,
            );
          }

          return CourtlyBlockedUser(id: id, name: 'Blocked user');
        })
        .where((profile) => profile.id.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<bool> isContentReported(String contentId) async {
    return (await reportedContentIds()).contains(contentId);
  }

  Future<bool> isUserBlocked(String userId) async {
    return (await blockedUserIds()).contains(userId);
  }

  Future<void> reportContent({
    required String contentId,
    required String type,
    required String reason,
    String? userId,
    String? summary,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(_reportedContentKey) ?? <String>[];
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
        'userId': userId,
        'summary': summary,
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );
    await addSystemMessage(
      CourtlySystemMessage(
        id: 'report-${contentId.hashCode}-${DateTime.now().microsecondsSinceEpoch}',
        kind: 'report',
        title: 'Report submitted',
        body: 'We saved your report and hid the reported content locally.',
        timeLabel: _formatTime(DateTime.now()),
        userId: userId,
        targetId: 'report:$contentId',
      ),
    );
  }

  Future<void> blockUser(
    String userId, {
    String? name,
    String? avatarAsset,
  }) async {
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(_blockedUsersKey) ?? <String>[];
    final summaryChanged = await _saveBlockedUserSummary(
      preferences,
      userId: cleanUserId,
      name: name,
      avatarAsset: avatarAsset,
    );
    if (!ids.contains(cleanUserId)) {
      ids.add(cleanUserId);
      await preferences.setStringList(_blockedUsersKey, ids);
      await addSystemMessage(
        CourtlySystemMessage(
          id: 'block-$cleanUserId-${DateTime.now().microsecondsSinceEpoch}',
          kind: 'block',
          title: 'Player blocked',
          body: 'That player and their messages are hidden from Club Chats.',
          timeLabel: _formatTime(DateTime.now()),
          userId: cleanUserId,
          targetId: 'user:$cleanUserId',
        ),
      );
      _notifyRelationshipChanged();
    } else if (summaryChanged) {
      _notifyRelationshipChanged();
    }
  }

  Future<void> unblockUser(String userId) async {
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(_blockedUsersKey) ?? <String>[];
    if (!ids.remove(cleanUserId)) {
      return;
    }

    await preferences.setStringList(_blockedUsersKey, ids);
    final summaries = _loadBlockedUserSummaryMap(preferences);
    if (summaries.remove(cleanUserId) != null) {
      await _storeBlockedUserSummaries(preferences, summaries);
    }
    _notifyRelationshipChanged();
  }

  Future<void> requestFollow(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(_followRequestsKey) ?? <String>[];
    if (!ids.contains(userId)) {
      ids.add(userId);
      await preferences.setStringList(_followRequestsKey, ids);
      final followers = preferences.getStringList(_followersKey) ?? <String>[];
      if (followers.contains(userId)) {
        final following =
            preferences.getStringList(_followingKey) ?? <String>[];
        if (!following.contains(userId)) {
          following.add(userId);
          await preferences.setStringList(_followingKey, following);
        }
        await addSystemMessage(
          CourtlySystemMessage(
            id: 'mutual-$userId-${DateTime.now().microsecondsSinceEpoch}',
            kind: 'mutual',
            title: 'Mutual follow unlocked',
            body:
                'You and this player follow each other. Private chat is open.',
            timeLabel: _formatTime(DateTime.now()),
            userId: userId,
            targetId: 'user:$userId',
          ),
        );
      } else {
        await addSystemMessage(
          CourtlySystemMessage(
            id: 'follow-$userId-${DateTime.now().microsecondsSinceEpoch}',
            kind: 'follow',
            title: 'Follow request sent',
            body: 'Chat unlocks after this player follows you back.',
            timeLabel: _formatTime(DateTime.now()),
            userId: userId,
            targetId: 'user:$userId',
          ),
        );
      }
      _notifyRelationshipChanged();
    }
  }

  Future<void> followUserLocally(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(_followingKey) ?? <String>[];
    if (!ids.contains(userId)) {
      ids.add(userId);
      await preferences.setStringList(_followingKey, ids);
      final followers = preferences.getStringList(_followersKey) ?? <String>[];
      await addSystemMessage(
        CourtlySystemMessage(
          id: followers.contains(userId)
              ? 'mutual-$userId-${DateTime.now().microsecondsSinceEpoch}'
              : 'follow-$userId-${DateTime.now().microsecondsSinceEpoch}',
          kind: followers.contains(userId) ? 'mutual' : 'follow',
          title: followers.contains(userId)
              ? 'Mutual follow unlocked'
              : 'Following player',
          body: followers.contains(userId)
              ? 'You and this player follow each other. Private chat is open.'
              : 'You are following this player.',
          timeLabel: _formatTime(DateTime.now()),
          userId: userId,
          targetId: 'user:$userId',
        ),
      );
      _notifyRelationshipChanged();
    }
  }

  Future<void> unfollowUser(String userId) async {
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final following = preferences.getStringList(_followingKey) ?? <String>[];
    final requests =
        preferences.getStringList(_followRequestsKey) ?? <String>[];
    final removedFollowing = following.remove(cleanUserId);
    final removedRequest = requests.remove(cleanUserId);
    if (!removedFollowing && !removedRequest) {
      return;
    }

    await preferences.setStringList(_followingKey, following);
    await preferences.setStringList(_followRequestsKey, requests);
    _notifyRelationshipChanged();
  }

  Future<bool> hasRequestedFollow(String userId) async {
    return (await _loadStringSet(_followRequestsKey)).contains(userId);
  }

  Future<bool> isFollowing(String userId) async {
    return (await _loadStringSet(_followingKey)).contains(userId);
  }

  Future<bool> isMutualFollow(String userId) async {
    final following = await isFollowing(userId);
    final followers = await _loadStringSet(_followersKey);
    return following && followers.contains(userId);
  }

  Future<List<String>> mutualFollowUserIds() async {
    final following = await _loadStringSet(_followingKey);
    final followers = await _loadStringSet(_followersKey);
    return following.where(followers.contains).toList(growable: false)..sort();
  }

  Future<void> ensureLoginFollowerBoost() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_loginFollowerBoostKey) == true) {
      return;
    }

    final random = Random(DateTime.now().microsecondsSinceEpoch);
    final followers = preferences.getStringList(_followersKey) ?? <String>[];
    final blocked = preferences.getStringList(_blockedUsersKey) ?? <String>[];
    final candidates = CourtlyUserDirectory.featuredProfiles(20)
        .where(
          (profile) =>
              !followers.contains(profile.id) && !blocked.contains(profile.id),
        )
        .toList(growable: false);
    if (candidates.isEmpty) {
      await preferences.setBool(_loginFollowerBoostKey, true);
      return;
    }

    final shuffledCandidates = List.of(candidates)..shuffle(random);
    final followerCount = min(shuffledCandidates.length, 2 + random.nextInt(2));
    final selectedProfiles = shuffledCandidates.take(followerCount).toList();
    final now = DateTime.now();
    final newMessages = <CourtlySystemMessage>[];

    for (final profile in selectedProfiles) {
      followers.add(profile.id);
      newMessages.add(
        CourtlySystemMessage(
          id: 'login-follower-${profile.id}-${now.microsecondsSinceEpoch}',
          kind: 'follow',
          title: 'New follower',
          body:
              '${profile.name} started following you. Follow back to become mutual friends.',
          timeLabel: _formatTime(now),
          userId: profile.id,
          targetId: 'user:${profile.id}',
        ),
      );
    }

    await preferences.setStringList(_followersKey, followers);
    final existingMessages = await loadSystemMessages();
    await preferences.setString(
      _systemMessagesKey,
      jsonEncode(
        [
          ...newMessages,
          ...existingMessages,
        ].take(60).map((message) => message.toJson()).toList(),
      ),
    );
    await preferences.setBool(_loginFollowerBoostKey, true);
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

  Future<List<String>> messageUserIds() async {
    return (await _loadStringSet(_messageUsersKey)).toList(growable: false);
  }

  Future<List<CourtlyStoredMessage>> loadMessages(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('$_messagePrefix$userId');
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
        .where((message) => message.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> saveMessages({
    required String userId,
    required List<CourtlyStoredMessage> messages,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      '$_messagePrefix$userId',
      jsonEncode(messages.map((message) => message.toJson()).toList()),
    );

    final ids = preferences.getStringList(_messageUsersKey) ?? <String>[];
    if (!ids.contains(userId)) {
      ids.add(userId);
      await preferences.setStringList(_messageUsersKey, ids);
    }
    _notifyMessageCenterChanged();
  }

  Future<void> deleteMessages(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('$_messagePrefix$userId');
    final ids = preferences.getStringList(_messageUsersKey) ?? <String>[];
    ids.remove(userId);
    await preferences.setStringList(_messageUsersKey, ids);
    _notifyMessageCenterChanged();
  }

  Future<void> clearAllMessages() async {
    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(_messageUsersKey) ?? <String>[];
    for (final userId in ids) {
      await preferences.remove('$_messagePrefix$userId');
    }
    await preferences.setStringList(_messageUsersKey, const <String>[]);
    await preferences.setString(_systemMessagesKey, jsonEncode(const []));
    _notifyMessageCenterChanged();
  }

  Future<List<CourtlyPublishedPost>> loadPublishedPosts() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_publishedPostsKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map((entry) => CourtlyPublishedPost.fromJson(entry.cast()))
        .where((post) => post.id.isNotEmpty && post.imagePath.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<List<CourtlyPublishedReel>> loadPublishedReels() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_publishedReelsKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map((entry) => CourtlyPublishedReel.fromJson(entry.cast()))
        .where((reel) => reel.id.isNotEmpty && reel.videoPath.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<void> addPublishedPost({
    required String body,
    required String imagePath,
  }) async {
    final cleanBody = body.trim();
    final cleanPath = imagePath.trim();
    if (cleanBody.isEmpty || cleanPath.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final post = CourtlyPublishedPost(
      id: 'local-post-${now.microsecondsSinceEpoch}',
      body: cleanBody,
      imagePath: cleanPath,
      timeLabel: _formatTime(now),
    );
    final posts = await loadPublishedPosts();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _publishedPostsKey,
      jsonEncode(
        [
          post,
          ...posts.where((entry) => entry.id != post.id),
        ].take(80).map((entry) => entry.toJson()).toList(),
      ),
    );
    _notifyPublishedContentChanged();
  }

  Future<void> addPublishedReel({
    required String caption,
    required String videoPath,
  }) async {
    final cleanCaption = caption.trim();
    final cleanPath = videoPath.trim();
    if (cleanCaption.isEmpty || cleanPath.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final reel = CourtlyPublishedReel(
      id: 'local-reel-${now.microsecondsSinceEpoch}',
      caption: cleanCaption,
      videoPath: cleanPath,
      timeLabel: _formatTime(now),
    );
    final reels = await loadPublishedReels();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _publishedReelsKey,
      jsonEncode(
        [
          reel,
          ...reels.where((entry) => entry.id != reel.id),
        ].take(80).map((entry) => entry.toJson()).toList(),
      ),
    );
    _notifyPublishedContentChanged();
  }

  Future<void> ensureClubMessagesSeeded() async {
    final preferences = await SharedPreferences.getInstance();
    await ensureLoginFollowerBoost();
    if (preferences.getBool(_messageCenterSeededKey) == true) {
      return;
    }

    final messageUsers =
        preferences.getStringList(_messageUsersKey) ?? <String>[];
    if (!messageUsers.contains('bettie-norton')) {
      messageUsers.add('bettie-norton');
    }
    await preferences.setStringList(_messageUsersKey, messageUsers);
    if ((await loadMessages('bettie-norton')).isEmpty) {
      await preferences.setString(
        '${_messagePrefix}bettie-norton',
        jsonEncode(
          const [
            CourtlyStoredMessage(
              id: 'seed-chat-bettie-1',
              senderName: 'Bettie Norton',
              body: 'Want to book a dusk rally after practice?',
              timeLabel: '08:36',
              isMine: false,
            ),
            CourtlyStoredMessage(
              id: 'seed-chat-bettie-2',
              senderName: 'You',
              body: 'Yes. Send me the court slot and I will confirm.',
              timeLabel: '08:38',
              isMine: true,
            ),
          ].map((message) => message.toJson()).toList(),
        ),
      );
    }
    await preferences.setBool(_messageCenterSeededKey, true);
    _notifyRelationshipChanged();
    _notifyMessageCenterChanged();
  }

  Future<Set<String>> _loadStringSet(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(key) ?? <String>[]).toSet();
  }

  Future<bool> _saveBlockedUserSummary(
    SharedPreferences preferences, {
    required String userId,
    String? name,
    String? avatarAsset,
  }) async {
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      return false;
    }

    final known = CourtlyUserDirectory.knownById(cleanUserId);
    final cleanName = name?.trim();
    final cleanAvatar = avatarAsset?.trim();
    final summary = CourtlyBlockedUser(
      id: cleanUserId,
      name: cleanName == null || cleanName.isEmpty
          ? known?.name ?? 'Blocked user'
          : cleanName,
      avatarAsset: cleanAvatar == null || cleanAvatar.isEmpty
          ? known?.avatarAsset
          : cleanAvatar,
    );
    final summaries = _loadBlockedUserSummaryMap(preferences);
    final current = summaries[cleanUserId];
    if (current != null &&
        current.name == summary.name &&
        current.avatarAsset == summary.avatarAsset) {
      return false;
    }

    summaries[cleanUserId] = summary;
    await _storeBlockedUserSummaries(preferences, summaries);
    return true;
  }

  Map<String, CourtlyBlockedUser> _loadBlockedUserSummaryMap(
    SharedPreferences preferences,
  ) {
    final raw = preferences.getString(_blockedUserProfilesKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, CourtlyBlockedUser>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <String, CourtlyBlockedUser>{};
      }

      return {
        for (final entry in decoded.whereType<Map>())
          CourtlyBlockedUser.fromJson(entry.cast()).id:
              CourtlyBlockedUser.fromJson(entry.cast()),
      }..removeWhere((id, user) => id.trim().isEmpty || user.name.isEmpty);
    } catch (_) {
      return <String, CourtlyBlockedUser>{};
    }
  }

  Future<void> _storeBlockedUserSummaries(
    SharedPreferences preferences,
    Map<String, CourtlyBlockedUser> summaries,
  ) async {
    await preferences.setString(
      _blockedUserProfilesKey,
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
