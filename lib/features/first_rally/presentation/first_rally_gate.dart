import 'dart:async';

import 'package:courtly/atelier/navigation/courtly_tabs.dart';
import 'package:courtly/features/first_rally/data/rally_session_vault.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_onboarding_run_page.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_welcome_choice_page.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_backdrop_layer.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_loading_layers.dart';
import 'package:flutter/cupertino.dart';

class FirstRallyGate extends StatefulWidget {
  const FirstRallyGate({super.key});

  @override
  State<FirstRallyGate> createState() => _FirstRallyGateState();
}

class _FirstRallyGateState extends State<FirstRallyGate> {
  final RallySessionVault _sessionVault = const RallySessionVault();

  @override
  void initState() {
    super.initState();
    unawaited(_routeAfterOpeningLoad());
  }

  Future<void> _routeAfterOpeningLoad() async {
    final sessionRead = _sessionVault.readActiveSession();
    final onboardingRead = _sessionVault.hasFinishedOnboarding();

    await Future<void>.delayed(const Duration(milliseconds: 1450));
    final activeSession = await sessionRead;
    final onboardingSettled = await onboardingRead;

    if (!mounted) {
      return;
    }

    final Widget nextPage = activeSession != null
        ? const CourtlyTabs()
        : onboardingSettled
            ? const RallyWelcomeChoicePage()
            : const RallyOnboardingRunPage();

    Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(builder: (_) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: RallyBackdropLayer(
        backdropPath: RallyBackdrop.surfaceSplash,
        child: RallyOpeningLoad(),
      ),
    );
  }
}
