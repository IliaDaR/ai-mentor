import '../models/source.dart';
import '../database/database_helper.dart';

/// Репозиторий для работы с транскриптами встреч
class TranscriptRepository {
  Future<int> insertTranscript(Transcript transcript) =>
      DatabaseHelper.insertTranscript(transcript);
  Future<List<Transcript>> getTranscripts() =>
      DatabaseHelper.getTranscripts();
}
