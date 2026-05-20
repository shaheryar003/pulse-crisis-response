import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/incident.dart';
import '../services/api.dart';
import '../shared/auth.dart';
import '../shared/strings.dart';
import '../shared/theme.dart';
import '../shared/tokens.dart';
import '../shared/widgets/audit_chain_panel.dart';
import '../shared/widgets/degraded_mode_banner.dart';
import '../shared/widgets/dot_leader.dart';
import '../shared/widgets/error_box.dart';
import '../shared/widgets/incident_card.dart';
import '../shared/widgets/map_pin.dart';
import '../shared/widgets/section_label.dart';
import '../shared/widgets/skeleton_loader.dart';
import '../shared/widgets/sparkbar.dart';
import '../shared/widgets/trace_event_card.dart';
import '../shared/widgets/util_bar.dart';

class CommandDashboardPage extends StatefulWidget {
  const CommandDashboardPage({super.key});

  @override
  State<CommandDashboardPage> createState() => _CommandDashboardPageState();
}

class _CommandDashboardPageState extends State<CommandDashboardPage> {
  final List<_TraceEvent> _events = [];
  List<Incident> _incidents = const [];
  Map<String, int> _assetCounts = {};
  StreamSubscription<Map<String, dynamic>>? _sub;
  String? _selectedIncidentId;
  Map<String, dynamic>? _incidentDetail;
  bool _detailLoading = false;
  DateTime _lastUpdate = DateTime.now();
  String? _loadError;
  bool _wsConnected = false;
  int _wsRetryCount = 0;
  Timer? _wsRetryTimer;

  // Degraded-mode signals surfaced from /trace
  final List<DegradedSignal> _degradedSignals = [];

  static const _zoneCoords = <String, LatLng>{
    'G-10': LatLng(33.696, 73.005),
    'G-11': LatLng(33.690, 72.985),
    'G-8': LatLng(33.705, 73.045),
    'G-9': LatLng(33.700, 73.025),
    'F-6': LatLng(33.727, 73.085),
    'F-7': LatLng(33.728, 73.065),
    'F-7-katchi': LatLng(33.720, 73.062),
    'F-8': LatLng(33.728, 73.045),
    'F-10': LatLng(33.708, 73.008),
    'F-11': LatLng(33.700, 72.985),
    'I-8': LatLng(33.685, 73.045),
    'I-9': LatLng(33.680, 73.025),
    'I-10': LatLng(33.675, 73.005),
    'I-11': LatLng(33.670, 72.985),
    'Blue-Area': LatLng(33.720, 73.060),
    'Bara-Kahu': LatLng(33.732, 73.160),
    'Islamabad': LatLng(33.700, 73.040),
  };

  @override
  void initState() {
    super.initState();
    _refreshIncidents();
    _refreshResources();
    _connect();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _wsRetryTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshIncidents() async {
    setState(() => _loadError = null);
    try {
      final r = await ApiClient.shared.listIncidents();
      if (!mounted) return;
      setState(() {
        _incidents = r;
        _lastUpdate = DateTime.now();
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  Future<void> _refreshResources() async {
    try {
      final list = await ApiClient.shared.resources();
      final byType = <String, int>{};
      for (final a in list) {
        final t = a['type'] as String? ?? 'other';
        byType[t] = (byType[t] ?? 0) + 1;
      }
      if (mounted) setState(() => _assetCounts = byType);
    } catch (_) {
      // Resource gauge is non-critical — silent failure acceptable
    }
  }

  Future<void> _loadIncidentDetail(String id) async {
    setState(() {
      _selectedIncidentId = id;
      _incidentDetail = null;
      _detailLoading = true;
    });
    try {
      final detail = await ApiClient.shared.incidentDetail(id);
      if (mounted) setState(() => _incidentDetail = detail);
    } catch (_) {
      // Detail fetch failure is non-critical
    } finally {
      if (mounted) setState(() => _detailLoading = false);
    }
  }

  void _connect() {
    _sub?.cancel();
    _sub = ApiClient.shared.traceStream().listen(
      (event) {
        if (!mounted) return;
        if (!_wsConnected) setState(() => _wsConnected = true);
        _wsRetryCount = 0;
        _processTraceEvent(event);
      },
      onError: (_) => _scheduleReconnect(),
      onDone: () => _scheduleReconnect(),
    );
    setState(() => _wsConnected = true);
  }

  void _scheduleReconnect() {
    if (!mounted) return;
    setState(() => _wsConnected = false);
    _wsRetryTimer?.cancel();
    final delay = Duration(seconds: _wsRetryCount < 3 ? 3 : 10);
    _wsRetryCount++;
    _wsRetryTimer = Timer(delay, () {
      if (mounted) _connect();
    });
  }

  void _processTraceEvent(Map<String, dynamic> event) {
    final payload =
        (event['payload'] as Map?)?.cast<String, dynamic>() ?? const {};
    final envelope =
        (payload['envelope'] as Map?)?.cast<String, dynamic>() ?? const {};
    final tier = (payload['tier'] ?? envelope['tier']) as int? ?? 0;
    final agent = (payload['agent'] ?? envelope['agent']) as String? ?? 'unknown';
    final decision = (payload['decision'] ?? envelope['decision']) as String? ?? '';
    final conf = (payload['confidence'] ?? envelope['confidence']) as num?;
    final hyp =
        (payload['hypothesis'] ?? envelope['hypothesis']) as String?;
    final ts = DateTime.now();

    // Extract rich detail fields from all tiers
    final details = <String, String>{};
    for (final key in const [
      // T1
      'zone', 'trigger', 'stale_minutes',
      // T2
      'candidate_id', 'diversity_score', 'avg_credibility',
      // T3
      'type', 'severity', 'low_confidence',
      // T4
      'spread_risk',
      // T5
      'incident_id', 'trade_offs', 'resource_shortfall',
      // T6
      'channel', 'body_en', 'requires_human_approval',
      // T7
      'retraction_message_en',
    ]) {
      if (payload[key] != null) details[key] = payload[key].toString();
    }

    // Detect degraded-mode signals (T1 weather cache + sensor:silent)
    _checkDegradedSignal(payload, tier);

    setState(() {
      _events.insert(
        0,
        _TraceEvent(
          tier: tier,
          agent: agent,
          decision: decision,
          confidence: conf?.toDouble(),
          timestamp: _msTimestamp(ts),
          hypothesis: hyp,
          details: details,
        ),
      );
      if (_events.length > 80) _events.removeRange(80, _events.length);
    });

    if (tier == 3 || tier == 6 || tier == 7) {
      _refreshIncidents();
    }
  }

  void _checkDegradedSignal(Map<String, dynamic> payload, int tier) {
    if (tier != 1) return;
    final stale = payload['stale_minutes'] as int?;
    final source = payload['agent'] as String? ?? 'unknown';
    final trigger = (payload['trigger'] ?? payload['triggers']) as Object?;

    if (stale != null && stale > 0) {
      final sig = DegradedSignal(source: source, staleMinutes: stale);
      // Avoid duplicating same source
      final exists = _degradedSignals.any((s) => s.source == source && !s.sensorSilent);
      if (!exists) setState(() => _degradedSignals.add(sig));
    }
    if (trigger is String && trigger.contains('silent') ||
        trigger is List && trigger.any((t) => t.toString().contains('silent'))) {
      final sensorId = payload['sensor_id'] as String?;
      final sig = DegradedSignal(source: source, sensorSilent: true, sensorId: sensorId);
      final exists =
          _degradedSignals.any((s) => s.source == source && s.sensorSilent);
      if (!exists) setState(() => _degradedSignals.add(sig));
    }
  }

  String _msTimestamp(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}.${t.millisecond.toString().padLeft(3, '0')}';

  Future<void> _runScenario(String id) async {
    final sm = ScaffoldMessenger.of(context);
    sm.showSnackBar(SnackBar(content: Text('Running scenario $id…')));
    try {
      final r = await ApiClient.shared.runScenario(id);
      sm.showSnackBar(SnackBar(
        content: Text(
          'Scenario $id complete · ${r['dispatches']} dispatches · ${r['messages']} messages · ${r['recall']} recall',
        ),
      ));
      _refreshIncidents();
    } catch (e) {
      sm.showSnackBar(SnackBar(content: Text('Scenario failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final wide = size.width >= 1100;
    return Scaffold(
      backgroundColor: PulseColors.ink900,
      appBar: UtilBar(
        tabs: const [UtilTab('Dashboard')],
        actions: [
          _ScenarioMenu(onRun: _runScenario),
          const SizedBox(width: PulseSpace.x2),
          UtilIconButton(
            icon: Icons.refresh,
            tooltip: 'Refresh',
            onPressed: () {
              _refreshIncidents();
              _refreshResources();
            },
          ),
          const SizedBox(width: PulseSpace.x2),
          UtilIconButton(
            icon: Icons.logout,
            tooltip: 'Sign out',
            onPressed: () async {
              session.token = null;
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Degraded-mode banner sits below the AppBar, above all content
          if (_degradedSignals.isNotEmpty)
            DegradedModeBanner(
              signals: _degradedSignals,
              onDismiss: (s) =>
                  setState(() => _degradedSignals.remove(s)),
            ),
          Expanded(
            child: wide ? _wideLayout() : _narrowLayout(),
          ),
        ],
      ),
    );
  }

  Widget _wideLayout() {
    return Row(
      children: [
        Expanded(flex: 6, child: _leftPane()),
        Container(width: 1, color: PulseColors.hairline),
        Expanded(flex: 4, child: _tracePane()),
      ],
    );
  }

  Widget _narrowLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: PulseColors.hairline)),
            ),
            child: TabBar(
              tabs: const [Tab(text: 'OPS'), Tab(text: 'TRACE')],
              labelStyle:
                  PulseTheme.label(color: PulseColors.pearl).copyWith(fontSize: 11),
              unselectedLabelStyle: PulseTheme.label().copyWith(fontSize: 11),
              indicatorColor: PulseColors.signal,
              dividerColor: Colors.transparent,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [_leftPane(), _tracePane()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _leftPane() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(PulseSpace.x4, PulseSpace.x4, PulseSpace.x4, PulseSpace.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(PulseStrings.get('command.dashboard.title'),
                style: PulseTheme.display(size: 22)),
            const Spacer(),
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: PulseColors.lime,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: PulseColors.lime.withValues(alpha: 0.4),
                    blurRadius: 4,
                  )
                ],
              ),
            ),
            const SizedBox(width: PulseSpace.x2),
            Text(PulseStrings.get('common.live'),
                style: PulseTheme.label(color: PulseColors.lime)),
          ]),
          const SizedBox(height: PulseSpace.x1),
          EmDashLeader(
              '${_incidents.length} active · ${_msTimestamp(_lastUpdate).split('.').first}'),
          // Error banner with retry
          if (_loadError != null) ...[
            const SizedBox(height: PulseSpace.x3),
            ErrorBox(
              error: _loadError!,
              onRetry: () {
                _refreshIncidents();
                _refreshResources();
              },
            ),
          ],
          const SizedBox(height: PulseSpace.x4),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: PulseColors.hairline),
                borderRadius: BorderRadius.circular(PulseRadii.xl),
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(33.700, 73.040),
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'pulse.mobile',
                  ),
                  MarkerLayer(
                    markers: _incidents.map((i) {
                      final p = _zoneCoords[i.zone] ?? const LatLng(33.7, 73.05);
                      return Marker(
                        point: p,
                        width: 56,
                        height: 56,
                        child: MapPin(
                          severity: i.severity,
                          active: i.status == 'active',
                          zone: i.zone,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: PulseSpace.x5),
          SectionLabel(text: 'Active incidents', subtitle: 'count ${_incidents.length}'),
          const SizedBox(height: PulseSpace.x2),
          if (_incidents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PulseSpace.x6),
              child: Center(
                child: EmDashLeader(PulseStrings.get('command.dashboard.empty')),
              ),
            )
          else
            for (final inc in _incidents)
              IncidentCard(
                incident: inc,
                selected: inc.id == _selectedIncidentId,
                onTap: () => _loadIncidentDetail(inc.id),
                dense: true,
              ),
          // Incident detail + audit chain (shown when an incident is selected)
          if (_selectedIncidentId != null) ...[
            const SizedBox(height: PulseSpace.x5),
            SectionLabel(
              text: 'Incident detail',
              subtitle: _selectedIncidentId!.length > 10
                  ? _selectedIncidentId!.substring(0, 10)
                  : _selectedIncidentId,
            ),
            const SizedBox(height: PulseSpace.x3),
            if (_detailLoading)
              const Padding(
                padding: EdgeInsets.all(PulseSpace.x4),
                child: SkeletonLoader(height: 200, borderRadius: PulseRadii.xl),
              )
            else if (_incidentDetail != null)
              _IncidentDetailPane(detail: _incidentDetail!),
          ],
          const SizedBox(height: PulseSpace.x5),
          const SectionLabel(text: 'Resources'),
          const SizedBox(height: PulseSpace.x3),
          _ResourceGauges(counts: _assetCounts),
        ],
      ),
    );
  }

  Widget _tracePane() {
    return Container(
      color: PulseColors.ink900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
                PulseSpace.x4, PulseSpace.x4, PulseSpace.x4, PulseSpace.x3),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: PulseColors.hairline)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _wsConnected
                          ? PulseColors.signal
                          : PulseColors.amber,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(PulseRadii.sm),
                  ),
                  child: Text(
                    _wsConnected
                        ? PulseStrings.get('common.live')
                        : PulseStrings.get('command.trace.disconnected'),
                    style: PulseTheme.label(
                        color: _wsConnected
                            ? PulseColors.signal
                            : PulseColors.amber),
                  ),
                ),
                const SizedBox(width: PulseSpace.x3),
                Text(PulseStrings.get('command.trace.title'),
                    style: PulseTheme.display(size: 18)),
                const Spacer(),
                Text('${_events.length} events', style: PulseTheme.dataXs()),
              ],
            ),
          ),
          Expanded(
            child: _events.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(PulseSpace.x6),
                      child: Text(
                        PulseStrings.get('command.trace.empty'),
                        textAlign: TextAlign.center,
                        style: PulseTheme.dataSm(color: PulseColors.mist),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(PulseSpace.x3),
                    itemCount: _events.length,
                    itemBuilder: (_, i) {
                      final e = _events[i];
                      return TraceEventCard(
                        tier: e.tier,
                        agent: e.agent,
                        decision: e.decision,
                        confidence: e.confidence,
                        timestamp: e.timestamp,
                        hypothesis: e.hypothesis,
                        details: e.details,
                        isNew: i == 0,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TraceEvent {
  final int tier;
  final String agent;
  final String decision;
  final double? confidence;
  final String timestamp;
  final String? hypothesis;
  final Map<String, String> details;
  const _TraceEvent({
    required this.tier,
    required this.agent,
    required this.decision,
    this.confidence,
    required this.timestamp,
    this.hypothesis,
    required this.details,
  });
}

/// Renders the full incident detail fetched from GET /incidents/{id}.
/// Shows Tier-4 p10/p90 bands (if present in detail), plus the Tier-7
/// audit chain panel.
class _IncidentDetailPane extends StatelessWidget {
  final Map<String, dynamic> detail;
  const _IncidentDetailPane({required this.detail});

  @override
  Widget build(BuildContext context) {
    final auditLog = (detail['audit_log'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const [];
    final inc = detail['incident'] as Map<String, dynamic>? ?? detail;

    final confidence = (inc['confidence'] as num?)?.toDouble();
    final spreadRisk = inc['spread_risk'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick stats row
        if (confidence != null)
          DotLeader(
            label: 'confidence',
            value: confidence.toStringAsFixed(2),
          ),
        if (spreadRisk != null)
          DotLeader(
            label: 'spread risk',
            value: spreadRisk.toUpperCase(),
            valueColor: spreadRisk == 'high'
                ? PulseColors.crimson
                : spreadRisk == 'medium'
                    ? PulseColors.amber
                    : PulseColors.mist,
          ),
        const SizedBox(height: PulseSpace.x4),
        AuditChainPanel(auditLog: auditLog),
      ],
    );
  }
}

class _ResourceGauges extends StatelessWidget {
  final Map<String, int> counts;
  const _ResourceGauges({required this.counts});

  static const _displayOrder = [
    'ambulance', 'rescue', 'fire_unit', 'police_traffic',
    'water_tanker', 'mobile_clinic', 'utility_crew', 'generator', 'drone',
  ];

  @override
  Widget build(BuildContext context) {
    final entries = _displayOrder
        .where((k) => counts.containsKey(k))
        .map((k) => MapEntry(k, counts[k]!))
        .toList();
    final maxV =
        entries.fold<int>(0, (m, e) => e.value > m ? e.value : m).clamp(1, 100);
    return Container(
      padding: const EdgeInsets.all(PulseSpace.x3),
      decoration: BoxDecoration(
        color: PulseColors.ink800.withValues(alpha: 0.5),
        border: Border.all(color: PulseColors.hairline),
        borderRadius: BorderRadius.circular(PulseRadii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child:
                        Text(e.key.replaceAll('_', ' '), style: PulseTheme.label()),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      e.value.toString().padLeft(2),
                      style:
                          PulseTheme.data(size: 12, color: PulseColors.pearl),
                    ),
                  ),
                  const SizedBox(width: PulseSpace.x2),
                  Expanded(
                    child: Sparkbar(
                      value: e.value / maxV,
                      filledColor: PulseColors.signal,
                    ),
                  ),
                ],
              ),
            ),
          if (entries.isEmpty)
            Text('— no roster loaded —', style: PulseTheme.dataXs()),
        ],
      ),
    );
  }
}

class _ScenarioMenu extends StatelessWidget {
  final ValueChanged<String> onRun;
  const _ScenarioMenu({required this.onRun});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Run scenario',
      child: PopupMenuButton<String>(
        tooltip: 'Run scenario',
        color: PulseColors.ink700,
        onSelected: onRun,
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'A', child: Text('Scenario A · G-10 flood')),
          PopupMenuItem(value: 'B', child: Text('Scenario B · F-7 heatwave')),
          PopupMenuItem(value: 'C', child: Text('Scenario C · recovery flip')),
          PopupMenuItem(value: 'D', child: Text('Scenario D · degraded mode')),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: PulseSpace.x3, vertical: 7),
          decoration: BoxDecoration(
            color: PulseColors.signal.withValues(alpha: 0.08),
            border: Border.all(color: PulseColors.signal, width: 1),
            borderRadius: BorderRadius.circular(PulseRadii.xl),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('▸',
                  style: PulseTheme.data(
                      size: 13,
                      color: PulseColors.signal,
                      weight: FontWeight.w700)),
              const SizedBox(width: PulseSpace.x2),
              Text('RUN', style: PulseTheme.label(color: PulseColors.signal)),
              const SizedBox(width: PulseSpace.x1),
              Text('▾',
                  style: PulseTheme.data(size: 11, color: PulseColors.signal)),
            ],
          ),
        ),
      ),
    );
  }
}
