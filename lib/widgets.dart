import 'package:flutter/material.dart';

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
}

final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? requiredValidator(String? v, String field) =>
    (v == null || v.trim().isEmpty) ? '$field obbligatorio' : null;

String? emailValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email obbligatoria';
  if (!emailRegex.hasMatch(v.trim())) return 'Email non valida';
  return null;
}

/// Stato di errore con pulsante "Riprova".
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stato vuoto (elenco senza elementi).
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    // ListView per permettere il pull-to-refresh anche a elenco vuoto.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    );
  }
}

/// Riga "etichetta: valore" con icona, usata nei dettagli.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label, style: Theme.of(context).textTheme.labelMedium),
      subtitle: SelectableText(value, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

/// Pulsante con indicatore di caricamento.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.loading,
    required this.onPressed,
    required this.label,
    this.icon,
  });

  final bool loading;
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon ?? Icons.check),
        label: Text(label),
      ),
    );
  }
}
