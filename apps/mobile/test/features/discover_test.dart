import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/core/api_client.dart';
import 'package:parallel/core/models.dart';
import 'package:parallel/core/session.dart';
import 'package:parallel/features/discover/discover_page.dart';

import '../support/fake_api.dart';
import '../support/test_app.dart';

void main() {
  testWidgets("shows today's introductions with the explain reason",
      (tester) async {
    final fake = FakeApi({
      'GET /discover/today': (_) => {
            'count': 1,
            'day': 20752,
            'introductions': [
              {
                'user_id': 2,
                'user': {'id': 2, 'name': 'Maya', 'age': 27, 'city': 'Denver'},
                'photos': [],
                'reason': {
                  'overall': 83.0,
                  'shared_interests': 1,
                  'explain': [
                    {'level': 'easy', 'text': 'Direct communication (Both: very direct)'},
                  ],
                },
              },
            ],
          },
      'GET /discover/requests/incoming': (_) => [],
    });
    final state = AppState(api: ApiClient(client: fake.build()))
      ..me = PublicUser(id: 1, name: 'Alex');

    await pumpApp(tester, state, Scaffold(body: DiscoverPage(state: state)));
    await tester.pumpAndSettle();

    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('83%'), findsOneWidget);
    expect(find.textContaining('Direct communication'), findsOneWidget);
  });

  testWidgets('introducing yourself posts to /discover/introduce',
      (tester) async {
    final fake = FakeApi({
      'GET /discover/today': (_) => {
            'count': 1,
            'day': 1,
            'introductions': [
              {
                'user_id': 2,
                'user': {'id': 2, 'name': 'Maya'},
                'photos': [],
                'reason': {'overall': 50.0, 'shared_interests': 0, 'explain': []},
              },
            ],
          },
      'GET /discover/requests/incoming': (_) => [],
      'POST /discover/introduce': (body) {
        expect(body?['to_user'], 2);
        return {'matched': false, 'message': 'Introduction sent.'};
      },
    });
    final state = AppState(api: ApiClient(client: fake.build()))
      ..me = PublicUser(id: 1, name: 'Alex');

    await pumpApp(tester, state, Scaffold(body: DiscoverPage(state: state)));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Introduce'));
    await tester.pumpAndSettle();

    expect(fake.calls, contains('POST /discover/introduce'));
    expect(find.textContaining('Introduction sent to Maya'), findsOneWidget);
  });
}
