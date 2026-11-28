import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart' show BillingResponse;
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../prefs/dialer_prefs.dart';

/// What a tip purchase came to, for the Support page's toast.
enum TipResult { thanks, pending, failed }

/// Settings › Support One Dialer: one-time tips through Google Play Billing. Tips unlock nothing;
/// each is a consumable, consumed as soon as Play confirms it so it can be bought again.
class Tips {
  Tips._();
  static final instance = Tips._();

  /// Play Console › Monetize › In-app products, cheapest first.
  static const productIds = ['tip_small', 'tip_medium', 'tip_large'];

  final results = StreamController<TipResult>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchases;

  /// Starts the billing client only when it's needed: the Support page opens, or a pending tip
  /// (paid later, e.g. in cash) is still waiting from an earlier launch.
  Future<void> start() async {
    if (_purchases != null) return;
    _purchases = InAppPurchase.instance.purchaseStream.listen(_onPurchases, onError: (_) {});
    try {
      // Tips bought but not consumed yet (the app closed first) come back here as restored.
      await InAppPurchase.instance.restorePurchases();
    } catch (error) {
      debugPrint('Tips: could not check past purchases: $error');
    }
  }

  /// At launch, only when a tip was left pending.
  Future<void> resumePending() async {
    if (await DialerPrefs.instance.tipPending()) await start();
  }

  /// The tips in price order; empty when Play Billing isn't available (no Play Store, or a
  /// build Play doesn't know about).
  Future<List<ProductDetails>> load() async {
    await start();
    if (!await InAppPurchase.instance.isAvailable()) return const [];
    try {
      final response = await InAppPurchase.instance.queryProductDetails(productIds.toSet());
      if (response.error != null || response.notFoundIDs.isNotEmpty) {
        debugPrint('Tips: error ${response.error}, not found ${response.notFoundIDs}');
      }
      return response.productDetails..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    } catch (error) {
      // The plugin reads each tip's backwards-compatible purchase option; without one it throws.
      debugPrint('Tips: could not read the tips: $error');
      return const [];
    }
  }

  /// Opens Play's purchase sheet; the outcome arrives on [results].
  Future<void> buy(ProductDetails product) async {
    try {
      await InAppPurchase.instance.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
        autoConsume: false, // consumed in _onPurchases, also for tips restored after a restart
      );
    } catch (error) {
      debugPrint('Tips: purchase failed to start: $error');
      results.add(TipResult.failed);
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          await DialerPrefs.instance.setTipPending(true);
          results.add(TipResult.pending);
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          if (!productIds.contains(purchase.productID)) continue;
          final addition = InAppPurchase.instance.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
          final consumed = await addition.consumePurchase(purchase);
          // Not consumed: it stays owned, and the next start() tries again.
          if (consumed.responseCode != BillingResponse.ok) continue;
          await DialerPrefs.instance.setTipPending(false);
          if (purchase.status == PurchaseStatus.purchased) results.add(TipResult.thanks);
        case PurchaseStatus.error:
          results.add(TipResult.failed);
        case PurchaseStatus.canceled:
          break;
      }
    }
  }
}
