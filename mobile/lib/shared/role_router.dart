import 'package:flutter/material.dart';

import '../citizen/home.dart';
import '../citizen/report.dart';
import '../citizen/alerts.dart';
import '../citizen/verify.dart';
import '../command/dashboard.dart';
import '../responder/queue.dart';
import '../responder/status.dart';
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
  // Sprint-5 task 5.8: verify screen now wired in as 4th tab
  final _pages = const [
    CitizenHome(),
    CitizenReportPage(),
    CitizenAlertsPage(),
    CitizenVerifyPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.ink900,
      appBar: UtilBar(
        tabs: const [
          UtilTab('Map'),
          UtilTab('Report'),
          UtilTab('Alerts'),
          UtilTab('Verify'),
        ],
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

class ResponderShell extends StatefulWidget {
  const ResponderShell({super.key});
  @override
  State<ResponderShell> createState() => _ResponderShellState();
}

class _ResponderShellState extends State<ResponderShell> {
  int _index = 0;
  // Sprint-5 task 5.10: status screen now wired in as 2nd tab
  final _pages = const [ResponderQueuePage(), ResponderStatusPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.ink900,
      appBar: UtilBar(
        tabs: const [UtilTab('Queue'), UtilTab('Status')],
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

class CommandShell extends StatelessWidget {
  const CommandShell({super.key});
  @override
  Widget build(BuildContext context) {
    return const CommandDashboardPage();
  }
}
