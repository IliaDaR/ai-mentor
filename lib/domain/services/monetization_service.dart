import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

class MonetizationService {
  static const String PRO_MONTHLY = 'pro_monthly';
  static const String PRO_YEARLY = 'pro_yearly';
  static const String PRO_LIFETIME = 'pro_lifetime';
  static const String PRO_PLUS_TEAM = 'pro_plus_team';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Проверка, активна ли Pro-подписка
  Future<bool> isPro() async {
    try {
      await _inAppPurchase.restorePurchases();
      final hasLifetime = false;
      final hasActive = false;
      
      // In production, use purchase updates stream
      // For now, check local flag

      // Also check local flag for offline verification
      final localPro = await _storage.read(key: 'is_pro');

      return hasActive || hasLifetime || localPro == 'true';
    } catch (e) {
      // Fallback to local check
      final localPro = await _storage.read(key: 'is_pro');
      return localPro == 'true';
    }
  }

  /// Проверка пробного периода
  Future<bool> isTrialActive() async {
    final prefs = await SharedPreferences.getInstance();
    final trialStart = prefs.getInt('trial_start');

    if (trialStart == null) {
      // First launch — start trial
      await prefs.setInt(
          'trial_start', DateTime.now().millisecondsSinceEpoch);
      return true;
    }

    final start = DateTime.fromMillisecondsSinceEpoch(trialStart);
    final end = start.add(Duration(days: AppConstants.proTrialDays));
    return DateTime.now().isBefore(end);
  }

  /// Можно ли использовать AI
  Future<bool> canUseAI({required int dailyRequestsUsed}) async {
    if (await isPro()) return true;
    if (await isTrialActive()) return true;
    return dailyRequestsUsed < AppConstants.freeDailyRequests;
  }

  /// Показывать ли рекламу
  Future<bool> shouldShowAds() async {
    if (await isPro()) return false;
    if (await isTrialActive()) return false;
    return true;
  }

  /// Максимальное количество задач
  Future<int> getMaxTasks() async {
    if (await isPro()) return 999999;
    return AppConstants.freeMaxTasks;
  }

  /// Максимальное количество совещаний
  Future<int> getMaxMeetings() async {
    if (await isPro()) return 999999;
    return AppConstants.freeMaxMeetings;
  }

  /// Начать пробный период
  Future<void> startTrial() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('trial_start')) {
      await prefs.setInt(
          'trial_start', DateTime.now().millisecondsSinceEpoch);
    }
  }

  /// Активировать Pro (для тестов/офлайн)
  Future<void> activateProLocally() async {
    await _storage.write(key: 'is_pro', value: 'true');
    await _storage.write(
        key: 'pro_activated_at',
        value: DateTime.now().millisecondsSinceEpoch.toString());
  }

  /// Деактивировать Pro
  Future<void> deactivatePro() async {
    await _storage.delete(key: 'is_pro');
    await _storage.delete(key: 'pro_activated_at');
  }

  bool _isSubscriptionActive(PurchaseDetails purchase) {
    // Check if subscription is active based on status
    return purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored;
  }

  /// Купить подписку
  Future<bool> purchaseProduct(String productId) async {
    try {
      final productDetails = await _inAppPurchase.queryProductDetails(
        {productId},
      );

      if (productDetails.notFoundIDs.isNotEmpty) {
        logger.w('Product not found: $productId');
        return false;
      }

      final product = productDetails.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      return true;
    } catch (e) {
      logger.e('Purchase failed: $e');
      return false;
    }
  }

  /// Восстановить покупки
  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }
}
