import 'package:courtly/atelier/theme/courtly_cupertino_theme.dart';
import 'package:courtly/features/first_rally/presentation/first_rally_gate.dart';
import 'package:flutter/cupertino.dart';

class CourtlyApp extends StatelessWidget {
  const CourtlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Courtly',
      debugShowCheckedModeBanner: false,
      theme: CourtlyCupertinoTheme.daybook,
      home: const FirstRallyGate(),
    );
  }
}
