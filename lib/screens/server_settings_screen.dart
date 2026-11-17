import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../session.dart';
import '../widgets.dart';

/// Permette di impostare l'indirizzo del server (es. http://192.168.1.10:8080),
/// necessario quando l'app gira su uno smartphone reale.
class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late final _controller = TextEditingController(text: session.baseUrl);
  bool _testing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? v) {
    final uri = Uri.tryParse(v?.trim() ?? '');
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
      return 'Inserisci un indirizzo tipo http://192.168.1.10:8080';
    }
    return null;
  }

  Future<void> _saveAndTest() async {
    final error = _validate(_controller.text);
    if (error != null) {
      showMessage(context, error, error: true);
      return;
    }
    await session.setBaseUrl(_controller.text);
    setState(() => _testing = true);
    try {
      final res = await http
          .get(Uri.parse('${session.baseUrl}/api/health'))
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      showMessage(
        context,
        res.statusCode == 200 ? 'Connessione riuscita ✔' : 'Il server ha risposto ${res.statusCode}',
        error: res.statusCode != 200,
      );
    } catch (_) {
      if (mounted) showMessage(context, 'Server non raggiungibile', error: true);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni server')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Indirizzo del server',
              hintText: 'http://192.168.1.10:8080',
              prefixIcon: Icon(Icons.dns),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Usa l\'indirizzo IP del PC su cui gira il back-end (lo stampa il server '
            'all\'avvio). Smartphone e PC devono essere sulla stessa rete Wi-Fi. '
            'Sull\'emulatore Android usa http://10.0.2.2:8080.',
          ),
          const SizedBox(height: 24),
          LoadingButton(
            loading: _testing,
            onPressed: _saveAndTest,
            label: 'Salva e verifica connessione',
            icon: Icons.wifi_tethering,
          ),
        ],
      ),
    );
  }
}
