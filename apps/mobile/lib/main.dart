import 'package:flutter/material.dart';

import 'core/session.dart';
import 'design/theme.dart';
import 'features/auth/auth_page.dart';
import 'features/home/home_shell.dart';

void main() {
  runApp(ParallelApp(state: AppState()));
}

class ParallelApp extends StatelessWidget {
  const ParallelApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Parallel',
        theme: buildParallelTheme(),
        debugShowCheckedModeBanner: false,
        home: ListenableBuilder(
          listenable: state,
          builder: (context, _) =>
              state.loggedIn ? const HomeShell() : const AuthPage(),
        ),
      ),
    );
  }
}