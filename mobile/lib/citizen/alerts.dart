import 'package:flutter/material.dart';

import '../models/alert.dart';
import '../services/api.dart';
import '../shared/theme.dart';
import '../shared/tokens.dart';
import '../shared/widgets/section_label.dart';
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
                  Text('Alerts', style: PulseTheme.display(size: 26)),
                  const SizedBox(height: PulseSpace.x1),
                  EmDashLeader('${_alerts.length} issued · $retractedCount retracted'),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: PulseColors.signal, strokeWidth: 1.5),
                ),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(PulseSpace.x6),
                child: Text(_error!, style: PulseTheme.dataSm(color: PulseColors.crimson)),
              ),
            )
          else if (_alerts.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(PulseSpace.x8),
                child: Center(child: EmDashLeader('No alerts yet — run a scenario from Command.')),
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

  Color _channelAccent() {
    if (alert.isRetracted) return PulseColors.dim;
    final body = (alert.bodyEn ?? '').toLowerCase();
    if (body.contains('flood') || body.contains('water')) return PulseColors.crimson;
    if (body.contains('fire')) return PulseColors.crimson;
    if (body.contains('heat')) return PulseColors.amber;
    if (body.contains('power')) return PulseColors.amber;
    return PulseColors.signal;
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
    final idShort = alert.incidentId.length > 10
        ? alert.incidentId.substring(0, 10)
        : alert.incidentId;

    return Container(
      decoration: BoxDecoration(
        color: PulseColors.ink800,
        border: Border(
          left: BorderSide(color: retracted ? PulseColors.dim : accent, width: 3),
          top: const BorderSide(color: PulseColors.hairline, width: 1),
          right: const BorderSide(color: PulseColors.hairline, width: 1),
          bottom: const BorderSide(color: PulseColors.hairline, width: 1),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(PulseRadii.md),
          bottomRight: Radius.circular(PulseRadii.md),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(PulseSpace.x4, PulseSpace.x3, PulseSpace.x4, PulseSpace.x2),
            child: Row(
              children: [
                Text(
                  retracted ? '⊘' : '⚠',
                  style: PulseTheme.data(size: 14, color: accent, weight: FontWeight.w700),
                ),
                const SizedBox(width: PulseSpace.x2),
                Text(
                  retracted ? 'RETRACTED' : 'PUBLIC ALERT',
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
                    style: PulseTheme.data(size: 13, color: PulseColors.pearl).copyWith(
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
                      style: PulseTheme.urdu(size: 15, color: retracted ? PulseColors.dim : PulseColors.stone)
                          .copyWith(decoration: retracted ? TextDecoration.lineThrough : null),
                    ),
                  ),
                ],
                if (retracted) ...[
                  const SizedBox(height: PulseSpace.x4),
                  Row(children: [
                    Text('CORRECTION', style: PulseTheme.label(color: PulseColors.signal)),
                    const SizedBox(width: PulseSpace.x3),
                    Expanded(child: Container(height: 1, color: PulseColors.hairlineStrong)),
                  ]),
                  const SizedBox(height: PulseSpace.x3),
                  Text(
                    'The original classification has been retracted. Updated agencies are responding. Apologies for the alarm.',
                    style: PulseTheme.data(size: 12, color: PulseColors.pearl),
                  ),
                  const SizedBox(height: PulseSpace.x2),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'پہلی اطلاع واپس لی جا چکی ہے۔ متعلقہ ادارے کام کر رہے ہیں۔',
                      style: PulseTheme.urdu(size: 14, color: PulseColors.stone),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(height: 1, color: PulseColors.hairline),
          Padding(
            padding: const EdgeInsets.fromLTRB(PulseSpace.x4, PulseSpace.x2, PulseSpace.x4, PulseSpace.x3),
            child: Row(
              children: [
                if (retracted)
                  StatusPill(label: 'RETRACTED', color: PulseColors.dim, dense: true)
                else
                  StatusPill(label: 'ACTIVE', color: accent, dense: true),
                const SizedBox(width: PulseSpace.x3),
                if (retracted && alert.retractedAt != null)
                  Text(
                    'retracted ${_fmtTs(alert.retractedAt!)}',
                    style: PulseTheme.dataXs(),
                  )
                else
                  Text('helpline 1122', style: PulseTheme.dataXs()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
