import 'package:courtly/atelier/theme/courtly_font_families.dart';
import 'package:courtly/features/my_court/presentation/courtly_wallet_page.dart';
import 'package:courtly/shared/wallet/courtly_wallet_store.dart';
import 'package:flutter/cupertino.dart';

const Color _coinPurple = Color(0xFF17003D);
const Color _coinPanel = Color(0xFF2A0861);
const Color _coinGold = Color(0xFFFFC934);
const Color _coinWhite = Color(0xFFFFFFFF);

Future<bool> showCourtlyCoinSpendGate({
  required BuildContext context,
  required CourtlyCoinFeature feature,
}) async {
  final wallet = CourtlyWalletStore.instance;
  final rule = CourtlyWalletStore.spendRuleFor(feature);
  final balance = await wallet.loadBalance();

  if (!context.mounted) {
    return false;
  }

  if (balance < rule.cost) {
    await _showCoinStatusDialog(
      context: context,
      icon: CupertinoIcons.money_dollar_circle_fill,
      title: 'Add coins first',
      message:
          '${rule.title} needs ${rule.cost} coins. Your balance is ${_formatCoins(balance)} coins.',
      primaryLabel: 'Recharge',
      secondaryLabel: 'Not now',
      onPrimary: (dialogContext) {
        Navigator.of(dialogContext).pop();
        Navigator.of(context).push(
          CupertinoPageRoute<void>(builder: (_) => const CourtlyWalletPage()),
        );
      },
    );
    return false;
  }

  final confirmed = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return _CoinSpendDialog(
        rule: rule,
        balance: balance,
        onCancel: () => Navigator.of(context).pop(false),
        onConfirm: () => Navigator.of(context).pop(true),
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return false;
  }

  final result = await wallet.spendCoins(feature);
  if (!context.mounted) {
    return false;
  }

  if (result.succeeded) {
    await _showCoinStatusDialog(
      context: context,
      icon: CupertinoIcons.check_mark_circled_solid,
      title: 'Plan unlocked',
      message:
          '${result.rule.cost} coins were used. Balance: ${_formatCoins(result.balance)} coins.',
      primaryLabel: 'Continue',
    );
    return true;
  }

  await _showCoinStatusDialog(
    context: context,
    icon: CupertinoIcons.money_dollar_circle_fill,
    title: 'Add coins first',
    message:
        '${result.rule.title} needs ${result.rule.cost} coins. Your balance is ${_formatCoins(result.balance)} coins.',
    primaryLabel: 'Recharge',
    secondaryLabel: 'Not now',
    onPrimary: (dialogContext) {
      Navigator.of(dialogContext).pop();
      Navigator.of(context).push(
        CupertinoPageRoute<void>(builder: (_) => const CourtlyWalletPage()),
      );
    },
  );
  return false;
}

Future<void> _showCoinStatusDialog({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String message,
  required String primaryLabel,
  String? secondaryLabel,
  void Function(BuildContext dialogContext)? onPrimary,
}) {
  return showCupertinoDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return _CoinStatusDialog(
        icon: icon,
        title: title,
        message: message,
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
        onPrimary: () {
          if (onPrimary == null) {
            Navigator.of(dialogContext).pop();
          } else {
            onPrimary(dialogContext);
          }
        },
        onSecondary: secondaryLabel == null
            ? null
            : () => Navigator.of(dialogContext).pop(),
      );
    },
  );
}

class _CoinSpendDialog extends StatelessWidget {
  const _CoinSpendDialog({
    required this.rule,
    required this.balance,
    required this.onCancel,
    required this.onConfirm,
  });

  final CourtlyCoinSpendRule rule;
  final int balance;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final afterBalance = balance - rule.cost;

    return _CoinDialogFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _CoinBadge(icon: CupertinoIcons.sparkles),
          const SizedBox(height: 14),
          Text(
            'Use ${rule.cost} coins',
            textAlign: TextAlign.center,
            style: _coinText(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _coinWhite,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            rule.title,
            textAlign: TextAlign.center,
            style: _coinText(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: _coinGold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            rule.description,
            textAlign: TextAlign.center,
            style: _coinText(
              fontSize: 14,
              height: 1.32,
              fontWeight: FontWeight.w700,
              color: _coinWhite.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 18),
          _CoinInfoStrip(
            cost: rule.cost,
            balance: balance,
            afterBalance: afterBalance,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _CoinDialogButton(
                  label: 'Cancel',
                  onPressed: onCancel,
                  secondary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CoinDialogButton(
                  label: 'Use coins',
                  onPressed: onConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoinStatusDialog extends StatelessWidget {
  const _CoinStatusDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final secondaryLabel = this.secondaryLabel;
    final onSecondary = this.onSecondary;

    return _CoinDialogFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CoinBadge(icon: icon),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: _coinText(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: _coinText(
              color: _coinWhite.withValues(alpha: 0.78),
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          if (secondaryLabel == null || onSecondary == null)
            _CoinDialogButton(label: primaryLabel, onPressed: onPrimary)
          else
            Row(
              children: [
                Expanded(
                  child: _CoinDialogButton(
                    label: secondaryLabel,
                    onPressed: onSecondary,
                    secondary: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CoinDialogButton(
                    label: primaryLabel,
                    onPressed: onPrimary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CoinDialogFrame extends StatelessWidget {
  const _CoinDialogFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_coinPanel, _coinPurple],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _coinWhite.withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(
                  color: _coinPurple.withValues(alpha: 0.52),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: _coinGold,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _coinGold.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: _coinPurple, size: 28),
    );
  }
}

class _CoinInfoStrip extends StatelessWidget {
  const _CoinInfoStrip({
    required this.cost,
    required this.balance,
    required this.afterBalance,
  });

  final int cost;
  final int balance;
  final int afterBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _coinWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _coinWhite.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _CoinInfoRow(label: 'Cost', value: '$cost coins'),
          const SizedBox(height: 8),
          _CoinInfoRow(
            label: 'Current balance',
            value: '${_formatCoins(balance)} coins',
          ),
          const SizedBox(height: 8),
          _CoinInfoRow(
            label: 'After use',
            value: '${_formatCoins(afterBalance)} coins',
          ),
        ],
      ),
    );
  }
}

class _CoinInfoRow extends StatelessWidget {
  const _CoinInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: _coinText(
              color: _coinWhite.withValues(alpha: 0.58),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: _coinText(
            color: _coinWhite,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CoinDialogButton extends StatelessWidget {
  const _CoinDialogButton({
    required this.label,
    required this.onPressed,
    this.secondary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: secondary ? _coinWhite.withValues(alpha: 0.1) : _coinGold,
          borderRadius: BorderRadius.circular(14),
          border: secondary
              ? Border.all(color: _coinWhite.withValues(alpha: 0.12))
              : null,
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _coinText(
              color: secondary ? _coinWhite : _coinPurple,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
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

TextStyle _coinText({
  Color color = _coinWhite,
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w700,
  double? height,
}) {
  return TextStyle(
    color: color,
    fontSize: fontSize,
    height: height,
    fontWeight: fontWeight,
    fontFamily: CourtlyFontFamilies.ui,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );
}
