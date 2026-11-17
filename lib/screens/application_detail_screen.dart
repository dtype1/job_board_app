import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../api_client.dart';
import '../models.dart';
import '../widgets.dart';
import 'company_home_screen.dart';

/// Dati del candidato e apertura del curriculum allegato (R7).
class ApplicationDetailScreen extends StatefulWidget {
  const ApplicationDetailScreen({super.key, required this.application});

  final JobApplication application;

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  bool _opening = false;

  /// Scarica il CV dal server in una cartella temporanea e lo apre con
  /// l'app predefinita del telefono (es. visualizzatore PDF).
  Future<void> _openCv() async {
    final a = widget.application;
    setState(() => _opening = true);
    try {
      final bytes = await api.downloadCv(a.id);
      final dir = await getTemporaryDirectory();
      final safeName = a.cvFileName.replaceAll(RegExp(r'[^\w.\- ]'), '_');
      final file = File('${dir.path}/cv_${a.id}_$safeName');
      await file.writeAsBytes(bytes, flush: true);

      final result = await OpenFilex.open(file.path);
      if (!mounted) return;
      if (result.type != ResultType.done) {
        showMessage(
          context,
          result.type == ResultType.noAppToOpen
              ? 'Nessuna app installata per aprire questo tipo di file'
              : 'Impossibile aprire il file: ${result.message}',
          error: true,
        );
      }
    } on ApiException catch (e) {
      if (mounted) handleReservedError(context, e);
    } catch (e) {
      if (mounted) showMessage(context, 'Errore durante l\'apertura del CV: $e', error: true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.application;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Candidatura')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                child: Text(
                  '${a.firstName.isEmpty ? '' : a.firstName[0]}${a.lastName.isEmpty ? '' : a.lastName[0]}'
                      .toUpperCase(),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.fullName, style: theme.textTheme.headlineSmall),
                    Text('per "${a.jobTitle}"', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          InfoRow(icon: Icons.person, label: 'Nome', value: a.firstName),
          InfoRow(icon: Icons.person_outline, label: 'Cognome', value: a.lastName),
          InfoRow(icon: Icons.email, label: 'Email', value: a.email),
          if (a.phone.isNotEmpty) InfoRow(icon: Icons.phone, label: 'Telefono', value: a.phone),
          InfoRow(
              icon: Icons.calendar_today, label: 'Data candidatura', value: formatDate(a.createdAt)),
          if (a.message.isNotEmpty)
            InfoRow(icon: Icons.notes, label: 'Messaggio', value: a.message),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, size: 36),
              title: Text(a.cvFileName),
              subtitle: Text('Curriculum · ${formatBytes(a.cvSize)}'),
            ),
          ),
          const SizedBox(height: 16),
          LoadingButton(
            loading: _opening,
            onPressed: _openCv,
            label: 'Apri curriculum',
            icon: Icons.open_in_new,
          ),
        ],
      ),
    );
  }
}
