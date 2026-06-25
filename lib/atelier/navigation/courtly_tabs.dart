import 'dart:async';

import 'package:courtly/features/club_chats/presentation/club_chats_view.dart';
import 'package:courtly/features/court_reels/presentation/court_reels_home_view.dart';
import 'package:courtly/features/my_court/presentation/my_court_view.dart';
import 'package:courtly/features/post_sharing/presentation/post_sharing_home_view.dart';
import 'package:courtly/shared/wallet/courtly_wallet_store.dart';
import 'package:flutter/cupertino.dart';

class CourtlyTabs extends StatefulWidget {
  const CourtlyTabs({super.key});

  @override
  State<CourtlyTabs> createState() => _CourtlyTabsState();
}

class _CourtlyTabsState extends State<CourtlyTabs> {
  int _selectedIndex = 0;

  static const List<Widget> _courtDecks = [
    CourtReelsHomeView(),
    PostSharingHomeView(),
    ClubChatsView(),
    MyCourtView(),
  ];

  static const List<_CourtlyTabSpec> _tabSpecs = [
    _CourtlyTabSpec(
      activeAsset: 'assets/images/Practice.png',
      inactiveAsset: 'assets/images/Doubles.png',
      label: 'Practice',
    ),
    _CourtlyTabSpec(
      activeAsset: 'assets/images/Session.png',
      inactiveAsset: 'assets/images/Partner.png',
      label: 'Session',
    ),
    _CourtlyTabSpec(
      activeAsset: 'assets/images/Rival.png',
      inactiveAsset: 'assets/images/Teammate.png',
      label: 'Chats',
    ),
    _CourtlyTabSpec(
      activeAsset: 'assets/images/Warmup.png',
      inactiveAsset: 'assets/images/Clubhouse.png',
      label: 'My Court',
    ),
  ];

  @override
  void initState() {
    super.initState();
    CourtlyWalletStore.instance.startPurchaseListener();
    unawaited(_showWelcomeGrantIfNeeded());
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                for (var index = 0; index < _courtDecks.length; index++)
                  HeroMode(
                    enabled: index == _selectedIndex,
                    child: _courtDecks[index],
                  ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: _CourtlyBottomDock(
                selectedIndex: _selectedIndex,
                specs: _tabSpecs,
                onChanged: (index) => setState(() => _selectedIndex = index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showWelcomeGrantIfNeeded() async {
    final grant = await CourtlyWalletStore.instance.claimWelcomeGiftIfNeeded();
    if (grant == null || !mounted) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) {
      return;
    }

    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _CourtlyWelcomeGrantDialog(grant: grant),
    );
  }
}

class _CourtlyWelcomeGrantDialog extends StatelessWidget {
  const _CourtlyWelcomeGrantDialog({required this.grant});

  final CourtlyWelcomeGrant grant;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.88, end: 1),
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Opacity(opacity: scale.clamp(0.0, 1.0), child: child),
          );
        },
        child: Container(
          width: MediaQuery.sizeOf(context).width.clamp(0.0, 390.0) - 46,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF120034).withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFFC934).withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF2DD2).withValues(alpha: 0.28),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 8,
                child: Container(
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF2DD2).withValues(alpha: 0.34),
                        const Color(0xFFFFC934).withValues(alpha: 0.12),
                        const Color(0xFF120034).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Neon Serve Grant',
                    style: _welcomeText(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Image.asset(
                    'assets/images/Clinic.png',
                    width: 116,
                    height: 116,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+${_formatCoins(grant.coins)}',
                    style: _welcomeText(
                      color: const Color(0xFFFFC934),
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'opening coins',
                    style: _welcomeText(
                      color: CupertinoColors.white.withValues(alpha: 0.68),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: CupertinoColors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      'Balance ${_formatCoins(grant.balance)} coins',
                      textAlign: TextAlign.center,
                      style: _welcomeText(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 42,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2DD2),
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: Center(
                        child: Text(
                          'Enter the court',
                          style: _welcomeText(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
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

class _CourtlyBottomDock extends StatelessWidget {
  const _CourtlyBottomDock({
    required this.selectedIndex,
    required this.specs,
    required this.onChanged,
  });

  final int selectedIndex;
  final List<_CourtlyTabSpec> specs;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final dockWidth = MediaQuery.sizeOf(
      context,
    ).width.clamp(0.0, 390.0).toDouble();

    return Container(
      width: dockWidth,
      height: 83,
      decoration: const BoxDecoration(
        color: Color(0xFF1A004D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var index = 0; index < specs.length; index++)
            _CourtlyTabButton(
              spec: specs[index],
              isSelected: index == selectedIndex,
              onPressed: () => onChanged(index),
            ),
        ],
      ),
    );
  }
}

class _CourtlyTabButton extends StatelessWidget {
  const _CourtlyTabButton({
    required this.spec,
    required this.isSelected,
    required this.onPressed,
  });

  final _CourtlyTabSpec spec;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 28,
      child: CupertinoButton(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Image.asset(
          isSelected ? spec.activeAsset : spec.inactiveAsset,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
          semanticLabel: spec.label,
        ),
      ),
    );
  }
}

class _CourtlyTabSpec {
  const _CourtlyTabSpec({
    required this.activeAsset,
    required this.inactiveAsset,
    required this.label,
  });

  final String activeAsset;
  final String inactiveAsset;
  final String label;
}

TextStyle _welcomeText({
  Color color = CupertinoColors.white,
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w700,
}) {
  return TextStyle(
    color: color,
    fontSize: fontSize,
    height: 1,
    fontWeight: fontWeight,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );
}

String _formatCoins(int coins) {
  final text = coins.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    final remaining = text.length - index;
    buffer.write(text[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
