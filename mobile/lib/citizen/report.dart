import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../services/api.dart';
import '../services/offline.dart';
import '../shared/auth.dart';
import '../shared/strings.dart';
import '../shared/theme.dart';
import '../shared/tokens.dart';
import '../shared/widgets/cta_button.dart';
import '../shared/widgets/section_label.dart';
import '../shared/widgets/status_pill.dart';

class CitizenReportPage extends StatefulWidget {
  const CitizenReportPage({super.key});

  @override
  State<CitizenReportPage> createState() => _CitizenReportPageState();
}

class _CitizenReportPageState extends State<CitizenReportPage> {
  final _description = TextEditingController();
  String _category = 'flood';
  Position? _position;
  String? _photoPath;
  bool _busy = false;
  String? _result;
  String? _error;

  Position _demoPosition() => Position(
        longitude: 73.005,
        latitude: 33.696,
        timestamp: DateTime.now(),
        accuracy: 25,
        altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
      );

  Future<void> _captureLocation() async {
    setState(() => _busy = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        if (kIsWeb) {
          _position = _demoPosition();
          setState(() {});
          return;
        }
        setState(() => _error = PulseStrings.get('citizen.report.gps_denied'));
        return;
      }
      _position = await Geolocator.getCurrentPosition();
      setState(() {});
    } catch (e) {
      if (kIsWeb) {
        _position = _demoPosition();
        setState(() {});
      } else {
        setState(() => _error = '${PulseStrings.get('citizen.report.gps_error')}: $e');
      }
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _attachPhoto() async {
    if (kIsWeb) {
      setState(() => _photoPath = 'web-demo://photo');
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    if (file != null) setState(() => _photoPath = file.path);
  }

  Future<void> _submit() async {
    if (_position == null) {
      setState(() => _error = PulseStrings.get('citizen.report.gps_required'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    final payload = {
      'report_id': const Uuid().v4(),
      'user_id': session.userId ?? 'anonymous',
      'category': _category,
      'description': _description.text,
      'geo': {
        'lat': _position!.latitude,
        'lon': _position!.longitude,
        'accuracy_m': _position!.accuracy.round(),
      },
      'media': _photoPath != null ? [{'type': 'photo', 'url': _photoPath}] : <Map<String, String>>[],
      'ts': DateTime.now().toUtc().toIso8601String(),
      'user_trust': 0.5,
    };
    try {
      final r = await ApiClient.shared.submitCitizenReport(payload);
      setState(() => _result = 'Submitted · zone ${r['zone']} · credibility ${r['credibility']}');
      _description.clear();
      _photoPath = null;
    } catch (e) {
      await OfflineQueue.enqueue(payload);
      setState(() => _error = '${PulseStrings.get('citizen.report.offline_queued')} ($e)');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(PulseSpace.x4, PulseSpace.x5, PulseSpace.x4, PulseSpace.x8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(PulseStrings.get('citizen.report.title'), style: PulseTheme.display(size: 26)),
          const SizedBox(height: PulseSpace.x1),
          EmDashLeader(PulseStrings.get('citizen.report.subtitle')),
          const SizedBox(height: PulseSpace.x6),
          const SectionLabel(text: 'Category'),
          const SizedBox(height: PulseSpace.x2),
          Wrap(
            spacing: PulseSpace.x2,
            runSpacing: PulseSpace.x2,
            children: [
              for (final cat in const [
                ('flood', 'FLOOD'),
                ('fire', 'FIRE'),
                ('accident', 'ACCIDENT'),
                ('power_outage', 'POWER OUTAGE'),
                ('water_main_burst', 'WATER MAIN'),
                ('infrastructure', 'INFRASTRUCTURE'),
                ('other', 'OTHER'),
              ])
                _CategoryChip(
                  label: cat.$2,
                  selected: _category == cat.$1,
                  onTap: () => setState(() => _category = cat.$1),
                ),
            ],
          ),
          const SizedBox(height: PulseSpace.x5),
          const SectionLabel(text: 'Description'),
          const SizedBox(height: PulseSpace.x2),
          TextField(
            controller: _description,
            minLines: 3,
            maxLines: 6,
            style: PulseTheme.data(size: 14, color: PulseColors.pearl),
            decoration: const InputDecoration(hintText: 'What is happening?'),
          ),
          const SizedBox(height: PulseSpace.x5),
          const SectionLabel(text: 'Evidence'),
          const SizedBox(height: PulseSpace.x2),
          Row(children: [
            Expanded(
              child: _EvidenceCard(
                marker: '◎',
                label: PulseStrings.get('citizen.report.gps_label'),
                confirmed: _position != null
                    ? '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}\n±${_position!.accuracy.round()}m'
                    : null,
                onTap: _busy ? null : _captureLocation,
              ),
            ),
            const SizedBox(width: PulseSpace.x3),
            Expanded(
              child: _EvidenceCard(
                marker: '⊕',
                label: PulseStrings.get('citizen.report.photo_label'),
                confirmed: _photoPath != null ? 'photo attached' : null,
                onTap: _busy ? null : _attachPhoto,
              ),
            ),
          ]),
          const SizedBox(height: PulseSpace.x6),
          CtaButton(
            label: PulseStrings.get('citizen.report.submit'),
            loading: _busy,
            onPressed: _busy ? null : _submit,
          ),
          if (_result != null) ...[
            const SizedBox(height: PulseSpace.x4),
            Container(
              padding: const EdgeInsets.all(PulseSpace.x3),
              decoration: BoxDecoration(
                color: PulseColors.lime.withValues(alpha: 0.06),
                border: Border.all(color: PulseColors.lime, width: 1),
                borderRadius: BorderRadius.circular(PulseRadii.sm),
              ),
              child: Row(children: [
                StatusPill(
                    label: PulseStrings.get('citizen.report.accepted'),
                    color: PulseColors.lime,
                    dense: true),
                const SizedBox(width: PulseSpace.x3),
                Expanded(child: Text(_result!, style: PulseTheme.dataSm(color: PulseColors.lime))),
              ]),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: PulseSpace.x4),
            Container(
              padding: const EdgeInsets.all(PulseSpace.x3),
              decoration: BoxDecoration(
                color: PulseColors.crimson.withValues(alpha: 0.06),
                border: Border.all(color: PulseColors.crimson, width: 1),
                borderRadius: BorderRadius.circular(PulseRadii.sm),
              ),
              child: Text(_error!, style: PulseTheme.dataSm(color: PulseColors.crimson)),
            ),
          ],
          const SizedBox(height: PulseSpace.x6),
          EmDashLeader(PulseStrings.get('citizen.report.privacy_hash')),
          const SizedBox(height: PulseSpace.x1),
          EmDashLeader(PulseStrings.get('citizen.report.privacy_trust')),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PulseRadii.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: PulseSpace.x3, vertical: PulseSpace.x3),
            decoration: BoxDecoration(
              color: selected ? PulseColors.signal.withValues(alpha: 0.10) : PulseColors.ink800,
              border: Border.all(
                  color: selected ? PulseColors.signal : PulseColors.hairline, width: 1),
              borderRadius: BorderRadius.circular(PulseRadii.sm),
            ),
            child: Text(
              label,
              style: PulseTheme.label(color: selected ? PulseColors.signal : PulseColors.stone)
                  .copyWith(fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final String marker;
  final String label;
  final String? confirmed;
  final VoidCallback? onTap;
  const _EvidenceCard({required this.marker, required this.label, this.confirmed, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasValue = confirmed != null;
    final color = hasValue ? PulseColors.lime : PulseColors.signal;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PulseRadii.md),
        child: Container(
          padding: const EdgeInsets.all(PulseSpace.x4),
          decoration: BoxDecoration(
            color: PulseColors.ink800,
            border: Border.all(color: hasValue ? color : PulseColors.hairline, width: 1),
            borderRadius: BorderRadius.circular(PulseRadii.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(marker,
                    style: PulseTheme.data(size: 16, color: color, weight: FontWeight.w700)),
                const SizedBox(width: PulseSpace.x2),
                Text(label, style: PulseTheme.label(color: color).copyWith(fontSize: 11)),
              ]),
              const SizedBox(height: PulseSpace.x3),
              Container(height: 1, color: PulseColors.hairline),
              const SizedBox(height: PulseSpace.x3),
              if (hasValue)
                Row(children: [
                  Text('✓',
                      style:
                          PulseTheme.data(size: 12, color: color, weight: FontWeight.w700)),
                  const SizedBox(width: PulseSpace.x2),
                  Expanded(
                      child:
                          Text(confirmed!, style: PulseTheme.dataSm(color: PulseColors.pearl))),
                ])
              else
                Text('tap to capture', style: PulseTheme.dataXs()),
            ],
          ),
        ),
      ),
    );
  }
}
