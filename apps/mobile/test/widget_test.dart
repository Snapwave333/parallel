import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/main.dart';
import 'package:parallel/core/session.dart';

void main() {
  testWidgets('shows the auth screen when logged out', (tester) async {
    await tester.pumpWidget(ParallelApp(state: AppState()));

    expect(find.text('Parallel'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Try the demo accounts'), findsOneWidget);
    expect(find.byType(Text), findsWidgets);
  });
}