import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/core/api_client.dart';
import 'package:parallel/core/models.dart';
import 'package:parallel/core/session.dart';
import 'package:parallel/features/dates/dates_page.dart';

import '../support/fake_api.dart';
import '../support/test_app.dart';

void main() {
  testWidgets('shows a pending plan with its fallback and lets me accept it',
      (tester) async {
    final fake = FakeApi({
      'GET /dates/plans': (_) => {
            'plans': [
              {
                'plan': {
                  'id': 5,
                  'initiator_id': 2,
                  'partner_id': 1,
                  'title': 'Quiet coffee',
                  'plan_a': 'Coffee shop on 5th',
                  'plan_b': 'Walk in the park instead',
                  'day': 20760,
                  'state': 'pending',
                  'other_user': {'id': 2, 'name': 'Maya'},
                },
              },
            ],
          },
      'GET /discover/connections': (_) => [],
      'POST /dates/plans/5/accept': (_) => {'id': 5, 'state': 'accepted'},
    });
    final state = AppState(api: ApiClient(client: fake.build()))
      ..me = PublicUser(id: 1, name: 'Alex');

    await pumpApp(tester, state, const DatesPage());
    await tester.pumpAndSettle();

    expect(find.text('Quiet coffee'), findsOneWidget);
    expect(find.text('Coffee shop on 5th'), findsOneWidget);
    expect(find.text('Walk in the park instead'), findsOneWidget);

    // Alex (id 1) is the recipient, not the initiator (id 2): "Accept".
    await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
    await tester.pumpAndSettle();

    expect(fake.calls, contains('POST /dates/plans/5/accept'));
  });
}
