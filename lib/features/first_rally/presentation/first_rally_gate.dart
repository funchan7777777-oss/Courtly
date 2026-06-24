import 'dart:async';

import 'package:courtly/features/first_rally/presentation/pages/rally_welcome_choice_page.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_backdrop_layer.dart';
import 'package:flutter/cupertino.dart';

class FirstRallyGate extends StatefulWidget {
  const FirstRallyGate({super.key});

  @override
  State<FirstRallyGate> createState() => _FirstRallyGateState();
}

class _FirstRallyGateState extends State<FirstRallyGate> {
  Timer? _handoffClock;

  @override
  void initState() {
    super.initState();
    _handoffClock = Timer(const Duration(milliseconds: 1300), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute<void>(
          builder: (_) => const RallyWelcomeChoicePage(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _handoffClock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: RallyBackdropLayer(
        backdropPath: RallyBackdrop.surfaceSplash,
      ),
    );
  }
}
