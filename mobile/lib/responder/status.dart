import 'package:flutter/material.dart';

import '../services/api.dart';
import '../shared/auth.dart';
import '../shared/strings.dart';
import '../shared/theme.dart';
import '../shared/tokens.dart';
import '../shared/widgets/cta_button.dart';
import '../shared/widgets/section_label.dart';
import '../shared/widgets/status_pill.dart';

class ResponderStatusPage extends StatefulWidget {
  const ResponderStatusPage({super.key});

  @override
  State<ResponderStatusPage> createState() => _ResponderStatusPageState();
}

class _ResponderStatusPageState extends State<ResponderStatusPage> {
  final _assetCtl = TextEditingController(text: 'rescue-3');
  String _selected = 'on_duty';
  bool _busy = false;
  String? _result;
  String? _error;

  static const _statuses = [
    ('on_duty', 'responder.status.on_duty'),
    ('standby', 'responder.status.standby'),
    ('off_duty', 'responder.status.off_duty'),
  ];

  Future<void> _submit() async {
    final assetId = _assetCtl.text.trim();
    if (assetId.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      await ApiClient.shared.updateDispatchStatus(assetId, _selected);
      setState(() =>
          _result = 'Status updated: ${_selected.replaceAll('_', ' ')}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          PulseSpace.x4, PulseSpace.x6, PulseSpace.x4, PulseSpace.x8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(PulseStrings.get('responder.status.title'),
              style: PulseTheme.display(size: 32)),
          const SizedBox(height: PulseSpace.x1),
          EmDashLeader(PulseStrings.get('responder.status.subtitle')),
          const SizedBox(height: PulseSpace.x8),
          const SectionLabel(text: 'Asset ID'),
          const SizedBox(height: PulseSpace.x3),
          TextField(
            controller: _assetCtl,
            style: PulseTheme.data(size: 15),
            decoration: InputDecoration(
              hintText: PulseStrings.get('responder.queue.asset_hint'),
              filled: true,
              fillColor: PulseColors.ink800.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(PulseRadii.xl),
                borderSide: const BorderSide(color: PulseColors.hairlineStrong),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(PulseRadii.xl),
                borderSide: const BorderSide(color: PulseColors.hairlineStrong),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(PulseRadii.xl),
                borderSide: const BorderSide(color: PulseColors.signal, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: PulseSpace.x6),
          const SectionLabel(text: 'Availability'),
          const SizedBox(height: PulseSpace.x3),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: PulseColors.hairlineStrong),
              borderRadius: BorderRadius.circular(PulseRadii.xxl),
              color: PulseColors.ink800,
            ),
            child: Row(
              children: _statuses.map((s) {
                final active = _selected == s.$1;
                final color = switch (s.$1) {
                  'on_duty' => PulseColors.lime,
                  'standby' => PulseColors.amber,
                  _ => PulseColors.dim,
                };
                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: active,
                    label: PulseStrings.get(s.$2),
                    child: InkWell(
                      onTap: () => setState(() => _selected = s.$1),
                      borderRadius: BorderRadius.circular(PulseRadii.xxl),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 80),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              vertical: PulseSpace.x4),
                          decoration: BoxDecoration(
                            color: active
                                ? color.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(PulseRadii.xxl),
                            border: Border.all(
                              color: active ? color : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (active)
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                                ),
                              if (active) const SizedBox(height: PulseSpace.x2),
                              Text(
                                PulseStrings.get(s.$2),
                                style: PulseTheme.label(
                                        color: active ? color : PulseColors.mist)
                                    .copyWith(fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: PulseSpace.x8),
          CtaButton(
            label: PulseStrings.get('responder.status.submit'),
            loading: _busy,
            onPressed: _busy ? null : _submit,
          ),
          if (_result != null) ...[
            const SizedBox(height: PulseSpace.x4),
            Container(
              padding: const EdgeInsets.all(PulseSpace.x4),
              decoration: BoxDecoration(
                color: PulseColors.lime.withValues(alpha: 0.06),
                border: Border.all(color: PulseColors.lime, width: 1.5),
                borderRadius: BorderRadius.circular(PulseRadii.xl),
              ),
              child: Row(children: [
                const StatusPill(label: 'UPDATED', color: PulseColors.lime, dense: true),
                const SizedBox(width: PulseSpace.x3),
                Expanded(
                    child: Text(_result!,
                        style: PulseTheme.dataSm(color: PulseColors.lime))),
              ]),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: PulseSpace.x4),
            Container(
              padding: const EdgeInsets.all(PulseSpace.x4),
              decoration: BoxDecoration(
                color: PulseColors.crimson.withValues(alpha: 0.06),
                border: Border.all(color: PulseColors.crimson, width: 1.5),
                borderRadius: BorderRadius.circular(PulseRadii.xl),
              ),
              child: Text(_error!,
                  style: PulseTheme.dataSm(color: PulseColors.crimson)),
            ),
          ],
          const SizedBox(height: PulseSpace.x8),
          Center(
            child: EmDashLeader(
                'Logged as ${session.userId ?? 'anonymous'} · ${_assetCtl.text}'),
          ),
        ],
      ),
    );
  }
}
