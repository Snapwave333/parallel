import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/core/api_client.dart';
import 'package:parallel/core/models.dart';
import 'package:parallel/core/session.dart';
import 'package:parallel/features/safety/safety_page.dart';

import '../support/fake_api.dart';
import '../support/test_app.dart';

void main() {
  testWidgets('lists blocked people and lets me unblock one', (tester) async {
    final fake = FakeApi({
      'GET /safety/blocks': (_) => [
            {
              'blocked_id': 5,
              'user': {'id': 5, 'name': 'Jordan'},
              'created_at': 0,
            },
          ],
      'DELETE /safety/blocks/5': (_) => {'ok': true},
    });
    final state = AppState(api: ApiClient(client: fake.build()))
      ..me = PublicUser(id: 1, name: 'Alex');

    await pumpApp(tester, state, const SafetyPage());
    await tester.pumpAndSettle();

    expect(find.text('Jordan'), findsOneWidget);

    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();

    expect(fake.calls, contains('DELETE /safety/blocks/5'));
  });
}
