import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/core/session.dart';

/// Wraps [child] with the [AppScope] every feature page expects above it,
/// mirroring what `main.dart` sets up for the real app.
Future<void> pumpApp(
  WidgetTester tester,
  AppState state,
  Widget child,
) async {
  await tester.pumpWidget(
    AppScope(
      state: state,
      child: MaterialApp(home: child),
    ),
  );
}
