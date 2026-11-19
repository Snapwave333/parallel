import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:parallel/core/api_client.dart';
import 'package:parallel/core/session.dart';
import 'package:parallel/features/auth/auth_page.dart';

import '../support/fake_api.dart';
import '../support/test_app.dart';

void main() {
  testWidgets('logging in with email and password sets the session',
      (tester) async {
    final fake = FakeApi({
      'POST /auth/login': (body) {
        expect(body, {'email': 'alex@example.com', 'password': 'password123'});
        return {
          'token': 'session-token',
          'user': {'id': 1, 'name': 'Alex'},
        };
      },
    });
    final state = AppState(api: ApiClient(client: fake.build()));

    await pumpApp(tester, state, const AuthPage());

    await tester.enterText(find.byType(TextFormField).at(0), 'alex@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(state.loggedIn, isTrue);
    expect(state.me?.displayName, 'Alex');
    expect(fake.calls, contains('POST /auth/login'));
  });

  testWidgets('the demo-accounts button seeds and logs in', (tester) async {
    final fake = FakeApi({
      'POST /dev/seed': (_) => {
            'seeded': [
              {
                'user_id': 1,
                'email': 'seed.alex@example.com',
                'name': 'Alex',
                'password': 'password123',
                'token': 'seed-token',
              },
            ],
          },
      'GET /profile/me': (_) => {
            'user': {'id': 1, 'name': 'Alex', 'city': 'Denver'},
          },
    });
    final state = AppState(api: ApiClient(client: fake.build()));

    await pumpApp(tester, state, const AuthPage());

    await tester.tap(find.widgetWithText(OutlinedButton, 'Try the demo accounts'));
    await tester.pumpAndSettle();

    expect(state.loggedIn, isTrue);
    expect(state.me?.city, 'Denver');
  });

  testWidgets('a failed login surfaces the server error', (tester) async {
    final fake = FakeApi({
      'POST /auth/login': (_) =>
          throw FakeHttpError(401, 'invalid email or password'),
    });
    final state = AppState(api: ApiClient(client: fake.build()));

    await pumpApp(tester, state, const AuthPage());

    await tester.enterText(find.byType(TextFormField).at(0), 'alex@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(state.loggedIn, isFalse);
    expect(find.textContaining('invalid email or password'), findsOneWidget);
  });
}
