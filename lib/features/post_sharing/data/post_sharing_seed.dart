import 'package:courtly/features/post_sharing/domain/post_sharing_post.dart';
import 'package:courtly/shared/data/courtly_media_assets.dart';
import 'package:courtly/shared/social/courtly_user_directory.dart';

abstract final class PostSharingSeed {
  static final List<PostSharingPost> openingPosts = List.generate(
    CourtlyMediaAssets.postImages.length,
    (index) {
      final author = _authors[index % _authors.length];
      final authorProfile = CourtlyUserDirectory.byId(
        CourtlyUserDirectory.idFromName(author),
      );
      return PostSharingPost(
        id: 'post-${(index + 1).toString().padLeft(2, '0')}',
        authorId: authorProfile.id,
        authorName: authorProfile.name,
        createdAtLabel: _createdAtLabels[index % _createdAtLabels.length],
        body: _captions[index % _captions.length],
        imageAsset: CourtlyMediaAssets.postImages[index],
        avatarAsset: authorProfile.avatarAsset,
        likes: 96 + (index * 37),
        isLiked: false,
        isFollowed: false,
        comments: _commentsFor(index),
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

  static const List<String> _createdAtLabels = [
    'Just now',
    '6 min ago',
    '14 min ago',
    '31 min ago',
    '1 h ago',
    '2 h ago',
    '3 h ago',
    'Today 09:20',
    'Today 11:45',
    'Today 16:10',
    'Yesterday 08:45',
    'Yesterday 16:30',
    '2 days ago',
    '3 days ago',
    '4 days ago',
    '5 days ago',
    'Last week',
    'This week',
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
    'Your shoulder turn looks much looser here.',
    'That split step timing is getting sharp.',
    'Clean court energy, especially on the recovery.',
    'The net approach feels brave and controlled.',
    'Love the way you finish balanced after contact.',
    'This would be a great drill to repeat tomorrow.',
    'The serve target looks much clearer now.',
    'Nice patience before changing direction.',
    'That topspin window is really visible.',
    'The camera angle makes the movement easy to study.',
  ];

  static const List<String> _commentTimeLabels = [
    'now',
    '3 min ago',
    '9 min ago',
    '18 min ago',
    '32 min ago',
    '1 h ago',
    '2 h ago',
    'Today 13:12',
    'Yesterday',
  ];

  static List<PostSharingComment> _commentsFor(int index) {
    final count = 1 + (index % 4);
    final postId = (index + 1).toString().padLeft(2, '0');

    return List.generate(count, (offset) {
      final authorIndex = (index + offset * 3) % _commentAuthors.length;
      final author = _commentAuthors[authorIndex];
      final bodyIndex = (index * 2 + offset * 5) % _commentBodies.length;
      final avatarIndex =
          (index * 7 + offset * 11 + 20) % CourtlyMediaAssets.allHeads.length;

      return PostSharingComment(
        id: 'post-$postId-comment-${offset + 1}',
        authorId: CourtlyUserDirectory.idFromName(author),
        authorName: author,
        createdAtLabel:
            _commentTimeLabels[(index + offset) % _commentTimeLabels.length],
        body: _commentBodies[bodyIndex],
        avatarAsset: CourtlyMediaAssets.allHeads[avatarIndex],
      );
    });
  }
}
