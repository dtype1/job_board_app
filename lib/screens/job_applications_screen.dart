import 'package:flutter/material.dart';

import '../api_client.dart';
import '../models.dart';
import '../widgets.dart';
import 'application_detail_screen.dart';
import 'company_home_screen.dart';
import 'job_detail_screen.dart';

/// Candidature ricevute per un annuncio dell'azienda (R7).
class JobApplicationsScreen extends StatefulWidget {
  const JobApplicationsScreen({super.key, required this.job});

  final Job job;

  @override
  State<JobApplicationsScreen> createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  List<JobApplication>? _applications;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await api.fetchApplications(widget.job.id);
      if (mounted) setState(() => _applications = list);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isUnauthorized) {
        handleReservedError(context, e);
      } else {
        setState(() => _error = e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidature ricevute'),
        actions: [
          IconButton(
            tooltip: 'Vedi annuncio',
            icon: const Icon(Icons.article_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  JobDetailScreen(jobId: widget.job.id, initial: widget.job, showApply: false),
            )),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: ListTile(
              leading: const Icon(Icons.work_outline),
              title: Text(widget.job.title, style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text(_applications == null
                  ? 'Caricamento…'
                  : '${_applications!.length} candidatur${_applications!.length == 1 ? 'a' : 'e'}'),
            ),
          ),
          Expanded(child: RefreshIndicator(onRefresh: _load, child: _buildBody())),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    final list = _applications;
    if (list == null) return const Center(child: CircularProgressIndicator());
    if (list.isEmpty) {
      return const EmptyView(
        icon: Icons.inbox_outlined,
        message: 'Nessuna candidatura ricevuta per questo annuncio.',
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final a = list[i];
        return ListTile(
          leading: CircleAvatar(child: Text(a.firstName.isEmpty ? '?' : a.firstName[0].toUpperCase())),
          title: Text(a.fullName),
          subtitle: Text('${a.email}\nRicevuta il ${formatDate(a.createdAt)}'),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ApplicationDetailScreen(application: a),
          )),
        );
      },
    );
  }
}
