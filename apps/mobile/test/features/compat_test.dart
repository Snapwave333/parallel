import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/core/api_client.dart';
import 'package:parallel/core/models.dart';
import 'package:parallel/core/session.dart';
import 'package:parallel/features/compat/explain_page.dart';

import '../support/fake_api.dart';
import '../support/test_app.dart';

void main() {
  testWidgets('explains a compatibility match dimension by dimension',
      (tester) async {
    final fake = FakeApi({
      'GET /compat/explain/2': (_) => {
            'dealbreaker_conflicts': [],
            'dimensions': [
              {
                'dimension': 'communication.directness',
                'label': 'Directness',
                'alignment': 'Aligned',
                'compat': 1.0,
                'importance': {'a': 5, 'b': 5},
                'items': {
                  'a': {'value': 'very_direct'},
                  'b': {'value': 'very_direct'},
                },
              },
            ],
            'shared_interests': 2,
            'explain': [
              {'level': 'easy', 'text': 'Direct communication (Both: very direct)'},
            ],
          },
    });
    final state = AppState(api: ApiClient(client: fake.build()))
      ..me = PublicUser(id: 1, name: 'Alex');

    await pumpApp(tester, state, ExplainPage(state: state, otherId: 2));
    await tester.pumpAndSettle();

    expect(find.text('Directness'), findsOneWidget);
    expect(find.text('Aligned'), findsOneWidget);
    expect(find.textContaining('2 shared interests'), findsOneWidget);
    expect(find.textContaining('Direct communication'), findsOneWidget);
  });
}
