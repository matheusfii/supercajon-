import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService extends ChangeNotifier {
  static const annualSubscriptionId = 'super_cajon_pro';
  static const _entitlementKey = 'annual_subscription_active';
  static const _lastVerifiedKey = 'annual_subscription_last_verified';
  static const _offlineGracePeriod = Duration(days: 3);

  final InAppPurchase _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Timer? _validationTimer;

  ProductDetails? product;
  bool isPremium = false;
  bool storeAvailable = false;
  bool loading = true;
  bool purchasePending = false;
  String? message;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final cachedEntitlement = preferences.getBool(_entitlementKey) ?? false;
    final lastVerified = preferences.getInt(_lastVerifiedKey);
    isPremium = cachedEntitlement && _isInsideOfflineGracePeriod(lastVerified);

    _subscription = _store.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        purchasePending = false;
        message = 'Não foi possível validar a assinatura agora.';
        notifyListeners();
      },
    );

    try {
      storeAvailable = await _store.isAvailable();
      if (storeAvailable) {
        final response = await _store.queryProductDetails({
          annualSubscriptionId,
        });
        if (response.productDetails.isNotEmpty) {
          product = response.productDetails.first;
        } else if (!isPremium) {
          message = 'Assinatura ainda não disponível na Google Play.';
        }

        if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
          await _refreshAndroidEntitlement(showResult: false);
        }
      } else if (!isPremium) {
        message = 'Google Play indisponível neste dispositivo.';
      }
    } catch (_) {
      if (!isPremium) {
        message = 'Não foi possível acessar a Google Play.';
      }
    }

    loading = false;
    _validationTimer = Timer.periodic(
      const Duration(hours: 6),
      (_) => unawaited(refreshEntitlement()),
    );
    notifyListeners();
  }

  Future<void> refreshEntitlement() async {
    if (kIsWeb) return;
    try {
      storeAvailable = await _store.isAvailable();
      if (!storeAvailable) {
        await _expireStaleCacheIfNeeded();
        notifyListeners();
        return;
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _refreshAndroidEntitlement(showResult: false);
      }
    } catch (_) {
      await _expireStaleCacheIfNeeded();
      notifyListeners();
    }
  }

  bool _isInsideOfflineGracePeriod(int? lastVerified) {
    if (lastVerified == null) return false;
    final verifiedAt = DateTime.fromMillisecondsSinceEpoch(lastVerified);
    return DateTime.now().difference(verifiedAt) <= _offlineGracePeriod;
  }

  Future<void> buyAnnualSubscription() async {
    final currentProduct = product;
    if (currentProduct == null || purchasePending) {
      message = 'A assinatura ainda não está disponível.';
      notifyListeners();
      return;
    }

    purchasePending = true;
    message = null;
    notifyListeners();

    try {
      // The plugin uses buyNonConsumable for both non-consumables and
      // subscriptions. Google Play determines the billing flow from the
      // ProductDetails returned for the subscription product.
      await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: currentProduct),
      );
    } catch (_) {
      purchasePending = false;
      message = 'A assinatura não pôde ser iniciada.';
      notifyListeners();
    }
  }

  Future<void> restore() async {
    if (!storeAvailable) {
      message = 'Google Play indisponível neste dispositivo.';
      notifyListeners();
      return;
    }

    purchasePending = true;
    message = 'Verificando sua assinatura…';
    notifyListeners();

    try {
      if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
        await _refreshAndroidEntitlement(showResult: true);
      } else {
        await _store.restorePurchases();
      }
    } catch (_) {
      purchasePending = false;
      message = 'Não foi possível verificar a assinatura.';
      notifyListeners();
    }
  }

  Future<void> _refreshAndroidEntitlement({required bool showResult}) async {
    final addition = _store
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();
    if (response.error != null) {
      purchasePending = false;
      await _expireStaleCacheIfNeeded();
      if (showResult) {
        message = 'Não foi possível verificar a assinatura.';
      }
      notifyListeners();
      return;
    }

    PurchaseDetails? activeSubscription;
    for (final purchase in response.pastPurchases) {
      if (purchase.productID == annualSubscriptionId &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        activeSubscription = purchase;
        break;
      }
    }

    if (activeSubscription == null) {
      await _clearEntitlement();
      purchasePending = false;
      if (showResult) {
        message = 'Nenhuma assinatura ativa foi encontrada.';
      }
    } else {
      await _grantEntitlement(activeSubscription);
      purchasePending = false;
      if (showResult) {
        message = 'Assinatura ativa verificada com sucesso.';
      }
      if (activeSubscription.pendingCompletePurchase) {
        await _store.completePurchase(activeSubscription);
      }
    }
    notifyListeners();
  }

  Future<void> _expireStaleCacheIfNeeded() async {
    final preferences = await SharedPreferences.getInstance();
    final lastVerified = preferences.getInt(_lastVerifiedKey);
    if (!_isInsideOfflineGracePeriod(lastVerified)) {
      await _clearEntitlement();
    }
  }

  Future<void> _grantEntitlement(PurchaseDetails purchase) async {
    // A non-empty Play purchase token is the minimum local integrity check.
    // Production monitoring should also validate it with the Google Play
    // Developer API and Real-time Developer Notifications.
    if (purchase.verificationData.serverVerificationData.isEmpty) {
      throw StateError('Google Play returned an empty purchase token.');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_entitlementKey, true);
    await preferences.setInt(
      _lastVerifiedKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    isPremium = true;
  }

  Future<void> _clearEntitlement() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_entitlementKey, false);
    await preferences.remove(_lastVerifiedKey);
    isPremium = false;
  }

  void previewUnlock() {
    isPremium = true;
    purchasePending = false;
    message = 'Assinatura anual ativada para demonstração.';
    notifyListeners();
  }

  void previewLock() {
    isPremium = false;
    purchasePending = false;
    message = null;
    notifyListeners();
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != annualSubscriptionId) continue;

      if (purchase.status == PurchaseStatus.pending) {
        purchasePending = true;
        message = 'Aguardando confirmação da Google Play…';
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          await _grantEntitlement(purchase);
          purchasePending = false;
          message = purchase.status == PurchaseStatus.restored
              ? 'Assinatura restaurada com sucesso.'
              : 'Super Cajon Pro ativado!';
        } catch (_) {
          purchasePending = false;
          message = 'Não foi possível validar a assinatura.';
        }
      } else if (purchase.status == PurchaseStatus.error) {
        purchasePending = false;
        message = purchase.error?.message ?? 'A assinatura não foi concluída.';
      } else if (purchase.status == PurchaseStatus.canceled) {
        purchasePending = false;
        message = null;
      }

      if (purchase.pendingCompletePurchase &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        await _store.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _validationTimer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
