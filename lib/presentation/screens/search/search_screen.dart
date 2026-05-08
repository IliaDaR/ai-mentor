import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task.dart';
import '../../../domain/providers/repository_providers.dart';
import '../../../domain/providers/service_providers.dart';
import '../../../core/constants/enums.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/logger.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Task> _results = [];
  bool _isSearching = false;
  bool _isAiSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final taskRepo = ref.read(taskRepositoryProvider);
      final aiService = ref.read(aiServiceProvider);
      final monetization = ref.read(monetizationServiceProvider);

      // Local search first
      final localResults = await taskRepo.getTasks(searchQuery: query);

      // Try AI-powered search if Pro
      final isPro = await monetization.isPro();
      if (isPro && await monetization.canUseAI(dailyRequestsUsed: 0)) {
        try {
          final aiResult = await aiService.searchNaturalLanguage(query);
          if (aiResult != null && aiResult.containsKey('keywords') && aiResult['keywords'] is List) {
            final keywords = (aiResult['keywords'] as List).cast<String>();
            for (final keyword in keywords) {
              final additionalResults = await taskRepo.getTasks(searchQuery: keyword);
              for (final task in additionalResults) {
                if (!localResults.any((t) => t.id == task.id)) {
                  localResults.add(task);
                }
              }
            }
          }
          setState(() => _isAiSearch = true);
        } catch (e) {
          logger.w('AI search failed, using local only: $e');
          setState(() => _isAiSearch = false);
        }
      }

      setState(() {
        _results = localResults;
        _isSearching = false;
      });
    } catch (e) {
      logger.e('Search error: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Поиск задач...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          style: TextStyle(color: theme.colorScheme.onSurface),
          onSubmitted: _performSearch,
          onChanged: (val) {
            if (val.isEmpty) {
              setState(() {
                _results = [];
                _isSearching = false;
              });
            }
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _results = [];
                  _isSearching = false;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isAiSearch)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Поиск с AI',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Ничего не найдено',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить запрос',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Начните поиск',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ищите задачи по названию, тегам или описанию',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final task = _results[index];
        final quadrant = TaskQuadrant.values.firstWhere(
          (q) => q.value == task.quadrant,
          orElse: () => TaskQuadrant.notUrgentNotImportant,
        );

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Container(
              width: 8,
              height: 48,
              decoration: BoxDecoration(
                color: Color(quadrant.color),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            title: Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              quadrant.label,
              style: TextStyle(color: Color(quadrant.color)),
            ),
            trailing: Text(
              AppDateUtils.timeAgo(task.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/task-detail',
                arguments: task,
              );
            },
          ),
        );
      },
    );
  }
}
