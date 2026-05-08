import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.auto_awesome,
      title: 'Добро пожаловать в AI-Ментор!',
      description:
          'Ваш персональный AI-ассистент, который научит вас\nпродуктивности шаг за шагом.',
      color: Color(0xFF6750A4),
    ),
    _OnboardingPage(
      icon: Icons.grid_view_rounded,
      title: 'Матрица Эйзенхауэра',
      description:
          'Научитесь расставлять приоритеты\nс помощью проверенной методики.\nИИ поможет определить важность каждой задачи.',
      color: Color(0xFFF9AB00),
    ),
    _OnboardingPage(
      icon: Icons.psychology,
      title: 'SMART-цели',
      description:
          'Каждая задача проверяется по 5 критериям:\nКонкретность, Измеримость, Достижимость,\nАктуальность и Ограниченность по времени.',
      color: Color(0xFF2E7D32),
    ),
    _OnboardingPage(
      icon: Icons.timeline,
      title: 'Геймификация',
      description:
          'Зарабатывайте баллы, открывайте достижения,\nповышайте уровень и проходите 5 этапов обучения\nот новичка до наставника.',
      color: Color(0xFFB3261E),
    ),
    _OnboardingPage(
      icon: Icons.workspace_premium,
      title: 'Готовы начать?',
      description:
          'ИИ будет составлять планы,\nанализировать совещания, проверять задачи\nи помогать вам расти каждый день.',
      color: Color(0xFF6750A4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onComplete,
                child: const Text('Пропустить'),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) => _pages[index],
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    widget.onComplete();
                  }
                },
                child: Text(
                  _currentPage < _pages.length - 1
                      ? 'Далее'
                      : 'Начать работу!',
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, size: 60, color: color),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
