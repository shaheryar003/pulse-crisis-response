import 'package:flutter/material.dart';

import '../citizen/home.dart';
import '../citizen/report.dart';
import '../citizen/alerts.dart';
import '../command/dashboard.dart';
import '../responder/queue.dart';
import 'auth.dart';
import 'tokens.dart';
import 'widgets/util_bar.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    switch (session.role) {
      case 'responder':
        return const ResponderShell();
      case 'command':
        return const CommandShell();
      default:
        return const CitizenShell();
    }
  }
}

class CitizenShell extends StatefulWidget {
  const CitizenShell({super.key});
  @override
  State<CitizenShell> createState() => _CitizenShellState();
}

class _CitizenShellState extends State<CitizenShell> {
  int _index = 0;
  final _pages = const [CitizenHome(), CitizenReportPage(), CitizenAlertsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.ink900,
      appBar: UtilBar(
        tabs: const [UtilTab('Map'), UtilTab('Report'), UtilTab('Alerts')],
        activeIndex: _index,
        onTab: (i) => setState(() => _index = i),
        actions: [
          UtilIconButton(
            icon: Icons.logout,
            tooltip: 'Sign out',
            onPressed: () async {
              session.token = null;
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
    );
  }
}

class ResponderShell extends StatelessWidget {
  const ResponderShell({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.ink900,
      appBar: UtilBar(
        tabs: const [UtilTab('Queue')],
        actions: [
          UtilIconButton(
            icon: Icons.logout,
            tooltip: 'Sign out',
            onPressed: () async {
              session.token = null;
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: const ResponderQueuePage(),
    );
  }
}

class CommandShell extends StatelessWidget {
  const CommandShell({super.key});
  @override
  Widget build(BuildContext context) {
    return const CommandDashboardPage();
  }
}
