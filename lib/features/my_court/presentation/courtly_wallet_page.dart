import 'dart:async';

import 'package:courtly/shared/presentation/courtly_safe_layout.dart';
import 'package:courtly/shared/wallet/courtly_wallet_store.dart';
import 'package:flutter/cupertino.dart';

const Color _walletPurple = Color(0xFF1A004D);
const Color _walletPurpleDeep = Color(0xFF090019);
const Color _walletPanel = Color(0xFF26005F);
const Color _walletPink = Color(0xFFFF2DD2);
const Color _walletGold = Color(0xFFFFC934);
const Color _walletWhite = Color(0xFFFFFFFF);

class CourtlyWalletPage extends StatefulWidget {
  const CourtlyWalletPage({super.key});

  @override
  State<CourtlyWalletPage> createState() => _CourtlyWalletPageState();
}

class _CourtlyWalletPageState extends State<CourtlyWalletPage> {
  final CourtlyWalletStore _wallet = CourtlyWalletStore.instance;
  StreamSubscription<CourtlyPurchaseEvent>? _purchaseSubscription;
  int _balance = 0;
  String? _pendingProductId;

  @override
  void initState() {
    super.initState();
    _wallet.startPurchaseListener();
    _wallet.balanceVersion.addListener(_handleBalanceChanged);
    _purchaseSubscription = _wallet.purchaseEvents.listen(_handlePurchaseEvent);
    unawaited(_loadBalance());
  }

  @override
  void dispose() {
    _wallet.balanceVersion.removeListener(_handleBalanceChanged);
    unawaited(_purchaseSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _WalletBackdrop(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _WalletHeader(
                onBack: () => Navigator.of(context).pop(_balance),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
                child: _WalletHero(balance: _balance),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverList.separated(
                itemCount: CourtlyWalletStore.packs.length,
                itemBuilder: (context, index) {
                  final pack = CourtlyWalletStore.packs[index];
                  return _CoinPackCard(
                    pack: pack,
                    isPending: _pendingProductId == pack.productId,
                    onPressed: () => unawaited(_buyPack(pack)),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
                child: _CoinUsagePanel(rules: CourtlyWalletStore.spendRules),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  void _handleBalanceChanged() {
    if (!mounted) {
      return;
    }
    unawaited(_loadBalance());
  }

  Future<void> _loadBalance() async {
    final balance = await _wallet.loadBalance();
    if (!mounted) {
      return;
    }
    setState(() => _balance = balance);
  }

  Future<void> _buyPack(CourtlyCoinPack pack) async {
    if (_pendingProductId != null) {
      return;
    }

    setState(() => _pendingProductId = pack.productId);
    final event = await _wallet.buyPack(pack);
    if (!mounted) {
      return;
    }

    if (event.type != CourtlyPurchaseEventType.pending) {
      setState(() => _pendingProductId = null);
      await _showPurchaseEvent(event);
    }
  }

  void _handlePurchaseEvent(CourtlyPurchaseEvent event) {
    if (!mounted) {
      return;
    }

    final isKnownProduct =
        event.productId.isEmpty ||
        CourtlyWalletStore.packForProductId(event.productId) != null;
    if (!isKnownProduct) {
      return;
    }

    if (event.type != CourtlyPurchaseEventType.pending) {
      setState(() => _pendingProductId = null);
      unawaited(_showPurchaseEvent(event));
    }
  }

  Future<void> _showPurchaseEvent(CourtlyPurchaseEvent event) async {
    final title = switch (event.type) {
      CourtlyPurchaseEventType.success => 'Coins added',
      CourtlyPurchaseEventType.canceled => 'Purchase canceled',
      CourtlyPurchaseEventType.storeUnavailable => 'Store unavailable',
      CourtlyPurchaseEventType.productUnavailable => 'Pack unavailable',
      CourtlyPurchaseEventType.pending => 'Purchase pending',
      CourtlyPurchaseEventType.error => 'Purchase failed',
    };
    final balance = await _wallet.loadBalance();
    if (!mounted) {
      return;
    }

    await showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(
            event.type == CourtlyPurchaseEventType.success
                ? '${event.message}\nBalance: ${_formatCoins(balance)} coins'
                : event.message,
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, courtlySafeTop(context, 10), 14, 0),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              onPressed: onBack,
              child: const SizedBox.square(
                dimension: 42,
                child: Icon(
                  CupertinoIcons.chevron_left,
                  color: _walletWhite,
                  size: 22,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Wallet',
                textAlign: TextAlign.center,
                style: _walletText(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 42),
          ],
        ),
      ),
    );
  }
}

class _WalletHero extends StatelessWidget {
  const _WalletHero({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 252,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: RadialGradient(
              center: const Alignment(0, -0.25),
              radius: 0.86,
              colors: [
                _walletPink.withValues(alpha: 0.38),
                const Color(0xFF5820B8).withValues(alpha: 0.3),
                _walletPanel.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(color: _walletWhite.withValues(alpha: 0.08)),
          ),
        ),
        Positioned(
          top: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _walletWhite.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _walletWhite.withValues(alpha: 0.08)),
            ),
            child: Text(
              'Live balance',
              style: _walletText(
                color: _walletWhite.withValues(alpha: 0.78),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Positioned(
          top: 48,
          child: Image.asset(
            'assets/images/Clinic.png',
            width: 132,
            height: 132,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          bottom: 34,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatCoins(balance),
                style: _walletText(fontSize: 34, fontWeight: FontWeight.w900),
              ),
              Text(
                'coins',
                style: _walletText(
                  color: _walletWhite.withValues(alpha: 0.68),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoinPackCard extends StatelessWidget {
  const _CoinPackCard({
    required this.pack,
    required this.isPending,
    required this.onPressed,
  });

  final CourtlyCoinPack pack;
  final bool isPending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bestValue = pack.coins >= 8000;
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: isPending ? null : onPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 66),
        decoration: BoxDecoration(
          color: _walletPanel.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: bestValue
                ? _walletGold.withValues(alpha: 0.34)
                : _walletWhite.withValues(alpha: 0.06),
          ),
          boxShadow: [
            if (bestValue)
              BoxShadow(
                color: _walletGold.withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Image.asset(
              'assets/images/Clinic.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatCoins(pack.coins)} coins',
                    style: _walletText(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pack.tone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _walletText(
                      color: _walletWhite.withValues(alpha: 0.56),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 34,
              constraints: const BoxConstraints(minWidth: 78),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _walletPink,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Center(
                child: isPending
                    ? const CupertinoActivityIndicator(
                        color: _walletWhite,
                        radius: 8,
                      )
                    : Text(
                        pack.displayPrice,
                        style: _walletText(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinUsagePanel extends StatelessWidget {
  const _CoinUsagePanel({required this.rules});

  final List<CourtlyCoinSpendRule> rules;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: _walletPurpleDeep.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _walletWhite.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coin uses',
            style: _walletText(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          for (final rule in rules) ...[
            _UsageRuleRow(rule: rule),
            const SizedBox(height: 10),
          ],
          const _FreeFeatureRow(
            label: 'Mutual chats, messages, and video calls',
          ),
        ],
      ),
    );
  }
}

class _UsageRuleRow extends StatelessWidget {
  const _UsageRuleRow({required this.rule});

  final CourtlyCoinSpendRule rule;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _walletPink.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.sparkles,
            color: _walletPink,
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rule.title,
                style: _walletText(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                rule.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _walletText(
                  color: _walletWhite.withValues(alpha: 0.55),
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${rule.cost}',
          style: _walletText(
            color: _walletGold,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _FreeFeatureRow extends StatelessWidget {
  const _FreeFeatureRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _walletWhite.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.chat_bubble_2_fill,
            color: _walletWhite,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: _walletText(
              color: _walletWhite.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          'Free',
          style: _walletText(
            color: _walletGold,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _WalletBackdrop extends StatelessWidget {
  const _WalletBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/Arena.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _walletPurple.withValues(alpha: 0.9),
                const Color(0xFF32107D).withValues(alpha: 0.84),
                _walletPurpleDeep.withValues(alpha: 0.96),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.8, -0.12),
              radius: 0.92,
              colors: [
                _walletPink.withValues(alpha: 0.28),
                _walletPurple.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

TextStyle _walletText({
  Color color = _walletWhite,
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w700,
  double height = 1,
}) {
  return TextStyle(
    color: color,
    fontSize: fontSize,
    height: height,
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
