import 'package:courtly/features/post_sharing/domain/post_sharing_post.dart';
import 'package:courtly/shared/data/courtly_media_assets.dart';
import 'package:courtly/shared/social/courtly_user_directory.dart';

abstract final class PostSharingSeed {
  static final List<PostSharingPost> openingPosts = List.generate(
    CourtlyMediaAssets.postImages.length,
    (index) {
      final author = _authors[index % _authors.length];
      final commentAuthor = _commentAuthors[index % _commentAuthors.length];
      final avatar = CourtlyMediaAssets.allHeads[index];
      final commentAvatar = CourtlyMediaAssets
          .allHeads[(index + 20) % CourtlyMediaAssets.allHeads.length];

      return PostSharingPost(
        id: 'post-${(index + 1).toString().padLeft(2, '0')}',
        authorId: CourtlyUserDirectory.idFromName(author),
        authorName: author,
        createdAtLabel:
            '2025/11/${(index + 1).toString().padLeft(2, '0')} 08:45',
        body: _captions[index % _captions.length],
        imageAsset: CourtlyMediaAssets.postImages[index],
        avatarAsset: avatar,
        likes: 96 + (index * 37),
        isLiked: index.isEven,
        isFollowed: false,
        comments: [
          PostSharingComment(
            id: 'post-${(index + 1).toString().padLeft(2, '0')}-comment-1',
            authorId: CourtlyUserDirectory.idFromName(commentAuthor),
            authorName: commentAuthor,
            createdAtLabel: '08:${(40 + index).toString().padLeft(2, '0')}',
            body: _commentBodies[index % _commentBodies.length],
            avatarAsset: commentAvatar,
          ),
          PostSharingComment(
            id: 'post-${(index + 1).toString().padLeft(2, '0')}-comment-2',
            authorId: CourtlyUserDirectory.idFromName('Court Partner'),
            authorName: 'Court Partner',
            createdAtLabel: '09:${(10 + index).toString().padLeft(2, '0')}',
            body: 'Saving this tennis note for the next practice block.',
            avatarAsset: CourtlyMediaAssets
                .allHeads[(index + 7) % CourtlyMediaAssets.allHeads.length],
          ),
        ],
        videoAssets: [
          CourtlyMediaAssets.postImages[index],
          CourtlyMediaAssets.postImages[(index + 1) %
              CourtlyMediaAssets.postImages.length],
          CourtlyMediaAssets.postImages[(index + 2) %
              CourtlyMediaAssets.postImages.length],
          CourtlyMediaAssets.postImages[(index + 3) %
              CourtlyMediaAssets.postImages.length],
          CourtlyMediaAssets.postImages[(index + 4) %
              CourtlyMediaAssets.postImages.length],
          CourtlyMediaAssets.postImages[(index + 5) %
              CourtlyMediaAssets.postImages.length],
        ],
      );
    },
  );

  static final List<PostRankingEntry> ranking = List.generate(10, (index) {
    return PostRankingEntry(
      rank: index + 1,
      name: _rankingNames[index],
      avatarAsset: CourtlyMediaAssets
          .allHeads[(index + 30) % CourtlyMediaAssets.allHeads.length],
      checkInDays: 520 - (index * 13),
    );
  });

  static const List<String> _authors = [
    'Bettie Norton',
    'Francis Aguilar',
    'Claire West',
    'Noah Hart',
    'Mina Cross',
    'Hollis Park',
    'Sofia Lane',
    'Arden Cole',
    'Iris Stone',
    'Leo Grant',
  ];

  static const List<String> _commentAuthors = [
    'Evan Perkins',
    'Rina Holt',
    'Miles Young',
    'Sophia Marshall',
    'Elizabeth Richards',
    'Terry George',
    'Bernice May',
    'Nina Green',
    'Mike Mack',
    'Grace Liu',
  ];

  static const List<String> _rankingNames = [
    'Brent',
    'Jennie',
    'Glenn',
    'Sophia Marshall',
    'Elizabeth Richards',
    'Terry George',
    'Bernice May',
    'Nina Green',
    'Mike Mack',
    'Avery Stone',
  ];

  static const List<String> _captions = [
    'The racket catches the dusk wind, all worries fade with every hit.',
    'Days of repeated swings shape a better version of my court rhythm.',
    'Soft hands at the net, brave feet on every split step.',
    'A compact serve session with loose shoulders and clear targets.',
    'Finding the next point with patience, spin, and a better recovery step.',
  ];

  static const List<String> _commentBodies = [
    'This rhythm looks ready for match day.',
    'The footwork cue is easy to follow.',
    'Night courts make the timing look even cleaner.',
    'That contact point is worth replaying.',
    'The rally shape feels calm and confident.',
  ];
}
