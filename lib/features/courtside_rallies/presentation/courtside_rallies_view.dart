import 'dart:async';

import 'package:camera/camera.dart';
import 'package:courtly/atelier/theme/courtly_font_families.dart';
import 'package:courtly/features/courtside_rallies/data/courtside_thread_seed.dart';
import 'package:courtly/features/courtside_rallies/domain/courtside_thread.dart';
import 'package:courtly/features/court_clips/data/court_clip_program.dart';
import 'package:courtly/features/court_moments/data/court_moment_chronicle.dart';
import 'package:courtly/shared/presentation/courtly_profile_image.dart';
import 'package:courtly/shared/presentation/courtly_safe_layout.dart';
import 'package:courtly/shared/social/courtly_content_safety.dart';
import 'package:courtly/shared/social/courtly_moderation.dart';
import 'package:courtly/shared/social/courtly_social_store.dart';
import 'package:courtly/shared/social/courtly_roster_book.dart';
import 'package:courtly/shared/social/courtly_player_card.dart';
import 'package:courtly/shared/social/courtly_player_card_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

const Color _chatPurple = Color(0xFF1A004D);
const Color _chatPurpleDeep = Color(0xFF130038);
const Color _chatPanel = Color(0xFF26005F);
const Color _chatPanelSoft = Color(0xFF522B88);
const Color _chatPink = Color(0xFFFF2DD2);
const Color _chatPinkSoft = Color(0xFFFF72DB);
const Color _chatWhite = Color(0xFFFFFFFF);

Future<void> openCourtsideRallyForCard(
  BuildContext context,
  CourtlyPlayerCard profile,
) async {
  final rallyNotes = await CourtlySocialStore.instance.loadMessages(
    profile.playerHandle,
  );
  if (!context.mounted) {
    return;
  }

  await Navigator.of(context).push<CourtsideRallyThread>(
    CupertinoPageRoute<CourtsideRallyThread>(
      builder: (_) => CourtsideRallyThreadPage(
        conversation: CourtsideRallyThread(
          threadId: 'chat-${profile.playerHandle}',
          playerHandle: profile.playerHandle,
          courtsideName: profile.courtsideName,
          ageBandLabel: profile.ageBandLabel,
          playerPortraitAsset: profile.playerPortraitAsset,
          courtCardAsset: profile.courtCardAsset,
          isCourtsideNow: false,
          unreadRallyNotes: 0,
          lastExchangeLabel: rallyNotes.isEmpty
              ? ''
              : rallyNotes.last.sentAtLabel,
          rallyNotes: rallyNotes
              .map(_messageFromStored)
              .toList(growable: false),
        ),
      ),
    ),
  );
}

List<CourtlyProfileVideoItem> _clubProfileVideosFor(String playerHandle) {
  return CourtClipProgram.trainingClipDispatches
      .where((clip) => clip.playerHandle == playerHandle)
      .map(
        (clip) => CourtlyProfileVideoItem(
          clipId: clip.clipId,
          coverFrameAsset: clip.coverFrameAsset,
        ),
      )
      .toList(growable: false);
}

List<CourtlyProfileMomentItem> _clubProfileMomentsFor(String playerHandle) {
  return CourtMomentChronicle.openingCourtMoments
      .where((moment) => moment.playerHandle == playerHandle)
      .map(
        (moment) => CourtlyProfileMomentItem(
          momentId: moment.momentId,
          momentImageAsset: moment.momentImageAsset,
          courtNote: moment.courtNote,
        ),
      )
      .toList(growable: false);
}

CourtsideRallyNote _messageFromStored(CourtlyStoredMessage rallyNote) {
  return CourtsideRallyNote(
    noteId: rallyNote.noteId,
    speakerName: rallyNote.speakerName,
    rallyLine: rallyNote.rallyLine,
    sentAtLabel: rallyNote.sentAtLabel,
    isFromCurrentPlayer: rallyNote.isFromCurrentPlayer,
  );
}

CourtlyStoredMessage _messageToStored(CourtsideRallyNote rallyNote) {
  return CourtlyStoredMessage(
    noteId: rallyNote.noteId,
    speakerName: rallyNote.speakerName,
    rallyLine: rallyNote.rallyLine,
    sentAtLabel: rallyNote.sentAtLabel,
    isFromCurrentPlayer: rallyNote.isFromCurrentPlayer,
  );
}

class CourtsideRalliesView extends StatefulWidget {
  const CourtsideRalliesView({super.key});

  @override
  State<CourtsideRalliesView> createState() => _CourtsideRalliesViewState();
}

class _CourtsideRalliesViewState extends State<CourtsideRalliesView> {
  List<CourtsideRallyThread> _conversations = List<CourtsideRallyThread>.of(
    CourtsideThreadSeed.openingRallyThreads,
  );
  List<CourtlySystemMessage> _systemMessages = const [];
  List<CourtlyPlayerCard> _mutualFriends = const [];
  Set<String> _blockedPlayerHandles = {};
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
      child: _CourtsideRallyBackdrop(
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
                child: _CourtsideRalliesTopBar(
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
                          rallyLine:
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
                      title: 'No rally notes yet',
                      rallyLine:
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

  List<CourtsideRallyThread> get _visibleConversations {
    return _conversations
        .where(
          (conversation) =>
              !_blockedPlayerHandles.contains(conversation.playerHandle) &&
              !_reportedContentIds.contains(
                'chat:${conversation.playerHandle}',
              ),
        )
        .toList(growable: false);
  }

  List<CourtlySystemMessage> get _visibleSystemMessages {
    return _systemMessages
        .where((rallyNote) {
          final playerHandle = rallyNote.playerHandle;
          final targetId = rallyNote.targetId;
          if (playerHandle != null &&
              _blockedPlayerHandles.contains(playerHandle) &&
              rallyNote.kind != 'block') {
            return false;
          }
          if (targetId != null && _reportedContentIds.contains(targetId)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  Widget _buildSystemMessageRow(CourtlySystemMessage rallyNote) {
    final opensProfile =
        rallyNote.playerHandle != null &&
        rallyNote.kind != 'report' &&
        rallyNote.kind != 'block';

    return Dismissible(
      key: ValueKey('system-${rallyNote.id}'),
      direction: DismissDirection.endToStart,
      background: const _DeleteSwipeBackground(),
      onDismissed: (_) => unawaited(_deleteSystemMessage(rallyNote.id)),
      child: _SystemMessageTile(
        rallyNote: rallyNote,
        onPressed: opensProfile
            ? () => _openProfile(
                CourtlyRosterBook.byHandle(rallyNote.playerHandle!),
              )
            : null,
      ),
    );
  }

  Widget _buildConversationRow(CourtsideRallyThread conversation) {
    return Dismissible(
      key: ValueKey('conversation-${conversation.threadId}'),
      direction: DismissDirection.endToStart,
      background: const _DeleteSwipeBackground(),
      onDismissed: (_) => unawaited(_deleteConversation(conversation.threadId)),
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
    final blocked = await store.blockedPlayerHandles();
    final reported = await store.reportedContentIds();
    final systemMessages = await store.loadSystemMessages();
    final mutualIds = await store.mutualFollowPlayerHandles();
    final messagePlayerHandles = await store.messagePlayerHandles();
    final conversations = <CourtsideRallyThread>[];

    for (final playerHandle in messagePlayerHandles) {
      if (blocked.contains(playerHandle)) {
        continue;
      }
      final rallyNotes = await store.loadMessages(playerHandle);
      if (rallyNotes.isEmpty) {
        continue;
      }
      final profile = CourtlyRosterBook.byHandle(playerHandle);
      conversations.add(
        CourtsideRallyThread(
          threadId: 'chat-$playerHandle',
          playerHandle: playerHandle,
          courtsideName: profile.courtsideName,
          ageBandLabel: profile.ageBandLabel,
          playerPortraitAsset: profile.playerPortraitAsset,
          courtCardAsset: profile.courtCardAsset,
          isCourtsideNow: false,
          unreadRallyNotes: 0,
          lastExchangeLabel: rallyNotes.last.sentAtLabel,
          rallyNotes: rallyNotes
              .map(_messageFromStored)
              .toList(growable: false),
        ),
      );
    }
    conversations.sort((left, right) {
      return right.lastExchangeLabel.compareTo(left.lastExchangeLabel);
    });

    if (!mounted) {
      return;
    }
    setState(() {
      _blockedPlayerHandles = blocked;
      _reportedContentIds = reported;
      _systemMessages = systemMessages;
      _mutualFriends = mutualIds
          .where((playerHandle) => !blocked.contains(playerHandle))
          .map(CourtlyRosterBook.byHandle)
          .toList(growable: false);
      _conversations = conversations;
    });
  }

  void _handleStoreChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_loadLocalState());
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

  void _openProfile(CourtlyPlayerCard profile) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => CourtlyPlayerCardPage(
          profile: profile,
          videos: _clubProfileVideosFor(profile.playerHandle),
          moments: _clubProfileMomentsFor(profile.playerHandle),
          onOpenChat: (profile) {
            unawaited(openCourtsideRallyForCard(context, profile));
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

  Future<void> _openChatForProfile(CourtlyPlayerCard profile) async {
    await openCourtsideRallyForCard(context, profile);
    if (mounted) {
      await _loadLocalState();
    }
  }

  Future<void> _openChat(CourtsideRallyThread conversation) async {
    final updated = await Navigator.of(context).push<CourtsideRallyThread>(
      CupertinoPageRoute<CourtsideRallyThread>(
        builder: (_) => CourtsideRallyThreadPage(conversation: conversation),
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    await _loadLocalState();
    if (!mounted) {
      return;
    }

    final index = _conversations.indexWhere(
      (entry) => entry.threadId == updated.threadId,
    );
    if (index == -1) {
      return;
    }

    setState(() {
      final next = List<CourtsideRallyThread>.of(_conversations);
      next[index] = updated;
      _conversations = next;
    });
  }

  void _openConversationProfile(CourtsideRallyThread conversation) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => CourtlyPlayerCardPage(
          profile: CourtlyRosterBook.fromCourtsideIdentity(
            playerHandle: conversation.playerHandle,
            courtsideName: conversation.courtsideName,
            playerPortraitAsset: conversation.playerPortraitAsset,
            courtCardAsset: conversation.courtCardAsset,
          ),
          videos: _clubProfileVideosFor(conversation.playerHandle),
          moments: _clubProfileMomentsFor(conversation.playerHandle),
          onOpenChat: (profile) {
            unawaited(openCourtsideRallyForCard(context, profile));
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

  Future<void> _askDeleteConversation(CourtsideRallyThread conversation) async {
    final confirmed = await _confirmDeleteConversation(conversation);
    if (!confirmed || !mounted) {
      return;
    }

    await _deleteConversation(conversation.threadId);
  }

  Future<bool> _confirmDeleteConversation(
    CourtsideRallyThread conversation,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Delete ${conversation.courtsideName}?'),
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
      (entry) => entry.threadId == conversationId,
    );
    if (conversationIndex == -1) {
      return;
    }
    final conversation = _conversations[conversationIndex];
    setState(() {
      _conversations = _conversations
          .where((conversation) => conversation.threadId != conversationId)
          .toList();
    });
    await CourtlySocialStore.instance.deleteMessages(conversation.playerHandle);
  }

  Future<void> _deleteSystemMessage(String messageId) async {
    setState(() {
      _systemMessages = _systemMessages
          .where((rallyNote) => rallyNote.id != messageId)
          .toList(growable: false);
    });
    await CourtlySocialStore.instance.deleteSystemMessage(messageId);
  }

  Future<void> _clearAllMessages() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Clear all rally notes?'),
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

class _CourtsideRallyBackdrop extends StatelessWidget {
  const _CourtsideRallyBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/courtly_swing.png',
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

class _CourtsideRalliesTopBar extends StatelessWidget {
  const _CourtsideRalliesTopBar({
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
          'assets/images/courtly_approach.png',
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

class _MutualFriendCard extends StatelessWidget {
  const _MutualFriendCard({
    required this.profile,
    required this.onPressed,
    required this.onMessage,
  });

  final CourtlyPlayerCard profile;
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
            _ClubAvatar(assetPath: profile.playerPortraitAsset, size: 54),
            const SizedBox(height: 8),
            Text(
              profile.courtsideName,
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
  const _SystemMessageTile({required this.rallyNote, this.onPressed});

  final CourtlySystemMessage rallyNote;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final profile = rallyNote.playerHandle == null
        ? null
        : CourtlyRosterBook.byHandle(rallyNote.playerHandle!);

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
            _SystemMessageIcon(rallyNote: rallyNote, profile: profile),
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
                          rallyNote.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _clubTextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SystemKindPill(kind: rallyNote.kind),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    rallyNote.body,
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
                  rallyNote.timeLabel,
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
  const _SystemMessageIcon({required this.rallyNote, required this.profile});

  final CourtlySystemMessage rallyNote;
  final CourtlyPlayerCard? profile;

  @override
  Widget build(BuildContext context) {
    final profile = this.profile;
    if (profile != null &&
        rallyNote.kind != 'report' &&
        rallyNote.kind != 'block') {
      return _ClubAvatar(assetPath: profile.playerPortraitAsset, size: 52);
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _chatWhite.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: _chatWhite.withValues(alpha: 0.14)),
      ),
      child: Icon(_systemIcon(rallyNote.kind), color: _chatPinkSoft, size: 23),
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

  final CourtsideRallyThread conversation;
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
                      assetPath: conversation.playerPortraitAsset,
                      size: 54,
                      showGlow: conversation.isCourtsideNow,
                    ),
                  ),
                  if (conversation.isCourtsideNow)
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
                                conversation.courtsideName,
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
                        _AgePill(ageBandLabel: conversation.ageBandLabel),
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
                    conversation.lastExchangeLabel,
                    style: _clubTextStyle(
                      color: _chatWhite.withValues(alpha: 0.35),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  if (conversation.unreadRallyNotes > 0)
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: _chatPink,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          conversation.unreadRallyNotes.toString(),
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

class CourtsideRallyThreadPage extends StatefulWidget {
  const CourtsideRallyThreadPage({required this.conversation, super.key});

  final CourtsideRallyThread conversation;

  @override
  State<CourtsideRallyThreadPage> createState() =>
      _CourtsideRallyThreadPageState();
}

class _CourtsideRallyThreadPageState extends State<CourtsideRallyThreadPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late CourtsideRallyThread _conversation;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation.copyWith(unreadRallyNotes: 0);
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
      child: _CourtsideRallyBackdrop(
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
                  itemCount: _conversation.rallyNotes.length,
                  itemBuilder: (context, index) {
                    return _MessageBubble(
                      rallyNote: _conversation.rallyNotes[index],
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
    final rallyLine = _messageController.text.trim();
    if (rallyLine.isEmpty) {
      return;
    }
    if (!await _ensureMutualAccess('Messages require mutual follow')) {
      return;
    }
    if (!mounted) {
      return;
    }

    final safety = CourtlyContentSafety.validateText(
      rallyLine,
      surface: CourtlyContentSurface.chatMessage,
    );
    if (!safety.allowed) {
      await showCourtlyContentSafetyNotice(context: context, result: safety);
      return;
    }

    final rallyNote = CourtsideRallyNote(
      noteId: 'local-${DateTime.now().microsecondsSinceEpoch}',
      speakerName: 'You',
      rallyLine: rallyLine,
      sentAtLabel: _formatNow(),
      isFromCurrentPlayer: true,
    );

    setState(() {
      _conversation = _conversation.copyWith(
        rallyNotes: [..._conversation.rallyNotes, rallyNote],
        unreadRallyNotes: 0,
        lastExchangeLabel: rallyNote.sentAtLabel,
      );
    });
    await CourtlySocialStore.instance.saveMessages(
      playerHandle: _conversation.playerHandle,
      messages: _conversation.rallyNotes.map(_messageToStored).toList(),
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

    await Navigator.of(context).push<CourtsideCallSessionResult>(
      CupertinoPageRoute<CourtsideCallSessionResult>(
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
      _conversation.playerHandle,
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
    final profile = CourtlyRosterBook.fromCourtsideIdentity(
      playerHandle: _conversation.playerHandle,
      courtsideName: _conversation.courtsideName,
      playerPortraitAsset: _conversation.playerPortraitAsset,
      courtCardAsset: _conversation.courtCardAsset,
    );
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => CourtlyPlayerCardPage(
          profile: profile,
          videos: _clubProfileVideosFor(profile.playerHandle),
          moments: _clubProfileMomentsFor(profile.playerHandle),
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
      targetId: 'chat:${_conversation.playerHandle}',
      targetType: 'chat',
      title: _conversation.courtsideName,
      playerHandle: _conversation.playerHandle,
      summary: _conversation.preview,
      playerPortraitAsset: _conversation.playerPortraitAsset,
    );
    if (result == null || !mounted) {
      return;
    }

    if (result.action == CourtlyModerationAction.block) {
      await showCourtlyActionSuccess(
        context: context,
        title: 'Player blocked',
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

  final CourtsideRallyThread conversation;
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
                  conversation.courtsideName,
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

  final CourtsideRallyThread conversation;
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
              assetPath: conversation.playerPortraitAsset,
              size: 86,
              showGlow: conversation.isCourtsideNow,
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
  const _MessageBubble({required this.rallyNote});

  final CourtsideRallyNote rallyNote;

  @override
  Widget build(BuildContext context) {
    final isFromCurrentPlayer = rallyNote.isFromCurrentPlayer;

    return Align(
      alignment: isFromCurrentPlayer
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: isFromCurrentPlayer ? _chatPink : _chatWhite,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isFromCurrentPlayer ? 14 : 4),
              bottomRight: Radius.circular(isFromCurrentPlayer ? 4 : 14),
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
            rallyNote.rallyLine,
            style: _clubTextStyle(
              color: isFromCurrentPlayer ? _chatWhite : const Color(0xFF4B4158),
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
                placeholder: 'Send a courtside note',
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

  final CourtsideRallyThread conversation;
  final CameraController cameraController;

  @override
  State<ClubVideoCallPage> createState() => _ClubVideoCallPageState();
}

class _ClubVideoCallPageState extends State<ClubVideoCallPage> {
  bool _speakerOn = true;
  bool _muted = false;
  bool _cameraOn = true;
  late final CameraController _cameraController = widget.cameraController;

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
            conversation.courtCardAsset,
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
              courtsideName: conversation.courtsideName,
              onBack: () => Navigator.of(
                context,
              ).pop(const CourtsideCallSessionResult(started: false)),
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
              ).pop(const CourtsideCallSessionResult(started: true)),
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
    } catch (_) {}
  }
}

class _VideoCallHeader extends StatelessWidget {
  const _VideoCallHeader({required this.courtsideName, required this.onBack});

  final String courtsideName;
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
                  courtsideName,
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

  final CourtsideRallyThread conversation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ClubAvatar(
          assetPath: conversation.playerPortraitAsset,
          size: 104,
          showGlow: true,
        ),
        const SizedBox(height: 18),
        Text(
          'Calling ${conversation.courtsideName.split(' ').first}',
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

class ClubMutualFriendsPage extends StatelessWidget {
  const ClubMutualFriendsPage({required this.profiles, super.key});

  final List<CourtlyPlayerCard> profiles;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _CourtsideRallyBackdrop(
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
                          rallyLine:
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
                              builder: (_) => CourtlyPlayerCardPage(
                                profile: profile,
                                videos: _clubProfileVideosFor(
                                  profile.playerHandle,
                                ),
                                moments: _clubProfileMomentsFor(
                                  profile.playerHandle,
                                ),
                                onOpenChat: (profile) {
                                  unawaited(
                                    openCourtsideRallyForCard(context, profile),
                                  );
                                },
                              ),
                            ),
                          ),
                          onOpenChat: () => unawaited(
                            openCourtsideRallyForCard(context, profile),
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

  final CourtlyPlayerCard profile;
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
            child: _ClubAvatar(
              assetPath: profile.playerPortraitAsset,
              size: 54,
            ),
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
                    profile.courtsideName,
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

  final CourtsideCircleInvitation request;
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
          _ClubAvatar(assetPath: request.playerPortraitAsset, size: 52),
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
                        request.courtsideName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _clubTextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    _AgePill(ageBandLabel: request.ageBandLabel),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  request.courtMotto,
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
          _FollowButton(followed: request.isInCourtCircle, onPressed: onFollow),
        ],
      ),
    );
  }
}

class CourtsideInvitationProfilePage extends StatelessWidget {
  const CourtsideInvitationProfilePage({
    required this.request,
    required this.onFollowChanged,
    super.key,
  });

  final CourtsideCircleInvitation request;
  final VoidCallback onFollowChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _CourtsideRallyBackdrop(
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
              _ClubAvatar(assetPath: request.playerPortraitAsset, size: 112),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    request.courtsideName,
                    style: _clubTextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AgePill(ageBandLabel: request.ageBandLabel),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                request.courtMotto,
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
                followed: request.isInCourtCircle,
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
  const _AgePill({required this.ageBandLabel, this.compact = false});

  final String ageBandLabel;
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
          ageBandLabel,
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
          'assets/images/courtly_alley.png',
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
        'assets/images/courtly_love.png',
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
        'assets/images/courtly_love.png',
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
    required this.rallyLine,
  });

  final IconData icon;
  final String title;
  final String rallyLine;

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
                  rallyLine,
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
