import 'package:freezed_annotation/freezed_annotation.dart';

part 'source.freezed.dart';
part 'source.g.dart';

@freezed
class Source with _$Source {
  const factory Source({
    required String id,
    required String type,
    String? rawContent,
    String? aiSummary,
    String? aiCategory,
    double? aiConfidence,
    DateTime? processedAt,
    String? linkedTaskId,
    String? metadata,
    @Default(false) bool isSpam,
    required DateTime createdAt,
  }) = _Source;

  factory Source.fromJson(Map<String, dynamic> json) => _$SourceFromJson(json);
}

@freezed
class Transcript with _$Transcript {
  const factory Transcript({
    required String id,
    required String audioFilePath,
    String? fullText,
    String? aiSummary,
    String? aiActionItems,
    String? aiDecisions,
    String? aiOpenQuestions,
    int? durationSeconds,
    required DateTime recordedAt,
    String? meetingTitle,
    String? participants,
  }) = _Transcript;

  factory Transcript.fromJson(Map<String, dynamic> json) =>
      _$TranscriptFromJson(json);
}
