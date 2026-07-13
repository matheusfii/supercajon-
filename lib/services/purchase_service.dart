import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService extends ChangeNotifier {
  static const fullUnlockId = 'super_cajon_full_unlock';
  static const _entitlementKey = 'premium_full_unlock';

  final InAppPurchase _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  ProductDetails? product;
  bool isPremium = false;
  bool storeAvailable = false;
  bool loading = true;
  bool purchasePending = false;
  String? message;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    isPremium = preferences.getBool(_entitlementKey) ?? false;

    _subscription = _store.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        purchasePending = false;
        message = 'Não foi possível concluir a compra.';
        notifyListeners();
      },
    );

    try {
      storeAvailable = await _store.isAvailable();
      if (storeAvailable) {
        final response = await _store.queryProductDetails({fullUnlockId});
        if (response.productDetails.isNotEmpty) {
          product = response.productDetails.first;
        } else if (!isPremium) {
          message = 'Produto ainda não disponível na Google Play.';
        }
      } else if (!isPremium) {
        message = 'Google Play indisponível neste dispositivo.';
      }
    } catch (_) {
      if (!isPremium) message = 'Não foi possível acessar a Google Play.';
    }

    loading = false;
    notifyListeners();
  }

  Future<void> buyFullUnlock() async {
    final currentProduct = product;
    if (currentProduct == null || purchasePending) {
      message = 'A compra ainda não está disponível.';
      notifyListeners();
      return;
    }

    purchasePending = true;
    message = null;
    notifyListeners();

    try {
      await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: currentProduct),
      );
    } catch (_) {
      purchasePending = false;
      message = 'A compra não pôde ser iniciada.';
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
    message = 'Procurando compras anteriores…';
    notifyListeners();
    try {
      await _store.restorePurchases();
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!isPremium) {
        purchasePending = false;
        message = 'Nenhuma compra anterior foi encontrada.';
        notifyListeners();
      }
    } catch (_) {
      purchasePending = false;
      message = 'Não foi possível restaurar a compra.';
      notifyListeners();
    }
  }

  void previewUnlock() {
    isPremium = true;
    purchasePending = false;
    message = 'Super Cajon completo desbloqueado!';
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
      if (purchase.productID != fullUnlockId) continue;

      if (purchase.status == PurchaseStatus.pending) {
        purchasePending = true;
        message = 'Aguardando confirmação da Google Play…';
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Para o lançamento, valide o token da compra em um servidor antes de
        // liberar o acesso em produção. O estado local mantém o app offline.
        final preferences = await SharedPreferences.getInstance();
        await preferences.setBool(_entitlementKey, true);
        isPremium = true;
        purchasePending = false;
        message = purchase.status == PurchaseStatus.restored
            ? 'Compra restaurada com sucesso.'
            : 'Super Cajon completo desbloqueado!';
      } else if (purchase.status == PurchaseStatus.error) {
        purchasePending = false;
        message = purchase.error?.message ?? 'A compra não foi concluída.';
      } else if (purchase.status == PurchaseStatus.canceled) {
        purchasePending = false;
        message = null;
      }

      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
