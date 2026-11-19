import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiException implements Exception {
  ApiException(this.status, this.message);
  final int status;
  final String message;

  @override
  String toString() => message;
}

/// Thin JSON client for the Parallel backend. Holds the bearer token, so a
/// logged-in [ApiClient] is all a feature page needs.
class ApiClient {
  ApiClient({this.baseUrl = apiBase, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? token;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers({bool json = false}) => {
        if (token != null) 'Authorization': 'Bearer $token',
        if (json) 'Content-Type': 'application/json',
      };

  Future<Object?> req(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final hasBody = body != null;
    http.Response resp;
    try {
      final uri = _uri(path);
      final headers = _headers(json: hasBody);
      switch (method.toUpperCase()) {
        case 'GET':
          resp = await _client.get(uri, headers: headers);
        case 'POST':
          resp = await _client.post(uri,
              headers: headers,
              body: hasBody ? jsonEncode(body) : null);
        case 'PUT':
          resp = await _client.put(uri,
              headers: headers,
              body: hasBody ? jsonEncode(body) : null);
        case 'PATCH':
          resp = await _client.patch(uri,
              headers: headers,
              body: hasBody ? jsonEncode(body) : null);
        case 'DELETE':
          resp = await _client.delete(uri, headers: headers);
        default:
          throw ApiException(0, 'unsupported method $method');
      }
    } on http.ClientException catch (e) {
      throw ApiException(0, 'Cannot reach the server at $baseUrl (${e.message}).');
    }

    Object? decoded;
    if (resp.body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(resp.bodyBytes));
      } catch (_) {
        decoded = null;
      }
    }
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return decoded;
    }
    final msg = decoded is Map && decoded['error'] is String
        ? decoded['error'] as String
        : 'HTTP ${resp.statusCode}';
    throw ApiException(resp.statusCode, msg);
  }

  Future<Object?> get(String path) => req('GET', path);
  Future<Object?> post(String path, [Map<String, Object?>? body]) =>
      req('POST', path, body: body);
  Future<Object?> put(String path, [Map<String, Object?>? body]) =>
      req('PUT', path, body: body);
  Future<Object?> patch(String path, [Map<String, Object?>? body]) =>
      req('PATCH', path, body: body);
  Future<Object?> delete(String path) => req('DELETE', path);
}