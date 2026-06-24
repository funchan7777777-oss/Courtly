import 'dart:async';

import 'package:camera/camera.dart';
import 'package:courtly/features/club_chats/data/club_chat_seed.dart';
import 'package:courtly/features/club_chats/domain/club_chat.dart';
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
  Set<String> _blockedUserIds = {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadLocalState());
  }

  @override
  Widget build(BuildContext context) {
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
                  requestCount: _requests.length,
                  onOpenRequests: _openRequests,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: _ClubSectionHeader(
                  artAsset: 'assets/images/Breakpoint.png',
                  artWidth: 168,
                  artHeight: 26,
                  trailing: 'More',
                  onTrailingPressed: _openRequests,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 164,
                child: _requests.isEmpty
                    ? const _EmptyRequestStrip()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final request = _requests[index];

                          return _FriendRequestCard(
                            request: request,
                            onPressed: () => _openRequestDetail(request),
                            onFollow: () => _toggleRequestFollow(request.id),
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
                child: _ClubSectionHeader(
                  artAsset: 'assets/images/Sparring.png',
                  artWidth: 116,
                  artHeight: 28,
                  trailing: '${_visibleConversations.length} chats',
                ),
              ),
            ),
            if (_visibleConversations.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(22, 0, 22, 124),
                  child: _EmptyConversationPanel(),
                ),
              )
            else
              SliverList.separated(
                itemCount: _visibleConversations.length,
                itemBuilder: (context, index) {
                  final conversation = _visibleConversations[index];

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      0,
                      22,
                      index == _visibleConversations.length - 1 ? 122 : 0,
                    ),
                    child: Dismissible(
                      key: ValueKey(conversation.id),
                      direction: DismissDirection.endToStart,
                      background: const _DeleteSwipeBackground(),
                      confirmDismiss: (_) =>
                          _confirmDeleteConversation(conversation),
                      onDismissed: (_) => _deleteConversation(conversation.id),
                      child: _ConversationTile(
                        conversation: conversation,
                        onPressed: () => unawaited(_openChat(conversation)),
                        onLongPress: () =>
                            unawaited(_askDeleteConversation(conversation)),
                      ),
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
        .where((conversation) => !_blockedUserIds.contains(conversation.userId))
        .toList(growable: false);
  }

  Future<void> _loadLocalState() async {
    final store = CourtlySocialStore.instance;
    final blocked = await store.blockedUserIds();
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

    if (!mounted) {
      return;
    }
    setState(() {
      _blockedUserIds = blocked;
      _conversations = conversations;
      _requests = _requests
          .where((request) => !blocked.contains(request.userId))
          .toList();
    });
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

  Future<void> _askDeleteConversation(ClubConversation conversation) async {
    final confirmed = await _confirmDeleteConversation(conversation);
    if (!confirmed || !mounted) {
      return;
    }

    _deleteConversation(conversation.id);
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

  void _deleteConversation(String conversationId) {
    setState(() {
      _conversations = _conversations
          .where((conversation) => conversation.id != conversationId)
          .toList();
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
    required this.requestCount,
    required this.onOpenRequests,
  });

  final int requestCount;
  final VoidCallback onOpenRequests;

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
          onPressed: onOpenRequests,
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
                  '$requestCount',
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

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onPressed,
    required this.onLongPress,
  });

  final ClubConversation conversation;
  final VoidCallback onPressed;
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
                  _ClubAvatar(
                    assetPath: conversation.avatarAsset,
                    size: 54,
                    showGlow: conversation.online,
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
                onVideoCall: () => unawaited(_confirmAndOpenVideoCall()),
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

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _CallCostDialog(
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await Navigator.of(context).push<ClubCallResult>(
      CupertinoPageRoute<ClubCallResult>(
        builder: (_) => ClubVideoCallPage(conversation: _conversation),
      ),
    );
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
      name: _conversation.playerName,
      avatarAsset: _conversation.avatarAsset,
      heroAsset: _conversation.heroAsset,
    );
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => CourtlyUserProfilePage(
          profile: profile,
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
    required this.onVideoCall,
  });

  final ClubConversation conversation;
  final VoidCallback onBack;
  final VoidCallback onOpenProfile;
  final VoidCallback onVideoCall;

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
            _HeaderIconButton(
              icon: CupertinoIcons.ellipsis,
              onPressed: onVideoCall,
            ),
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
  const ClubVideoCallPage({required this.conversation, super.key});

  final ClubConversation conversation;

  @override
  State<ClubVideoCallPage> createState() => _ClubVideoCallPageState();
}

class _ClubVideoCallPageState extends State<ClubVideoCallPage> {
  bool _speakerOn = true;
  bool _muted = false;
  bool _cameraOn = true;
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareCamera());
  }

  @override
  void dispose() {
    _cameraController?.dispose();
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
              cameraReady: _cameraReady,
              cameraOn: _cameraOn,
              permissionDenied: _permissionDenied,
            ),
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
              onCamera: () => setState(() => _cameraOn = !_cameraOn),
              onEnd: () => Navigator.of(
                context,
              ).pop(const ClubCallResult(started: true)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _prepareCamera() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();
    if (!cameraStatus.isGranted || !microphoneStatus.isGranted) {
      if (mounted) {
        setState(() => _permissionDenied = true);
      }
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        setState(() => _permissionDenied = true);
      }
      return;
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
    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _cameraController = controller;
      _cameraReady = true;
    });
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
  const _VideoPreview({
    required this.controller,
    required this.cameraReady,
    required this.cameraOn,
    required this.permissionDenied,
  });

  final CameraController? controller;
  final bool cameraReady;
  final bool cameraOn;
  final bool permissionDenied;

  @override
  Widget build(BuildContext context) {
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
        child: cameraReady && cameraOn && controller != null
            ? CameraPreview(controller!)
            : DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFF1A004D)),
                child: Center(
                  child: Icon(
                    permissionDenied
                        ? CupertinoIcons.lock_fill
                        : CupertinoIcons.video_camera,
                    color: _chatPinkSoft,
                    size: 28,
                  ),
                ),
              ),
      ),
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
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return DecoratedBox(
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
            );
          },
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _chatPanel.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            'No new friend requests right now.',
            style: _clubTextStyle(
              color: _chatWhite.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyConversationPanel extends StatelessWidget {
  const _EmptyConversationPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _chatPanel.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Your court chats are clear. Follow a player to start a new rally.',
          textAlign: TextAlign.center,
          style: _clubTextStyle(
            color: _chatWhite.withValues(alpha: 0.75),
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
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
    fontSize: fontSize,
    height: height,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );
}
