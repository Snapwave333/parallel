import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/core/api_client.dart';
import 'package:parallel/core/models.dart';
import 'package:parallel/core/session.dart';
import 'package:parallel/features/messaging/chat_page.dart';
import 'package:parallel/features/messaging/conversations_page.dart';

import '../support/fake_api.dart';
import '../support/test_app.dart';

void main() {
  testWidgets('lists conversations with their last message', (tester) async {
    final fake = FakeApi({
      'GET /messaging/conversations': (_) => [
            {
              'id': 10,
              'other_user': {'id': 2, 'name': 'Maya'},
              'last_message': {
                'id': 1,
                'sender_id': 2,
                'body': 'hey there',
                'created_at': 0,
              },
            },
          ],
      'GET /discover/connections': (_) => [],
    });
    final state = AppState(api: ApiClient(client: fake.build()))
      ..me = PublicUser(id: 1, name: 'Alex');

    await pumpApp(tester, state, ConversationsPage(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('hey there'), findsOneWidget);
  });

  testWidgets('sending a chat message appends it and shows no-response flag',
      (tester) async {
    final fake = FakeApi({
      'GET /messaging/conversations/10/messages': (_) => {
            'conversation_id': 10,
            'messages': [
              {
                'id': 1,
                'conversation_id': 10,
                'sender_id': 2,
                'body': 'hi!',
                'kind': 'text',
                'no_response_needed': false,
                'state': 'sent',
                'created_at': 0,
              },
            ],
          },
      'GET /messaging/conversations/10/contract': (_) => {'rules': []},
      'GET /messaging/intent/2': (_) => {
            'mine': null,
            'mutual': null,
            'theirs_revealed': false,
          },
      'GET /messaging/status/me': (_) => {'battery': 3, 'temperature': 'normal'},
      'POST /messaging/conversations/10/messages': (body) {
        expect(body?['body'], 'hello back');
        return {
          'type': 'message',
          'message': {
            'id': 2,
            'conversation_id': 10,
            'sender_id': 1,
            'body': 'hello back',
            'kind': 'text',
            'no_response_needed': false,
            'state': 'sent',
            'created_at': 1,
          },
        };
      },
    });
    final state = AppState(api: ApiClient(client: fake.build()))
      ..me = PublicUser(id: 1, name: 'Alex');

    await pumpApp(
      tester,
      state,
      ChatPage(
        state: state,
        conversationId: 10,
        peer: PublicUser(id: 2, name: 'Maya'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('hi!'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hello back');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('hello back'), findsOneWidget);
    expect(fake.calls, contains('POST /messaging/conversations/10/messages'));
  });
}
