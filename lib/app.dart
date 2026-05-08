import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/models/task.dart';
import 'data/models/source.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/inbox/inbox_screen.dart';
import 'presentation/screens/meeting/meeting_recorder_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/settings/api_settings_screen.dart';
import 'presentation/screens/search/search_screen.dart';
import 'presentation/screens/pro/pro_upgrade_screen.dart';
import 'presentation/screens/home/learning_screen.dart';
import 'presentation/screens/analytics/analytics_screen.dart';
import 'presentation/screens/task/task_list_screen.dart';
import 'presentation/screens/task/task_detail_screen.dart';
import 'presentation/screens/task/task_create_screen.dart';
import 'presentation/screens/meeting/meeting_detail_screen.dart';
import 'presentation/screens/focus/focus_screen.dart';
import 'presentation/screens/debrief/debrief_screen.dart';
import 'presentation/screens/home/daily_plan_screen.dart';
import 'domain/services/monetization_service.dart';
import 'domain/services/focus_service.dart';
import 'core/utils/logger.dart';

class AiMentorApp extends StatefulWidget {
  const AiMentorApp({super.key});

  @override
  State<AiMentorApp> createState() => _AiMentorAppState();
}

class _AiMentorAppState extends State<AiMentorApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;
  bool _isFirstLaunch = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check if first launch
      final monetization = MonetizationService();
      final isPro = await monetization.isPro();
      final isTrial = await monetization.isTrialActive();

      // For first launch detection, we check if trial was just started
      // In real app, use SharedPreferences
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isFirstLaunch = !isPro && !isTrial;
        _isAuthenticated = true; // Skip auth initially
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Error initializing app: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void _onboardingComplete() {
    setState(() {
      _isFirstLaunch = false;
    });
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: _buildHome(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/api-settings':
        return MaterialPageRoute(builder: (_) => const ApiSettingsScreen());
      case '/search':
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case '/pro':
        return MaterialPageRoute(builder: (_) => const ProUpgradeScreen());
      case '/learning':
        return MaterialPageRoute(builder: (_) => const LearningScreen());
      case '/analytics':
        return MaterialPageRoute(builder: (_) => const AnalyticsScreen());
      case '/tasks':
        return MaterialPageRoute(builder: (_) => const TaskListScreen());
      case '/task-create':
        return MaterialPageRoute(builder: (_) => const TaskCreateScreen());
      case '/task-detail':
        final task = settings.arguments as Task?;
        if (task == null) return null;
        return MaterialPageRoute(
          builder: (_) => TaskDetailScreen(task: task),
        );
      case '/meeting-detail':
        final source = settings.arguments as Source?;
        if (source == null) return null;
        return MaterialPageRoute(
          builder: (_) => MeetingDetailScreen(
            source: source,
          ),
        );
      default:
        return null;
    }
  }

  Widget _buildHome() {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text(
                'AI-Ментор',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('Учись продуктивности'),
            ],
          ),
        ),
      );
    }

    if (_isFirstLaunch) {
      return OnboardingScreen(onComplete: _onboardingComplete);
    }

    if (!_isAuthenticated) {
      return AuthScreen(
        onAuthenticated: () {
          setState(() {
            _isAuthenticated = true;
          });
        },
      );
    }

    return MainNavigationShell(
      themeMode: _themeMode,
      onToggleTheme: _toggleTheme,
    );
  }
}

/// Main navigation shell with BottomNav and Drawer
class MainNavigationShell extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const MainNavigationShell({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final FocusService _focusService = FocusService();

  final List<Widget> _screens = [
    const HomeScreen(),
    const InboxScreen(),
    const MeetingRecorderScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFab(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_getTitle()),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() => _currentIndex = index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Главная',
        ),
        NavigationDestination(
          icon: Icon(Icons.inbox_outlined),
          selectedIcon: Icon(Icons.inbox),
          label: 'Inbox',
        ),
        NavigationDestination(
          icon: Icon(Icons.mic_outlined),
          selectedIcon: Icon(Icons.mic),
          label: 'Совещания',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Профиль',
        ),
      ],
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
          builder: (_) => const FocusScreen(),
          ),
        );
      },
      icon: const Icon(Icons.mic),
      label: const Text('Запись'),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text('👤', style: TextStyle(fontSize: 30)),
                ),
                SizedBox(height: 8),
                Text(
                  'Пользователь',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('🌱 Новичок | 0 баллов'),
                Text('🔥 Стрик: 0 дней'),
              ],
            ),
          ),
          _drawerItem(Icons.home, 'Главная', () => _navigateTo(0)),
          _drawerItem(Icons.list_alt, 'Все задачи', () {
            Navigator.pushNamed(context, '/tasks');
          }),
          _drawerItem(Icons.inbox, 'Inbox', () => _navigateTo(1)),
          _drawerItem(Icons.mic, 'Совещания', () => _navigateTo(2)),
          _drawerItem(Icons.analytics, 'Аналитика', () {
            Navigator.pushNamed(context, '/analytics');
          }),
          _drawerItem(Icons.school, 'Обучение', () {
            Navigator.pushNamed(context, '/learning');
          }),
          const Divider(),
          _drawerItem(Icons.settings, 'Настройки', () {
            Navigator.pushNamed(context, '/settings');
          }),
          _drawerItem(Icons.key, 'API и AI', () {
            Navigator.pushNamed(context, '/api-settings');
          }),
          _drawerItem(Icons.star, 'Pro версия', () {
            Navigator.pushNamed(context, '/pro');
          }),
          const Divider(),
          _drawerItem(Icons.help, 'Помощь', () {}),
          SwitchListTile(
            title: const Text('🌙 Тёмная тема'),
            value: widget.themeMode == ThemeMode.dark,
            onChanged: (val) {
              widget.onToggleTheme();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  String _getTitle() {
    const titles = ['Главная', 'Inbox', 'Совещания', 'Профиль'];
    return titles[_currentIndex];
  }
}
