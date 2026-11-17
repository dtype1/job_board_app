import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'session.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Client HTTP verso il back-end. Ogni metodo corrisponde a un endpoint.
class ApiClient {
  ApiClient._();

  static final instance = ApiClient._();

  static const _timeout = Duration(seconds: 15);

  Uri _uri(String path) => Uri.parse('${session.baseUrl}$path');

  Map<String, String> _headers({bool auth = false}) => {
        'content-type': 'application/json',
        if (auth && session.token != null) 'authorization': 'Bearer ${session.token}',
      };

  // ---------------- Auth ----------------

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String description = '',
  }) async {
    await _send(() => http.post(
          _uri('/api/auth/register'),
          headers: _headers(),
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'description': description,
          }),
        ));
  }

  Future<(String token, Company company)> login(String email, String password) async {
    final data = await _send(() => http.post(
          _uri('/api/auth/login'),
          headers: _headers(),
          body: jsonEncode({'email': email, 'password': password}),
        )) as Map<String, dynamic>;
    return (
      data['token'] as String,
      Company.fromJson(data['company'] as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    await _send(() => http.post(_uri('/api/auth/logout'), headers: _headers(auth: true)));
  }

  // ---------------- Bacheca pubblica ----------------

  Future<List<Job>> fetchJobs() async {
    final data = await _send(() => http.get(_uri('/api/jobs'))) as List;
    return data.map((e) => Job.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Job> fetchJob(String id) async {
    final data = await _send(() => http.get(_uri('/api/jobs/$id')));
    return Job.fromJson(data as Map<String, dynamic>);
  }

  Future<void> apply({
    required String jobId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String message,
    required String cvFileName,
    required Uint8List cvBytes,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/jobs/$jobId/applications'))
      ..fields.addAll({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'message': message,
      })
      ..files.add(http.MultipartFile.fromBytes('cv', cvBytes, filename: cvFileName));

    await _send(() async => http.Response.fromStream(await request.send()),
        timeout: const Duration(seconds: 60));
  }

  // ---------------- Area riservata ----------------

  Future<Job> createJob({
    required String title,
    required String description,
    required String location,
    required String contractType,
  }) async {
    final data = await _send(() => http.post(
          _uri('/api/jobs'),
          headers: _headers(auth: true),
          body: jsonEncode({
            'title': title,
            'description': description,
            'location': location,
            'contractType': contractType,
          }),
        ));
    return Job.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Job>> fetchMyJobs() async {
    final data =
        await _send(() => http.get(_uri('/api/company/jobs'), headers: _headers(auth: true))) as List;
    return data.map((e) => Job.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<JobApplication>> fetchApplications(String jobId) async {
    final data = await _send(() => http.get(
          _uri('/api/company/jobs/$jobId/applications'),
          headers: _headers(auth: true),
        )) as List;
    return data.map((e) => JobApplication.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Uint8List> downloadCv(String applicationId) async {
    final response = await _raw(() => http.get(
          _uri('/api/company/applications/$applicationId/cv'),
          headers: _headers(auth: true),
        ), timeout: const Duration(seconds: 60));
    return response.bodyBytes;
  }

  // ---------------- Helpers ----------------

  Future<Object?> _send(Future<http.Response> Function() call, {Duration? timeout}) async {
    final response = await _raw(call, timeout: timeout);
    if (response.statusCode == 204 || response.body.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<http.Response> _raw(Future<http.Response> Function() call, {Duration? timeout}) async {
    final http.Response response;
    try {
      response = await call().timeout(timeout ?? _timeout);
    } on TimeoutException {
      throw ApiException('Il server non risponde (${session.baseUrl}). Controlla che sia avviato.');
    } on SocketException {
      throw ApiException(
          'Impossibile contattare il server (${session.baseUrl}). Verifica indirizzo e rete Wi-Fi.');
    } on http.ClientException {
      throw ApiException('Errore di connessione con il server (${session.baseUrl}).');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return response;

    var message = 'Errore del server (${response.statusCode})';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['error'] is String) message = body['error'] as String;
    } on FormatException {
      // corpo non JSON: si usa il messaggio generico
    }
    throw ApiException(message, statusCode: response.statusCode);
  }
}

final api = ApiClient.instance;
