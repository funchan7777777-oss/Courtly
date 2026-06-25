import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CourtlyCoinFeature { publishPost, publishReel, retroCheckIn }

enum CourtlyPurchaseEventType {
  pending,
  success,
  error,
  canceled,
  storeUnavailable,
  productUnavailable,
}

class CourtlyCoinPack {
  const CourtlyCoinPack({
    required this.productId,
    required this.coins,
    required this.displayPrice,
    required this.tone,
  });

  final String productId;
  final int coins;
  final String displayPrice;
  final String tone;
}

class CourtlyCoinSpendRule {
  const CourtlyCoinSpendRule({
    required this.feature,
    required this.title,
    required this.cost,
    required this.description,
  });

  final CourtlyCoinFeature feature;
  final String title;
  final int cost;
  final String description;
}

class CourtlyCoinSpendResult {
  const CourtlyCoinSpendResult({
    required this.succeeded,
    required this.rule,
    required this.balance,
  });

  final bool succeeded;
  final CourtlyCoinSpendRule rule;
  final int balance;
}

class CourtlyPurchaseEvent {
  const CourtlyPurchaseEvent({
    required this.type,
    required this.productId,
    required this.message,
    this.coins = 0,
  });

  final CourtlyPurchaseEventType type;
  final String productId;
  final String message;
  final int coins;
}

class CourtlyWelcomeGrant {
  const CourtlyWelcomeGrant({required this.coins, required this.balance});

  final int coins;
  final int balance;
}

class CourtlyWalletStore {
  CourtlyWalletStore._();

  static final CourtlyWalletStore instance = CourtlyWalletStore._();

  static const int welcomeGiftCoins = 888;
  static const String _balanceKey = 'courtly_wallet_coin_balance';
  static const String _welcomeGiftKey = 'courtly_wallet_welcome_gift_claimed';
  static const String _processedPurchasesKey =
      'courtly_wallet_processed_purchases';

  static const List<CourtlyCoinPack> packs = [
    CourtlyCoinPack(
      productId: 'kgxayonkvutkitnv',
      coins: 10000,
      displayPrice: r'$99.99',
      tone: 'Grand slam vault',
    ),
    CourtlyCoinPack(
      productId: 'znsderhguwehqifp',
      coins: 8000,
      displayPrice: r'$79.99',
      tone: 'Champion reserve',
    ),
    CourtlyCoinPack(
      productId: 'wfkexczpgvsbvhvo',
      coins: 5000,
      displayPrice: r'$49.99',
      tone: 'Night court stack',
    ),
    CourtlyCoinPack(
      productId: 'fzikcqumlrydlsjx',
      coins: 2000,
      displayPrice: r'$19.99',
      tone: 'Rally fuel',
    ),
    CourtlyCoinPack(
      productId: 'lfjuhaysktvxoouu',
      coins: 1000,
      displayPrice: r'$9.99',
      tone: 'Fast set',
    ),
    CourtlyCoinPack(
      productId: 'rfjzigslwqatfels',
      coins: 500,
      displayPrice: r'$4.99',
      tone: 'Serve pocket',
    ),
    CourtlyCoinPack(
      productId: 'mhnjokyopjzkvyij',
      coins: 200,
      displayPrice: r'$1.99',
      tone: 'Warmup clip',
    ),
    CourtlyCoinPack(
      productId: 'cmeppgwmrszbwvtp',
      coins: 100,
      displayPrice: r'$0.99',
      tone: 'First bounce',
    ),
  ];

  static const List<CourtlyCoinSpendRule> spendRules = [
    CourtlyCoinSpendRule(
      feature: CourtlyCoinFeature.publishPost,
      title: 'Publish a court post',
      cost: 30,
      description: 'Share one photo moment to your court feed.',
    ),
    CourtlyCoinSpendRule(
      feature: CourtlyCoinFeature.publishReel,
      title: 'Release a video reel',
      cost: 60,
      description: 'Release one video clip to the reels court.',
    ),
    CourtlyCoinSpendRule(
      feature: CourtlyCoinFeature.retroCheckIn,
      title: 'Retro check-in',
      cost: 20,
      description: 'Recover one missed Tennis Diary check-in.',
    ),
  ];

  final ValueNotifier<int> balanceVersion = ValueNotifier<int>(0);
  final StreamController<CourtlyPurchaseEvent> _purchaseEvents =
      StreamController<CourtlyPurchaseEvent>.broadcast();
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  Stream<CourtlyPurchaseEvent> get purchaseEvents => _purchaseEvents.stream;

  void startPurchaseListener() {
    _purchaseSubscription ??= _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _purchaseEvents.add(
          CourtlyPurchaseEvent(
            type: CourtlyPurchaseEventType.error,
            productId: '',
            message: 'The App Store purchase stream could not be read.',
          ),
        );
      },
    );
  }

  Future<int> loadBalance() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_balanceKey) ?? 0;
  }

  Future<CourtlyWelcomeGrant?> claimWelcomeGiftIfNeeded() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_welcomeGiftKey) == true) {
      return null;
    }

    final balance = await _setBalance(
      preferences,
      (preferences.getInt(_balanceKey) ?? 0) + welcomeGiftCoins,
    );
    await preferences.setBool(_welcomeGiftKey, true);
    return CourtlyWelcomeGrant(coins: welcomeGiftCoins, balance: balance);
  }

  Future<CourtlyCoinSpendResult> spendCoins(CourtlyCoinFeature feature) async {
    final rule = spendRuleFor(feature);
    final preferences = await SharedPreferences.getInstance();
    final balance = preferences.getInt(_balanceKey) ?? 0;
    if (balance < rule.cost) {
      return CourtlyCoinSpendResult(
        succeeded: false,
        rule: rule,
        balance: balance,
      );
    }

    final nextBalance = await _setBalance(preferences, balance - rule.cost);
    return CourtlyCoinSpendResult(
      succeeded: true,
      rule: rule,
      balance: nextBalance,
    );
  }

  Future<int> addCoins(int coins) async {
    if (coins <= 0) {
      return loadBalance();
    }

    final preferences = await SharedPreferences.getInstance();
    return _setBalance(
      preferences,
      (preferences.getInt(_balanceKey) ?? 0) + coins,
    );
  }

  Future<void> clearLocalWallet() async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.remove(_balanceKey),
      preferences.remove(_welcomeGiftKey),
      preferences.remove(_processedPurchasesKey),
    ]);
    balanceVersion.value += 1;
  }

  Future<CourtlyPurchaseEvent> buyPack(CourtlyCoinPack pack) async {
    startPurchaseListener();

    final available = await _iap.isAvailable();
    if (!available) {
      return CourtlyPurchaseEvent(
        type: CourtlyPurchaseEventType.storeUnavailable,
        productId: pack.productId,
        message: 'The App Store is not available right now.',
      );
    }

    final response = await _iap.queryProductDetails({pack.productId});
    if (response.error != null) {
      return CourtlyPurchaseEvent(
        type: CourtlyPurchaseEventType.error,
        productId: pack.productId,
        message: response.error!.message,
      );
    }

    final products = response.productDetails
        .where((product) => product.id == pack.productId)
        .toList(growable: false);
    if (products.isEmpty || response.notFoundIDs.contains(pack.productId)) {
      return CourtlyPurchaseEvent(
        type: CourtlyPurchaseEventType.productUnavailable,
        productId: pack.productId,
        message: 'This coin pack is not available in App Store Connect yet.',
      );
    }

    final purchaseParam = PurchaseParam(productDetails: products.first);
    final started = await _iap.buyConsumable(
      purchaseParam: purchaseParam,
      autoConsume: true,
    );
    return CourtlyPurchaseEvent(
      type: started
          ? CourtlyPurchaseEventType.pending
          : CourtlyPurchaseEventType.error,
      productId: pack.productId,
      message: started
          ? 'Apple purchase sheet opened.'
          : 'The App Store purchase could not be started.',
    );
  }

  static CourtlyCoinSpendRule spendRuleFor(CourtlyCoinFeature feature) {
    return spendRules.firstWhere((rule) => rule.feature == feature);
  }

  static CourtlyCoinPack? packForProductId(String productId) {
    for (final pack in packs) {
      if (pack.productId == productId) {
        return pack;
      }
    }
    return null;
  }

  Future<int> _setBalance(SharedPreferences preferences, int balance) async {
    final nextBalance = balance < 0 ? 0 : balance;
    await preferences.setInt(_balanceKey, nextBalance);
    balanceVersion.value += 1;
    return nextBalance;
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      await _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    final pack = packForProductId(purchase.productID);
    if (purchase.status == PurchaseStatus.pending) {
      _purchaseEvents.add(
        CourtlyPurchaseEvent(
          type: CourtlyPurchaseEventType.pending,
          productId: purchase.productID,
          message: 'Waiting for Apple to confirm the purchase.',
        ),
      );
      return;
    }

    if (purchase.status == PurchaseStatus.error) {
      _purchaseEvents.add(
        CourtlyPurchaseEvent(
          type: CourtlyPurchaseEventType.error,
          productId: purchase.productID,
          message: purchase.error?.message ?? 'The purchase failed.',
        ),
      );
      await _completeIfNeeded(purchase);
      return;
    }

    if (purchase.status == PurchaseStatus.canceled) {
      _purchaseEvents.add(
        CourtlyPurchaseEvent(
          type: CourtlyPurchaseEventType.canceled,
          productId: purchase.productID,
          message: 'The purchase was canceled.',
        ),
      );
      await _completeIfNeeded(purchase);
      return;
    }

    if (pack == null) {
      await _completeIfNeeded(purchase);
      return;
    }

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      final delivered = await _markPurchaseProcessed(purchase);
      if (delivered) {
        await addCoins(pack.coins);
        _purchaseEvents.add(
          CourtlyPurchaseEvent(
            type: CourtlyPurchaseEventType.success,
            productId: purchase.productID,
            coins: pack.coins,
            message: '${pack.coins} coins have been added to your wallet.',
          ),
        );
      }
      await _completeIfNeeded(purchase);
    }
  }

  Future<void> _completeIfNeeded(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  Future<bool> _markPurchaseProcessed(PurchaseDetails purchase) async {
    final preferences = await SharedPreferences.getInstance();
    final processed =
        preferences.getStringList(_processedPurchasesKey) ?? <String>[];
    final purchaseKey = _purchaseKey(purchase);
    if (processed.contains(purchaseKey)) {
      return false;
    }

    processed.add(purchaseKey);
    await preferences.setStringList(_processedPurchasesKey, processed);
    return true;
  }

  String _purchaseKey(PurchaseDetails purchase) {
    final rawKey =
        purchase.purchaseID ??
        purchase.transactionDate ??
        purchase.verificationData.serverVerificationData;
    return '${purchase.productID}:$rawKey';
  }
}
