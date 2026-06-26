import 'package:courtly/features/court_moments/domain/court_moment_entry.dart';
import 'package:courtly/shared/data/courtly_media_assets.dart';
import 'package:courtly/shared/social/courtly_roster_book.dart';

abstract final class CourtMomentChronicle {
  static final List<CourtMomentEntry> openingCourtMoments = List.generate(
    CourtlyMediaAssets.momentImages.length,
    (index) {
      final author = _authors[index % _authors.length];
      final authorProfile = CourtlyRosterBook.byHandle(
        CourtlyRosterBook.handleFromName(author),
      );
      return CourtMomentEntry(
        momentId: 'moment-${(index + 1).toString().padLeft(2, '0')}',
        playerHandle: authorProfile.playerHandle,
        courtsideName: authorProfile.courtsideName,
        rallyClockLabel: _rallyClockLabels[index % _rallyClockLabels.length],
        courtNote: _captions[index % _captions.length],
        momentImageAsset: CourtlyMediaAssets.momentImages[index],
        playerPortraitAsset: authorProfile.playerPortraitAsset,
        applauseCount: 96 + (index * 37),
        hasApplauded: false,
        isInCourtCircle: false,
        rallyReplies: _commentsFor(index),
        practiceClipAssets: [
          CourtlyMediaAssets.momentImages[index],
          CourtlyMediaAssets.momentImages[(index + 1) %
              CourtlyMediaAssets.momentImages.length],
          CourtlyMediaAssets.momentImages[(index + 2) %
              CourtlyMediaAssets.momentImages.length],
          CourtlyMediaAssets.momentImages[(index + 3) %
              CourtlyMediaAssets.momentImages.length],
          CourtlyMediaAssets.momentImages[(index + 4) %
              CourtlyMediaAssets.momentImages.length],
          CourtlyMediaAssets.momentImages[(index + 5) %
              CourtlyMediaAssets.momentImages.length],
        ],
      );
    },
  );

  static final List<CourtRhythmStanding> courtRhythmStandings = List.generate(
    10,
    (index) {
      return CourtRhythmStanding(
        standingRank: index + 1,
        courtsideName: _rankingNames[index],
        playerPortraitAsset: CourtlyMediaAssets
            .allHeads[(index + 30) % CourtlyMediaAssets.allHeads.length],
        rallyStreakDays: 520 - (index * 13),
      );
    },
  );

  static const List<String> _authors = [
    'Mira Vale',
    'Noemi Ashford',
    'Siena Brooks',
    'Theo Marlow',
    'Lina Sato',
    'Rina Sol',
    'Ivy Calder',
    'Rowan Ellis',
    'Tessa Vale',
    'Leon Ward',
  ];

  static const List<String> _commentAuthors = [
    'Camden Rhys',
    'Nia Greer',
    'Miles Aoki',
    'Sofia Bell',
    'Elise Renard',
    'Terry Vale',
    'Brielle May',
    'Nia Greer',
    'Micah Knox',
    'Grace Lin',
  ];

  static const List<String> _rallyClockLabels = [
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
    'Harlan',
    'Siena',
    'Rowan',
    'Sofia Bell',
    'Elise Renard',
    'Terry Vale',
    'Brielle May',
    'Nia Greer',
    'Micah Knox',
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

  static List<CourtMomentReply> _commentsFor(int index) {
    final count = 1 + (index % 4);
    final momentOrdinal = (index + 1).toString().padLeft(2, '0');

    return List.generate(count, (offset) {
      final authorIndex = (index + offset * 3) % _commentAuthors.length;
      final author = _commentAuthors[authorIndex];
      final bodyIndex = (index * 2 + offset * 5) % _commentBodies.length;
      final avatarIndex =
          (index * 7 + offset * 11 + 20) % CourtlyMediaAssets.allHeads.length;

      return CourtMomentReply(
        replyId: 'moment-$momentOrdinal-reply-${offset + 1}',
        playerHandle: CourtlyRosterBook.handleFromName(author),
        courtsideName: author,
        rallyClockLabel:
            _commentTimeLabels[(index + offset) % _commentTimeLabels.length],
        courtNote: _commentBodies[bodyIndex],
        playerPortraitAsset: CourtlyMediaAssets.allHeads[avatarIndex],
      );
    });
  }
}
