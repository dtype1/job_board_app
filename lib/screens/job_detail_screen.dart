import 'package:flutter/material.dart';

import '../api_client.dart';
import '../models.dart';
import '../widgets.dart';
import 'apply_screen.dart';

/// Dettaglio di un annuncio (R5) con avvio della candidatura (R6).
class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.jobId, this.initial, this.showApply = true});

  final String jobId;

  /// Dati già noti dall'elenco, mostrati subito mentre si aggiorna.
  final Job? initial;

  /// Nell'area riservata l'azienda non si candida: il pulsante viene nascosto.
  final bool showApply;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  Job? _job;
  String? _error;

  @override
  void initState() {
    super.initState();
    _job = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final job = await api.fetchJob(widget.jobId);
      if (mounted) setState(() => _job = job);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dettaglio annuncio')),
      body: job == null
          ? (_error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : const Center(child: CircularProgressIndicator()))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                Text(job.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(job.companyName,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (job.location.isNotEmpty)
                      Chip(avatar: const Icon(Icons.place, size: 18), label: Text(job.location)),
                    if (job.contractType.isNotEmpty)
                      Chip(
                          avatar: const Icon(Icons.badge_outlined, size: 18),
                          label: Text(job.contractType)),
                    Chip(
                        avatar: const Icon(Icons.calendar_today, size: 18),
                        label: Text('Pubblicato il ${formatDate(job.createdAt)}')),
                  ],
                ),
                const Divider(height: 32),
                Text('Descrizione', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SelectableText(job.description, style: theme.textTheme.bodyLarge),
              ],
            ),
      bottomNavigationBar: job == null || !widget.showApply
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Candidati'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ApplyScreen(job: job)),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
