import 'package:courtly/features/club_chats/presentation/club_chats_view.dart';
import 'package:courtly/features/court_reels/presentation/court_reels_home_view.dart';
import 'package:courtly/features/my_court/presentation/my_court_view.dart';
import 'package:courtly/features/post_sharing/presentation/post_sharing_home_view.dart';
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
