import 'package:flutter/material.dart';

import '../models/alert.dart';
import '../services/api.dart';
import '../shared/strings.dart';
import '../shared/theme.dart';
import '../shared/tokens.dart';
import '../shared/widgets/approval_gate_badge.dart';
import '../shared/widgets/error_box.dart';
import '../shared/widgets/section_label.dart';
import '../shared/widgets/skeleton_loader.dart';
import '../shared/widgets/status_pill.dart';

class CitizenAlertsPage extends StatefulWidget {
  const CitizenAlertsPage({super.key});

  @override
  State<CitizenAlertsPage> createState() => _CitizenAlertsPageState();
}

class _CitizenAlertsPageState extends State<CitizenAlertsPage> {
  List<AlertItem> _alerts = const [];
  bool _loading = true;
  String? _error;

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
      final all = await ApiClient.shared.listAlerts();
      setState(() => _alerts = all.where((a) => a.channel == 'public_push').toList());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final retractedCount = _alerts.where((a) => a.isRetracted).length;
    return RefreshIndicator(
      color: PulseColors.signal,
      backgroundColor: PulseColors.ink800,
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(PulseSpace.x4, PulseSpace.x5, PulseSpace.x4, PulseSpace.x3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(PulseStrings.get('citizen.alerts.title'), style: PulseTheme.display(size: 26)),
                  const SizedBox(height: PulseSpace.x1),
                  EmDashLeader('${_alerts.length} issued · $retractedCount retracted'),
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
                itemBuilder: (_, __) => const SkeletonLoader(height: 120, borderRadius: PulseRadii.xl),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: ErrorBox(error: _error!, onRetry: _refresh),
            )
          else if (_alerts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(PulseSpace.x8),
                child: Center(
                  child: EmDashLeader(PulseStrings.get('citizen.alerts.empty')),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: PulseSpace.x4),
              sliver: SliverList.separated(
                itemCount: _alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: PulseSpace.x3),
                itemBuilder: (_, i) => _AlertCard(alert: _alerts[i]),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: PulseSpace.x8)),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertItem alert;
  const _AlertCard({required this.alert});

  /// Color derived from incidentType field (structured) rather than English
  /// keyword matching — works correctly for Urdu-only alerts.
  Color _channelAccent() {
    if (alert.isRetracted) return PulseColors.dim;
    return switch (alert.incidentType) {
      'flood' || 'water_main_burst' => PulseColors.crimson,
      'fire' => PulseColors.crimson,
      'heat' || 'heatwave' => PulseColors.amber,
      'power_outage' => PulseColors.amber,
      'accident' || 'infrastructure' => PulseColors.saffron,
      _ => PulseColors.signal,
    };
  }

  String _fmtTs(String iso) {
    if (iso.isEmpty) return '';
    final t = DateTime.tryParse(iso.replaceFirst(' ', 'T'));
    if (t == null) return iso;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _channelAccent();
    final retracted = alert.isRetracted;
    final idShort = 'Alert #${alert.incidentId.hashCode.abs() % 10000}';

    return Container(
      decoration: BoxDecoration(
        color: PulseColors.ink800.withValues(alpha: 0.85),
        border: Border.all(color: PulseColors.hairline),
        borderRadius: BorderRadius.circular(PulseRadii.xl),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PulseRadii.xl),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: retracted ? PulseColors.dim : accent, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                    // header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          PulseSpace.x4, PulseSpace.x3, PulseSpace.x4, PulseSpace.x2),
                      child: Row(
                        children: [
                          Text(
                            retracted ? '⊘' : '⚠',
                            style: PulseTheme.data(
                                size: 14, color: accent, weight: FontWeight.w700),
                          ),
                          const SizedBox(width: PulseSpace.x2),
                          Text(
                            retracted
                                ? PulseStrings.get('common.retracted')
                                : 'PUBLIC ALERT',
                            style: PulseTheme.label(color: accent),
                          ),
                          const Spacer(),
                          Text(_fmtTs(alert.issuedAt), style: PulseTheme.dataXs()),
                          const SizedBox(width: PulseSpace.x3),
                          Text(idShort, style: PulseTheme.dataXs()),
                        ],
                      ),
                    ),
                    Container(height: 1, color: PulseColors.hairline),
                    // body
                    Padding(
                      padding: const EdgeInsets.all(PulseSpace.x4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (alert.bodyEn != null && alert.bodyEn!.isNotEmpty)
                            Text(
                              alert.bodyEn!,
                              style: PulseTheme.data(size: 13, color: PulseColors.pearl)
                                  .copyWith(
                                decoration: retracted ? TextDecoration.lineThrough : null,
                                decorationColor: PulseColors.dim,
                                decorationThickness: 1.5,
                                color: retracted ? PulseColors.dim : PulseColors.pearl,
                              ),
                            ),
                          if (alert.bodyUr != null && alert.bodyUr!.isNotEmpty) ...[
                            const SizedBox(height: PulseSpace.x3),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                alert.bodyUr!,
                                style: PulseTheme.urdu(
                                        size: 15,
                                        color: retracted
                                            ? PulseColors.dim
                                            : PulseColors.stone)
                                    .copyWith(
                                        decoration: retracted
                                            ? TextDecoration.lineThrough
                                            : null),
                              ),
                            ),
                          ],
                          if (retracted) ...[
                            const SizedBox(height: PulseSpace.x4),
                            Row(children: [
                              Text(
                                PulseStrings.get(
                                    'citizen.alerts.retraction.correction_label'),
                                style: PulseTheme.label(color: PulseColors.signal),
                              ),
                              const SizedBox(width: PulseSpace.x3),
                              Expanded(
                                  child: Container(
                                      height: 1,
                                      color: PulseColors.hairlineStrong)),
                            ]),
                            const SizedBox(height: PulseSpace.x3),
                            Text(
                              PulseStrings.get(
                                  'citizen.alerts.retraction.correction_en'),
                              style: PulseTheme.data(size: 12, color: PulseColors.pearl),
                            ),
                            const SizedBox(height: PulseSpace.x2),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                PulseStrings.get(
                                    'citizen.alerts.retraction.correction_ur',
                                    PulseStrings.ur),
                                style: PulseTheme.urdu(size: 14, color: PulseColors.stone),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(height: 1, color: PulseColors.hairline),
                    // footer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          PulseSpace.x4, PulseSpace.x2, PulseSpace.x4, PulseSpace.x3),
                      child: Row(
                        children: [
                          if (retracted)
                            StatusPill(
                                label: PulseStrings.get('common.retracted'),
                                color: PulseColors.dim,
                                dense: true)
                          else
                            StatusPill(
                                label: PulseStrings.get('common.active'),
                                color: accent,
                                dense: true),
                          const SizedBox(width: PulseSpace.x3),
                          if (retracted && alert.retractedAt != null)
                            Text(
                              'retracted ${_fmtTs(alert.retractedAt!)}',
                              style: PulseTheme.dataXs(),
                            )
                          else if (alert.requiresHumanApproval)
                            const ApprovalGateBadge()
                          else
                            Text(
                              PulseStrings.get('citizen.alerts.helpline'),
                              style: PulseTheme.dataXs(),
                            ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
