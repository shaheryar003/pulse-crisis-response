import 'package:flutter/material.dart';

import 'shared/auth.dart';
import 'shared/theme.dart';
import 'shared/role_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PulseApp());
}

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse — Crisis Response',
      debugShowCheckedModeBanner: false,
      theme: PulseTheme.dark(),
      darkTheme: PulseTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const AuthGate(),
      routes: {
        '/role': (_) => const RoleRouter(),
      },
    );
  }
}
