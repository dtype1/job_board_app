import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../api_client.dart';
import '../models.dart';
import '../widgets.dart';

/// Form di candidatura del candidato (R6). Nessun login richiesto.
class ApplyScreen extends StatefulWidget {
  const ApplyScreen({super.key, required this.job});

  final Job job;

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  static const _maxBytes = 10 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();

  String? _cvName;
  Uint8List? _cvBytes;
  bool _cvMissing = false;
  bool _sending = false;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _phone, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCv() async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Seleziona il curriculum',
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _maxBytes) {
        showMessage(context, 'Il file supera i 10 MB', error: true);
        return;
      }
      setState(() {
        _cvName = file.name;
        _cvBytes = bytes;
        _cvMissing = false;
      });
    } catch (e) {
      if (mounted) showMessage(context, 'Impossibile leggere il file: $e', error: true);
    }
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    setState(() => _cvMissing = _cvBytes == null);
    if (!formOk || _cvBytes == null) return;

    setState(() => _sending = true);
    try {
      await api.apply(
        jobId: widget.job.id,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        message: _message.text.trim(),
        cvFileName: _cvName!,
        cvBytes: _cvBytes!,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ApplicationSentScreen(job: widget.job, name: _firstName.text.trim()),
      ));
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatura')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.job.title, style: theme.textTheme.titleLarge),
            Text(widget.job.companyName, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'Nome *'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) => requiredValidator(v, 'Nome'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Cognome *'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) => requiredValidator(v, 'Cognome'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email *'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: emailValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Telefono (facoltativo)'),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _message,
              decoration: const InputDecoration(
                labelText: 'Messaggio / lettera di presentazione (facoltativo)',
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 6,
            ),
            const SizedBox(height: 20),
            Text('Curriculum *', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Card(
              color: _cvMissing ? theme.colorScheme.errorContainer : null,
              child: ListTile(
                leading: Icon(_cvBytes == null ? Icons.upload_file : Icons.picture_as_pdf),
                title: Text(_cvName ?? 'Nessun file selezionato'),
                subtitle: Text(_cvBytes == null
                    ? (_cvMissing ? 'Allega il curriculum per continuare' : 'PDF, DOC o DOCX, max 10 MB')
                    : formatBytes(_cvBytes!.length)),
                trailing: TextButton(
                  onPressed: _sending ? null : _pickCv,
                  child: Text(_cvBytes == null ? 'Scegli' : 'Cambia'),
                ),
                onTap: _sending ? null : _pickCv,
              ),
            ),
            const SizedBox(height: 28),
            LoadingButton(
              loading: _sending,
              onPressed: _submit,
              label: 'Invia candidatura',
              icon: Icons.send,
            ),
          ],
        ),
      ),
    );
  }
}

/// Messaggio di conferma dopo l'invio.
class ApplicationSentScreen extends StatelessWidget {
  const ApplicationSentScreen({super.key, required this.job, required this.name});

  final Job job;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatura inviata'), automaticallyImplyLeading: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 96, color: Colors.green.shade600),
              const SizedBox(height: 20),
              Text('Grazie $name!', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                'La tua candidatura per "${job.title}" presso ${job.companyName} '
                'è stata registrata correttamente.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                icon: const Icon(Icons.home),
                label: const Text('Torna alla bacheca'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
