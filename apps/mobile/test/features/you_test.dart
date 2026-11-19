import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/core/api_client.dart';
import 'package:parallel/core/models.dart';
import 'package:parallel/core/session.dart';
import 'package:parallel/features/you/you_page.dart';

import '../support/fake_api.dart';
import '../support/test_app.dart';

void main() {
  testWidgets('shows the profile and current social-capacity status',
      (tester) async {
    final fake = FakeApi({
      'GET /messaging/status/me': (_) => {'battery': 2, 'temperature': 'normal'},
    });
    final state = AppState(api: ApiClient(client: fake.build()))
      ..me = PublicUser(id: 1, name: 'Alex', age: 29, city: 'Denver');

    await pumpApp(tester, state, const YouPage());
    await tester.pumpAndSettle();

    expect(find.text('Alex'), findsWidgets);
    expect(find.text('Denver'), findsOneWidget);
    expect(find.text('Your social capacity'), findsOneWidget);
  });

  testWidgets('changing the battery segment saves the new status',
      (tester) async {
    final fake = FakeApi({
      'GET /messaging/status/me': (_) => {'battery': 2, 'temperature': 'normal'},
      'PUT /messaging/status/me': (body) {
        expect(body?['battery'], 4);
        return {'battery': 4, 'temperature': 'normal'};
      },
    });
    final state = AppState(api: ApiClient(client: fake.build()))
      ..me = PublicUser(id: 1, name: 'Alex');

    await pumpApp(tester, state, const YouPage());
    await tester.pumpAndSettle();

    await tester.tap(find.text('4').first);
    await tester.pumpAndSettle();

    expect(fake.calls, contains('PUT /messaging/status/me'));
  });
}
