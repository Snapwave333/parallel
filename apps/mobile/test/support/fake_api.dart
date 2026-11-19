import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Thrown by a route handler to make the fake backend answer with a
/// non-2xx status (mirrors how [ApiClient] decodes `{"error": "..."}`).
class FakeHttpError {
  FakeHttpError(this.status, this.message);
  final int status;
  final String message;
}

/// A minimal fake backend for widget tests. Maps "METHOD /path" (path only,
/// no query string) to a JSON-encodable response. Unhandled routes 404 so a
/// test fails loudly instead of hanging on a silent network call.
class FakeApi {
  FakeApi(this.routes);

  final Map<String, Object? Function(Map<String, Object?>? body)> routes;
  final List<String> calls = [];

  http.Client build() => MockClient((request) async {
        final key = '${request.method} ${request.url.path}';
        calls.add(key);
        final handler = routes[key];
        if (handler == null) {
          return http.Response(
              jsonEncode({'error': 'unhandled route: $key'}), 404);
        }
        final body = request.body.isEmpty
            ? null
            : jsonDecode(request.body) as Map<String, Object?>;
        try {
          final result = handler(body);
          return http.Response(jsonEncode(result), 200,
              headers: {'content-type': 'application/json'});
        } on FakeHttpError catch (e) {
          return http.Response(
              jsonEncode({'error': e.message}), e.status,
              headers: {'content-type': 'application/json'});
        }
      });
}
