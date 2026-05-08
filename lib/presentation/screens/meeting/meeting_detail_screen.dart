import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/models/source.dart';

class MeetingDetailScreen extends StatefulWidget {
  final Source source;

  const MeetingDetailScreen({super.key, required this.source});

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = widget.source;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали совещания'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mic, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text(
                          'Совещание',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      source.aiSummary ?? 'Без темы',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          AppDateUtils.formatDateTime(source.createdAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Raw content
            if (source.rawContent != null) ...[
              Text(
                'Транскрипт',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    source.rawContent!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],

            // Metadata
            if (source.metadata != null) ...[
              const SizedBox(height: 16),
              _buildMetadata(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Метаданные',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Дата',
                AppDateUtils.formatDateTime(widget.source.createdAt)),
            _buildInfoRow('Тип', widget.source.type),
            if (widget.source.metadata != null)
              _buildInfoRow('Источник', widget.source.metadata!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
