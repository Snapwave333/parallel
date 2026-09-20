import 'package:flutter/widgets.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../core/models.dart';

/// Root application state. Owns the [ApiClient] (and therefore the bearer
/// token) and the current user. Pages read this through [AppState.of] and
/// call its mutations instead of holding their own auth state.
class AppState extends ChangeNotifier {
  AppState({String? baseUrl}) : api = ApiClient(baseUrl: baseUrl ?? apiBase);

  final ApiClient api;
  PublicUser? me;
  String? authError;

  bool get loggedIn => api.token != null;

  void _setToken(String token) {
    api.token = token;
    notifyListeners();
  }

  Future<void> register(
      String email, String password, String name) async {
    authError = null;
    try {
      final json = await api.post('/auth/register', {
        'email': email,
        'password': password,
        'name': name,
      });
      _applyAuth(json);
    } catch (e) {
      authError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    authError = null;
    try {
      final json = await api.post('/auth/login', {
        'email': email,
        'password': password,
      });
      _applyAuth(json);
    } catch (e) {
      authError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Debug convenience: `POST /dev/seed` returns the three demo users and
  /// tokens; log in as the first one.
  Future<void> demoLogin() async {
    authError = null;
    try {
      final json = await api.post('/dev/seed');
      final seeded = json is Map && json['seeded'] is List
          ? (json['seeded'] as List)
              .whereType<Map<String, Object?>>()
              .first
          : null;
      if (seeded == null) {
        throw ApiException(0, 'no seeded users returned');
      }
      _setToken(_str(seeded['token']));
      me = PublicUser.fromJson(seeded);
      await refreshProfile();
    } catch (e) {
      authError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void _applyAuth(Object? json) {
    if (json is! Map) throw ApiException(0, 'invalid auth response');
    _setToken(_str(json['token']));
    final user = json['user'];
    me = user is Map<String, Object?> ? PublicUser.fromJson(user) : null;
  }

  Future<void> refreshProfile() async {
    final json = await api.get('/profile/me');
    if (json is Map<String, Object?> && json['user'] is Map) {
      me = PublicUser.fromJson(json['user'] as Map<String, Object?>);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final had = loggedIn;
    api.token = null;
    me = null;
    notifyListeners();
    if (had) {
      try {
        await api.post('/auth/logout');
      } catch (_) {
        // token already gone locally; the server session stays until it
        // expires, which is fine for a dev build.
      }
    }
  }

  static String _str(Object? v) {
    if (v is String) return v;
    if (v is num) return v.toString();
    return '';
  }

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget');
    return scope!.state;
  }

  static AppState read(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<AppScope>();
    assert(element != null, 'AppScope is missing above this widget');
    return (element!.widget as AppScope).state;
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.state, required super.child});

  final AppState state;

  @override
  bool updateShouldNotify(AppScope oldWidget) => state != oldWidget.state;
}