import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../services/api.dart';
import '../shared/auth.dart';
import '../shared/strings.dart';
import '../shared/theme.dart';
import '../shared/tokens.dart';
import '../shared/widgets/cta_button.dart';
import '../shared/widgets/error_box.dart';
import '../shared/widgets/section_label.dart';
import '../shared/widgets/severity_pill.dart';
import '../shared/widgets/skeleton_loader.dart';
import '../shared/widgets/status_pill.dart';

/// Citizen verify-nearby flow (Sprint-5 task 5.8).
///
/// Lists active incidents. For each, the citizen can submit a field
/// verification (confirm they see it) or dispute (flags possible
/// misclassification). Both submit via POST /signals/citizen with
/// expert_correction = true.
class CitizenVerifyPage extends StatefulWidget {
  const CitizenVerifyPage({super.key});

  @override
  State<CitizenVerifyPage> createState() => _CitizenVerifyPageState();
}

class _CitizenVerifyPageState extends State<CitizenVerifyPage> {
  List<Incident> _incidents = const [];
  bool _loading = true;
  String? _error;
  final Map<String, _VerifyState> _states = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ApiClient.shared.listIncidents();
      setState(() => _incidents = r.where((i) => i.status == 'active').toList());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit(Incident inc, bool confirm) async {
    setState(() => _states[inc.id] = _VerifyState.busy);
    try {
      final payload = {
        'report_id': '${inc.id}_verify_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': session.userId ?? 'anonymous',
        'category': inc.type,
        'description': confirm
            ? 'Field verification: confirmed observation of ${inc.type} in ${inc.zone}'
            : 'Field dispute: cannot confirm ${inc.type} classification in ${inc.zone}',
        'geo': {'lat': 0.0, 'lon': 0.0, 'accuracy_m': 9999},
        'media': <Map<String, String>>[],
        'ts': DateTime.now().toUtc().toIso8601String(),
        'user_trust': 0.7,
        'expert_correction': true,
        'verification_type': confirm ? 'confirm' : 'dispute',
        'incident_id': inc.id,
      };
      await ApiClient.shared.submitCitizenReport(payload);
      setState(() => _states[inc.id] =
          confirm ? _VerifyState.confirmed : _VerifyState.disputed);
    } catch (e) {
      setState(() => _states[inc.id] = _VerifyState.idle);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: PulseColors.signal,
      backgroundColor: PulseColors.ink800,
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  PulseSpace.x4, PulseSpace.x5, PulseSpace.x4, PulseSpace.x3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(PulseStrings.get('citizen.verify.title'),
                      style: PulseTheme.display(size: 26)),
                  const SizedBox(height: PulseSpace.x1),
                  EmDashLeader(PulseStrings.get('citizen.verify.subtitle')),
                ],
              ),
            ),
          ),
          if (_loading)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: PulseSpace.x4),
              sliver: SliverList.separated(
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(height: PulseSpace.x3),
                itemBuilder: (_, __) => const SkeletonLoader(height: 140, borderRadius: PulseRadii.xl),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
                child: ErrorBox(error: _error!, onRetry: _refresh))
          else if (_incidents.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(PulseSpace.x8),
                child: Center(
                  child: EmDashLeader(PulseStrings.get('citizen.verify.empty')),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: PulseSpace.x4),
              sliver: SliverList.separated(
                itemCount: _incidents.length,
                separatorBuilder: (_, __) => const SizedBox(height: PulseSpace.x3),
                itemBuilder: (_, i) => _VerifyCard(
                  incident: _incidents[i],
                  state: _states[_incidents[i].id] ?? _VerifyState.idle,
                  onConfirm: () => _submit(_incidents[i], true),
                  onDispute: () => _submit(_incidents[i], false),
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: PulseSpace.x8)),
        ],
      ),
    );
  }
}

enum _VerifyState { idle, busy, confirmed, disputed }

class _VerifyCard extends StatelessWidget {
  final Incident incident;
  final _VerifyState state;
  final VoidCallback onConfirm;
  final VoidCallback onDispute;
  const _VerifyCard({
    required this.incident,
    required this.state,
    required this.onConfirm,
    required this.onDispute,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = incident.type.replaceAll('_', ' ').toUpperCase();
    final done = state == _VerifyState.confirmed || state == _VerifyState.disputed;
    final busy = state == _VerifyState.busy;

    return Container(
      decoration: BoxDecoration(
        color: PulseColors.ink800.withValues(alpha: 0.85),
        border: Border.all(color: PulseColors.hairline),
        borderRadius: BorderRadius.circular(PulseRadii.xl),
      ),
      padding: const EdgeInsets.all(PulseSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            SeverityPill(severity: incident.severity, withLabel: false),
            const SizedBox(width: PulseSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(typeLabel,
                      style: PulseTheme.label(color: PulseColors.pearl)
                          .copyWith(fontSize: 12)),
                  Text(incident.zone,
                      style: PulseTheme.dataSm(color: PulseColors.stone)),
                ],
              ),
            ),
            if (done)
              StatusPill(
                label: state == _VerifyState.confirmed
                    ? 'CONFIRMED'
                    : 'DISPUTED',
                color: state == _VerifyState.confirmed
                    ? PulseColors.lime
                    : PulseColors.amber,
                dense: true,
              ),
          ]),
          if (!done) ...[
            const SizedBox(height: PulseSpace.x4),
            Container(height: 1, color: PulseColors.hairline),
            const SizedBox(height: PulseSpace.x3),
            Row(children: [
              Expanded(
                child: CtaButton(
                  label: PulseStrings.get('citizen.verify.confirm'),
                  loading: busy,
                  onPressed: busy ? null : onConfirm,
                  color: PulseColors.lime,
                ),
              ),
              const SizedBox(width: PulseSpace.x3),
              Expanded(
                child: CtaButton(
                  label: PulseStrings.get('citizen.verify.dispute'),
                  loading: busy,
                  onPressed: busy ? null : onDispute,
                  color: PulseColors.amber,
                ),
              ),
            ]),
          ],
          if (done) ...[
            const SizedBox(height: PulseSpace.x2),
            Text(
              PulseStrings.get('citizen.verify.submitted'),
              style: PulseTheme.dataSm(color: PulseColors.mist),
            ),
          ],
        ],
      ),
    );
  }
}
