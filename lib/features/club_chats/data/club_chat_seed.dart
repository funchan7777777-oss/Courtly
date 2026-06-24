import 'package:courtly/features/club_chats/domain/club_chat.dart';

abstract final class ClubChatSeed {
  static const List<ClubFriendRequest> openingRequests = [
    ClubFriendRequest(
      id: 'francis-request',
      playerName: 'Francis',
      ageLabel: '25',
      avatarAsset: 'assets/images/head/women/woman_head_16.jpg',
      motto: 'One ball, one racket, pure freedom',
      following: false,
    ),
    ClubFriendRequest(
      id: 'mina-request',
      playerName: 'Mina',
      ageLabel: '24',
      avatarAsset: 'assets/images/head/women/woman_head_17.jpg',
      motto: 'Indoor doubles after work',
      following: false,
    ),
    ClubFriendRequest(
      id: 'sofia-request',
      playerName: 'Sofia',
      ageLabel: '27',
      avatarAsset: 'assets/images/head/women/woman_head_18.jpg',
      motto: 'Looking for a patient hitting partner',
      following: false,
    ),
    ClubFriendRequest(
      id: 'aria-request',
      playerName: 'Aria',
      ageLabel: '23',
      avatarAsset: 'assets/images/head/women/woman_head_19.jpg',
      motto: 'Serve practice and court photos',
      following: false,
    ),
  ];

  static const List<ClubConversation> openingConversations = [
    ClubConversation(
      id: 'francis-chat',
      playerName: 'Francis',
      ageLabel: '25',
      avatarAsset: 'assets/images/head/women/woman_head_16.jpg',
      heroAsset: 'assets/images/Forehand.png',
      online: true,
      unreadCount: 0,
      lastTimeLabel: '08:12',
      messages: [
        ClubChatMessage(
          id: 'francis-early',
          senderName: 'Francis',
          body:
              'I played for an hour today, an hour every day, and soon my skills will surpass yours',
          timeLabel: '08:02',
          isMine: false,
        ),
        ClubChatMessage(
          id: 'me-coach',
          senderName: 'You',
          body:
              'Then you have to persevere, strive for better ball skills, and remember to play ball every day.',
          timeLabel: '08:06',
          isMine: true,
        ),
        ClubChatMessage(
          id: 'francis-reply',
          senderName: 'Francis',
          body:
              'Mmm, I will persevere. I really enjoy tennis, it is so fun and my body is getting stronger.',
          timeLabel: '08:10',
          isMine: false,
        ),
        ClubChatMessage(
          id: 'me-followup',
          senderName: 'You',
          body:
              'It is good if you like it. If there is anything you do not know, ask me anytime.',
          timeLabel: '08:12',
          isMine: true,
        ),
      ],
    ),
    ClubConversation(
      id: 'mina-chat',
      playerName: 'Mina',
      ageLabel: '24',
      avatarAsset: 'assets/images/head/women/woman_head_17.jpg',
      heroAsset: 'assets/images/Profile.png',
      online: true,
      unreadCount: 3,
      lastTimeLabel: '08:12',
      messages: [
        ClubChatMessage(
          id: 'mina-one',
          senderName: 'Mina',
          body: 'I mostly play indoor, so rain will not stop our match.',
          timeLabel: '08:04',
          isMine: false,
        ),
        ClubChatMessage(
          id: 'me-mina-one',
          senderName: 'You',
          body: 'Perfect. I can book court two for tonight.',
          timeLabel: '08:08',
          isMine: true,
        ),
      ],
    ),
    ClubConversation(
      id: 'sofia-chat',
      playerName: 'Sofia',
      ageLabel: '27',
      avatarAsset: 'assets/images/head/women/woman_head_18.jpg',
      heroAsset: 'assets/images/Surface.png',
      online: false,
      unreadCount: 1,
      lastTimeLabel: '08:12',
      messages: [
        ClubChatMessage(
          id: 'sofia-one',
          senderName: 'Sofia',
          body: 'Can we run ten minutes of slice returns before doubles?',
          timeLabel: '07:58',
          isMine: false,
        ),
      ],
    ),
    ClubConversation(
      id: 'aria-chat',
      playerName: 'Aria',
      ageLabel: '23',
      avatarAsset: 'assets/images/head/women/woman_head_19.jpg',
      heroAsset: 'assets/images/Strings.png',
      online: true,
      unreadCount: 0,
      lastTimeLabel: 'Yesterday',
      messages: [
        ClubChatMessage(
          id: 'aria-one',
          senderName: 'Aria',
          body: 'Send me your warmup ladder when you have a minute.',
          timeLabel: '20:18',
          isMine: false,
        ),
        ClubChatMessage(
          id: 'me-aria-one',
          senderName: 'You',
          body: 'Done. Keep the first round light and fast.',
          timeLabel: '20:21',
          isMine: true,
        ),
      ],
    ),
    ClubConversation(
      id: 'leo-chat',
      playerName: 'Leo',
      ageLabel: '29',
      avatarAsset: 'assets/images/head/men/man_head_20.jpg',
      heroAsset: 'assets/images/Arena.png',
      online: false,
      unreadCount: 0,
      lastTimeLabel: 'Mon',
      messages: [
        ClubChatMessage(
          id: 'leo-one',
          senderName: 'Leo',
          body: 'The league bracket is posted. We drew the early slot.',
          timeLabel: 'Mon',
          isMine: false,
        ),
      ],
    ),
  ];
}
