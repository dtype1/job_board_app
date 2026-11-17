import 'package:flutter/material.dart';

import '../api_client.dart';
import '../models.dart';
import '../session.dart';
import '../widgets.dart';
import 'company_home_screen.dart';
import 'job_detail_screen.dart';
import 'login_screen.dart';
import 'server_settings_screen.dart';

/// Schermata pubblica iniziale: elenco degli annunci (R5).
class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  late Future<List<Job>> _jobs;

  @override
  void initState() {
    super.initState();
    _jobs = api.fetchJobs();
  }

  Future<void> _reload() async {
    final future = api.fetchJobs();
    setState(() => _jobs = future);
    try {
      await future;
    } catch (_) {
      // l'errore viene mostrato dal FutureBuilder
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bacheca Lavoro'),
        actions: [
          IconButton(
            tooltip: 'Impostazioni server',
            icon: const Icon(Icons.settings_ethernet),
            onPressed: () => _open(const ServerSettingsScreen()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Job>>(
          future: _jobs,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorView(message: '${snapshot.error}', onRetry: _reload);
            }
            final jobs = snapshot.data!;
            if (jobs.isEmpty) {
              return const EmptyView(
                icon: Icons.work_off_outlined,
                message: 'Nessun annuncio pubblicato al momento.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: jobs.length,
              itemBuilder: (context, i) => JobCard(
                job: jobs[i],
                onTap: () => _open(JobDetailScreen(jobId: jobs[i].id, initial: jobs[i])),
              ),
            );
          },
        ),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: session,
        builder: (context, _) => FloatingActionButton.extended(
          heroTag: 'company',
          onPressed: () => _open(
            session.isLoggedIn ? const CompanyHomeScreen() : const LoginScreen(),
          ),
          icon: Icon(session.isLoggedIn ? Icons.business_center : Icons.login),
          label: Text(session.isLoggedIn ? 'Area riservata' : 'Area aziende'),
        ),
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job, required this.onTap, this.trailing});

  final Job job;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      if (job.location.isNotEmpty) job.location,
      if (job.contractType.isNotEmpty) job.contractType,
      formatDate(job.createdAt),
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  job.companyName.isEmpty ? '?' : job.companyName[0].toUpperCase(),
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(job.companyName, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(meta, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
