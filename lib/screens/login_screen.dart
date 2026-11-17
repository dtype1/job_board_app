import 'package:flutter/material.dart';

import '../api_client.dart';
import '../session.dart';
import '../widgets.dart';
import 'company_home_screen.dart';
import 'register_screen.dart';

/// Login dell'azienda (R2).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final (token, company) = await api.login(_email.text.trim(), _password.text);
      await session.signIn(token, company);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CompanyHomeScreen()),
      );
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goToRegister() async {
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (email != null && mounted) {
      _email.text = email;
      _password.clear();
      showMessage(context, 'Account creato! Ora accedi con le tue credenziali.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Area aziende')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.business, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Accedi', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            const Text('Accedi per pubblicare annunci e consultare le candidature.',
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: emailValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onFieldSubmitted: (_) => _login(),
              validator: (v) => (v == null || v.isEmpty) ? 'Password obbligatoria' : null,
            ),
            const SizedBox(height: 28),
            LoadingButton(loading: _loading, onPressed: _login, label: 'Accedi', icon: Icons.login),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loading ? null : _goToRegister,
              child: const Text('Non hai un account? Registra la tua azienda'),
            ),
          ],
        ),
      ),
    );
  }
}
