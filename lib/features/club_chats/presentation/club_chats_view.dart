import 'dart:async';

import 'package:camera/camera.dart';
import 'package:courtly/atelier/theme/courtly_font_families.dart';
import 'package:courtly/features/club_chats/data/club_chat_seed.dart';
import 'package:courtly/features/club_chats/domain/club_chat.dart';
import 'package:courtly/features/court_reels/data/court_reel_seed.dart';
import 'package:courtly/features/post_sharing/data/post_sharing_seed.dart';
import 'package:courtly/shared/presentation/courtly_profile_image.dart';
import 'package:courtly/shared/presentation/courtly_safe_layout.dart';
import 'package:courtly/shared/social/courtly_moderation.dart';
import 'package:courtly/shared/social/courtly_social_store.dart';
import 'package:courtly/shared/social/courtly_user_directory.dart';
import 'package:courtly/shared/social/courtly_user_profile.dart';
import 'package:courtly/shared/social/courtly_user_profile_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

const Color _chatPurple = Color(0xFF1A004D);
const Color _chatPurpleDeep = Color(0xFF130038);
const Color _chatPanel = Color(0xFF26005F);
const Color _chatPanelSoft = Color(0xFF522B88);
const Color _chatPink = Color(0xFFFF2DD2);
const Color _chatPinkSoft = Color(0xFFFF72DB);
const Color _chatWhite = Color(0xFFFFFFFF);

Future<void> openClubChatForProfile(
  BuildContext context,
  CourtlyUserProfile profile,
) async {
  final messages = await CourtlySocialStore.instance.loadMessages(profile.id);
  if (!context.mounted) {
    return;
  }

  await Navigator.of(context).push<ClubConversation>(
    CupertinoPageRoute<ClubConversation>(
      builder: (_) => ClubChatThreadPage(
        conversation: ClubConversation(
          id: 'chat-${profile.id}',
          userId: profile.id,
          playerName: profile.name,
          ageLabel: profile.ageLabel,
          avatarAsset: profile.avatarAsset,
          heroAsset: profile.heroAsset,
          online: false,
          unreadCount: 0,
          lastTimeLabel: messages.isEmpty ? '' : messages.last.timeLabel,
          messages: messages.map(_messageFromStored).toList(growable: false),
        ),
      ),
    ),
  );
}

List<CourtlyProfileVideoItem> _clubProfileVideosFor(String userId) {
  return CourtReelSeed.openingFeed
      .where((reel) => reel.userId == userId)
      .map(
        (reel) => CourtlyProfileVideoItem(
          id: reel.id,
          thumbnailAsset: reel.backdropAsset,
        ),
      )
      .toList(growable: false);
}

List<CourtlyProfilePostItem> _clubProfilePostsFor(String userId) {
  return PostSharingSeed.openingPosts
      .where((post) => post.authorId == userId)
      .map(
        (post) => CourtlyProfilePostItem(
          id: post.id,
          imageAsset: post.imageAsset,
          body: post.body,
        ),
      )
      .toList(growable: false);
}

ClubChatMessage _messageFromStored(CourtlyStoredMessage message) {
  return ClubChatMessage(
    id: message.id,
    senderName: message.senderName,
    body: message.body,
    timeLabel: message.timeLabel,
    isMine: message.isMine,
  );
}

CourtlyStoredMessage _messageToStored(ClubChatMessage message) {
  return CourtlyStoredMessage(
    id: message.id,
    senderName: message.senderName,
    body: message.body,
    timeLabel: message.timeLabel,
    isMine: message.isMine,
  );
}

class ClubChatsView extends StatefulWidget {
  const ClubChatsView({super.key});

  @override
  State<ClubChatsView> createState() => _ClubChatsViewState();
}

class _ClubChatsViewState extends State<ClubChatsView> {
  List<ClubFriendRequest> _requests = List<ClubFriendRequest>.of(
    ClubChatSeed.openingRequests,
  );
  List<ClubConversation> _conversations = List<ClubConversation>.of(
    ClubChatSeed.openingConversations,
  );
  List<CourtlySystemMessage> _systemMessages = const [];
  List<CourtlyUserProfile> _mutualFriends = const [];
  Set<String> _blockedUserIds = {};
  Set<String> _reportedContentIds = {};

  @override
  void initState() {
    super.initState();
    CourtlySocialStore.instance.relationshipVersion.addListener(
      _handleStoreChanged,
    );
    CourtlySocialStore.instance.messageCenterVersion.addListener(
      _handleStoreChanged,
    );
    unawaited(_loadLocalState());
  }

  @override
  void dispose() {
    CourtlySocialStore.instance.relationshipVersion.removeListener(
      _handleStoreChanged,
    );
    CourtlySocialStore.instance.messageCenterVersion.removeListener(
      _handleStoreChanged,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleMessagesCount =
        _visibleSystemMessages.length + _visibleConversations.length;

    return CupertinoPageScaffold(
      child: _ClubChatBackdrop(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  22,
                  courtlySafeTop(context, 10),
                  22,
                  0,
                ),
                child: _ClubChatsTopBar(
                  mutualCount: _mutualFriends.length,
                  onOpenMutuals: _openMutualFriends,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: _ClubTextSectionHeader(
                  title: 'Mutual follows',
                  detail: '${_mutualFriends.length} friends',
                  actionLabel: 'View all',
                  onAction: _openMutualFriends,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 150,
                child: _mutualFriends.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(22, 12, 22, 0),
                        child: _InlineInfoCard(
                          icon: CupertinoIcons.person_2_fill,
                          title: 'No mutual follows yet',
                          body:
                              'Follow each other to unlock private chat and calls.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _mutualFriends.length,
                        itemBuilder: (context, index) {
                          final profile = _mutualFriends[index];

                          return _MutualFriendCard(
                            profile: profile,
                            onPressed: () => _openProfile(profile),
                            onMessage: () =>
                                unawaited(_openChatForProfile(profile)),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
                child: _ClubTextSectionHeader(
                  title: 'Messages',
                  detail: '$visibleMessagesCount items',
                  actionLabel: visibleMessagesCount == 0 ? null : 'Clear all',
                  onAction: visibleMessagesCount == 0
                      ? null
                      : () => unawaited(_clearAllMessages()),
                ),
              ),
            ),
            if (visibleMessagesCount == 0)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(22, 0, 22, 124),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _InlineInfoCard(
                      icon: CupertinoIcons.chat_bubble_2_fill,
                      title: 'No messages yet',
                      body:
                          'System updates and chat history will stay here after they happen.',
                    ),
                  ),
                ),
              )
            else
              SliverList.separated(
                itemCount: visibleMessagesCount,
                itemBuilder: (context, index) {
                  final systemMessages = _visibleSystemMessages;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      0,
                      22,
                      index == visibleMessagesCount - 1 ? 122 : 0,
                    ),
                    child: index < systemMessages.length
                        ? _buildSystemMessageRow(systemMessages[index])
                        : _buildConversationRow(
                            _visibleConversations[index -
                                systemMessages.length],
                          ),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
              ),
          ],
        ),
      ),
    );
  }

  List<ClubConversation> get _visibleConversations {
    return _conversations
        .where(
          (conversation) =>
              !_blockedUserIds.contains(conversation.userId) &&
              !_reportedContentIds.contains('chat:${conversation.userId}'),
        )
        .toList(growable: false);
  }

  List<CourtlySystemMessage> get _visibleSystemMessages {
    return _systemMessages
        .where((message) {
          final userId = message.userId;
          final targetId = message.targetId;
          if (userId != null &&
              _blockedUserIds.contains(userId) &&
              message.kind != 'block') {
            return false;
          }
          if (targetId != null && _reportedContentIds.contains(targetId)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  Widget _buildSystemMessageRow(CourtlySystemMessage message) {
    final opensProfile =
        message.userId != null &&
        message.kind != 'report' &&
        message.kind != 'block';

    return Dismissible(
      key: ValueKey('system-${message.id}'),
      direction: DismissDirection.endToStart,
      background: const _DeleteSwipeBackground(),
      onDismissed: (_) => unawaited(_deleteSystemMessage(message.id)),
      child: _SystemMessageTile(
        message: message,
        onPressed: opensProfile
            ? () => _openProfile(CourtlyUserDirectory.byId(message.userId!))
            : null,
      ),
    );
  }

  Widget _buildConversationRow(ClubConversation conversation) {
    return Dismissible(
      key: ValueKey('conversation-${conversation.id}'),
      direction: DismissDirection.endToStart,
      background: const _DeleteSwipeBackground(),
      onDismissed: (_) => unawaited(_deleteConversation(conversation.id)),
      child: _ConversationTile(
        conversation: conversation,
        onPressed: () => unawaited(_openChat(conversation)),
        onOpenProfile: () => _openConversationProfile(conversation),
        onLongPress: () => unawaited(_askDeleteConversation(conversation)),
      ),
    );
  }

  Future<void> _loadLocalState() async {
    final store = CourtlySocialStore.instance;
    await store.ensureClubMessagesSeeded();
    final blocked = await store.blockedUserIds();
    final reported = await store.reportedContentIds();
    final systemMessages = await store.loadSystemMessages();
    final mutualIds = await store.mutualFollowUserIds();
    final messageUserIds = await store.messageUserIds();
    final conversations = <ClubConversation>[];

    for (final userId in messageUserIds) {
      if (blocked.contains(userId)) {
        continue;
      }
      final messages = await store.loadMessages(userId);
      if (messages.isEmpty) {
        continue;
      }
      final profile = CourtlyUserDirectory.byId(userId);
      conversations.add(
        ClubConversation(
          id: 'chat-$userId',
          userId: userId,
          playerName: profile.name,
          ageLabel: profile.ageLabel,
          avatarAsset: profile.avatarAsset,
          heroAsset: profile.heroAsset,
          online: false,
          unreadCount: 0,
          lastTimeLabel: messages.last.timeLabel,
          messages: messages.map(_messageFromStored).toList(growable: false),
        ),
      );
    }
    conversations.sort((left, right) {
      return right.lastTimeLabel.compareTo(left.lastTimeLabel);
    });

    if (!mounted) {
      return;
    }
    setState(() {
      _blockedUserIds = blocked;
      _reportedContentIds = reported;
      _systemMessages = systemMessages;
      _mutualFriends = mutualIds
          .where((userId) => !blocked.contains(userId))
          .map(CourtlyUserDirectory.byId)
          .toList(growable: false);
      _conversations = conversations;
      _requests = _requests
          .where((request) => !blocked.contains(request.userId))
          .toList();
    });
  }

  void _handleStoreChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_loadLocalState());
  }

  void _toggleRequestFollow(String requestId) {
    final index = _requests.indexWhere((request) => request.id == requestId);
    if (index == -1) {
      return;
    }

    setState(() {
      final next = List<ClubFriendRequest>.of(_requests);
      final request = next[index];
      next[index] = request.copyWith(following: !request.following);
      _requests = next;
    });
  }

  Future<void> _openRequests() async {
    final nextRequests = await Navigator.of(context)
        .push<List<ClubFriendRequest>>(
          CupertinoPageRoute<List<ClubFriendRequest>>(
            builder: (_) => ClubFriendRequestsPage(requests: _requests),
          ),
        );

    if (nextRequests == null || !mounted) {
      return;
    }

    setState(() => _requests = nextRequests);
  }

  Future<void> _openMutualFriends() async {
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        builder: (_) => ClubMutualFriendsPage(profiles: _mutualFriends),
      ),
    );
    if (mounted) {
      unawaited(_loadLocalState());
    }
  }

  void _openProfile(CourtlyUserProfile profile) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => CourtlyUserProfilePage(
          profile: profile,
          videos: _clubProfileVideosFor(profile.id),
          posts: _clubProfilePostsFor(profile.id),
          onOpenChat: (profile) {
            unawaited(openClubChatForProfile(context, profile));
          },
          onModerated: (result) {
            if (result.action == CourtlyModerationAction.block) {
              unawaited(_loadLocalState());
            }
          },
        ),
      ),
    );
  }

  Future<void> _openChatForProfile(CourtlyUserProfile profile) async {
    await openClubChatForProfile(context, profile);
    if (mounted) {
      await _loadLocalState();
    }
  }

  void _openRequestDetail(ClubFriendRequest request) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => ClubFriendProfilePage(
          request: request,
          onFollowChanged: () => _toggleRequestFollow(request.id),
        ),
      ),
    );
  }

  Future<void> _openChat(ClubConversation conversation) async {
    final updated = await Navigator.of(context).push<ClubConversation>(
      CupertinoPageRoute<ClubConversation>(
        builder: (_) => ClubChatThreadPage(conversation: conversation),
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    await _loadLocalState();
    if (!mounted) {
      return;
    }

    final index = _conversations.indexWhere((entry) => entry.id == updated.id);
    if (index == -1) {
      return;
    }

    setState(() {
      final next = List<ClubConversation>.of(_conversations);
      next[index] = updated;
      _conversations = next;
    });
  }

  void _openConversationProfile(ClubConversation conversation) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => CourtlyUserProfilePage(
          profile: CourtlyUserDirectory.fromIdentity(
            id: conversation.userId,
            name: conversation.playerName,
            avatarAsset: conversation.avatarAsset,
            heroAsset: conversation.heroAsset,
          ),
          videos: _clubProfileVideosFor(conversation.userId),
          posts: _clubProfilePostsFor(conversation.userId),
          onOpenChat: (profile) {
            unawaited(openClubChatForProfile(context, profile));
          },
          onModerated: (result) {
            if (result.action == CourtlyModerationAction.block) {
              unawaited(_loadLocalState());
            }
          },
        ),
      ),
    );
  }

  Future<void> _askDeleteConversation(ClubConversation conversation) async {
    final confirmed = await _confirmDeleteConversation(conversation);
    if (!confirmed || !mounted) {
      return;
    }

    await _deleteConversation(conversation.id);
  }

  Future<bool> _confirmDeleteConversation(ClubConversation conversation) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Delete ${conversation.playerName}?'),
          content: const Text(
            'This removes the conversation from your club chat list.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _deleteConversation(String conversationId) async {
    final conversationIndex = _conversations.indexWhere(
      (entry) => entry.id == conversationId,
    );
    if (conversationIndex == -1) {
      return;
    }
    final conversation = _conversations[conversationIndex];
    setState(() {
      _conversations = _conversations
          .where((conversation) => conversation.id != conversationId)
          .toList();
    });
    await CourtlySocialStore.instance.deleteMessages(conversation.userId);
  }

  Future<void> _deleteSystemMessage(String messageId) async {
    setState(() {
      _systemMessages = _systemMessages
          .where((message) => message.id != messageId)
          .toList(growable: false);
    });
    await CourtlySocialStore.instance.deleteSystemMessage(messageId);
  }

  Future<void> _clearAllMessages() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Clear all messages?'),
          content: const Text(
            'This removes chat history and system notifications from this device.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    await CourtlySocialStore.instance.clearAllMessages();
    if (!mounted) {
      return;
    }
    setState(() {
      _systemMessages = const [];
      _conversations = const [];
    });
  }
}

class _ClubChatBackdrop extends StatelessWidget {
  const _ClubChatBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/Swing.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        DecoratedBox(
          decoration: BoxDecoration(color: _chatPurple.withValues(alpha: 0.18)),
        ),
        child,
      ],
    );
  }
}

class _ClubChatsTopBar extends StatelessWidget {
  const _ClubChatsTopBar({
    required this.mutualCount,
    required this.onOpenMutuals,
  });

  final int mutualCount;
  final VoidCallback onOpenMutuals;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/Approach.png',
          width: 178,
          height: 36,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
        ),
        const Spacer(),
        CupertinoButton(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          onPressed: onOpenMutuals,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _chatWhite.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: _chatWhite.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.person_2_fill,
                  color: _chatPinkSoft,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  '$mutualCount',
                  style: _clubTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ClubTextSectionHeader extends StatelessWidget {
  const _ClubTextSectionHeader({
    required this.title,
    required this.detail,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final actionLabel = this.actionLabel;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: _clubTextStyle(
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              style: _clubTextStyle(
                color: _chatWhite.withValues(alpha: 0.48),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (actionLabel != null)
          CupertinoButton(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: _clubTextStyle(
                color: actionLabel == 'Clear all'
                    ? _chatPinkSoft
                    : _chatWhite.withValues(alpha: 0.58),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _ClubSectionHeader extends StatelessWidget {
  const _ClubSectionHeader({
    required this.artAsset,
    required this.artWidth,
    required this.artHeight,
    this.trailing,
    this.onTrailingPressed,
  });

  final String artAsset;
  final double artWidth;
  final double artHeight;
  final String? trailing;
  final VoidCallback? onTrailingPressed;

  @override
  Widget build(BuildContext context) {
    final trailingText = trailing;

    return Row(
      children: [
        Image.asset(
          artAsset,
          width: artWidth,
          height: artHeight,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
        ),
        const Spacer(),
        if (trailingText != null)
          CupertinoButton(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            onPressed: onTrailingPressed,
            child: Row(
              children: [
                Text(
                  trailingText,
                  style: _clubTextStyle(
                    color: _chatWhite.withValues(alpha: 0.52),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (onTrailingPressed != null) ...[
                  const SizedBox(width: 2),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: _chatWhite.withValues(alpha: 0.52),
                    size: 13,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _FriendRequestCard extends StatelessWidget {
  const _FriendRequestCard({
    required this.request,
    required this.onPressed,
    required this.onFollow,
  });

  final ClubFriendRequest request;
  final VoidCallback onPressed;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: _chatPanel.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
          child: Column(
            children: [
              _ClubAvatar(assetPath: request.avatarAsset, size: 52),
              const SizedBox(height: 9),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      request.playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _clubTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _AgePill(ageLabel: request.ageLabel, compact: true),
                ],
              ),
              const Spacer(),
              _FollowButton(
                followed: request.following,
                onPressed: onFollow,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MutualFriendCard extends StatelessWidget {
  const _MutualFriendCard({
    required this.profile,
    required this.onPressed,
    required this.onMessage,
  });

  final CourtlyUserProfile profile;
  final VoidCallback onPressed;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 132,
        decoration: BoxDecoration(
          color: _chatPanel.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _chatWhite.withValues(alpha: 0.08)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          children: [
            _ClubAvatar(assetPath: profile.avatarAsset, size: 54),
            const SizedBox(height: 8),
            Text(
              profile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _clubTextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Mutual follow',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _clubTextStyle(
                color: _chatWhite.withValues(alpha: 0.56),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              onPressed: onMessage,
              child: Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _chatPink,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.chat_bubble_fill,
                      color: _chatWhite,
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Chat',
                      style: _clubTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemMessageTile extends StatelessWidget {
  const _SystemMessageTile({required this.message, this.onPressed});

  final CourtlySystemMessage message;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final profile = message.userId == null
        ? null
        : CourtlyUserDirectory.byId(message.userId!);

    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        decoration: BoxDecoration(
          color: _chatPanel.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _chatWhite.withValues(alpha: 0.07)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            _SystemMessageIcon(message: message, profile: profile),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          message.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _clubTextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SystemKindPill(kind: message.kind),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    message.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _clubTextStyle(
                      color: _chatWhite.withValues(alpha: 0.74),
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.timeLabel,
                  style: _clubTextStyle(
                    color: _chatWhite.withValues(alpha: 0.38),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Icon(
                  CupertinoIcons.chevron_left,
                  color: _chatWhite.withValues(alpha: 0.22),
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemMessageIcon extends StatelessWidget {
  const _SystemMessageIcon({required this.message, required this.profile});

  final CourtlySystemMessage message;
  final CourtlyUserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final profile = this.profile;
    if (profile != null &&
        message.kind != 'report' &&
        message.kind != 'block') {
      return _ClubAvatar(assetPath: profile.avatarAsset, size: 52);
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _chatWhite.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: _chatWhite.withValues(alpha: 0.14)),
      ),
      child: Icon(_systemIcon(message.kind), color: _chatPinkSoft, size: 23),
    );
  }
}

class _SystemKindPill extends StatelessWidget {
  const _SystemKindPill({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _chatWhite.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          _systemKindLabel(kind),
          style: _clubTextStyle(
            color: _chatWhite.withValues(alpha: 0.78),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onPressed,
    required this.onOpenProfile,
    required this.onLongPress,
  });

  final ClubConversation conversation;
  final VoidCallback onPressed;
  final VoidCallback onOpenProfile;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      onLongPress: onLongPress,
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: _chatPanel.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CupertinoButton(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    onPressed: onOpenProfile,
                    child: _ClubAvatar(
                      assetPath: conversation.avatarAsset,
                      size: 54,
                      showGlow: conversation.online,
                    ),
                  ),
                  if (conversation.online)
                    Positioned(
                      right: 1,
                      bottom: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF58F58A),
                          shape: BoxShape.circle,
                          border: Border.all(color: _chatPanel, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: CupertinoButton(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            onPressed: onOpenProfile,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                conversation.playerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _clubTextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        _AgePill(ageLabel: conversation.ageLabel),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      conversation.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _clubTextStyle(
                        color: _chatWhite.withValues(alpha: 0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    conversation.lastTimeLabel,
                    style: _clubTextStyle(
                      color: _chatWhite.withValues(alpha: 0.35),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  if (conversation.unreadCount > 0)
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: _chatPink,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          conversation.unreadCount.toString(),
                          style: _clubTextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    )
                  else
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: _chatWhite.withValues(alpha: 0.28),
                      size: 16,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClubChatThreadPage extends StatefulWidget {
  const ClubChatThreadPage({required this.conversation, super.key});

  final ClubConversation conversation;

  @override
  State<ClubChatThreadPage> createState() => _ClubChatThreadPageState();
}

class _ClubChatThreadPageState extends State<ClubChatThreadPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ClubConversation _conversation;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation.copyWith(unreadCount: 0);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;

    return CupertinoPageScaffold(
      child: _ClubChatBackdrop(
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardBottom),
          child: Column(
            children: [
              _ThreadHeader(
                conversation: _conversation,
                onBack: _close,
                onOpenProfile: _openProfile,
                onMore: () => unawaited(_openModeration()),
              ),
              _ThreadProfileCard(
                conversation: _conversation,
                onOpenProfile: _openProfile,
                onVideoCall: () => unawaited(_confirmAndOpenVideoCall()),
              ),
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                  itemCount: _conversation.messages.length,
                  itemBuilder: (context, index) {
                    return _MessageBubble(
                      message: _conversation.messages[index],
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 18),
                ),
              ),
              _MessageComposer(
                controller: _messageController,
                onSubmitted: () => unawaited(_sendMessage()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    if (body.isEmpty) {
      return;
    }
    if (!await _ensureMutualAccess('Messages require mutual follow')) {
      return;
    }

    final message = ClubChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      senderName: 'You',
      body: body,
      timeLabel: _formatNow(),
      isMine: true,
    );

    setState(() {
      _conversation = _conversation.copyWith(
        messages: [..._conversation.messages, message],
        unreadCount: 0,
        lastTimeLabel: message.timeLabel,
      );
    });
    await CourtlySocialStore.instance.saveMessages(
      userId: _conversation.userId,
      messages: _conversation.messages.map(_messageToStored).toList(),
    );
    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      unawaited(
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  Future<void> _confirmAndOpenVideoCall() async {
    if (!await _ensureMutualAccess('Video calls require mutual follow')) {
      return;
    }
    if (!mounted) {
      return;
    }

    final cameraController = await _prepareCallCamera();
    if (cameraController == null || !mounted) {
      await cameraController?.dispose();
      return;
    }

    await Navigator.of(context).push<ClubCallResult>(
      CupertinoPageRoute<ClubCallResult>(
        builder: (_) => ClubVideoCallPage(
          conversation: _conversation,
          cameraController: cameraController,
        ),
      ),
    );
  }

  Future<CameraController?> _prepareCallCamera() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();
    if (!cameraStatus.isGranted || !microphoneStatus.isGranted) {
      if (mounted) {
        await showCourtlyAccessDialog(
          context: context,
          title: 'Camera and microphone required',
          message:
              'Allow camera and microphone access to preview yourself before the call starts.',
        );
      }
      return null;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          await showCourtlyAccessDialog(
            context: context,
            title: 'Camera unavailable',
            message:
                'No camera was found on this device. Please check the simulator or device settings.',
          );
        }
        return null;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await controller.initialize();
      return controller;
    } catch (_) {
      if (mounted) {
        await showCourtlyAccessDialog(
          context: context,
          title: 'Preview failed',
          message:
              'Courtly could not start the camera preview. Check permission settings and try again.',
        );
      }
      return null;
    }
  }

  Future<bool> _ensureMutualAccess(String title) async {
    final mutual = await CourtlySocialStore.instance.isMutualFollow(
      _conversation.userId,
    );
    if (mutual) {
      return true;
    }
    if (!mounted) {
      return false;
    }

    await showCourtlyAccessDialog(
      context: context,
      title: title,
      message:
          'Courtly only unlocks private chat and video after both players follow each other. Send a follow request from the profile first.',
    );
    return false;
  }

  void _openProfile() {
    final profile = CourtlyUserDirectory.fromIdentity(
      id: _conversation.userId,
      name: _conversation.playerName,
      avatarAsset: _conversation.avatarAsset,
      heroAsset: _conversation.heroAsset,
    );
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => CourtlyUserProfilePage(
          profile: profile,
          videos: _clubProfileVideosFor(profile.id),
          posts: _clubProfilePostsFor(profile.id),
          onOpenChat: (_) {},
          onModerated: (result) {
            if (result.action == CourtlyModerationAction.block) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }

  Future<void> _openModeration() async {
    final result = await showCourtlyModerationSheet(
      context: context,
      targetId: 'chat:${_conversation.userId}',
      targetType: 'chat',
      title: _conversation.playerName,
      userId: _conversation.userId,
      summary: _conversation.preview,
      avatarAsset: _conversation.avatarAsset,
    );
    if (result == null || !mounted) {
      return;
    }

    if (result.action == CourtlyModerationAction.block) {
      await showCourtlyActionSuccess(
        context: context,
        title: 'User blocked',
        message:
            'This player and their conversation will stay hidden from your club chat.',
      );
      if (mounted) {
        Navigator.of(context).pop(_conversation);
      }
      return;
    }

    await showCourtlyActionSuccess(
      context: context,
      title: 'Report sent',
      message: 'The report was saved locally.',
    );
  }

  void _close() {
    Navigator.of(context).pop(_conversation);
  }

  String _formatNow() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({
    required this.conversation,
    required this.onBack,
    required this.onOpenProfile,
    required this.onMore,
  });

  final ClubConversation conversation;
  final VoidCallback onBack;
  final VoidCallback onOpenProfile;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, courtlySafeTop(context, 10), 14, 0),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            _HeaderIconButton(
              icon: CupertinoIcons.chevron_left,
              onPressed: onBack,
            ),
            Expanded(
              child: CupertinoButton(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                onPressed: onOpenProfile,
                child: Text(
                  conversation.playerName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _clubTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            _HeaderIconButton(icon: CupertinoIcons.ellipsis, onPressed: onMore),
          ],
        ),
      ),
    );
  }
}

class _ThreadProfileCard extends StatelessWidget {
  const _ThreadProfileCard({
    required this.conversation,
    required this.onOpenProfile,
    required this.onVideoCall,
  });

  final ClubConversation conversation;
  final VoidCallback onOpenProfile;
  final VoidCallback onVideoCall;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
      child: Column(
        children: [
          CupertinoButton(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            onPressed: onOpenProfile,
            child: _ClubAvatar(
              assetPath: conversation.avatarAsset,
              size: 86,
              showGlow: conversation.online,
            ),
          ),
          const SizedBox(height: 10),
          CupertinoButton(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            onPressed: onVideoCall,
            child: Container(
              width: 76,
              height: 36,
              decoration: BoxDecoration(
                color: _chatPink,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55FF2DD2),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.video_camera_solid,
                color: _chatWhite,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ClubChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: isMine ? _chatPink : _chatWhite,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isMine ? 14 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 14),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            message.body,
            style: _clubTextStyle(
              color: isMine ? _chatWhite : const Color(0xFF4B4158),
              fontSize: 13,
              height: 1.28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _chatPanelSoft.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _chatWhite.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: CupertinoTextField.borderless(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 0, 10, 1),
                placeholder: 'Please enter...',
                placeholderStyle: _clubTextStyle(
                  color: _chatWhite.withValues(alpha: 0.28),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                style: _clubTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                cursorColor: _chatPink,
                minLines: 1,
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmitted(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CupertinoButton(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                onPressed: onSubmitted,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: _chatWhite,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.paperplane_fill,
                    color: _chatPink,
                    size: 21,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClubVideoCallPage extends StatefulWidget {
  const ClubVideoCallPage({
    required this.conversation,
    required this.cameraController,
    super.key,
  });

  final ClubConversation conversation;
  final CameraController cameraController;

  @override
  State<ClubVideoCallPage> createState() => _ClubVideoCallPageState();
}

class _ClubVideoCallPageState extends State<ClubVideoCallPage> {
  bool _speakerOn = true;
  bool _muted = false;
  bool _cameraOn = true;
  late CameraController _cameraController = widget.cameraController;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation;

    return CupertinoPageScaffold(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            conversation.heroAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _chatPurpleDeep.withValues(alpha: 0.42),
                  _chatPurpleDeep.withValues(alpha: 0.06),
                  _chatPurpleDeep.withValues(alpha: 0.54),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: courtlySafeTop(context, 10),
            child: _VideoCallHeader(
              name: conversation.playerName,
              onBack: () => Navigator.of(
                context,
              ).pop(const ClubCallResult(started: false)),
            ),
          ),
          Positioned(
            right: 24,
            top: courtlySafeTop(context, 84),
            child: _VideoPreview(
              controller: _cameraController,
              cameraOn: _cameraOn,
            ),
          ),
          Positioned(
            left: 32,
            right: 32,
            top: courtlySafeTop(context, 254),
            child: _RemoteCallStatus(conversation: conversation),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 72,
            child: _VideoControlBar(
              speakerOn: _speakerOn,
              muted: _muted,
              cameraOn: _cameraOn,
              onSpeaker: () => setState(() => _speakerOn = !_speakerOn),
              onMute: () => setState(() => _muted = !_muted),
              onCamera: () => unawaited(_toggleCamera()),
              onEnd: () => Navigator.of(
                context,
              ).pop(const ClubCallResult(started: true)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCamera() async {
    final cameraOn = !_cameraOn;
    setState(() => _cameraOn = cameraOn);

    try {
      if (cameraOn) {
        await _cameraController.resumePreview();
      } else {
        await _cameraController.pausePreview();
      }
    } catch (_) {
      // The fake call can keep the visible toggle state even if preview pause
      // is already in the requested state on a simulator or device.
    }
  }
}

class _VideoCallHeader extends StatelessWidget {
  const _VideoCallHeader({required this.name, required this.onBack});

  final String name;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          _HeaderIconButton(
            icon: CupertinoIcons.chevron_left,
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _clubTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Court video call',
                  style: _clubTextStyle(
                    color: _chatWhite.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _HeaderIconButton(icon: CupertinoIcons.ellipsis, onPressed: () {}),
        ],
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({required this.controller, required this.cameraOn});

  final CameraController controller;
  final bool cameraOn;

  @override
  Widget build(BuildContext context) {
    final cameraReady = controller.value.isInitialized;

    return Container(
      width: 102,
      height: 142,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _chatPink, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: cameraReady && cameraOn
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controller),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.black.withValues(alpha: 0.44),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'You',
                          style: _clubTextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFF1A004D)),
                child: Center(
                  child: Icon(
                    CupertinoIcons.video_camera,
                    color: _chatPinkSoft,
                    size: 28,
                  ),
                ),
              ),
      ),
    );
  }
}

class _RemoteCallStatus extends StatelessWidget {
  const _RemoteCallStatus({required this.conversation});

  final ClubConversation conversation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ClubAvatar(
          assetPath: conversation.avatarAsset,
          size: 104,
          showGlow: true,
        ),
        const SizedBox(height: 18),
        Text(
          'Calling ${conversation.playerName.split(' ').first}',
          textAlign: TextAlign.center,
          style: _clubTextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Waiting for answer...',
          textAlign: TextAlign.center,
          style: _clubTextStyle(
            color: _chatWhite.withValues(alpha: 0.72),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VideoControlBar extends StatelessWidget {
  const _VideoControlBar({
    required this.speakerOn,
    required this.muted,
    required this.cameraOn,
    required this.onSpeaker,
    required this.onMute,
    required this.onCamera,
    required this.onEnd,
  });

  final bool speakerOn;
  final bool muted;
  final bool cameraOn;
  final VoidCallback onSpeaker;
  final VoidCallback onMute;
  final VoidCallback onCamera;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: _chatWhite.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(36),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _VideoRoundButton(
            icon: speakerOn
                ? CupertinoIcons.speaker_2_fill
                : CupertinoIcons.speaker_slash_fill,
            active: speakerOn,
            onPressed: onSpeaker,
          ),
          _VideoRoundButton(
            icon: cameraOn
                ? CupertinoIcons.video_camera_solid
                : CupertinoIcons.video_camera,
            active: cameraOn,
            onPressed: onCamera,
          ),
          CupertinoButton(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            onPressed: onEnd,
            child: Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: _chatPink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.phone_down_fill,
                color: _chatWhite,
                size: 25,
              ),
            ),
          ),
          _VideoRoundButton(
            icon: muted
                ? CupertinoIcons.mic_slash_fill
                : CupertinoIcons.mic_fill,
            active: !muted,
            onPressed: onMute,
          ),
        ],
      ),
    );
  }
}

class _VideoRoundButton extends StatelessWidget {
  const _VideoRoundButton({
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: active ? _chatWhite.withValues(alpha: 0.74) : _chatPanel,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: active ? _chatWhite : _chatPinkSoft, size: 22),
      ),
    );
  }
}

class ClubFriendRequestsPage extends StatefulWidget {
  const ClubFriendRequestsPage({required this.requests, super.key});

  final List<ClubFriendRequest> requests;

  @override
  State<ClubFriendRequestsPage> createState() => _ClubFriendRequestsPageState();
}

class _ClubFriendRequestsPageState extends State<ClubFriendRequestsPage> {
  late List<ClubFriendRequest> _requests;

  @override
  void initState() {
    super.initState();
    _requests = List<ClubFriendRequest>.of(widget.requests);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _ClubChatBackdrop(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                courtlySafeTop(context, 10),
                14,
                0,
              ),
              child: SizedBox(
                height: 42,
                child: Row(
                  children: [
                    _HeaderIconButton(
                      icon: CupertinoIcons.chevron_left,
                      onPressed: _close,
                    ),
                    Expanded(
                      child: Text(
                        'Friend request',
                        textAlign: TextAlign.center,
                        style: _clubTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
                itemCount: _requests.length,
                itemBuilder: (context, index) {
                  final request = _requests[index];

                  return _FriendRequestRow(
                    request: request,
                    onFollow: () => _toggleFollow(request.id),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFollow(String requestId) {
    final index = _requests.indexWhere((request) => request.id == requestId);
    if (index == -1) {
      return;
    }

    setState(() {
      final next = List<ClubFriendRequest>.of(_requests);
      final request = next[index];
      next[index] = request.copyWith(following: !request.following);
      _requests = next;
    });
  }

  void _close() {
    Navigator.of(context).pop(_requests);
  }
}

class ClubMutualFriendsPage extends StatelessWidget {
  const ClubMutualFriendsPage({required this.profiles, super.key});

  final List<CourtlyUserProfile> profiles;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _ClubChatBackdrop(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                courtlySafeTop(context, 10),
                14,
                0,
              ),
              child: SizedBox(
                height: 42,
                child: Row(
                  children: [
                    _HeaderIconButton(
                      icon: CupertinoIcons.chevron_left,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Mutual follows',
                        textAlign: TextAlign.center,
                        style: _clubTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),
              ),
            ),
            Expanded(
              child: profiles.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(22, 28, 22, 0),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _InlineInfoCard(
                          icon: CupertinoIcons.person_2,
                          title: 'No mutual follows yet',
                          body:
                              'When both players follow each other, they appear here.',
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
                      itemCount: profiles.length,
                      itemBuilder: (context, index) {
                        final profile = profiles[index];

                        return _MutualFriendRow(
                          profile: profile,
                          onOpenProfile: () => Navigator.of(context).push(
                            CupertinoPageRoute<void>(
                              builder: (_) => CourtlyUserProfilePage(
                                profile: profile,
                                videos: _clubProfileVideosFor(profile.id),
                                posts: _clubProfilePostsFor(profile.id),
                                onOpenChat: (profile) {
                                  unawaited(
                                    openClubChatForProfile(context, profile),
                                  );
                                },
                              ),
                            ),
                          ),
                          onOpenChat: () => unawaited(
                            openClubChatForProfile(context, profile),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 13),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MutualFriendRow extends StatelessWidget {
  const _MutualFriendRow({
    required this.profile,
    required this.onOpenProfile,
    required this.onOpenChat,
  });

  final CourtlyUserProfile profile;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: _chatPanel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _chatWhite.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          CupertinoButton(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            onPressed: onOpenProfile,
            child: _ClubAvatar(assetPath: profile.avatarAsset, size: 54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              onPressed: onOpenProfile,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _clubTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Private chat and video calls are unlocked',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _clubTextStyle(
                      color: _chatWhite.withValues(alpha: 0.62),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          CupertinoButton(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            onPressed: onOpenChat,
            child: Container(
              width: 44,
              height: 34,
              decoration: BoxDecoration(
                color: _chatPink,
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                CupertinoIcons.chat_bubble_fill,
                color: _chatWhite,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendRequestRow extends StatelessWidget {
  const _FriendRequestRow({required this.request, required this.onFollow});

  final ClubFriendRequest request;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: _chatPanel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          _ClubAvatar(assetPath: request.avatarAsset, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        request.playerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _clubTextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    _AgePill(ageLabel: request.ageLabel),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  request.motto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _clubTextStyle(
                    color: _chatWhite.withValues(alpha: 0.74),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _FollowButton(followed: request.following, onPressed: onFollow),
        ],
      ),
    );
  }
}

class ClubFriendProfilePage extends StatelessWidget {
  const ClubFriendProfilePage({
    required this.request,
    required this.onFollowChanged,
    super.key,
  });

  final ClubFriendRequest request;
  final VoidCallback onFollowChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _ClubChatBackdrop(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, courtlySafeTop(context, 10), 22, 28),
          child: Column(
            children: [
              Row(
                children: [
                  _HeaderIconButton(
                    icon: CupertinoIcons.chevron_left,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                ],
              ),
              const Spacer(),
              _ClubAvatar(assetPath: request.avatarAsset, size: 112),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    request.playerName,
                    style: _clubTextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AgePill(ageLabel: request.ageLabel),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                request.motto,
                textAlign: TextAlign.center,
                style: _clubTextStyle(
                  color: _chatWhite.withValues(alpha: 0.72),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),
              _FollowButton(
                followed: request.following,
                onPressed: onFollowChanged,
                wide: true,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallCostDialog extends StatelessWidget {
  const _CallCostDialog({required this.onCancel, required this.onConfirm});

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DefaultTextStyle(
        style: _clubTextStyle(),
        child: Container(
          width: MediaQuery.sizeOf(context).width.clamp(0.0, 320.0).toDouble(),
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: _chatPurple,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _chatWhite.withValues(alpha: 0.16)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please note',
                style: _clubTextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 132,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _chatPanelSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Starting a video call spends one rally credit. Confirm when you are ready to connect.',
                      textAlign: TextAlign.center,
                      style: _clubTextStyle(
                        color: _chatWhite.withValues(alpha: 0.88),
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              CupertinoButton(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                onPressed: onConfirm,
                child: Container(
                  height: 46,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _chatPink,
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: Center(
                    child: Text(
                      'Confirm',
                      style: _clubTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              CupertinoButton(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                onPressed: onCancel,
                child: Text(
                  'Not now',
                  style: _clubTextStyle(
                    color: _chatWhite.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgePill extends StatelessWidget {
  const _AgePill({required this.ageLabel, this.compact = false});

  final String ageLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 18 : 20,
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 7),
      decoration: BoxDecoration(
        color: _chatPinkSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          ageLabel,
          style: _clubTextStyle(
            fontSize: compact ? 9 : 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.followed,
    required this.onPressed,
    this.compact = false,
    this.wide = false,
  });

  final bool followed;
  final VoidCallback onPressed;
  final bool compact;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: wide ? 190 : (compact ? 82 : 76),
        height: compact ? 28 : 30,
        decoration: BoxDecoration(
          color: followed ? _chatWhite.withValues(alpha: 0.22) : _chatPink,
          borderRadius: BorderRadius.circular(15),
          border: followed
              ? Border.all(color: _chatWhite.withValues(alpha: 0.24))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              followed ? CupertinoIcons.check_mark : CupertinoIcons.star_fill,
              color: _chatWhite,
              size: compact ? 12 : 13,
            ),
            const SizedBox(width: 4),
            Text(
              followed ? 'Followed' : 'Follow',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _clubTextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubAvatar extends StatelessWidget {
  const _ClubAvatar({
    required this.assetPath,
    required this.size,
    this.showGlow = false,
  });

  final String assetPath;
  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _chatWhite.withValues(alpha: 0.35), width: 2),
        boxShadow: [
          if (showGlow)
            const BoxShadow(
              color: Color(0x55FF2DD2),
              blurRadius: 18,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipOval(
        child: CourtlyProfileImage(
          imagePath: assetPath,
          fit: BoxFit.cover,
          fallback: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_chatPink, _chatPanelSoft]),
            ),
            child: Center(
              child: Icon(
                CupertinoIcons.person_fill,
                color: _chatWhite,
                size: size * 0.48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: SizedBox.square(
        dimension: 42,
        child: Icon(icon, color: _chatWhite, size: 22),
      ),
    );
  }
}

class _DeleteSwipeBackground extends StatelessWidget {
  const _DeleteSwipeBackground();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Image.asset(
          'assets/images/Alley.png',
          width: 54,
          height: 54,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _EmptyRequestStrip extends StatelessWidget {
  const _EmptyRequestStrip();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/Love.png',
        width: 150,
        height: 150,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _EmptyConversationPanel extends StatelessWidget {
  const _EmptyConversationPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/Love.png',
        width: 190,
        height: 190,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _InlineInfoCard extends StatelessWidget {
  const _InlineInfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: _chatPanel.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _chatWhite.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _chatWhite.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _chatPinkSoft, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _clubTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: _clubTextStyle(
                    color: _chatWhite.withValues(alpha: 0.62),
                    fontSize: 12,
                    height: 1.28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _clubTextStyle({
  Color color = _chatWhite,
  double fontSize = 14,
  double? height,
  FontWeight fontWeight = FontWeight.w600,
  FontStyle fontStyle = FontStyle.normal,
}) {
  return TextStyle(
    color: color,
    fontFamily: CourtlyFontFamilies.ui,
    fontSize: fontSize,
    height: height,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );
}

IconData _systemIcon(String kind) {
  return switch (kind) {
    'mutual' => CupertinoIcons.person_2_fill,
    'follow' => CupertinoIcons.person_badge_plus,
    'comment' => CupertinoIcons.chat_bubble_text_fill,
    'report' => CupertinoIcons.shield_lefthalf_fill,
    'block' => CupertinoIcons.hand_raised_fill,
    _ => CupertinoIcons.bell_fill,
  };
}

String _systemKindLabel(String kind) {
  return switch (kind) {
    'mutual' => 'MUTUAL',
    'follow' => 'FOLLOW',
    'comment' => 'COMMENT',
    'report' => 'REPORT',
    'block' => 'BLOCK',
    _ => 'SYSTEM',
  };
}
