import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/task.dart';
import '../../data/models/settings.dart';

class AIService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Uuid _uuid = const Uuid();

  String? _cachedApiKey;
  String? _cachedBaseUrl;
  String? _cachedModel;

  Future<Map<String, String>> _getApiConfig() async {
    if (_cachedApiKey != null) {
      return {
        'key': _cachedApiKey!,
        'url': _cachedBaseUrl ?? AppConstants.defaultApiBaseUrl,
        'model': _cachedModel ?? AppConstants.defaultApiModel,
      };
    }

    // Try custom key first
    final customKey = await _storage.read(key: 'api_key_deepseek');
    if (customKey != null && customKey.isNotEmpty) {
      final baseUrl = await _storage.read(key: 'base_url_deepseek') ??
          AppConstants.defaultApiBaseUrl;
      final model = await _storage.read(key: 'model_deepseek') ??
          AppConstants.defaultApiModel;
      _cachedApiKey = customKey;
      _cachedBaseUrl = baseUrl;
      _cachedModel = model;
      return {'key': customKey, 'url': baseUrl, 'model': model};
    }

    // No key configured, return defaults
    _cachedApiKey = '';
    _cachedBaseUrl = AppConstants.defaultApiBaseUrl;
    _cachedModel = AppConstants.defaultApiModel;
    return {
      'key': '',
      'url': AppConstants.defaultApiBaseUrl,
      'model': AppConstants.defaultApiModel,
    };
  }

  Future<AIPlan> generateDailyPlan({
    required List<Task> yesterdayTasks,
    required List<Map<String, dynamic>> emails,
    required List<Map<String, dynamic>> notifications,
    required List<Map<String, dynamic>> meetings,
    required String userLevel,
    required String learningStage,
    required String productiveHours,
    required String commonMistakes,
  }) async {
    final config = await _getApiConfig();

    final systemPrompt = '''
Ты — опытный менеджер и наставник по продуктивности. 
Твоя задача — проанализировать входящие данные пользователя и составить план на день. 
Для КАЖДОЙ задачи ты ДОЛЖЕН: 
1) Сформулировать по SMART, 
2) Определить квадрант Эйзенхауэра с обоснованием, 
3) Предложить временной блок, 
4) Объяснить почему именно так — в 2-3 предложениях. 
Ответ ТОЛЬКО в JSON.
''';

    final userPrompt = '''
Составь план на день. Данные пользователя:

Незавершённые задачи вчера:
${yesterdayTasks.map((t) => '- ${t.title} (${t.quadrant})').join('\n')}

Новые письма (${emails.length}):
${emails.map((e) => '- ${e['subject']}').join('\n')}

Уведомления (${notifications.length}):
${notifications.map((n) => '- ${n['text']}').join('\n')}

Совещания сегодня:
${meetings.map((m) => '- ${m['title']} (${m['time']})').join('\n')}

Статистика пользователя:
- Уровень: $userLevel
- Этап обучения: $learningStage
- Обычно работает: $productiveHours
- Частые ошибки: $commonMistakes
''';

    try {
      final response = await _dio.post(
        '${config['url']}/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${config['key']}',
          'Content-Type': 'application/json',
        }),
        data: jsonEncode({
          'model': config['model'],
          'messages': [
            {'role': 'system', 'content': '${systemPrompt}\n\nВАЖНО: Верни ТОЛЬКО валидный JSON без дополнительного текста и без markdown-разметки.'},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.3,
        }),
      );

      final content = response.data['choices'][0]['message']['content'];
      // Clean response from possible markdown formatting
      final cleaned = content.replaceAll(RegExp(r'```(json)?\s*'), '').trim();
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      final planItems = (parsed['plan'] as List)
          .map((item) => AIPlanItem(
                title: item['title'],
                quadrant: item['quadrant'],
                quadrantReason: item['quadrant_reason'],
                timeBlock: item['time_block'],
                timeReason: item['time_reason'],
                context: item['context'],
                explanation: item['explanation'],
                learningPoint: item['learning_point'],
                sourceId: item['source_id'],
                sourceType: item['source_type'],
              ))
          .toList();

      return AIPlan(
        plan: planItems,
        overallStrategy: parsed['overall_strategy'] ?? '',
        learningTip: parsed['learning_tip'] ?? '',
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      // Return fallback plan if API fails
      return AIPlan(
        plan: [
          AIPlanItem(
            title: 'Проанализировать входящие и расставить приоритеты',
            quadrant: 'important-not-urgent',
            quadrantReason: 'Начни день с планирования — это важно для продуктивности',
            timeBlock: '09:00-09:30',
            timeReason: 'Утро — лучшее время для стратегического планирования',
            context: 'Ежедневная рутина',
            explanation: 'Планирование задаёт вектор на весь день',
            learningPoint: 'Всегда начинай день с плана, а не с проверки почты',
          ),
        ],
        overallStrategy: 'Сфокусируйся на важном, не отвлекайся на срочное',
        learningTip: 'Попробуй технику "Съешь лягушку" — начни с самой сложной задачи',
        generatedAt: DateTime.now(),
      );
    }
  }

  Future<SmartCheckResult> checkSmart({
    required String title,
    String? description,
    String? quadrant,
    DateTime? deadline,
    String? userLevel,
  }) async {
    final config = await _getApiConfig();

    final systemPrompt = '''
Ты — наставник по продуктивности. Пользователь ставит задачу сам. 
Проверь её по критериям SMART. Тон: поддерживающий, конструктивный. 
Если задача хорошая — похвали конкретно. Ответ ТОЛЬКО в JSON.
''';

    final userPrompt = '''
Проверь задачу пользователя:

Заголовок: $title
Описание: ${description ?? 'нет'}
Квадрант: ${quadrant ?? 'не указан'}
Дедлайн: ${deadline?.toIso8601String() ?? 'не указан'}
Уровень пользователя: ${userLevel ?? 'novice'}
''';

    try {
      final response = await _dio.post(
        '${config['url']}/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${config['key']}',
          'Content-Type': 'application/json',
        }),
        data: jsonEncode({
          'model': config['model'],
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.2,
        }),
      );

      final content = response.data['choices'][0]['message']['content'];
      final cleaned = content.replaceAll(RegExp(r'```(json)?\s*'), '').trim();
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

      return SmartCheckResult(
        isValid: parsed['is_valid'] ?? false,
        score: parsed['score'] ?? 0,
        specific: SmartCheckItem(
          valid: parsed['smart_check']['specific']['valid'],
          comment: parsed['smart_check']['specific']['comment'],
        ),
        measurable: SmartCheckItem(
          valid: parsed['smart_check']['measurable']['valid'],
          comment: parsed['smart_check']['measurable']['comment'],
        ),
        achievable: SmartCheckItem(
          valid: parsed['smart_check']['achievable']['valid'],
          comment: parsed['smart_check']['achievable']['comment'],
        ),
        relevant: SmartCheckItem(
          valid: parsed['smart_check']['relevant']['valid'],
          comment: parsed['smart_check']['relevant']['comment'],
        ),
        timeBound: SmartCheckItem(
          valid: parsed['smart_check']['time_bound']['valid'],
          comment: parsed['smart_check']['time_bound']['comment'],
        ),
        improvedVersion: parsed['improved_version'] ?? title,
        learningPoints: List<String>.from(parsed['learning_points'] ?? []),
        praise: parsed['praise'],
      );
    } catch (e) {
      // Fallback local check
      return _localSmartCheck(title, description, deadline);
    }
  }

  SmartCheckResult _localSmartCheck(
      String title, String? description, DateTime? deadline) {
    final specific = SmartCheckItem(
      valid: title.split(' ').length >= 3,
      comment: title.split(' ').length < 3
          ? 'Слишком коротко. Добавь больше деталей'
          : 'Хорошая формулировка',
    );
    final measurable = SmartCheckItem(
      valid: title.contains(RegExp(r'\d+')) || (description?.contains(RegExp(r'\d+')) ?? false),
      comment: 'Добавь числовой критерий: сколько, какой результат',
    );
    final achievable = SmartCheckItem(
      valid: true,
      comment: 'В пределах возможностей',
    );
    final relevant = SmartCheckItem(
      valid: true,
      comment: 'Актуальная задача',
    );
    final timeBound = SmartCheckItem(
      valid: deadline != null,
      comment: deadline == null ? 'Добавь дедлайн' : 'Дедлайн установлен',
    );

    final score = [
      specific.valid,
      measurable.valid,
      achievable.valid,
      relevant.valid,
      timeBound.valid,
    ].where((v) => v).length * 20;

    return SmartCheckResult(
      isValid: score >= 80,
      score: score,
      specific: specific,
      measurable: measurable,
      achievable: achievable,
      relevant: relevant,
      timeBound: timeBound,
      improvedVersion: title,
      learningPoints: [
        'Начинай задачу с глагола: Согласовать, Написать, Проверить',
        'Добавь результат: что будет готово к концу задачи?',
        'Всегда ставь дедлайн — даже примерный',
      ],
    );
  }

  Future<Map<String, dynamic>> analyzeMeeting({
    required String meetingTitle,
    required DateTime meetingDate,
    String? participants,
    required String transcriptText,
  }) async {
    final config = await _getApiConfig();

    final systemPrompt = '''
Ты — секретарь совещания. Проанализируй транскрипт и выдели структурированный конспект. 
Для каждого action item укажи: SMART-задачу, ответственного, дедлайн, контекст. 
Ответ ТОЛЬКО в JSON.
''';

    final userPrompt = '''
Проанализируй транскрипт совещания:

Название: $meetingTitle
Дата: ${meetingDate.toIso8601String()}
Участники: ${participants ?? 'не указаны'}

Транскрипт:
$transcriptText
''';

    try {
      final response = await _dio.post(
        '${config['url']}/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${config['key']}',
          'Content-Type': 'application/json',
        }),
        data: jsonEncode({
          'model': config['model'],
          'messages': [
            {'role': 'system', 'content': '${systemPrompt}\n\nВАЖНО: Верни ТОЛЬКО валидный JSON без дополнительного текста и без markdown-разметки.'},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.3,
        }),
      );

      final content = response.data['choices'][0]['message']['content'];
      final cleaned = content.replaceAll(RegExp(r'```(json)?\s*'), '').trim();
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      return {
        'summary': 'Не удалось проанализировать совещание',
        'decisions': [],
        'action_items': [],
        'open_questions': [],
        'meeting_quality': 'Не оценено',
      };
    }
  }

  Future<Map<String, dynamic>> classifyInbox({
    required String sourceType,
    required String sender,
    required String subject,
    required String body,
  }) async {
    final config = await _getApiConfig();

    final systemPrompt = '''
Ты — фильтр входящих. Классифицируй сообщение по матрице Эйзенхауэра. 
Ответ ТОЛЬКО JSON.
''';

    final userPrompt = '''
Тип: $sourceType
Отправитель: $sender
Тема: $subject
Текст: $body
''';

    try {
      final response = await _dio.post(
        '${config['url']}/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${config['key']}',
          'Content-Type': 'application/json',
        }),
        data: jsonEncode({
          'model': config['model'],
          'messages': [
            {'role': 'system', 'content': '${systemPrompt}\n\nВАЖНО: Верни ТОЛЬКО валидный JSON без дополнительного текста и без markdown-разметки.'},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.2,
        }),
      );

      final content = response.data['choices'][0]['message']['content'];
      final cleaned = content.replaceAll(RegExp(r'```(json)?\s*'), '').trim();
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      return {
        'category': 'not-urgent-not-important',
        'confidence': 0.5,
        'summary': body.length > 100 ? '${body.substring(0, 100)}...' : body,
        'is_spam': false,
      };
    }
  }

  Future<Map<String, dynamic>> dailyDebrief({
    required int planned,
    required int done,
    required int postponed,
    required int missed,
    required int focusMinutes,
    required int emailsProcessed,
    required int meetingsCount,
    required String tasksList,
    required String focusHistory,
    required String mistakesToday,
    required String userLevel,
    required String learningStage,
  }) async {
    final config = await _getApiConfig();

    final systemPrompt = '''
Ты — наставник. Проведи разбор дня с пользователем. 
Тон: поддерживающий, не осуждающий, конструктивный. 
Найди 1 конкретное, что сделано хорошо. Найди 1 конкретное, что улучшить. 
Дай 1 упражнение на завтра. Ответ ТОЛЬКО в JSON.
''';

    final userPrompt = '''
Проведи разбор дня.

Статистика:
- Запланировано: $planned
- Выполнено: $done
- Перенесено: $postponed
- Пропущено: $missed
- Фокус: $focusMinutes мин
- Писем: $emailsProcessed
- Совещаний: $meetingsCount

Задачи:
$tasksList

История фокуса:
$focusHistory

Ошибки сегодня:
$mistakesToday

Уровень пользователя: $userLevel
Этап: $learningStage
''';

    try {
      final response = await _dio.post(
        '${config['url']}/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${config['key']}',
          'Content-Type': 'application/json',
        }),
        data: jsonEncode({
          'model': config['model'],
          'messages': [
            {'role': 'system', 'content': '${systemPrompt}\n\nВАЖНО: Верни ТОЛЬКО валидный JSON без дополнительного текста и без markdown-разметки.'},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.4,
        }),
      );

      final content = response.data['choices'][0]['message']['content'];
      final cleaned = content.replaceAll(RegExp(r'```(json)?\s*'), '').trim();
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      return {
        'summary': 'День прошёл продуктивно. Завтра будет ещё лучше!',
        'good': 'Ты выполнил $done из $planned задач — это отличный результат',
        'improve': 'Попробуй завтра начать с самой сложной задачи',
        'exercise': '24-часовой тест: спроси себя "Будет ли это важно завтра?"',
        'plan_tomorrow': ['Главная задача на завтра', 'Вторая задача', 'Третья задача'],
        'points_earned': done * 10,
      };
    }
  }

  Future<Map<String, dynamic>> processVoiceCommand(String voiceText) async {
    final config = await _getApiConfig();

    final systemPrompt = '''
Пользователь говорит голосовую команду. Преобразуй в структурированную задачу. 
Если неясно — задай уточняющий вопрос. Ответ ТОЛЬКО JSON.
''';

    try {
      final response = await _dio.post(
        '${config['url']}/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${config['key']}',
          'Content-Type': 'application/json',
        }),
        data: jsonEncode({
          'model': config['model'],
          'messages': [
            {'role': 'system', 'content': '${systemPrompt}\n\nВАЖНО: Верни ТОЛЬКО валидный JSON без дополнительного текста и без markdown-разметки.'},
            {'role': 'user', 'content': 'Команда: \'$voiceText\''},
          ],
          'temperature': 0.2,
        }),
      );

      final content = response.data['choices'][0]['message']['content'];
      final cleaned = content.replaceAll(RegExp(r'```(json)?\s*'), '').trim();
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      return {
        'intent': 'create_task',
        'task': {
          'title': voiceText,
          'context': 'Голосовой ввод',
        },
        'needs_clarification': false,
      };
    }
  }

  Future<Map<String, dynamic>> searchNaturalLanguage(String query) async {
    final config = await _getApiConfig();

    final systemPrompt = '''
Пользователь ищет информацию естественным языком. 
Сформируй структурированный запрос и объясни, что ищем. 
Ответ ТОЛЬКО JSON.
''';

    try {
      final response = await _dio.post(
        '${config['url']}/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${config['key']}',
          'Content-Type': 'application/json',
        }),
        data: jsonEncode({
          'model': config['model'],
          'messages': [
            {'role': 'system', 'content': '${systemPrompt}\n\nВАЖНО: Верни ТОЛЬКО валидный JSON без дополнительного текста и без markdown-разметки.'},
            {
              'role': 'user',
              'content':
                  'Поиск: \'$query\'\n\nДоступные источники: задачи, письма, совещания, сообщения.',
            },
          ],
          'temperature': 0.2,
        }),
      );

      final content = response.data['choices'][0]['message']['content'];
      final cleaned = content.replaceAll(RegExp(r'```(json)?\s*'), '').trim();
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      return {
        'search_intent': 'Найти: $query',
        'keywords': query.split(' '),
        'sources_to_search': ['tasks', 'emails', 'transcripts'],
        'time_range': 'last_30_days',
      };
    }
  }

  Future<bool> testConnection(String apiKey, String baseUrl) async {
    try {
      final response = await _dio.post(
        '$baseUrl/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        }),
        data: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'user', 'content': 'Hi'},
          ],
          'max_tokens': 5,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void clearCache() {
    _cachedApiKey = null;
    _cachedBaseUrl = null;
    _cachedModel = null;
  }

  Future<int> getTodayApiRequests() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final usages = await DatabaseHelper.getApiUsage('default',
        from: startOfDay);
    return usages.length;
  }
}
