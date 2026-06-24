import 'package:courtly/features/first_rally/data/rally_session_vault.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_welcome_choice_page.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_backdrop_layer.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_glass_action_button.dart';
import 'package:flutter/cupertino.dart';

class RallyOnboardingRunPage extends StatefulWidget {
  const RallyOnboardingRunPage({super.key});

  @override
  State<RallyOnboardingRunPage> createState() => _RallyOnboardingRunPageState();
}

class _RallyOnboardingRunPageState extends State<RallyOnboardingRunPage> {
  final PageController _pageController = PageController();
  final RallySessionVault _sessionVault = const RallySessionVault();
  int _currentBoard = 0;

  static const List<_OnboardingBoard> _boards = [
    _OnboardingBoard(
      backdrop: RallyBackdrop.surfaceSplash,
      title: 'Find your court circle',
      detail:
          'Keep friendly rallies, match notes, and social plans in one polished place.',
    ),
    _OnboardingBoard(
      backdrop: RallyBackdrop.forehandChoice,
      title: 'Step in with context',
      detail:
          'Arrive with the right profile, greeting, and matchday signal already set.',
    ),
    _OnboardingBoard(
      backdrop: RallyBackdrop.profileForm,
      title: 'Make your court card yours',
      detail:
          'Choose a name, photo, and signature that fit the way you show up.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastBoard = _currentBoard == _boards.length - 1;

    return CupertinoPageScaffold(
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _boards.length,
            onPageChanged: (index) => setState(() => _currentBoard = index),
            itemBuilder: (context, index) {
              final board = _boards[index];
              return RallyBackdropLayer(
                backdropPath: board.backdrop,
                child: Align(
                  alignment: const Alignment(0, 0.62),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF210A44).withValues(alpha: 0.48),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: CupertinoColors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              board.title,
                              textAlign: TextAlign.center,
                              style: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .copyWith(
                                    color: CupertinoColors.white,
                                    fontSize: 22,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                    decoration: TextDecoration.none,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              board.detail,
                              textAlign: TextAlign.center,
                              style: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .copyWith(
                                    color: CupertinoColors.white.withValues(
                                      alpha: 0.78,
                                    ),
                                    fontSize: 13,
                                    height: 1.42,
                                    fontWeight: FontWeight.w600,
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
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 52,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_boards.length, (index) {
                    final isActive = index == _currentBoard;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: isActive ? 22 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFFFB733)
                            : CupertinoColors.white.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 22),
                RallyGlassActionButton(
                  label: isLastBoard ? 'Enter Courtly' : 'Next',
                  onPressed: isLastBoard ? _finishOnboarding : _goNext,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finishOnboarding() async {
    await _sessionVault.markOnboardingSettled();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(builder: (_) => const RallyWelcomeChoicePage()),
    );
  }
}

class _OnboardingBoard {
  const _OnboardingBoard({
    required this.backdrop,
    required this.title,
    required this.detail,
  });

  final RallyBackdrop backdrop;
  final String title;
  final String detail;
}
