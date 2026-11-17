import 'package:flutter/material.dart';

import '../api_client.dart';
import '../widgets.dart';

/// Registrazione di una nuova azienda (R1).
/// Al termine torna al login restituendo l'email appena registrata.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _description, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final email = _email.text.trim();
      await api.register(
        name: _name.text.trim(),
        email: email,
        password: _password.text,
        description: _description.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(email);
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registra la tua azienda')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Nome azienda *', prefixIcon: Icon(Icons.business)),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) => requiredValidator(v, 'Nome azienda'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                  labelText: 'Breve descrizione (facoltativa)', prefixIcon: Icon(Icons.info_outline)),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              decoration:
                  const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email)),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: emailValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Password * (min. 6 caratteri)', prefixIcon: Icon(Icons.lock)),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Almeno 6 caratteri' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Conferma password *', prefixIcon: Icon(Icons.lock_outline)),
              validator: (v) => v != _password.text ? 'Le password non coincidono' : null,
              onFieldSubmitted: (_) => _register(),
            ),
            const SizedBox(height: 28),
            LoadingButton(
              loading: _loading,
              onPressed: _register,
              label: 'Crea account',
              icon: Icons.person_add,
            ),
          ],
        ),
      ),
    );
  }
}
