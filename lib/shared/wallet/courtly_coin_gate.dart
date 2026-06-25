import 'package:courtly/features/my_court/presentation/courtly_wallet_page.dart';
import 'package:courtly/shared/wallet/courtly_wallet_store.dart';
import 'package:flutter/cupertino.dart';

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

  final confirmed = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: Text('Use ${rule.cost} coins?'),
        content: Text(
          '${rule.description}\n\nCurrent balance: ${_formatCoins(balance)} coins',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Use coins'),
          ),
        ],
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
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Coins used'),
          content: Text(
            '${result.rule.cost} coins were spent.\nBalance: ${_formatCoins(result.balance)} coins',
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
    return true;
  }

  await showCupertinoDialog<void>(
    context: context,
    builder: (dialogContext) {
      return CupertinoAlertDialog(
        title: const Text('Not enough coins'),
        content: Text(
          '${result.rule.title} needs ${result.rule.cost} coins.\nYour balance is ${_formatCoins(result.balance)} coins.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const CourtlyWalletPage(),
                ),
              );
            },
            child: const Text('Recharge'),
          ),
        ],
      );
    },
  );
  return false;
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
