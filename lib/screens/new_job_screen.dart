import 'package:flutter/material.dart';

import '../api_client.dart';
import '../widgets.dart';
import 'company_home_screen.dart';

/// Pubblicazione di un nuovo annuncio (R4).
class NewJobScreen extends StatefulWidget {
  const NewJobScreen({super.key});

  @override
  State<NewJobScreen> createState() => _NewJobScreenState();
}

class _NewJobScreenState extends State<NewJobScreen> {
  static const _contractTypes = [
    'Tempo indeterminato',
    'Tempo determinato',
    'Stage / Tirocinio',
    'Part-time',
    'Freelance',
  ];

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  String? _contractType;
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final job = await api.createJob(
        title: _title.text.trim(),
        description: _description.text.trim(),
        location: _location.text.trim(),
        contractType: _contractType ?? '',
      );
      if (mounted) Navigator.of(context).pop(job);
    } on ApiException catch (e) {
      if (mounted) handleReservedError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo annuncio')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Titolo *',
                hintText: 'Es. Sviluppatore Flutter',
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (v) => requiredValidator(v, 'Titolo'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Sede (facoltativa)',
                hintText: 'Es. Roma / Remoto',
                prefixIcon: Icon(Icons.place),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _contractType,
              decoration: const InputDecoration(
                labelText: 'Tipo di contratto (facoltativo)',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: [
                for (final t in _contractTypes) DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => _contractType = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Descrizione *',
                hintText: 'Mansioni, requisiti, cosa offrite…',
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 6,
              maxLines: 14,
              validator: (v) => requiredValidator(v, 'Descrizione'),
            ),
            const SizedBox(height: 28),
            LoadingButton(
              loading: _loading,
              onPressed: _publish,
              label: 'Pubblica annuncio',
              icon: Icons.publish,
            ),
          ],
        ),
      ),
    );
  }
}
