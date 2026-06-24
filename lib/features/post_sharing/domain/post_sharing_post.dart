class PostSharingPost {
  const PostSharingPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.createdAtLabel,
    required this.body,
    required this.imageAsset,
    required this.avatarAsset,
    required this.likes,
    required this.isLiked,
    required this.isFollowed,
    required this.comments,
    required this.videoAssets,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String createdAtLabel;
  final String body;
  final String imageAsset;
  final String avatarAsset;
  final int likes;
  final bool isLiked;
  final bool isFollowed;
  final List<PostSharingComment> comments;
  final List<String> videoAssets;

  PostSharingPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? createdAtLabel,
    String? body,
    String? imageAsset,
    String? avatarAsset,
    int? likes,
    bool? isLiked,
    bool? isFollowed,
    List<PostSharingComment>? comments,
    List<String>? videoAssets,
  }) {
    return PostSharingPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAtLabel: createdAtLabel ?? this.createdAtLabel,
      body: body ?? this.body,
      imageAsset: imageAsset ?? this.imageAsset,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      isFollowed: isFollowed ?? this.isFollowed,
      comments: comments ?? this.comments,
      videoAssets: videoAssets ?? this.videoAssets,
    );
  }
}

class PostSharingComment {
  const PostSharingComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.createdAtLabel,
    required this.body,
    required this.avatarAsset,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String createdAtLabel;
  final String body;
  final String avatarAsset;
}

class PostSharingDraft {
  const PostSharingDraft({required this.body, required this.imagePath});

  final String body;
  final String imagePath;
}

class PostRankingEntry {
  const PostRankingEntry({
    required this.rank,
    required this.name,
    required this.avatarAsset,
    required this.checkInDays,
  });

  final int rank;
  final String name;
  final String avatarAsset;
  final int checkInDays;
}
