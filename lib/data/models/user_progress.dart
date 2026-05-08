import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_progress.freezed.dart';
part 'user_progress.g.dart';

@freezed
class UserProgress with _$UserProgress {
  const factory UserProgress({
    @Default('default') String userId,
    @Default('novice') String currentLevel,
    @Default(0) int totalPoints,
    @Default('stage1') String currentStage,
    @Default(0) int focusTimeTotalMinutes,
    @Default(0) int tasksCompleted,
    @Default(0) int tasksCreated,
    @Default(0) int tasksSmartCompliant,
    @Default(0) int meetingsRecorded,
    @Default(0) int inboxZeroDays,
    @Default(0) int currentStreakDays,
    @Default(0) int longestStreakDays,
    required DateTime joinedAt,
    DateTime? lastActiveAt,
    @Default(false) bool isPro,
    DateTime? proExpiresAt,
    DateTime? trialStartedAt,
    @Default(false) bool trialUsed,
  }) = _UserProgress;

  factory UserProgress.fromJson(Map<String, dynamic> json) =>
      _$UserProgressFromJson(json);
}

@freezed
class Achievement with _$Achievement {
  const factory Achievement({
    required String id,
    required String userId,
    required String achievementKey,
    required String title,
    String? description,
    @Default(0) int pointsReward,
    DateTime? unlockedAt,
    @Default(true) bool isNew,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);
}

@freezed
class DailyStats with _$DailyStats {
  const factory DailyStats({
    required String id,
    @Default('default') String userId,
    required String date,
    @Default(0) int tasksPlanned,
    @Default(0) int tasksDone,
    @Default(0) int tasksPostponed,
    @Default(0) int tasksMissed,
    @Default(0) int tasksDelegated,
    @Default(0) int focusTimeMinutes,
    @Default(0) int focusSessionsCount,
    @Default(0) int emailsProcessed,
    @Default(0) int notificationsReceived,
    @Default(0) int meetingsCount,
    @Default(0) int inboxZero,
    @Default(0) int pointsEarned,
    @Default(0) int aiInterventionsCount,
    @Default(0) int userAutonomousActions,
    @Default(0) int adsShown,
    @Default(0) int apiRequestsCount,
    @Default(0) int apiTokensUsed,
  }) = _DailyStats;

  factory DailyStats.fromJson(Map<String, dynamic> json) =>
      _$DailyStatsFromJson(json);
}
