import 'dart:convert';

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

class CourtlySocialStore {
  const CourtlySocialStore._();

  static const instance = CourtlySocialStore._();

  static const _reportedContentKey = 'courtly_reported_content_ids';
  static const _blockedUsersKey = 'courtly_blocked_user_ids';
  static const _followRequestsKey = 'courtly_follow_request_user_ids';
  static const _followingKey = 'courtly_following_user_ids';
  static const _followersKey = 'courtly_follower_user_ids';
  static const _messageUsersKey = 'courtly_message_user_ids';
  static const _messagePrefix = 'courtly_messages_for_';
  static const _reportPrefix = 'courtly_report_detail_';

  Future<Set<String>> reportedContentIds() async {
    return _loadStringSet(_reportedContentKey);
  }

  Future<Set<String>> blockedUserIds() async {
    return _loadStringSet(_blockedUsersKey);
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
  }

  Future<void> blockUser(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(_blockedUsersKey) ?? <String>[];
    if (!ids.contains(userId)) {
      ids.add(userId);
      await preferences.setStringList(_blockedUsersKey, ids);
    }
  }

  Future<void> requestFollow(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(_followRequestsKey) ?? <String>[];
    if (!ids.contains(userId)) {
      ids.add(userId);
      await preferences.setStringList(_followRequestsKey, ids);
    }
  }

  Future<void> followUserLocally(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(_followingKey) ?? <String>[];
    if (!ids.contains(userId)) {
      ids.add(userId);
      await preferences.setStringList(_followingKey, ids);
    }
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
  }

  Future<Set<String>> _loadStringSet(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(key) ?? <String>[]).toSet();
  }
}
