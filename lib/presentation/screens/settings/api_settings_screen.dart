import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/enums.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/providers/service_providers.dart';

class ApiSettingsScreen extends ConsumerStatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  ConsumerState<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends ConsumerState<ApiSettingsScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String _apiKey = '';
  String _selectedProvider = 'deepseek';
  String _selectedModel = 'deepseek-chat';
  String _baseUrl = 'https://api.deepseek.com/v1';
  bool _isLoading = true;
  bool _isTesting = false;
  bool _isKeyVisible = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final storedKey = await _storage.read(key: 'api_key_deepseek') ?? '';
      final storedUrl = await _storage.read(key: 'base_url_deepseek') ?? 'https://api.deepseek.com/v1';
      final storedModel = await _storage.read(key: 'model_deepseek') ?? 'deepseek-chat';
      final storedProvider = await _storage.read(key: 'api_provider') ?? 'deepseek';
      final config = {
        'key': storedKey,
        'url': storedUrl,
        'model': storedModel,
        'provider': storedProvider,
      };
      final apiKey = await _storage.read(key: 'api_key') ?? '';
      setState(() {
        _apiKey = apiKey;
        _selectedProvider = config['provider'] ?? 'deepseek';
        _selectedModel = config['model'] ?? 'deepseek-chat';
        _baseUrl = config['url'] ?? 'https://api.deepseek.com/v1';
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Error loading API config: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    try {
      await _storage.write(key: 'api_key', value: _apiKey);
      await _storage.write(key: 'api_provider', value: _selectedProvider);
      await _storage.write(key: 'api_model', value: _selectedModel);
      await _storage.write(key: 'api_base_url', value: _baseUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Настройки API сохранены')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final result = await aiService.testConnection(_apiKey, _baseUrl);
      setState(() {
        _testResult = result ? '✅ Подключение успешно' : '❌ Ошибка подключения';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Ошибка: $e';
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('API и AI'),
        actions: [
          TextButton(
            onPressed: _saveConfig,
            child: const Text('Сохранить'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // API Key
          Text('API Ключ', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    obscureText: !_isKeyVisible,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'Введите ваш API ключ',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_isKeyVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _isKeyVisible = !_isKeyVisible),
                      ),
                    ),
                    onChanged: (val) => _apiKey = val,
                    controller: TextEditingController(text: _apiKey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ключ хранится в защищённом хранилище устройства',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Provider
          Text('Провайдер', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: ApiProvider.values.map((provider) {
                final isSelected = provider.name.toLowerCase() == _selectedProvider;
                return RadioListTile<ApiProvider>(
                  title: Text(provider.name),
                  subtitle: Text(provider.baseUrl, style: const TextStyle(fontSize: 12)),
                  value: provider,
                  groupValue: ApiProvider.values.firstWhere(
                    (p) => p.name.toLowerCase() == _selectedProvider,
                    orElse: () => ApiProvider.deepseek,
                  ),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedProvider = val.name.toLowerCase();
                        _baseUrl = val.baseUrl;
                        _selectedModel = val.models.first;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Model
          Text('Модель', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                value: _selectedModel,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Модель AI',
                ),
                items: _getModelsForProvider().map((model) {
                  return DropdownMenuItem(
                    value: model,
                    child: Text(model),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedModel = val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Base URL
          Text('Base URL', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  border: OutlineInputBorder(),
                  hintText: 'https://api.example.com/v1',
                ),
                onChanged: (val) => _baseUrl = val,
                controller: TextEditingController(text: _baseUrl),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Test connection
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering),
              label: Text(_isTesting ? 'Тестирование...' : 'Проверить подключение'),
            ),
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 12),
            Card(
              color: _testResult!.startsWith('✅')
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _testResult!.startsWith('✅') ? Icons.check_circle : Icons.error,
                      color: _testResult!.startsWith('✅') ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_testResult!)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),

          // Usage info
          Text('Информация', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16),
                      const SizedBox(width: 8),
                      Text('Бесплатных запросов в день: ${AppConstants.freeDailyRequests}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_outline, size: 16),
                      const SizedBox(width: 8),
                      const Text('Pro: безлимитные запросы'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.cloud_outlined, size: 16),
                      const SizedBox(width: 8),
                    Text('Провайдер: ${ApiProvider.values.firstWhere((p) => p.name.toLowerCase() == _selectedProvider, orElse: () => ApiProvider.deepseek).name}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<String> _getModelsForProvider() {
    try {
      final provider = ApiProvider.values.firstWhere(
        (p) => p.name.toLowerCase() == _selectedProvider,
      );
      return provider.models;
    } catch (e) {
      return ['deepseek-chat'];
    }
  }
}
