import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Indirizzo predefinito del server. `10.0.2.2` è il PC visto dall'emulatore
/// Android; su smartphone reale va impostato l'IP del PC dalla schermata
/// "Impostazioni server" (oppure con `--dart-define=API_URL=http://...`).
const _defaultBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8080',
);

/// Stato globale dell'app: indirizzo del server e sessione dell'azienda.
/// Viene salvato in SharedPreferences, così sopravvive alla chiusura dell'app.
class AppSession extends ChangeNotifier {
  static const _kBaseUrl = 'baseUrl';
  static const _kToken = 'token';
  static const _kCompany = 'company';

  late SharedPreferences _prefs;

  String baseUrl = _defaultBaseUrl;
  String? token;
  Company? company;

  bool get isLoggedIn => token != null && company != null;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    baseUrl = _prefs.getString(_kBaseUrl) ?? _defaultBaseUrl;
    token = _prefs.getString(_kToken);
    final companyJson = _prefs.getString(_kCompany);
    if (companyJson != null) {
      company = Company.fromJson(jsonDecode(companyJson) as Map<String, dynamic>);
    }
  }

  Future<void> setBaseUrl(String value) async {
    baseUrl = value.trim().replaceAll(RegExp(r'/+$'), '');
    await _prefs.setString(_kBaseUrl, baseUrl);
    notifyListeners();
  }

  Future<void> signIn(String newToken, Company newCompany) async {
    token = newToken;
    company = newCompany;
    await _prefs.setString(_kToken, newToken);
    await _prefs.setString(_kCompany, jsonEncode(newCompany.toJson()));
    notifyListeners();
  }

  Future<void> clear() async {
    token = null;
    company = null;
    await _prefs.remove(_kToken);
    await _prefs.remove(_kCompany);
    notifyListeners();
  }
}

/// Istanza unica condivisa da tutte le schermate.
final session = AppSession();
