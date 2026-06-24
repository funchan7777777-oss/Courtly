import 'package:courtly/features/post_sharing/domain/post_sharing_post.dart';

abstract final class PostSharingSeed {
  static const List<PostSharingPost> openingPosts = [
    PostSharingPost(
      id: 'bettie-night-court',
      authorName: 'Bettie Norton',
      createdAtLabel: '2025/11/25 08:45',
      body: 'The racket catches the dusk wind, all worries fade with every hit',
      imageAsset: 'assets/images/Backhand.png',
      avatarAsset: 'assets/images/Story.png',
      likes: 158,
      isLiked: true,
      isFollowed: false,
      comments: [
        PostSharingComment(
          authorName: 'Evan Perkins',
          createdAtLabel: '08:45',
          body:
              'This hand brewed coffee is very fragrant and has a faint jasmine aroma~',
          avatarAsset: 'assets/images/Invite.png',
        ),
        PostSharingComment(
          authorName: 'Rina Holt',
          createdAtLabel: '08:52',
          body: 'Night courts make the timing look even cleaner.',
          avatarAsset: 'assets/images/Story.png',
        ),
        PostSharingComment(
          authorName: 'Miles Young',
          createdAtLabel: '09:10',
          body: 'That forehand finish is the reminder I needed today.',
          avatarAsset: 'assets/images/Invite.png',
        ),
      ],
      videoAssets: [
        'assets/images/Backhand.png',
        'assets/images/Forehand.png',
        'assets/images/Profile.png',
        'assets/images/Surface.png',
        'assets/images/Backhand.png',
        'assets/images/Forehand.png',
      ],
    ),
    PostSharingPost(
      id: 'francis-repeat-swings',
      authorName: 'Francis Aguilar',
      createdAtLabel: '2025/10/14 11:23',
      body: 'Days of repeated swings shape a better version of me',
      imageAsset: 'assets/images/Forehand.png',
      avatarAsset: 'assets/images/Invite.png',
      likes: 96,
      isLiked: false,
      isFollowed: true,
      comments: [
        PostSharingComment(
          authorName: 'Sophia Marshall',
          createdAtLabel: '11:38',
          body: 'Small repetitions are doing the real work.',
          avatarAsset: 'assets/images/Story.png',
        ),
      ],
      videoAssets: [
        'assets/images/Forehand.png',
        'assets/images/Backhand.png',
        'assets/images/Profile.png',
      ],
    ),
    PostSharingPost(
      id: 'claire-soft-hands',
      authorName: 'Claire West',
      createdAtLabel: '2025/09/28 19:02',
      body: 'Soft hands at the net, brave feet on every split step',
      imageAsset: 'assets/images/Profile.png',
      avatarAsset: 'assets/images/Story.png',
      likes: 212,
      isLiked: false,
      isFollowed: false,
      comments: [
        PostSharingComment(
          authorName: 'Terry George',
          createdAtLabel: '19:21',
          body: 'Saving this for volley practice before Friday.',
          avatarAsset: 'assets/images/Invite.png',
        ),
        PostSharingComment(
          authorName: 'Nina Green',
          createdAtLabel: '19:34',
          body: 'Great reminder to move through the ball.',
          avatarAsset: 'assets/images/Story.png',
        ),
      ],
      videoAssets: [
        'assets/images/Profile.png',
        'assets/images/Backhand.png',
        'assets/images/Surface.png',
      ],
    ),
  ];

  static const List<PostRankingEntry> ranking = [
    PostRankingEntry(
      rank: 1,
      name: 'Brent',
      avatarAsset: 'assets/images/Story.png',
      checkInDays: 520,
    ),
    PostRankingEntry(
      rank: 2,
      name: 'Jennie',
      avatarAsset: 'assets/images/Invite.png',
      checkInDays: 312,
    ),
    PostRankingEntry(
      rank: 3,
      name: 'Glenn',
      avatarAsset: 'assets/images/Story.png',
      checkInDays: 258,
    ),
    PostRankingEntry(
      rank: 4,
      name: 'Sophia Marshall',
      avatarAsset: 'assets/images/Invite.png',
      checkInDays: 522,
    ),
    PostRankingEntry(
      rank: 5,
      name: 'Elizabeth Richards',
      avatarAsset: 'assets/images/Story.png',
      checkInDays: 522,
    ),
    PostRankingEntry(
      rank: 6,
      name: 'Terry George',
      avatarAsset: 'assets/images/Invite.png',
      checkInDays: 522,
    ),
    PostRankingEntry(
      rank: 7,
      name: 'Bernice May',
      avatarAsset: 'assets/images/Story.png',
      checkInDays: 522,
    ),
  ];
}
