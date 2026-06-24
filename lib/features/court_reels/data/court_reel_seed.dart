import 'package:courtly/features/court_reels/domain/court_reel.dart';

abstract final class CourtReelSeed {
  static const List<CourtReel> openingFeed = [
    CourtReel(
      id: 'hollis-forehand-reset',
      playerName: 'Hollis',
      createdAtLabel: '2025-09-23 12:24',
      caption:
          'Daily moments of my cutie, heal all unhappiness. Happy hours filled with forehand rallies.',
      backdropAsset: 'assets/images/Forehand.png',
      avatarAsset: 'assets/images/Story.png',
      likes: 666,
      shares: 1245,
      isLiked: true,
      isFollowed: true,
      comments: [
        CourtReelComment(
          author: 'Evan Perkins',
          timeLabel: '08:45',
          message:
              'This hand brewed coffee is very fragrant and has a faint jasmine aroma~',
          avatarAsset: 'assets/images/Story.png',
        ),
        CourtReelComment(
          author: 'Mia Chen',
          timeLabel: '08:52',
          message: 'Your contact point is so clean. Saving this for practice.',
          avatarAsset: 'assets/images/Invite.png',
        ),
        CourtReelComment(
          author: 'Noah Hart',
          timeLabel: '09:11',
          message: 'That recovery step after the swing is the best part.',
          avatarAsset: 'assets/images/Story.png',
        ),
      ],
    ),
    CourtReel(
      id: 'mina-arena-warmup',
      playerName: 'Mina',
      createdAtLabel: '2025-09-23 15:08',
      caption:
          'Warmup wall before doubles night. Short backswing, early split, steady rhythm.',
      backdropAsset: 'assets/images/Surface.png',
      avatarAsset: 'assets/images/Invite.png',
      likes: 384,
      shares: 720,
      isLiked: false,
      isFollowed: false,
      comments: [
        CourtReelComment(
          author: 'Aria Novak',
          timeLabel: '15:18',
          message: 'The tempo drill looks useful before match play.',
          avatarAsset: 'assets/images/Story.png',
        ),
        CourtReelComment(
          author: 'Leo Park',
          timeLabel: '15:34',
          message: 'Need this routine before every league night.',
          avatarAsset: 'assets/images/Invite.png',
        ),
      ],
    ),
    CourtReel(
      id: 'court-card-release',
      playerName: 'Sofia',
      createdAtLabel: '2025-09-24 09:41',
      caption:
          'Court card test shoot. Purple light, clean grip, one compact rally story.',
      backdropAsset: 'assets/images/Profile.png',
      avatarAsset: 'assets/images/Story.png',
      likes: 529,
      shares: 999,
      isLiked: false,
      isFollowed: true,
      comments: [
        CourtReelComment(
          author: 'Grace Liu',
          timeLabel: '09:48',
          message: 'The palette and court mood match perfectly.',
          avatarAsset: 'assets/images/Invite.png',
        ),
      ],
    ),
  ];
}
