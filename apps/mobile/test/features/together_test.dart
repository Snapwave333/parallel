import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/core/api_client.dart';
import 'package:parallel/core/models.dart';
import 'package:parallel/core/session.dart';
import 'package:parallel/features/together/together_page.dart';

import '../support/fake_api.dart';
import '../support/test_app.dart';

void main() {
  testWidgets('shows an active session with its pairing code and signals',
      (tester) async {
    final fake = FakeApi({
      'GET /together/sessions': (_) => {
            'sessions': [
              {
                'id': 7,
                'pairing_code': 'AB12CD',
                'state': 'active',
                'permission_scope': {'no_data_saved': true},
                'created_at': 0,
                'other_user': {'id': 2, 'name': 'Maya'},
              },
            ],
          },
      'GET /discover/connections': (_) => [],
      'POST /together/sessions/7/signal': (body) {
        expect(body?['signal'], 'quiet');
        return {'ok': true};
      },
    });
    final state = AppState(api: ApiClient(client: fake.build()))
      ..me = PublicUser(id: 1, name: 'Alex');

    await pumpApp(tester, state, const TogetherPage());
    await tester.pumpAndSettle();

    expect(find.textContaining('AB12CD'), findsOneWidget);
    expect(find.textContaining('No data is saved'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, 'quiet'));
    await tester.pumpAndSettle();

    expect(fake.calls, contains('POST /together/sessions/7/signal'));
  });
}
