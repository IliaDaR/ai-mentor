/// Квадранты матрицы Эйзенхауэра
enum TaskQuadrant {
  urgentImportant('urgent-important', 'Срочно-Важно', 0xFFB3261E),
  importantNotUrgent('important-not-urgent', 'Важно-Не срочно', 0xFFF9AB00),
  urgentNotImportant('urgent-not-important', 'Срочно-Неважно', 0xFFE65100),
  notUrgentNotImportant(
      'not-urgent-not-important', 'Неважно', 0xFF757575);

  final String value;
  final String label;
  final int color;
  const TaskQuadrant(this.value, this.label, this.color);
}

/// Статус задачи
enum TaskStatus {
  pending('pending', 'Ожидает'),
  inProgress('in-progress', 'В работе'),
  completed('completed', 'Выполнено'),
  archived('archived', 'Архивировано'),
  delegated('delegated', 'Делегировано');

  final String value;
  final String label;
  const TaskStatus(this.value, this.label);
}

/// Источник задачи
enum TaskSource {
  email('email', 'Почта'),
  meeting('meeting', 'Совещание'),
  notification('notification', 'Уведомление'),
  manual('manual', 'Вручную'),
  shared('shared', 'Общее');

  final String value;
  final String label;
  const TaskSource(this.value, this.label);
}

/// Этап обучения
enum LearningStage {
  stage1('stage1', 'ИИ ведёт'),
  stage2('stage2', 'Совместно'),
  stage3('stage3', 'Проверка'),
  stage4('stage4', 'Автономия'),
  stage5('stage5', 'Наставник');

  final String value;
  final String label;
  const LearningStage(this.value, this.label);
}

/// Уровень пользователя
enum UserLevel {
  novice('novice', '🌱 Новичок', 0, 300),
  apprentice('apprentice', '🌿 Ученик', 300, 800),
  journeyman('journeyman', '🌳 Подмастерье', 800, 1500),
  master('master', '🏆 Мастер', 1500, 3000),
  autonomous('autonomous', '👑 Автоном', 3000, 5000),
  mentor('mentor', '🎓 Наставник', 5000, 999999);

  final String value;
  final String label;
  final int minPoints;
  final int maxPoints;
  const UserLevel(this.value, this.label, this.minPoints, this.maxPoints);

  static UserLevel fromPoints(int points) {
    for (final level in UserLevel.values.reversed) {
      if (points >= level.minPoints) return level;
    }
    return UserLevel.novice;
  }
}

/// Тип источника входящих
enum SourceType {
  email('email'),
  notification('notification'),
  message('message'),
  meeting('meeting');

  final String value;
  const SourceType(this.value);
}

/// Тип рекламы
enum AdType {
  banner,
  interstitial,
  native,
  rewarded,
}

/// Провайдер API
enum ApiProvider {
  deepseek('DeepSeek', 'https://api.deepseek.com/v1', ['deepseek-chat', 'deepseek-reasoner']),
  gigachat('GigaChat', 'https://gigachat.devices.sberbank.ru/api/v1', ['GigaChat']),
  openai('OpenAI', 'https://api.openai.com/v1', ['gpt-4o', 'gpt-3.5-turbo']),
  googleAI('Google AI', 'https://generativelanguage.googleapis.com', ['gemini-pro']),
  anthropic('Anthropic', 'https://api.anthropic.com/v1', ['claude-3-opus', 'claude-3-sonnet']),
  openRouter('OpenRouter', 'https://openrouter.ai/api/v1', ['multiple']),
  ollama('Ollama', 'http://localhost:11434', ['llama2', 'mistral']);

  final String name;
  final String baseUrl;
  final List<String> models;
  const ApiProvider(this.name, this.baseUrl, this.models);
}
