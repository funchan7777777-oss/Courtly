import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

class RallyOpeningLoad extends StatefulWidget {
  const RallyOpeningLoad({super.key});

  @override
  State<RallyOpeningLoad> createState() => _RallyOpeningLoadState();
}

class _RallyOpeningLoadState extends State<RallyOpeningLoad>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * math.pi * 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFB733).withValues(alpha: 0.82),
                  width: 2,
                ),
              ),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFFFFF0AC),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 8, height: 8),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RallyEntryLoadingCurtain extends StatefulWidget {
  const RallyEntryLoadingCurtain({
    required this.label,
    super.key,
  });

  final String label;

  @override
  State<RallyEntryLoadingCurtain> createState() =>
      _RallyEntryLoadingCurtainState();
}

class _RallyEntryLoadingCurtainState extends State<RallyEntryLoadingCurtain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF13022D).withValues(alpha: 0.72),
        ),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF321066).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: CupertinoColors.white.withValues(alpha: 0.12),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 28,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          final phase =
                              ((_controller.value + index * 0.22) % 1.0);
                          return Container(
                            width: 12,
                            height: 12 + phase * 10,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: index == 1
                                  ? const Color(0xFFFFB733)
                                  : const Color(0xFFB154FF),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.label,
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                          color: CupertinoColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                          decoration: TextDecoration.none,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
