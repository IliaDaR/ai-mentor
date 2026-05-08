import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';
import '../services/focus_service.dart';
import '../services/gamification_service.dart';
import '../services/learning_service.dart';
import '../services/monetization_service.dart';
import '../services/email_service.dart';
import '../services/ad_service.dart';
import 'repository_providers.dart';

// ===================== Service Providers =====================

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

final focusServiceProvider = ChangeNotifierProvider<FocusService>((ref) {
  return FocusService();
});

final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return GamificationService(
    userProgressRepository: ref.watch(userProgressRepositoryProvider),
    achievementRepository: ref.watch(achievementRepositoryProvider),
    dailyStatsRepository: ref.watch(dailyStatsRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
  );
});

final learningServiceProvider = Provider<LearningService>((ref) {
  return LearningService(
    userProgressRepository: ref.watch(userProgressRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
  );
});

final monetizationServiceProvider = Provider<MonetizationService>((ref) {
  return MonetizationService();
});

final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService();
});

final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});
