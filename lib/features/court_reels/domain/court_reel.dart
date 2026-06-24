class CourtReel {
  const CourtReel({
    required this.id,
    required this.playerName,
    required this.createdAtLabel,
    required this.caption,
    required this.backdropAsset,
    required this.avatarAsset,
    required this.likes,
    required this.shares,
    required this.isLiked,
    required this.isFollowed,
    required this.comments,
  });

  final String id;
  final String playerName;
  final String createdAtLabel;
  final String caption;
  final String backdropAsset;
  final String avatarAsset;
  final int likes;
  final int shares;
  final bool isLiked;
  final bool isFollowed;
  final List<CourtReelComment> comments;

  CourtReel copyWith({
    String? id,
    String? playerName,
    String? createdAtLabel,
    String? caption,
    String? backdropAsset,
    String? avatarAsset,
    int? likes,
    int? shares,
    bool? isLiked,
    bool? isFollowed,
    List<CourtReelComment>? comments,
  }) {
    return CourtReel(
      id: id ?? this.id,
      playerName: playerName ?? this.playerName,
      createdAtLabel: createdAtLabel ?? this.createdAtLabel,
      caption: caption ?? this.caption,
      backdropAsset: backdropAsset ?? this.backdropAsset,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      likes: likes ?? this.likes,
      shares: shares ?? this.shares,
      isLiked: isLiked ?? this.isLiked,
      isFollowed: isFollowed ?? this.isFollowed,
      comments: comments ?? this.comments,
    );
  }
}

class CourtReelComment {
  const CourtReelComment({
    required this.author,
    required this.timeLabel,
    required this.message,
    required this.avatarAsset,
  });

  final String author;
  final String timeLabel;
  final String message;
  final String avatarAsset;
}

class CourtReelDraft {
  const CourtReelDraft({required this.mood, required this.videoPath});

  final String mood;
  final String videoPath;
}
