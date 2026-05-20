import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/incident.dart';
import '../services/api.dart';
import '../shared/strings.dart';
import '../shared/theme.dart';
import '../shared/tokens.dart';
import '../shared/widgets/incident_card.dart';
import '../shared/widgets/map_pin.dart';
import '../shared/widgets/section_label.dart';
import '../shared/widgets/skeleton_loader.dart';

class CitizenHome extends StatefulWidget {
  const CitizenHome({super.key});

  @override
  State<CitizenHome> createState() => _CitizenHomeState();
}

class _CitizenHomeState extends State<CitizenHome> {
  List<Incident> _incidents = const [];
  String? _error;
  bool _loading = true;
  DateTime _lastUpdate = DateTime.now();

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
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ApiClient.shared.listIncidents();
      setState(() {
        _incidents = r;
        _lastUpdate = DateTime.now();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _ts(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

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
              padding: const EdgeInsets.fromLTRB(PulseSpace.x4, PulseSpace.x5, PulseSpace.x4, PulseSpace.x3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Live incidents', style: PulseTheme.display(size: 26)),
                  const SizedBox(height: PulseSpace.x1),
                  EmDashLeader('${_incidents.length} active · last update ${_ts(_lastUpdate)}'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: PulseSpace.x4),
              child: AspectRatio(
                aspectRatio: 16 / 11,
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
                            child: MapPin(severity: i.severity, active: i.status == 'active'),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(PulseSpace.x4, PulseSpace.x5, PulseSpace.x4, PulseSpace.x2),
              child: SectionLabel(text: 'Active incidents', subtitle: 'count ${_incidents.length}'),
            ),
          ),
          if (_loading)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: PulseSpace.x4),
              sliver: SliverList.separated(
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(height: PulseSpace.x3),
                itemBuilder: (_, __) => const SkeletonLoader(height: 100, borderRadius: PulseRadii.xl),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(child: _ErrorBox(error: _error!, onRetry: _refresh))
          else if (_incidents.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(PulseSpace.x8),
                child: Center(child: EmDashLeader(PulseStrings.get('citizen.home.empty', PulseStrings.en))),
              ),
            )
          else
            SliverList.builder(
              itemCount: _incidents.length,
              itemBuilder: (_, i) => IncidentCard(incident: _incidents[i], dense: true),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: PulseSpace.x8)),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorBox({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(PulseSpace.x6),
        child: Container(
          padding: const EdgeInsets.all(PulseSpace.x4),
          decoration: BoxDecoration(
            color: PulseColors.crimson.withValues(alpha: 0.06),
            border: Border.all(color: PulseColors.crimson, width: 1),
            borderRadius: BorderRadius.circular(PulseRadii.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NETWORK ERROR', style: PulseTheme.label(color: PulseColors.crimson)),
              const SizedBox(height: PulseSpace.x2),
              Text(error, style: PulseTheme.dataSm(color: PulseColors.crimson)),
              const SizedBox(height: PulseSpace.x3),
              OutlinedButton(onPressed: onRetry, child: const Text('RETRY')),
            ],
          ),
        ),
      );
}
