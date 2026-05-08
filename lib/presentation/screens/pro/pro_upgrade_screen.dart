import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/providers/service_providers.dart';

class ProUpgradeScreen extends ConsumerStatefulWidget {
  const ProUpgradeScreen({super.key});

  @override
  ConsumerState<ProUpgradeScreen> createState() => _ProUpgradeScreenState();
}

class _ProUpgradeScreenState extends ConsumerState<ProUpgradeScreen> {
  bool _isPro = false;
  bool _isLoading = true;
  String? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final monetization = ref.read(monetizationServiceProvider);
      final isPro = await monetization.isPro();
      setState(() {
        _isPro = isPro;
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Error loading pro status: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI-Ментор Pro')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isPro) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI-Ментор Pro')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, size: 80, color: Colors.amber.shade600),
                const SizedBox(height: 24),
                Text(
                  'Pro активирован!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Все возможности AI-Ментор разблокированы',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                  child: const Text('Настройки'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AI-Ментор Pro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.workspace_premium, size: 64, color: Colors.amber.shade600),
                const SizedBox(height: 16),
                Text(
                  'AI-Ментор Pro',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Раскройте весь потенциал продуктивности',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Benefits
          _buildBenefit(Icons.all_inclusive, 'Безлимитные AI-запросы'),
          _buildBenefit(Icons.block, 'Без рекламы'),
          _buildBenefit(Icons.list_alt, 'Неограниченное количество задач'),
          _buildBenefit(Icons.mic, 'Неограниченный анализ совещаний'),
          _buildBenefit(Icons.cloud, 'Приоритетный доступ к AI'),
          _buildBenefit(Icons.analytics, 'Расширенная аналитика'),
          _buildBenefit(Icons.sync, 'Синхронизация с почтой IMAP/SMTP'),
          _buildBenefit(Icons.business, 'Корпоративные серверы LDAP'),
          _buildBenefit(Icons.rocket_launch, 'Персонализированные промпты'),

          const SizedBox(height: 32),

          // Plans
          _buildPlanCard(
            'monthly',
            'Ежемесячная',
            '${AppConstants.proMonthlyPrice ?? 499} ₽/мес',
            '7 дней бесплатно',
            'Гибкая подписка, отмена в любой момент',
          ),
          const SizedBox(height: 12),
          _buildPlanCard(
            'yearly',
            'Годовая',
            '${AppConstants.proYearlyPrice ?? 2990} ₽/год',
            'Экономия 50%',
            '${AppConstants.proYearlyPrice ~/ 12 ?? 249} ₽/мес',
          ),
          const SizedBox(height: 12),
          _buildPlanCard(
            'lifetime',
            'Навсегда',
            '${AppConstants.proLifetimePrice ?? 6990} ₽',
            'Один платёж',
            'Все функции навсегда',
          ),
          const SizedBox(height: 12),
          _buildPlanCard(
            'team',
            'Pro+ Team',
            '${AppConstants.proPlusTeamPrice ?? 9990} ₽/год',
            'Для команд до 5 человек',
            'Корпоративные функции, общие проекты',
          ),

          const SizedBox(height: 32),

          // Restore
          Center(
            child: TextButton(
              onPressed: () async {
                try {
                  final monetization = ref.read(monetizationServiceProvider);
                  await monetization.restorePurchases();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Покупки восстановлены')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: $e')),
                    );
                  }
                }
              },
              child: const Text('Восстановить покупки'),
            ),
          ),
          const SizedBox(height: 16),

          // Footer
          Text(
            'Оплата будет списана с вашего аккаунта Google Play. '
            'Подписка автоматически продлевается, если не отключена '
            'за 24 часа до окончания текущего периода.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String planId, String title, String price, String badge, String subtitle) {
    final isSelected = _selectedPlan == planId;
    final theme = Theme.of(context);

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() => _selectedPlan = planId);
          _purchase(planId);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.brown.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchase(String planId) async {
    try {
      final monetization = ref.read(monetizationServiceProvider);
      await monetization.purchaseProduct(planId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Покупка выполнена успешно! Добро пожаловать в Pro!')),
        );
        setState(() => _isPro = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка покупки: $e')),
        );
      }
    }
  }
}
