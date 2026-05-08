import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    String? description,
    required String quadrant,
    @Default(3) int priority,
    DateTime? deadline,
    int? estimatedTimeMinutes,
    @Default('pending') String status,
    @Default('manual') String source,
    String? sourceId,
    String? delegatedTo,
    DateTime? timeBlockStart,
    DateTime? timeBlockEnd,
    @Default(false) bool isSmartCompliant,
    @Default(0) int smartScore,
    String? tags,
    required DateTime createdAt,
    DateTime? completedAt,
    String? aiExplanation,
    String? userCorrection,
    @Default('stage1') String learningStage,
    @Default('default') String userId,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}

@freezed
class SmartCheckResult with _$SmartCheckResult {
  const factory SmartCheckResult({
    required bool isValid,
    required int score,
    required SmartCheckItem specific,
    required SmartCheckItem measurable,
    required SmartCheckItem achievable,
    required SmartCheckItem relevant,
    required SmartCheckItem timeBound,
    required String improvedVersion,
    required List<String> learningPoints,
    String? praise,
  }) = _SmartCheckResult;

  factory SmartCheckResult.fromJson(Map<String, dynamic> json) =>
      _$SmartCheckResultFromJson(json);
}

@freezed
class SmartCheckItem with _$SmartCheckItem {
  const factory SmartCheckItem({
    required bool valid,
    required String comment,
  }) = _SmartCheckItem;

  factory SmartCheckItem.fromJson(Map<String, dynamic> json) =>
      _$SmartCheckItemFromJson(json);
}

@freezed
class AIPlan with _$AIPlan {
  const factory AIPlan({
    required List<AIPlanItem> plan,
    required String overallStrategy,
    required String learningTip,
    required DateTime generatedAt,
  }) = _AIPlan;

  factory AIPlan.fromJson(Map<String, dynamic> json) => _$AIPlanFromJson(json);
}

@freezed
class AIPlanItem with _$AIPlanItem {
  const factory AIPlanItem({
    required String title,
    required String quadrant,
    required String quadrantReason,
    required String timeBlock,
    required String timeReason,
    required String context,
    required String explanation,
    required String learningPoint,
    String? sourceId,
    String? sourceType,
  }) = _AIPlanItem;

  factory AIPlanItem.fromJson(Map<String, dynamic> json) =>
      _$AIPlanItemFromJson(json);
}
