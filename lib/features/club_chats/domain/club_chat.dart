class ClubChatMessage {
  const ClubChatMessage({
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
}

class ClubConversation {
  const ClubConversation({
    required this.id,
    required this.userId,
    required this.playerName,
    required this.ageLabel,
    required this.avatarAsset,
    required this.heroAsset,
    required this.online,
    required this.unreadCount,
    required this.lastTimeLabel,
    required this.messages,
  });

  final String id;
  final String userId;
  final String playerName;
  final String ageLabel;
  final String avatarAsset;
  final String heroAsset;
  final bool online;
  final int unreadCount;
  final String lastTimeLabel;
  final List<ClubChatMessage> messages;

  String get preview {
    if (messages.isEmpty) {
      return 'Say hello before the next rally.';
    }

    return messages.last.body;
  }

  ClubConversation copyWith({
    String? id,
    String? userId,
    String? playerName,
    String? ageLabel,
    String? avatarAsset,
    String? heroAsset,
    bool? online,
    int? unreadCount,
    String? lastTimeLabel,
    List<ClubChatMessage>? messages,
  }) {
    return ClubConversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      playerName: playerName ?? this.playerName,
      ageLabel: ageLabel ?? this.ageLabel,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      heroAsset: heroAsset ?? this.heroAsset,
      online: online ?? this.online,
      unreadCount: unreadCount ?? this.unreadCount,
      lastTimeLabel: lastTimeLabel ?? this.lastTimeLabel,
      messages: messages ?? this.messages,
    );
  }
}

class ClubFriendRequest {
  const ClubFriendRequest({
    required this.id,
    required this.userId,
    required this.playerName,
    required this.ageLabel,
    required this.avatarAsset,
    required this.motto,
    required this.following,
  });

  final String id;
  final String userId;
  final String playerName;
  final String ageLabel;
  final String avatarAsset;
  final String motto;
  final bool following;

  ClubFriendRequest copyWith({
    String? id,
    String? userId,
    String? playerName,
    String? ageLabel,
    String? avatarAsset,
    String? motto,
    bool? following,
  }) {
    return ClubFriendRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      playerName: playerName ?? this.playerName,
      ageLabel: ageLabel ?? this.ageLabel,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      motto: motto ?? this.motto,
      following: following ?? this.following,
    );
  }
}

class ClubCallResult {
  const ClubCallResult({required this.started});

  final bool started;
}
