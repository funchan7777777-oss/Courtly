import 'dart:async';
import 'dart:convert';

import 'package:courtly/atelier/theme/courtly_font_families.dart';
import 'package:courtly/shared/presentation/courtly_safe_layout.dart';
import 'package:courtly/shared/wallet/courtly_coin_gate.dart';
import 'package:courtly/shared/wallet/courtly_wallet_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _kitPurple = Color(0xFF1A004D);
const Color _kitPurpleDeep = Color(0xFF10002D);
const Color _kitPanel = Color(0xFF26005F);
const Color _kitPink = Color(0xFFFF2DD2);
const Color _kitGold = Color(0xFFFFC934);
const Color _kitWhite = Color(0xFFFFFFFF);

class CourtKitView extends StatefulWidget {
  const CourtKitView({super.key});

  @override
  State<CourtKitView> createState() => _CourtKitViewState();
}

class _CourtKitViewState extends State<CourtKitView> {
  static const String _savedCardsKey = 'courtly_court_kit_saved_cards';

  _KitFocus _focus = _KitFocus.serve;
  _KitLength _length = _KitLength.sixty;
  _KitSurface _surface = _KitSurface.hard;
  _KitPartner _partner = _KitPartner.mutual;
  _CourtKitCard? _activeCard;
  List<_CourtKitCard> _savedCards = const [];
  bool _isBuilding = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSavedCards());
  }

  @override
  Widget build(BuildContext context) {
    final rule = CourtlyWalletStore.spendRuleFor(
      CourtlyCoinFeature.courtKitPrep,
    );

    return CupertinoPageScaffold(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/courtly_courtside.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _kitPurpleDeep.withValues(alpha: 0.18),
                  _kitPurple.withValues(alpha: 0.78),
                  _kitPurpleDeep.withValues(alpha: 0.98),
                ],
                stops: const [0, 0.42, 1],
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    courtlySafeTop(context, 14),
                    22,
                    0,
                  ),
                  child: _KitHeader(rule: rule, savedCount: _savedCards.length),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                  child: _KitBuilderPanel(
                    focus: _focus,
                    length: _length,
                    surface: _surface,
                    partner: _partner,
                    rule: rule,
                    isBuilding: _isBuilding,
                    onFocusChanged: (value) => setState(() => _focus = value),
                    onLengthChanged: (value) => setState(() => _length = value),
                    onSurfaceChanged: (value) =>
                        setState(() => _surface = value),
                    onPartnerChanged: (value) =>
                        setState(() => _partner = value),
                    onBuild: () => unawaited(_buildPrepCard()),
                  ),
                ),
              ),
              if (_activeCard != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                    child: _PrepCardPanel(
                      card: _activeCard!,
                      onApplySetup: () => _applyCardSetup(_activeCard!),
                      onDelete: () => unawaited(_deleteSavedCard(_activeCard!)),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 126),
                  child: _SavedCardsPanel(
                    cards: _savedCards,
                    onOpen: (card) => setState(() => _activeCard = card),
                    onDelete: (card) => unawaited(_deleteSavedCard(card)),
                    onClear: _savedCards.isEmpty
                        ? null
                        : () => unawaited(_askClearSavedCards()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadSavedCards() async {
    final preferences = await SharedPreferences.getInstance();
    final rawCards = preferences.getStringList(_savedCardsKey) ?? const [];
    final cards = rawCards
        .map(_CourtKitCard.tryDecode)
        .whereType<_CourtKitCard>()
        .toList(growable: false);
    if (!mounted) {
      return;
    }

    setState(() {
      _savedCards = cards;
      _activeCard = cards.isEmpty ? null : cards.first;
    });
  }

  Future<void> _buildPrepCard() async {
    if (_isBuilding) {
      return;
    }

    final paid = await showCourtlyCoinSpendGate(
      context: context,
      feature: CourtlyCoinFeature.courtKitPrep,
    );
    if (!paid || !mounted) {
      return;
    }

    setState(() => _isBuilding = true);
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted) {
      return;
    }

    final card = _CourtKitCard.create(
      focus: _focus,
      length: _length,
      surface: _surface,
      partner: _partner,
      createdAt: DateTime.now(),
    );
    final nextCards = [
      card,
      ..._savedCards.where((entry) => entry.id != card.id),
    ].take(8).toList(growable: false);
    await _storeSavedCards(nextCards);
    if (!mounted) {
      return;
    }

    setState(() {
      _activeCard = card;
      _savedCards = nextCards;
      _isBuilding = false;
    });
  }

  Future<void> _deleteSavedCard(_CourtKitCard card) async {
    final nextCards = _savedCards
        .where((entry) => entry.id != card.id)
        .toList(growable: false);
    await _storeSavedCards(nextCards);
    if (!mounted) {
      return;
    }

    setState(() {
      _savedCards = nextCards;
      if (_activeCard?.id == card.id) {
        _activeCard = nextCards.isEmpty ? null : nextCards.first;
      }
    });
  }

  Future<void> _askClearSavedCards() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Clear saved plans?'),
          content: const Text(
            'This removes every Court Kit plan on this device.',
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
    if (confirmed == true && mounted) {
      await _clearSavedCards();
    }
  }

  Future<void> _clearSavedCards() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_savedCardsKey);
    if (!mounted) {
      return;
    }

    setState(() {
      _savedCards = const [];
      _activeCard = null;
    });
  }

  Future<void> _storeSavedCards(List<_CourtKitCard> cards) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _savedCardsKey,
      cards.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  void _applyCardSetup(_CourtKitCard card) {
    final focus = _KitFocus.fromKey(
      card.focusKey.isEmpty ? card.title : card.focusKey,
    );
    final length = _KitLength.fromKey(
      card.lengthKey.isEmpty ? card.title : card.lengthKey,
    );
    final surface = _KitSurface.fromKey(
      card.surfaceKey.isEmpty ? card.subtitle : card.surfaceKey,
    );
    final partner = _KitPartner.fromKey(
      card.partnerKey.isEmpty ? card.subtitle : card.partnerKey,
    );
    if (focus == null || length == null || surface == null || partner == null) {
      return;
    }

    setState(() {
      _focus = focus;
      _length = length;
      _surface = surface;
      _partner = partner;
    });
  }
}

class _KitHeader extends StatelessWidget {
  const _KitHeader({required this.rule, required this.savedCount});

  final CourtlyCoinSpendRule rule;
  final int savedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kitWhite.withValues(alpha: 0.18),
            _kitPanel.withValues(alpha: 0.52),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kitWhite.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: _kitPurpleDeep.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Court Kit',
                  style: _kitText(fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate a court-ready plan with warmup, drill pattern, etiquette, and gear notes.',
                  style: _kitText(
                    color: _kitWhite.withValues(alpha: 0.74),
                    fontSize: 12,
                    height: 1.32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _KitHeaderPill(
                      icon: CupertinoIcons.sparkles,
                      label: '${rule.cost} coins',
                    ),
                    _KitHeaderPill(
                      icon: CupertinoIcons.doc_text_fill,
                      label: '$savedCount saved',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          const _KitPlanBadge(),
        ],
      ),
    );
  }
}

class _KitPlanBadge extends StatelessWidget {
  const _KitPlanBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 96,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kitPurpleDeep.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kitWhite.withValues(alpha: 0.13)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _kitWhite.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _kitGold.withValues(alpha: 0.26)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 15,
                    child: _KitBadgeLine(widthFactor: 0.82),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 30,
                    child: _KitBadgeLine(widthFactor: 0.58),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 45,
                    child: _KitBadgeLine(widthFactor: 0.72),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Icon(
                      CupertinoIcons.sportscourt_fill,
                      color: _kitGold,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: _kitGold,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.check_mark,
                  color: _kitPurpleDeep,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  'Plan',
                  style: _kitText(
                    color: _kitPurpleDeep,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
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

class _KitBadgeLine extends StatelessWidget {
  const _KitBadgeLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: _kitWhite.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _KitHeaderPill extends StatelessWidget {
  const _KitHeaderPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _kitWhite.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _kitWhite.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _kitGold, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: _kitText(fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _KitBuilderPanel extends StatelessWidget {
  const _KitBuilderPanel({
    required this.focus,
    required this.length,
    required this.surface,
    required this.partner,
    required this.rule,
    required this.isBuilding,
    required this.onFocusChanged,
    required this.onLengthChanged,
    required this.onSurfaceChanged,
    required this.onPartnerChanged,
    required this.onBuild,
  });

  final _KitFocus focus;
  final _KitLength length;
  final _KitSurface surface;
  final _KitPartner partner;
  final CourtlyCoinSpendRule rule;
  final bool isBuilding;
  final ValueChanged<_KitFocus> onFocusChanged;
  final ValueChanged<_KitLength> onLengthChanged;
  final ValueChanged<_KitSurface> onSurfaceChanged;
  final ValueChanged<_KitPartner> onPartnerChanged;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    return _KitPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _kitGold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.slider_horizontal_3,
                  color: _kitGold,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan setup',
                      style: _kitText(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tune the session before spending coins.',
                      style: _kitText(
                        color: _kitWhite.withValues(alpha: 0.56),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _KitSelectionSummary(
            focus: focus,
            length: length,
            surface: surface,
            partner: partner,
          ),
          const SizedBox(height: 18),
          _OptionGroup<_KitFocus>(
            title: 'Focus',
            detail: 'The main skill theme for this plan',
            icon: CupertinoIcons.scope,
            selected: focus,
            options: [
              for (final value in _KitFocus.values)
                _KitOption(value: value, title: value.label),
            ],
            onSelected: onFocusChanged,
          ),
          const SizedBox(height: 18),
          _OptionGroup<_KitLength>(
            title: 'Session length',
            detail: 'Sets warmup depth and gear pacing',
            icon: CupertinoIcons.timer,
            selected: length,
            options: [
              for (final value in _KitLength.values)
                _KitOption(value: value, title: value.label),
            ],
            onSelected: onLengthChanged,
          ),
          const SizedBox(height: 18),
          _OptionGroup<_KitSurface>(
            title: 'Court context',
            detail: 'Adapts movement, targets, and equipment',
            icon: CupertinoIcons.sportscourt,
            selected: surface,
            options: [
              for (final value in _KitSurface.values)
                _KitOption(value: value, title: value.label),
            ],
            onSelected: onSurfaceChanged,
          ),
          const SizedBox(height: 18),
          _OptionGroup<_KitPartner>(
            title: 'Partner mode',
            detail: 'Adds etiquette notes for the session',
            icon: CupertinoIcons.person_2,
            selected: partner,
            options: [
              for (final value in _KitPartner.values)
                _KitOption(value: value, title: value.label),
            ],
            onSelected: onPartnerChanged,
          ),
          const SizedBox(height: 20),
          CupertinoButton(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            onPressed: isBuilding ? null : onBuild,
            child: Container(
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: isBuilding
                    ? null
                    : const LinearGradient(
                        colors: [_kitPink, _kitGold],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                color: isBuilding ? _kitWhite.withValues(alpha: 0.16) : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (!isBuilding)
                    BoxShadow(
                      color: _kitPink.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isBuilding
                          ? CupertinoIcons.hourglass
                          : CupertinoIcons.sparkles,
                      color: _kitWhite,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isBuilding
                            ? 'Building plan...'
                            : 'Generate court plan - ${rule.cost} coins',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _kitText(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Posting court moments and practice clips stays free. Coins only unlock optional planning tools.',
            textAlign: TextAlign.center,
            style: _kitText(
              color: _kitWhite.withValues(alpha: 0.58),
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _KitSelectionSummary extends StatelessWidget {
  const _KitSelectionSummary({
    required this.focus,
    required this.length,
    required this.surface,
    required this.partner,
  });

  final _KitFocus focus;
  final _KitLength length;
  final _KitSurface surface;
  final _KitPartner partner;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KitSummaryCell(
                icon: CupertinoIcons.scope,
                label: 'Focus',
                value: focus.label,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KitSummaryCell(
                icon: CupertinoIcons.timer_fill,
                label: 'Length',
                value: length.label,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _KitSummaryCell(
                icon: CupertinoIcons.sportscourt_fill,
                label: 'Court',
                value: surface.label,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KitSummaryCell(
                icon: CupertinoIcons.person_2_fill,
                label: 'Mode',
                value: partner.shortLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KitSummaryCell extends StatelessWidget {
  const _KitSummaryCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
      decoration: BoxDecoration(
        color: _kitWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kitWhite.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _kitGold, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _kitText(
                    color: _kitWhite.withValues(alpha: 0.48),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _kitText(fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrepCardPanel extends StatelessWidget {
  const _PrepCardPanel({
    required this.card,
    required this.onApplySetup,
    required this.onDelete,
  });

  final _CourtKitCard card;
  final VoidCallback onApplySetup;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _KitPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active plan',
                      style: _kitText(
                        color: _kitGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      card.title,
                      style: _kitText(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card.subtitle,
                      style: _kitText(
                        color: _kitWhite.withValues(alpha: 0.58),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _kitGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(
                  'assets/images/courtly_score.png',
                  width: 52,
                  height: 52,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PrepActionButton(
                  icon: CupertinoIcons.arrow_2_circlepath,
                  label: 'Use setup',
                  onPressed: onApplySetup,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PrepActionButton(
                  icon: CupertinoIcons.trash,
                  label: 'Delete',
                  onPressed: onDelete,
                  destructive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PrepCardRow(
            icon: CupertinoIcons.timer_fill,
            label: 'Warmup',
            value: card.warmup,
          ),
          _PrepCardRow(
            icon: CupertinoIcons.flag_fill,
            label: 'Pattern',
            value: card.pattern,
          ),
          _PrepCardRow(
            icon: CupertinoIcons.person_2_fill,
            label: 'Courtesy',
            value: card.courtesy,
          ),
          _PrepCardRow(
            icon: CupertinoIcons.bag_fill,
            label: 'Gear',
            value: card.gear,
          ),
        ],
      ),
    );
  }
}

class _PrepActionButton extends StatelessWidget {
  const _PrepActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? _kitPink : _kitGold;

    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: destructive ? 0.13 : 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _kitText(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedCardsPanel extends StatelessWidget {
  const _SavedCardsPanel({
    required this.cards,
    required this.onOpen,
    required this.onDelete,
    required this.onClear,
  });

  final List<_CourtKitCard> cards;
  final ValueChanged<_CourtKitCard> onOpen;
  final ValueChanged<_CourtKitCard> onDelete;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return _KitPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Saved plans',
                  style: _kitText(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              if (onClear != null)
                CupertinoButton(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  onPressed: onClear,
                  child: Text(
                    'Clear',
                    style: _kitText(
                      color: _kitGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (cards.isEmpty)
            Text(
              'No court plans yet. Generate one before a session and it will stay here.',
              style: _kitText(
                color: _kitWhite.withValues(alpha: 0.6),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            for (var index = 0; index < cards.length; index++) ...[
              _SavedCardTile(
                card: cards[index],
                onOpen: () => onOpen(cards[index]),
                onDelete: () => onDelete(cards[index]),
              ),
              if (index != cards.length - 1) const SizedBox(height: 9),
            ],
        ],
      ),
    );
  }
}

class _SavedCardTile extends StatelessWidget {
  const _SavedCardTile({
    required this.card,
    required this.onOpen,
    required this.onDelete,
  });

  final _CourtKitCard card;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: _kitWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kitWhite.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CupertinoButton(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            onPressed: onOpen,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _kitGold.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.doc_text_fill,
                color: _kitGold,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              onPressed: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _kitText(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${card.subtitle} • ${card.createdLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _kitText(
                      color: _kitWhite.withValues(alpha: 0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            onPressed: onDelete,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _kitPink.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.trash,
                color: _kitPink,
                size: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrepCardRow extends StatelessWidget {
  const _PrepCardRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _kitGold.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _kitGold, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: _kitText(
                    color: _kitGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: _kitText(
                    color: _kitWhite.withValues(alpha: 0.82),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
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

class _OptionGroup<T> extends StatelessWidget {
  const _OptionGroup({
    required this.title,
    required this.detail,
    required this.icon,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final String detail;
  final IconData icon;
  final T selected;
  final List<_KitOption<T>> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _kitWhite.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: _kitGold, size: 15),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _kitText(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: _kitText(
                      color: _kitWhite.withValues(alpha: 0.48),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              _OptionChip(
                title: option.title,
                selected: option.value == selected,
                onPressed: () => onSelected(option.value),
              ),
          ],
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.title,
    required this.selected,
    required this.onPressed,
  });

  final String title;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? _kitGold.withValues(alpha: 0.95)
              : _kitWhite.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _kitGold : _kitWhite.withValues(alpha: 0.09),
          ),
        ),
        child: Text(
          title,
          style: _kitText(
            color: selected ? _kitPurpleDeep : _kitWhite,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _KitPanel extends StatelessWidget {
  const _KitPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: _kitPanel.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kitWhite.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: _kitPurpleDeep.withValues(alpha: 0.36),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _KitOption<T> {
  const _KitOption({required this.value, required this.title});

  final T value;
  final String title;
}

class _CourtKitCard {
  const _CourtKitCard({
    required this.id,
    required this.focusKey,
    required this.lengthKey,
    required this.surfaceKey,
    required this.partnerKey,
    required this.title,
    required this.subtitle,
    required this.warmup,
    required this.pattern,
    required this.courtesy,
    required this.gear,
    required this.createdAt,
  });

  final String id;
  final String focusKey;
  final String lengthKey;
  final String surfaceKey;
  final String partnerKey;
  final String title;
  final String subtitle;
  final String warmup;
  final String pattern;
  final String courtesy;
  final String gear;
  final DateTime createdAt;

  String get createdLabel {
    final month = createdAt.month.toString().padLeft(2, '0');
    final day = createdAt.day.toString().padLeft(2, '0');
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$month/$day  $hour:$minute';
  }

  static _CourtKitCard create({
    required _KitFocus focus,
    required _KitLength length,
    required _KitSurface surface,
    required _KitPartner partner,
    required DateTime createdAt,
  }) {
    return _CourtKitCard(
      id: 'kit-${createdAt.microsecondsSinceEpoch}',
      focusKey: focus.name,
      lengthKey: length.name,
      surfaceKey: surface.name,
      partnerKey: partner.name,
      title: '${focus.label} / ${length.label}',
      subtitle: '${surface.label} court with ${partner.label.toLowerCase()}',
      warmup: _warmupFor(focus, length),
      pattern: _patternFor(focus, surface),
      courtesy: _courtesyFor(partner),
      gear: _gearFor(surface, length),
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'focusKey': focusKey,
      'lengthKey': lengthKey,
      'surfaceKey': surfaceKey,
      'partnerKey': partnerKey,
      'title': title,
      'subtitle': subtitle,
      'warmup': warmup,
      'pattern': pattern,
      'courtesy': courtesy,
      'gear': gear,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static _CourtKitCard? tryDecode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final json = decoded.cast<String, Object?>();
      return _CourtKitCard(
        id: json['id'] as String? ?? '',
        focusKey: json['focusKey'] as String? ?? '',
        lengthKey: json['lengthKey'] as String? ?? '',
        surfaceKey: json['surfaceKey'] as String? ?? '',
        partnerKey: json['partnerKey'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        warmup: json['warmup'] as String? ?? '',
        pattern: json['pattern'] as String? ?? '',
        courtesy: json['courtesy'] as String? ?? '',
        gear: json['gear'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

enum _KitFocus {
  serve('Serve'),
  footwork('Footwork'),
  netPlay('Net play'),
  calmPoints('Calm points');

  const _KitFocus(this.label);

  final String label;

  static _KitFocus? fromKey(String key) {
    final cue = key.toLowerCase();
    for (final value in _KitFocus.values) {
      if (value.name == key || cue.contains(value.label.toLowerCase())) {
        return value;
      }
    }
    return null;
  }
}

enum _KitLength {
  fortyFive('45 min'),
  sixty('60 min'),
  ninety('90 min');

  const _KitLength(this.label);

  final String label;

  static _KitLength? fromKey(String key) {
    final cue = key.toLowerCase();
    for (final value in _KitLength.values) {
      if (value.name == key || cue.contains(value.label.toLowerCase())) {
        return value;
      }
    }
    return null;
  }
}

enum _KitSurface {
  hard('Hard'),
  clay('Clay'),
  indoor('Indoor'),
  dusk('Dusk');

  const _KitSurface(this.label);

  final String label;

  static _KitSurface? fromKey(String key) {
    final cue = key.toLowerCase();
    for (final value in _KitSurface.values) {
      if (value.name == key || cue.contains(value.label.toLowerCase())) {
        return value;
      }
    }
    return null;
  }
}

enum _KitPartner {
  solo('Solo'),
  mutual('Mutual friend'),
  newPartner('New partner'),
  clubVisitor('Club visitor');

  const _KitPartner(this.label);

  final String label;

  String get shortLabel {
    return switch (this) {
      _KitPartner.solo => 'Solo',
      _KitPartner.mutual => 'Friend',
      _KitPartner.newPartner => 'New',
      _KitPartner.clubVisitor => 'Visitor',
    };
  }

  static _KitPartner? fromKey(String key) {
    final cue = key.toLowerCase();
    for (final value in _KitPartner.values) {
      if (value.name == key || cue.contains(value.label.toLowerCase())) {
        return value;
      }
    }
    return null;
  }
}

String _warmupFor(_KitFocus focus, _KitLength length) {
  final minutes = switch (length) {
    _KitLength.fortyFive => '8 minutes',
    _KitLength.sixty => '10 minutes',
    _KitLength.ninety => '14 minutes',
  };
  return switch (focus) {
    _KitFocus.serve =>
      '$minutes: shoulder circles, toss ladder, then five half-speed serves to each box.',
    _KitFocus.footwork =>
      '$minutes: split-step shadow swings, sideline shuffles, and recovery hops after each contact.',
    _KitFocus.netPlay =>
      '$minutes: mini-tennis, volley catches, and two-step closes from the service line.',
    _KitFocus.calmPoints =>
      '$minutes: easy cross-court rally, breath reset after misses, then three point-start routines.',
  };
}

String _patternFor(_KitFocus focus, _KitSurface surface) {
  final surfaceCue = switch (surface) {
    _KitSurface.hard => 'keep the first two balls deep through the middle',
    _KitSurface.clay => 'add height and use one extra recovery step',
    _KitSurface.indoor => 'shorten the backswing and protect the first strike',
    _KitSurface.dusk => 'call the ball early and keep targets larger',
  };
  return switch (focus) {
    _KitFocus.serve =>
      'Serve plus one: wide serve, recover to neutral, then $surfaceCue.',
    _KitFocus.footwork =>
      'Two-ball movement: cross-court feed, recover behind the mark, then $surfaceCue.',
    _KitFocus.netPlay =>
      'Approach plus hold: approach down the line, close with quiet hands, then $surfaceCue.',
    _KitFocus.calmPoints =>
      'Pressure point rehearsal: start at 30-all, play high margin, then $surfaceCue.',
  };
}

String _courtesyFor(_KitPartner partner) {
  return switch (partner) {
    _KitPartner.solo =>
      'Book an off-peak lane, keep spare balls contained, and leave the court ready for the next player.',
    _KitPartner.mutual =>
      'Agree on first-drill rhythm, water breaks, and whether points or technique notes come first.',
    _KitPartner.newPartner =>
      'Open with level, injury, and pace preferences. Keep coaching comments opt-in.',
    _KitPartner.clubVisitor =>
      'Confirm arrival gate, visitor rules, and court end time before warmup starts.',
  };
}

String _gearFor(_KitSurface surface, _KitLength length) {
  final hydration = length == _KitLength.ninety
      ? 'two bottles plus a towel'
      : 'one bottle and a towel';
  final surfaceGear = switch (surface) {
    _KitSurface.hard => 'fresh overgrip and durable shoes',
    _KitSurface.clay => 'clay-safe shoes and an extra wristband',
    _KitSurface.indoor => 'non-marking shoes and lower-glare lens cloth',
    _KitSurface.dusk => 'clear cap or visor and a visible ball can',
  };
  return '$surfaceGear; pack $hydration.';
}

TextStyle _kitText({
  Color color = _kitWhite,
  double fontSize = 14,
  double? height,
  FontWeight fontWeight = FontWeight.w700,
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
