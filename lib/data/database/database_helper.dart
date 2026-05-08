import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';
import '../models/task.dart';
import '../models/user_progress.dart';
import '../models/source.dart';
import '../models/settings.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        quadrant TEXT NOT NULL,
        priority INTEGER NOT NULL DEFAULT 3,
        deadline INTEGER,
        estimated_time_minutes INTEGER,
        status TEXT NOT NULL DEFAULT 'pending',
        source TEXT NOT NULL DEFAULT 'manual',
        source_id TEXT,
        delegated_to TEXT,
        time_block_start INTEGER,
        time_block_end INTEGER,
        is_smart_compliant INTEGER NOT NULL DEFAULT 0,
        smart_score INTEGER NOT NULL DEFAULT 0,
        tags TEXT,
        created_at INTEGER NOT NULL,
        completed_at INTEGER,
        ai_explanation TEXT,
        user_correction TEXT,
        learning_stage TEXT NOT NULL DEFAULT 'stage1',
        user_id TEXT NOT NULL DEFAULT 'default'
      )
    ''');

    await db.execute('''
      CREATE TABLE sources (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        raw_content TEXT,
        ai_summary TEXT,
        ai_category TEXT,
        ai_confidence REAL,
        processed_at INTEGER,
        linked_task_id TEXT,
        metadata TEXT,
        is_spam INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transcripts (
        id TEXT PRIMARY KEY,
        audio_file_path TEXT NOT NULL,
        full_text TEXT,
        ai_summary TEXT,
        ai_action_items TEXT,
        ai_decisions TEXT,
        ai_open_questions TEXT,
        duration_seconds INTEGER,
        recorded_at INTEGER NOT NULL,
        meeting_title TEXT,
        participants TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_progress (
        user_id TEXT PRIMARY KEY DEFAULT 'default',
        current_level TEXT NOT NULL DEFAULT 'novice',
        total_points INTEGER NOT NULL DEFAULT 0,
        current_stage TEXT NOT NULL DEFAULT 'stage1',
        focus_time_total_minutes INTEGER DEFAULT 0,
        tasks_completed INTEGER DEFAULT 0,
        tasks_created INTEGER DEFAULT 0,
        tasks_smart_compliant INTEGER DEFAULT 0,
        meetings_recorded INTEGER DEFAULT 0,
        inbox_zero_days INTEGER DEFAULT 0,
        current_streak_days INTEGER DEFAULT 0,
        longest_streak_days INTEGER DEFAULT 0,
        joined_at INTEGER NOT NULL,
        last_active_at INTEGER,
        is_pro INTEGER DEFAULT 0,
        pro_expires_at INTEGER,
        trial_started_at INTEGER,
        trial_used INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        achievement_key TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        points_reward INTEGER DEFAULT 0,
        unlocked_at INTEGER,
        is_new INTEGER DEFAULT 1,
        UNIQUE(user_id, achievement_key)
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_stats (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        tasks_planned INTEGER DEFAULT 0,
        tasks_done INTEGER DEFAULT 0,
        tasks_postponed INTEGER DEFAULT 0,
        tasks_missed INTEGER DEFAULT 0,
        tasks_delegated INTEGER DEFAULT 0,
        focus_time_minutes INTEGER DEFAULT 0,
        focus_sessions_count INTEGER DEFAULT 0,
        emails_processed INTEGER DEFAULT 0,
        notifications_received INTEGER DEFAULT 0,
        meetings_count INTEGER DEFAULT 0,
        inbox_zero INTEGER DEFAULT 0,
        points_earned INTEGER DEFAULT 0,
        ai_interventions_count INTEGER DEFAULT 0,
        user_autonomous_actions INTEGER DEFAULT 0,
        ads_shown INTEGER DEFAULT 0,
        api_requests_count INTEGER DEFAULT 0,
        api_tokens_used INTEGER DEFAULT 0,
        UNIQUE(user_id, date)
      )
    ''');

    await db.execute('''
      CREATE TABLE api_usage (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        provider TEXT NOT NULL,
        model TEXT,
        request_type TEXT NOT NULL,
        tokens_input INTEGER DEFAULT 0,
        tokens_output INTEGER DEFAULT 0,
        cost_estimate REAL DEFAULT 0,
        timestamp INTEGER NOT NULL,
        success INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        user_id TEXT PRIMARY KEY DEFAULT 'default',
        daily_plan_time TEXT DEFAULT '08:00',
        debrief_time TEXT DEFAULT '18:00',
        focus_default_duration INTEGER DEFAULT 50,
        monk_mode_enabled INTEGER DEFAULT 1,
        auto_start_meeting_recording INTEGER DEFAULT 1,
        email_sync_interval_minutes INTEGER DEFAULT 15,
        theme TEXT DEFAULT 'system',
        notifications_enabled INTEGER DEFAULT 1,
        sound_enabled INTEGER DEFAULT 1,
        haptic_enabled INTEGER DEFAULT 1,
        api_provider TEXT DEFAULT 'deepseek',
        api_model TEXT DEFAULT 'deepseek-chat',
        api_base_url TEXT,
        imap_server TEXT,
        imap_port INTEGER DEFAULT 993,
        imap_username TEXT,
        smtp_server TEXT,
        smtp_port INTEGER DEFAULT 587,
        smtp_username TEXT,
        ldap_server TEXT,
        ad_limit_daily REAL DEFAULT 1.0,
        ad_banner_position TEXT DEFAULT 'bottom'
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_tasks_quadrant ON tasks(quadrant)');
    await db.execute('CREATE INDEX idx_tasks_status ON tasks(status)');
    await db.execute('CREATE INDEX idx_tasks_deadline ON tasks(deadline)');
    await db.execute('CREATE INDEX idx_tasks_source ON tasks(source, source_id)');
    await db.execute('CREATE INDEX idx_sources_category ON sources(ai_category)');
    await db.execute('CREATE INDEX idx_sources_task ON sources(linked_task_id)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations
  }

  // ========== TASKS ==========

  static Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', _taskToMap(task));
  }

  static Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      _taskToMap(task),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  static Future<int> deleteTask(String id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Task?> getTask(String id) async {
    final db = await database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _taskFromMap(maps.first);
  }

  static Future<List<Task>> getTasks({
    String? quadrant,
    String? status,
    String? searchQuery,
    bool? onlyToday,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (quadrant != null) {
      where.add('quadrant = ?');
      args.add(quadrant);
    }
    if (status != null) {
      where.add('status = ?');
      args.add(status);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      where.add('(title LIKE ? OR description LIKE ?)');
      args.addAll(['%$searchQuery%', '%$searchQuery%']);
    }
    if (onlyToday == true) {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      where.add('created_at >= ? AND created_at < ?');
      args.addAll([startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch]);
    }

    final maps = await db.query(
      'tasks',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'priority ASC, created_at DESC',
    );
    return maps.map(_taskFromMap).toList();
  }

  static Future<List<Task>> getTasksByQuadrant(String quadrant) async {
    return getTasks(quadrant: quadrant);
  }

  static Future<List<Task>> getTasksByStatus(String status) async {
    return getTasks(status: status);
  }

  static Future<int> getTaskCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM tasks');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ========== USER PROGRESS ==========

  static Future<UserProgress?> getUserProgress(String userId) async {
    final db = await database;
    final maps = await db.query(
      'user_progress',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (maps.isEmpty) return null;
    return _userProgressFromMap(maps.first);
  }

  static Future<int> insertOrUpdateUserProgress(UserProgress progress) async {
    final db = await database;
    final existing = await getUserProgress(progress.userId);
    if (existing != null) {
      return await db.update(
        'user_progress',
        _userProgressToMap(progress),
        where: 'user_id = ?',
        whereArgs: [progress.userId],
      );
    }
    return await db.insert('user_progress', _userProgressToMap(progress));
  }

  static Future<int> addPoints(String userId, int points) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE user_progress SET total_points = total_points + ? WHERE user_id = ?',
      [points, userId],
    );
  }

  // ========== SOURCES ==========

  static Future<int> insertSource(Source source) async {
    final db = await database;
    return await db.insert('sources', _sourceToMap(source));
  }

  static Future<List<Source>> getSources({bool? isSpam}) async {
    final db = await database;
    final where = isSpam != null ? 'is_spam = ?' : null;
    final args = isSpam != null ? [isSpam ? 1 : 0] : null;
    final maps = await db.query(
      'sources',
      where: where,
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return maps.map(_sourceFromMap).toList();
  }

  // ========== TRANSCRIPTS ==========

  static Future<int> insertTranscript(Transcript transcript) async {
    final db = await database;
    return await db.insert('transcripts', _transcriptToMap(transcript));
  }

  static Future<List<Transcript>> getTranscripts() async {
    final db = await database;
    final maps = await db.query('transcripts', orderBy: 'recorded_at DESC');
    return maps.map(_transcriptFromMap).toList();
  }

  // ========== ACHIEVEMENTS ==========

  static Future<List<Achievement>> getAchievements(String userId) async {
    final db = await database;
    final maps = await db.query(
      'achievements',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'unlocked_at DESC',
    );
    return maps.map(_achievementFromMap).toList();
  }

  static Future<int> insertAchievement(Achievement achievement) async {
    final db = await database;
    return await db.insert('achievements', _achievementToMap(achievement));
  }

  // ========== DAILY STATS ==========

  static Future<DailyStats?> getDailyStats(String userId, String date) async {
    final db = await database;
    final maps = await db.query(
      'daily_stats',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );
    if (maps.isEmpty) return null;
    return _dailyStatsFromMap(maps.first);
  }

  static Future<int> updateDailyStats(DailyStats stats) async {
    final db = await database;
    final existing = await getDailyStats(stats.userId, stats.date);
    if (existing != null) {
      return await db.update(
        'daily_stats',
        _dailyStatsToMap(stats),
        where: 'user_id = ? AND date = ?',
        whereArgs: [stats.userId, stats.date],
      );
    }
    return await db.insert('daily_stats', _dailyStatsToMap(stats));
  }

  // ========== SETTINGS ==========

  static Future<AppSettings?> getSettings(String userId) async {
    final db = await database;
    final maps = await db.query(
      'settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (maps.isEmpty) return null;
    return _settingsFromMap(maps.first);
  }

  static Future<int> saveSettings(AppSettings settings) async {
    final db = await database;
    final existing = await getSettings(settings.userId);
    if (existing != null) {
      return await db.update(
        'settings',
        _settingsToMap(settings),
        where: 'user_id = ?',
        whereArgs: [settings.userId],
      );
    }
    return await db.insert('settings', _settingsToMap(settings));
  }

  // ========== API USAGE ==========

  static Future<int> logApiUsage(ApiUsage usage) async {
    final db = await database;
    return await db.insert('api_usage', _apiUsageToMap(usage));
  }

  static Future<List<ApiUsage>> getApiUsage(String userId, {DateTime? from}) async {
    final db = await database;
    final where = <String>['user_id = ?'];
    final args = <dynamic>[userId];
    if (from != null) {
      where.add('timestamp >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    final maps = await db.query(
      'api_usage',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'timestamp DESC',
    );
    return maps.map(_apiUsageFromMap).toList();
  }

  // ========== CONVERTERS ==========

  static Map<String, dynamic> _taskToMap(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'quadrant': task.quadrant,
      'priority': task.priority,
      'deadline': task.deadline?.millisecondsSinceEpoch,
      'estimated_time_minutes': task.estimatedTimeMinutes,
      'status': task.status,
      'source': task.source,
      'source_id': task.sourceId,
      'delegated_to': task.delegatedTo,
      'time_block_start': task.timeBlockStart?.millisecondsSinceEpoch,
      'time_block_end': task.timeBlockEnd?.millisecondsSinceEpoch,
      'is_smart_compliant': task.isSmartCompliant ? 1 : 0,
      'smart_score': task.smartScore,
      'tags': task.tags,
      'created_at': task.createdAt.millisecondsSinceEpoch,
      'completed_at': task.completedAt?.millisecondsSinceEpoch,
      'ai_explanation': task.aiExplanation,
      'user_correction': task.userCorrection,
      'learning_stage': task.learningStage,
      'user_id': task.userId,
    };
  }

  static Task _taskFromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      quadrant: map['quadrant'] as String,
      priority: map['priority'] as int? ?? 3,
      deadline: map['deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int)
          : null,
      estimatedTimeMinutes: map['estimated_time_minutes'] as int?,
      status: map['status'] as String? ?? 'pending',
      source: map['source'] as String? ?? 'manual',
      sourceId: map['source_id'] as String?,
      delegatedTo: map['delegated_to'] as String?,
      timeBlockStart: map['time_block_start'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['time_block_start'] as int)
          : null,
      timeBlockEnd: map['time_block_end'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['time_block_end'] as int)
          : null,
      isSmartCompliant: (map['is_smart_compliant'] as int?) == 1,
      smartScore: map['smart_score'] as int? ?? 0,
      tags: map['tags'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
      aiExplanation: map['ai_explanation'] as String?,
      userCorrection: map['user_correction'] as String?,
      learningStage: map['learning_stage'] as String? ?? 'stage1',
      userId: map['user_id'] as String? ?? 'default',
    );
  }

  static Map<String, dynamic> _userProgressToMap(UserProgress progress) {
    return {
      'user_id': progress.userId,
      'current_level': progress.currentLevel,
      'total_points': progress.totalPoints,
      'current_stage': progress.currentStage,
      'focus_time_total_minutes': progress.focusTimeTotalMinutes,
      'tasks_completed': progress.tasksCompleted,
      'tasks_created': progress.tasksCreated,
      'tasks_smart_compliant': progress.tasksSmartCompliant,
      'meetings_recorded': progress.meetingsRecorded,
      'inbox_zero_days': progress.inboxZeroDays,
      'current_streak_days': progress.currentStreakDays,
      'longest_streak_days': progress.longestStreakDays,
      'joined_at': progress.joinedAt.millisecondsSinceEpoch,
      'last_active_at': progress.lastActiveAt?.millisecondsSinceEpoch,
      'is_pro': progress.isPro ? 1 : 0,
      'pro_expires_at': progress.proExpiresAt?.millisecondsSinceEpoch,
      'trial_started_at': progress.trialStartedAt?.millisecondsSinceEpoch,
      'trial_used': progress.trialUsed ? 1 : 0,
    };
  }

  static UserProgress _userProgressFromMap(Map<String, dynamic> map) {
    return UserProgress(
      userId: map['user_id'] as String? ?? 'default',
      currentLevel: map['current_level'] as String? ?? 'novice',
      totalPoints: map['total_points'] as int? ?? 0,
      currentStage: map['current_stage'] as String? ?? 'stage1',
      focusTimeTotalMinutes: map['focus_time_total_minutes'] as int? ?? 0,
      tasksCompleted: map['tasks_completed'] as int? ?? 0,
      tasksCreated: map['tasks_created'] as int? ?? 0,
      tasksSmartCompliant: map['tasks_smart_compliant'] as int? ?? 0,
      meetingsRecorded: map['meetings_recorded'] as int? ?? 0,
      inboxZeroDays: map['inbox_zero_days'] as int? ?? 0,
      currentStreakDays: map['current_streak_days'] as int? ?? 0,
      longestStreakDays: map['longest_streak_days'] as int? ?? 0,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(map['joined_at'] as int),
      lastActiveAt: map['last_active_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_active_at'] as int)
          : null,
      isPro: (map['is_pro'] as int?) == 1,
      proExpiresAt: map['pro_expires_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['pro_expires_at'] as int)
          : null,
      trialStartedAt: map['trial_started_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['trial_started_at'] as int)
          : null,
      trialUsed: (map['trial_used'] as int?) == 1,
    );
  }

  static Map<String, dynamic> _sourceToMap(Source source) {
    return {
      'id': source.id,
      'type': source.type,
      'raw_content': source.rawContent,
      'ai_summary': source.aiSummary,
      'ai_category': source.aiCategory,
      'ai_confidence': source.aiConfidence,
      'processed_at': source.processedAt?.millisecondsSinceEpoch,
      'linked_task_id': source.linkedTaskId,
      'metadata': source.metadata,
      'is_spam': source.isSpam ? 1 : 0,
      'created_at': source.createdAt.millisecondsSinceEpoch,
    };
  }

  static Source _sourceFromMap(Map<String, dynamic> map) {
    return Source(
      id: map['id'] as String,
      type: map['type'] as String,
      rawContent: map['raw_content'] as String?,
      aiSummary: map['ai_summary'] as String?,
      aiCategory: map['ai_category'] as String?,
      aiConfidence: map['ai_confidence'] as double?,
      processedAt: map['processed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['processed_at'] as int)
          : null,
      linkedTaskId: map['linked_task_id'] as String?,
      metadata: map['metadata'] as String?,
      isSpam: (map['is_spam'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  static Map<String, dynamic> _transcriptToMap(Transcript transcript) {
    return {
      'id': transcript.id,
      'audio_file_path': transcript.audioFilePath,
      'full_text': transcript.fullText,
      'ai_summary': transcript.aiSummary,
      'ai_action_items': transcript.aiActionItems,
      'ai_decisions': transcript.aiDecisions,
      'ai_open_questions': transcript.aiOpenQuestions,
      'duration_seconds': transcript.durationSeconds,
      'recorded_at': transcript.recordedAt.millisecondsSinceEpoch,
      'meeting_title': transcript.meetingTitle,
      'participants': transcript.participants,
    };
  }

  static Transcript _transcriptFromMap(Map<String, dynamic> map) {
    return Transcript(
      id: map['id'] as String,
      audioFilePath: map['audio_file_path'] as String,
      fullText: map['full_text'] as String?,
      aiSummary: map['ai_summary'] as String?,
      aiActionItems: map['ai_action_items'] as String?,
      aiDecisions: map['ai_decisions'] as String?,
      aiOpenQuestions: map['ai_open_questions'] as String?,
      durationSeconds: map['duration_seconds'] as int?,
      recordedAt: DateTime.fromMillisecondsSinceEpoch(map['recorded_at'] as int),
      meetingTitle: map['meeting_title'] as String?,
      participants: map['participants'] as String?,
    );
  }

  static Map<String, dynamic> _achievementToMap(Achievement achievement) {
    return {
      'id': achievement.id,
      'user_id': achievement.userId,
      'achievement_key': achievement.achievementKey,
      'title': achievement.title,
      'description': achievement.description,
      'points_reward': achievement.pointsReward,
      'unlocked_at': achievement.unlockedAt?.millisecondsSinceEpoch,
      'is_new': achievement.isNew ? 1 : 0,
    };
  }

  static Achievement _achievementFromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      achievementKey: map['achievement_key'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      pointsReward: map['points_reward'] as int? ?? 0,
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['unlocked_at'] as int)
          : null,
      isNew: (map['is_new'] as int?) == 1,
    );
  }

  static Map<String, dynamic> _dailyStatsToMap(DailyStats stats) {
    return {
      'id': stats.id,
      'user_id': stats.userId,
      'date': stats.date,
      'tasks_planned': stats.tasksPlanned,
      'tasks_done': stats.tasksDone,
      'tasks_postponed': stats.tasksPostponed,
      'tasks_missed': stats.tasksMissed,
      'tasks_delegated': stats.tasksDelegated,
      'focus_time_minutes': stats.focusTimeMinutes,
      'focus_sessions_count': stats.focusSessionsCount,
      'emails_processed': stats.emailsProcessed,
      'notifications_received': stats.notificationsReceived,
      'meetings_count': stats.meetingsCount,
      'inbox_zero': stats.inboxZero,
      'points_earned': stats.pointsEarned,
      'ai_interventions_count': stats.aiInterventionsCount,
      'user_autonomous_actions': stats.userAutonomousActions,
      'ads_shown': stats.adsShown,
      'api_requests_count': stats.apiRequestsCount,
      'api_tokens_used': stats.apiTokensUsed,
    };
  }

  static DailyStats _dailyStatsFromMap(Map<String, dynamic> map) {
    return DailyStats(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? 'default',
      date: map['date'] as String,
      tasksPlanned: map['tasks_planned'] as int? ?? 0,
      tasksDone: map['tasks_done'] as int? ?? 0,
      tasksPostponed: map['tasks_postponed'] as int? ?? 0,
      tasksMissed: map['tasks_missed'] as int? ?? 0,
      tasksDelegated: map['tasks_delegated'] as int? ?? 0,
      focusTimeMinutes: map['focus_time_minutes'] as int? ?? 0,
      focusSessionsCount: map['focus_sessions_count'] as int? ?? 0,
      emailsProcessed: map['emails_processed'] as int? ?? 0,
      notificationsReceived: map['notifications_received'] as int? ?? 0,
      meetingsCount: map['meetings_count'] as int? ?? 0,
      inboxZero: map['inbox_zero'] as int? ?? 0,
      pointsEarned: map['points_earned'] as int? ?? 0,
      aiInterventionsCount: map['ai_interventions_count'] as int? ?? 0,
      userAutonomousActions: map['user_autonomous_actions'] as int? ?? 0,
      adsShown: map['ads_shown'] as int? ?? 0,
      apiRequestsCount: map['api_requests_count'] as int? ?? 0,
      apiTokensUsed: map['api_tokens_used'] as int? ?? 0,
    );
  }

  static Map<String, dynamic> _settingsToMap(AppSettings settings) {
    return {
      'user_id': settings.userId,
      'daily_plan_time': settings.dailyPlanTime,
      'debrief_time': settings.debriefTime,
      'focus_default_duration': settings.focusDefaultDuration,
      'monk_mode_enabled': settings.monkModeEnabled ? 1 : 0,
      'auto_start_meeting_recording': settings.autoStartMeetingRecording ? 1 : 0,
      'email_sync_interval_minutes': settings.emailSyncIntervalMinutes,
      'theme': settings.theme,
      'notifications_enabled': settings.notificationsEnabled ? 1 : 0,
      'sound_enabled': settings.soundEnabled ? 1 : 0,
      'haptic_enabled': settings.hapticEnabled ? 1 : 0,
      'api_provider': settings.apiProvider,
      'api_model': settings.apiModel,
      'api_base_url': settings.apiBaseUrl,
      'imap_server': settings.imapServer,
      'imap_port': settings.imapPort,
      'imap_username': settings.imapUsername,
      'smtp_server': settings.smtpServer,
      'smtp_port': settings.smtpPort,
      'smtp_username': settings.smtpUsername,
      'ldap_server': settings.ldapServer,
      'ad_limit_daily': settings.adLimitDaily,
      'ad_banner_position': settings.adBannerPosition,
    };
  }

  static AppSettings _settingsFromMap(Map<String, dynamic> map) {
    return AppSettings(
      userId: map['user_id'] as String? ?? 'default',
      dailyPlanTime: map['daily_plan_time'] as String? ?? '08:00',
      debriefTime: map['debrief_time'] as String? ?? '18:00',
      focusDefaultDuration: map['focus_default_duration'] as int? ?? 50,
      monkModeEnabled: (map['monk_mode_enabled'] as int?) == 1,
      autoStartMeetingRecording: (map['auto_start_meeting_recording'] as int?) == 1,
      emailSyncIntervalMinutes: map['email_sync_interval_minutes'] as int? ?? 15,
      theme: map['theme'] as String? ?? 'system',
      notificationsEnabled: (map['notifications_enabled'] as int?) == 1,
      soundEnabled: (map['sound_enabled'] as int?) == 1,
      hapticEnabled: (map['haptic_enabled'] as int?) == 1,
      apiProvider: map['api_provider'] as String? ?? 'deepseek',
      apiModel: map['api_model'] as String? ?? 'deepseek-chat',
      apiBaseUrl: map['api_base_url'] as String?,
      imapServer: map['imap_server'] as String?,
      imapPort: map['imap_port'] as int? ?? 993,
      imapUsername: map['imap_username'] as String?,
      smtpServer: map['smtp_server'] as String?,
      smtpPort: map['smtp_port'] as int? ?? 587,
      smtpUsername: map['smtp_username'] as String?,
      ldapServer: map['ldap_server'] as String?,
      adLimitDaily: (map['ad_limit_daily'] as num?)?.toDouble() ?? 1.0,
      adBannerPosition: map['ad_banner_position'] as String? ?? 'bottom',
    );
  }

  static Map<String, dynamic> _apiUsageToMap(ApiUsage usage) {
    return {
      'id': usage.id,
      'user_id': usage.userId,
      'provider': usage.provider,
      'model': usage.model,
      'request_type': usage.requestType,
      'tokens_input': usage.tokensInput,
      'tokens_output': usage.tokensOutput,
      'cost_estimate': usage.costEstimate,
      'timestamp': usage.timestamp.millisecondsSinceEpoch,
      'success': usage.success ? 1 : 0,
    };
  }

  static ApiUsage _apiUsageFromMap(Map<String, dynamic> map) {
    return ApiUsage(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? 'default',
      provider: map['provider'] as String,
      model: map['model'] as String?,
      requestType: map['request_type'] as String,
      tokensInput: map['tokens_input'] as int? ?? 0,
      tokensOutput: map['tokens_output'] as int? ?? 0,
      costEstimate: (map['cost_estimate'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      success: (map['success'] as int?) == 1,
    );
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
