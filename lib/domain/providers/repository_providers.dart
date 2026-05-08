import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/user_progress_repository.dart';
import '../../data/repositories/source_repository.dart';
import '../../data/repositories/transcript_repository.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../data/repositories/daily_stats_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/api_usage_repository.dart';

// ===================== Repository Providers =====================

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

final userProgressRepositoryProvider = Provider<UserProgressRepository>((ref) {
  return UserProgressRepository();
});

final sourceRepositoryProvider = Provider<SourceRepository>((ref) {
  return SourceRepository();
});

final transcriptRepositoryProvider = Provider<TranscriptRepository>((ref) {
  return TranscriptRepository();
});

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository();
});

final dailyStatsRepositoryProvider = Provider<DailyStatsRepository>((ref) {
  return DailyStatsRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final apiUsageRepositoryProvider = Provider<ApiUsageRepository>((ref) {
  return ApiUsageRepository();
});
