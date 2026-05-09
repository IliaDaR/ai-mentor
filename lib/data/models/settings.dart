import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default('default') String userId,
    @Default('08:00') String dailyPlanTime,
    @Default('18:00') String debriefTime,
    @Default(50) int focusDefaultDuration,
    @Default(true) bool monkModeEnabled,
    @Default(true) bool autoStartMeetingRecording,
    @Default(15) int emailSyncIntervalMinutes,
    @Default('system') String theme,
    @Default(true) bool notificationsEnabled,
    @Default(true) bool soundEnabled,
    @Default(true) bool hapticEnabled,
    @Default('deepseek') String apiProvider,
    @Default('deepseek-chat') String apiModel,
    String? apiBaseUrl,
    String? imapServer,
    @Default(993) int imapPort,
    String? imapUsername,
    String? smtpServer,
    @Default(587) int smtpPort,
    String? smtpUsername,
    String? ldapServer,
    @Default(1.0) double adLimitDaily,
    @Default('bottom') String adBannerPosition,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}

@freezed
class ApiUsage with _$ApiUsage {
  const factory ApiUsage({
    required String id,
    @Default('default') String userId,
    required String provider,
    String? model,
    required String requestType,
    @Default(0) int tokensInput,
    @Default(0) int tokensOutput,
    @Default(0.0) double costEstimate,
    required DateTime timestamp,
    @Default(true) bool success,
  }) = _ApiUsage;

  factory ApiUsage.fromJson(Map<String, dynamic> json) =>
      _$ApiUsageFromJson(json);
}
