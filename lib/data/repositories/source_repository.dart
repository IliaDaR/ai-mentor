import '../models/source.dart';
import '../database/database_helper.dart';

/// Репозиторий для работы с источниками входящих (email, уведомления)
class SourceRepository {
  Future<int> insertSource(Source source) => DatabaseHelper.insertSource(source);
  Future<List<Source>> getSources({bool? isSpam}) =>
      DatabaseHelper.getSources(isSpam: isSpam);
}
