import 'package:courtly/features/first_rally/data/rally_asset_ledger.dart';
import 'package:courtly/features/first_rally/presentation/pages/rally_profile_detail_page.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_asset_button.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_back_button.dart';
import 'package:courtly/features/first_rally/presentation/widgets/rally_backdrop_layer.dart';
import 'package:flutter/cupertino.dart';

class RallyProfileMediaPage extends StatefulWidget {
  const RallyProfileMediaPage({super.key});

  @override
  State<RallyProfileMediaPage> createState() => _RallyProfileMediaPageState();
}

class _RallyProfileMediaPageState extends State<RallyProfileMediaPage> {
  String _selectedCourtStyle = 'baseline';
  final DateTime _birthdateMarker = DateTime(2026, 8, 23);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: RallyBackdropLayer(
        backdropPath: RallyBackdrop.profileForm,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const RallyBackButton(),
            Align(
              alignment: const Alignment(0, 0.18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _AvatarInvitationCard(onPressed: () {})),
                    const SizedBox(height: 28),
                    const _ProfilePromptText('Choose your court style'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _CourtStyleCard(
                            label: 'Baseline',
                            symbol: CupertinoIcons.bolt_fill,
                            isSelected: _selectedCourtStyle == 'baseline',
                            onPressed: () {
                              setState(() => _selectedCourtStyle = 'baseline');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _CourtStyleCard(
                            label: 'Net play',
                            symbol: CupertinoIcons.scope,
                            isSelected: _selectedCourtStyle == 'net_play',
                            onPressed: () {
                              setState(() => _selectedCourtStyle = 'net_play');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _ProfilePromptText('Add your birthday marker'),
                    const SizedBox(height: 10),
                    _BirthdateRibbon(dateMarker: _birthdateMarker),
                    const SizedBox(height: 28),
                    Center(
                      child: RallyAssetButton(
                        assetPath: RallyAssetLedger.continueSetupButton,
                        semanticLabel: 'Next',
                        onPressed: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute<void>(
                              builder: (_) => RallyProfileDetailPage(
                                courtStyleKey: _selectedCourtStyle,
                                birthdateMarker: _birthdateMarker,
                              ),
                            ),
                          );
                        },
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

class _AvatarInvitationCard extends StatelessWidget {
  const _AvatarInvitationCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 150,
        height: 138,
        decoration: BoxDecoration(
          color: const Color(0xFF6E3CA1).withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                CupertinoIcons.add,
                color: CupertinoColors.white.withValues(alpha: 0.36),
                size: 42,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7A8C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.xmark,
                  color: CupertinoColors.white,
                  size: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourtStyleCard extends StatelessWidget {
  const _CourtStyleCard({
    required this.label,
    required this.symbol,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final IconData symbol;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 104,
        decoration: BoxDecoration(
          color: const Color(0xFF6E3CA1).withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFB733)
                : CupertinoColors.white.withValues(alpha: 0.10),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              symbol,
              color: CupertinoColors.white.withValues(alpha: 0.86),
              size: 34,
            ),
            const SizedBox(height: 9),
            Text(
              label,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: CupertinoColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BirthdateRibbon extends StatelessWidget {
  const _BirthdateRibbon({required this.dateMarker});

  final DateTime dateMarker;

  @override
  Widget build(BuildContext context) {
    final value =
        '${dateMarker.year}  ${dateMarker.month.toString().padLeft(2, '0')}  ${dateMarker.day.toString().padLeft(2, '0')}';

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF6C42A0).withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: CupertinoColors.white.withValues(alpha: 0.70),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_right,
            color: CupertinoColors.white,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _ProfilePromptText extends StatelessWidget {
  const _ProfilePromptText(this.copy);

  final String copy;

  @override
  Widget build(BuildContext context) {
    return Text(
      copy,
      style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
        color: CupertinoColors.white.withValues(alpha: 0.72),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }
}
