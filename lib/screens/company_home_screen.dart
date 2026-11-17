import 'package:flutter/material.dart';

import '../api_client.dart';
import '../models.dart';
import '../session.dart';
import '../widgets.dart';
import 'board_screen.dart';
import 'job_applications_screen.dart';
import 'new_job_screen.dart';

/// Esegue il logout (R3) e riporta alla schermata pubblica.
Future<void> logoutAndGoHome(BuildContext context, {String message = 'Logout effettuato'}) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await api.logout();
  } catch (_) {
    // anche se il server non risponde, il token locale viene eliminato
  }
  await session.clear();
  navigator.popUntil((r) => r.isFirst);
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

/// Gestisce gli errori dell'area riservata: se la sessione non è più valida
/// riporta l'utente alla bacheca pubblica.
void handleReservedError(BuildContext context, ApiException e) {
  if (e.isUnauthorized) {
    logoutAndGoHome(context, message: 'Sessione scaduta: effettua di nuovo il login');
  } else {
    showMessage(context, e.message, error: true);
  }
}

/// Area riservata dell'azienda: elenco dei propri annunci.
class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  List<Job>? _jobs;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final jobs = await api.fetchMyJobs();
      if (mounted) setState(() => _jobs = jobs);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isUnauthorized) {
        handleReservedError(context, e);
      } else {
        setState(() => _error = e.message);
      }
    }
  }

  Future<void> _newJob() async {
    final created = await Navigator.of(context).push<Job>(
      MaterialPageRoute(builder: (_) => const NewJobScreen()),
    );
    if (created != null && mounted) {
      showMessage(context, 'Annuncio "${created.title}" pubblicato nella bacheca');
      _load();
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Vuoi uscire dall\'area riservata?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Esci')),
        ],
      ),
    );
    if (ok == true && mounted) await logoutAndGoHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final company = session.company;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Area riservata'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.business, size: 40, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(company?.name ?? '', style: theme.textTheme.titleLarge),
                          Text(company?.email ?? ''),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Text('I miei annunci', style: theme.textTheme.titleMedium),
              ),
            ),
            ..._buildList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newJob,
        icon: const Icon(Icons.add),
        label: const Text('Nuovo annuncio'),
      ),
    );
  }

  List<Widget> _buildList() {
    if (_error != null) {
      return [SliverFillRemaining(child: ErrorView(message: _error!, onRetry: _load))];
    }
    final jobs = _jobs;
    if (jobs == null) {
      return [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))];
    }
    if (jobs.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Non hai ancora pubblicato annunci.\nTocca "Nuovo annuncio" per iniziare.',
                  textAlign: TextAlign.center),
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
        sliver: SliverList.builder(
          itemCount: jobs.length,
          itemBuilder: (context, i) {
            final job = jobs[i];
            final count = job.applicationsCount ?? 0;
            return JobCard(
              job: job,
              trailing: Badge(
                label: Text('$count'),
                isLabelVisible: count > 0,
                child: const Icon(Icons.people_alt_outlined),
              ),
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => JobApplicationsScreen(job: job),
                ));
                if (mounted) _load();
              },
            );
          },
        ),
      ),
    ];
  }
}
