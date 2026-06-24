import 'package:courtly/features/guest_courtesies/presentation/guest_courtesy_view.dart';
import 'package:courtly/features/reception_docket/presentation/reception_dashboard_view.dart';
import 'package:courtly/features/wardrobe_notes/presentation/wardrobe_brief_view.dart';
import 'package:flutter/cupertino.dart';

class CourtlyTabs extends StatelessWidget {
  const CourtlyTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.calendar),
            activeIcon: Icon(CupertinoIcons.calendar_badge_plus),
            label: 'Docket',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_2),
            activeIcon: Icon(CupertinoIcons.person_2_fill),
            label: 'Guests',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.tag),
            activeIcon: Icon(CupertinoIcons.tag_fill),
            label: 'Wardrobe',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return switch (index) {
              0 => const ReceptionDashboardView(),
              1 => const GuestCourtesyView(),
              _ => const WardrobeBriefView(),
            };
          },
        );
      },
    );
  }
}
