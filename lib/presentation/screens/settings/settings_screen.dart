import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/settings.dart';
import '../../../core/constants/enums.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/providers/repository_providers.dart';
import '../../../domain/providers/service_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AppSettings _settings = const AppSettings();
  bool _isLoading = true;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final monetization = ref.read(monetizationServiceProvider);

      final settings = await settingsRepo.getSettings('default');
      final isPro = await monetization.isPro();
      setState(() {
        _settings = settings ?? const AppSettings();
        _isPro = isPro;
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.saveSettings(_settings);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Расписание
          _buildSectionHeader('Расписание'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('План на день'),
                  subtitle: Text('Время: ${_settings.dailyPlanTime}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickTime('dailyPlanTime'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.nightlight_round),
                  title: const Text('Разбор дня'),
                  subtitle: Text('Время: ${_settings.debriefTime}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickTime('debriefTime'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Фокус
          _buildSectionHeader('Режим фокуса'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_fix_high),
                  title: const Text('Режим Монах'),
                  subtitle: const Text('Блокировка отвлекающих уведомлений'),
                  trailing: Switch(
                    value: _settings.monkModeEnabled,
                    onChanged: (val) {
                      setState(() => _settings = _settings.copyWith(monkModeEnabled: val));
                      _saveSettings();
                    },
                  ),
                  onTap: () {
                    setState(() => _settings = _settings.copyWith(monkModeEnabled: !_settings.monkModeEnabled));
                    _saveSettings();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('Длительность фокуса'),
                  subtitle: Text('${_settings.focusDefaultDuration} мин'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickDuration(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Совещания
          _buildSectionHeader('Совещания'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Автостарт записи'),
              subtitle: const Text('Автоматически начинать запись совещаний'),
              trailing: Switch(
                value: _settings.autoStartMeetingRecording,
                onChanged: (val) {
                  setState(() => _settings = _settings.copyWith(autoStartMeetingRecording: val));
                  _saveSettings();
                },
              ),
              onTap: () {
                setState(() => _settings = _settings.copyWith(autoStartMeetingRecording: !_settings.autoStartMeetingRecording));
                _saveSettings();
              },
            ),
          ),
          const SizedBox(height: 24),

          // Уведомления
          _buildSectionHeader('Уведомления'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Уведомления'),
                  trailing: Switch(
                    value: _settings.notificationsEnabled,
                    onChanged: (val) {
                      setState(() => _settings = _settings.copyWith(notificationsEnabled: val));
                      _saveSettings();
                    },
                  ),
                  onTap: () {
                    setState(() => _settings = _settings.copyWith(notificationsEnabled: !_settings.notificationsEnabled));
                    _saveSettings();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.volume_up),
                  title: const Text('Звук'),
                  trailing: Switch(
                    value: _settings.soundEnabled,
                    onChanged: (val) {
                      setState(() => _settings = _settings.copyWith(soundEnabled: val));
                      _saveSettings();
                    },
                  ),
                  onTap: () {
                    setState(() => _settings = _settings.copyWith(soundEnabled: !_settings.soundEnabled));
                    _saveSettings();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.vibration),
                  title: const Text('Тактильный отклик'),
                  trailing: Switch(
                    value: _settings.hapticEnabled,
                    onChanged: (val) {
                      setState(() => _settings = _settings.copyWith(hapticEnabled: val));
                      _saveSettings();
                    },
                  ),
                  onTap: () {
                    setState(() => _settings = _settings.copyWith(hapticEnabled: !_settings.hapticEnabled));
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // API
          _buildSectionHeader('AI Провайдер'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud),
                  title: const Text('Провайдер'),
                  subtitle: Text(_settings.apiProvider.toUpperCase()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectProvider(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.smart_toy),
                  title: const Text('Модель'),
                  subtitle: Text(_settings.apiModel),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectModel(),
                ),
                if (_settings.apiBaseUrl != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('Base URL'),
                    subtitle: Text(_settings.apiBaseUrl!),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editBaseUrl(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Почта
          _buildSectionHeader('IMAP/SMTP'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Синхронизация почты'),
                  trailing: Switch(
                    value: _settings.emailSyncIntervalMinutes > 0,
                    onChanged: (val) {
                      setState(() {
                        _settings = _settings.copyWith(
                          emailSyncIntervalMinutes: val ? 15 : 0,
                        );
                      });
                      _saveSettings();
                    },
                  ),
                  onTap: () {
                    final newVal = _settings.emailSyncIntervalMinutes > 0 ? 0 : 15;
                    setState(() {
                      _settings = _settings.copyWith(emailSyncIntervalMinutes: newVal);
                    });
                    _saveSettings();
                  },
                ),
                if (_settings.emailSyncIntervalMinutes > 0) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Интервал синхронизации'),
                    subtitle: Text('${_settings.emailSyncIntervalMinutes} мин'),
                    onTap: () => _editSyncInterval(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.dns),
                    title: const Text('IMAP сервер'),
                    subtitle: Text(_settings.imapServer ?? 'Не настроен'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editTextSetting('imapServer', 'IMAP сервер', _settings.imapServer ?? ''),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.dns_outlined),
                    title: const Text('SMTP сервер'),
                    subtitle: Text(_settings.smtpServer ?? 'Не настроен'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editTextSetting('smtpServer', 'SMTP сервер', _settings.smtpServer ?? ''),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pro
          _buildSectionHeader('AI-Ментор Pro'),
          Card(
            child: ListTile(
              leading: Icon(
                _isPro ? Icons.star : Icons.star_border,
                color: _isPro ? Colors.amber : null,
              ),
              title: Text(_isPro ? 'Pro активирован' : 'Перейти на Pro'),
              subtitle: Text(_isPro ? 'Все возможности разблокированы' : 'Больше запросов, без рекламы'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/pro');
              },
            ),
          ),
          const SizedBox(height: 32),

          // О приложении
          _buildSectionHeader('О приложении'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Версия'),
                  subtitle: const Text(AppConstants.appVersion),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Лицензионное соглашение'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Политика конфиденциальности'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Future<void> _pickTime(String field) async {
    final timeStr = field == 'dailyPlanTime' ? _settings.dailyPlanTime : _settings.debriefTime;
    final parts = timeStr.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      final newTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (field == 'dailyPlanTime') {
          _settings = _settings.copyWith(dailyPlanTime: newTime);
        } else {
          _settings = _settings.copyWith(debriefTime: newTime);
        }
      });
      _saveSettings();
    }
  }

  Future<void> _pickDuration() async {
    final controller = TextEditingController(text: _settings.focusDefaultDuration.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Длительность фокуса'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Минуты',
            suffixText: 'мин',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= AppConstants.focusMinDuration && val <= AppConstants.focusMaxDuration) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _settings = _settings.copyWith(focusDefaultDuration: result);
      });
      _saveSettings();
    }
  }

  Future<void> _selectProvider() async {
    final providers = ApiProvider.values;
    final selected = await showDialog<ApiProvider>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Выберите провайдера'),
        children: providers.map((p) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, p),
          child: Row(
            children: [
              Icon(
                p == ApiProvider.deepseek ? Icons.check : null,
                color: p.name == _settings.apiProvider ? Colors.green : null,
              ),
              const SizedBox(width: 8),
              Text(p.name),
            ],
          ),
        )).toList(),
      ),
    );

    if (selected != null) {
      setState(() {
        _settings = _settings.copyWith(
          apiProvider: selected.name.toLowerCase(),
          apiModel: selected.models.first,
          apiBaseUrl: selected.baseUrl,
        );
      });
      _saveSettings();
    }
  }

  Future<void> _selectModel() async {
    final provider = ApiProvider.values.firstWhere(
      (p) => p.name.toLowerCase() == _settings.apiProvider,
      orElse: () => ApiProvider.deepseek,
    );
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Выберите модель'),
        children: provider.models.map((m) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, m),
          child: Text(m),
        )).toList(),
      ),
    );

    if (selected != null) {
      setState(() {
        _settings = _settings.copyWith(apiModel: selected);
      });
      _saveSettings();
    }
  }

  Future<void> _editBaseUrl() async {
    await _editTextSetting('apiBaseUrl', 'Base URL', _settings.apiBaseUrl ?? '');
  }

  Future<void> _editTextSetting(String field, String title, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        if (field == 'imapServer') {
          _settings = _settings.copyWith(imapServer: result);
        } else if (field == 'smtpServer') {
          _settings = _settings.copyWith(smtpServer: result);
        } else if (field == 'apiBaseUrl') {
          _settings = _settings.copyWith(apiBaseUrl: result);
        }
      });
      _saveSettings();
    }
  }

  Future<void> _editSyncInterval() async {
    final controller = TextEditingController(text: _settings.emailSyncIntervalMinutes.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Интервал синхронизации'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Минуты',
            suffixText: 'мин',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _settings = _settings.copyWith(emailSyncIntervalMinutes: result);
      });
      _saveSettings();
    }
  }
}
