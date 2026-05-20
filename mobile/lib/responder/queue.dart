import 'package:flutter/material.dart';

import '../models/dispatch.dart';
import '../services/api.dart';
import '../shared/strings.dart';
import '../shared/theme.dart';
import '../shared/tokens.dart';
import '../shared/widgets/dot_leader.dart';
import '../shared/widgets/error_box.dart';
import '../shared/widgets/section_label.dart';
import '../shared/widgets/severity_pill.dart';
import '../shared/widgets/skeleton_loader.dart';
import '../shared/widgets/status_pill.dart';

class ResponderQueuePage extends StatefulWidget {
  const ResponderQueuePage({super.key});

  @override
  State<ResponderQueuePage> createState() => _ResponderQueuePageState();
}

class _ResponderQueuePageState extends State<ResponderQueuePage> {
  final _assetCtl = TextEditingController(text: 'rescue-3');
  String _assetId = 'rescue-3';
  List<Dispatch> _items = const [];
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
      final r = await ApiClient.shared.dispatchQueue(_assetId);
      setState(() => _items = r);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _ack(String id) async {
    await ApiClient.shared.ackDispatch(id);
    _refresh();
  }

  Future<void> _status(String id, String status) async {
    await ApiClient.shared.updateDispatchStatus(id, status);
    _refresh();
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
              padding: const EdgeInsets.fromLTRB(PulseSpace.x4, PulseSpace.x6, PulseSpace.x4, PulseSpace.x4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(PulseStrings.get('responder.queue.title'),
                      style: PulseTheme.display(size: 32)),
                  const SizedBox(height: PulseSpace.x1),
                  EmDashLeader('asset $_assetId · ${_items.length} active'),
                  const SizedBox(height: PulseSpace.x6),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _assetCtl,
                        style: PulseTheme.data(size: 15),
                        decoration: InputDecoration(
                          hintText: PulseStrings.get('responder.queue.asset_hint'),
                          filled: true,
                          fillColor: PulseColors.ink800.withValues(alpha: 0.5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: PulseSpace.x4, vertical: 0),
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
                        onSubmitted: (v) {
                          _assetId = v.trim();
                          _refresh();
                        },
                      ),
                    ),
                    const SizedBox(width: PulseSpace.x3),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: PulseSpace.x5, vertical: PulseSpace.x3),
                        side: const BorderSide(color: PulseColors.hairlineStrong),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PulseRadii.xl)),
                      ),
                      onPressed: () {
                        _assetId = _assetCtl.text.trim();
                        _refresh();
                      },
                      child: Text(PulseStrings.get('common.load'), style: PulseTheme.label(color: PulseColors.pearl)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          if (_loading)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: PulseSpace.x4, vertical: PulseSpace.x4),
              sliver: SliverList.separated(
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(height: PulseSpace.x3),
                itemBuilder: (_, __) => const SkeletonLoader(height: 200, borderRadius: PulseRadii.xxl),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: ErrorBox(error: _error!, onRetry: _refresh),
            )
          else if (_items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(PulseSpace.x8),
                child: Center(
                  child: EmDashLeader(PulseStrings.get('responder.queue.empty')),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: PulseSpace.x4, vertical: PulseSpace.x4),
              sliver: SliverList.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: PulseSpace.x4),
                itemBuilder: (_, i) {
                  final d = _items[i];
                  return _DispatchCard(
                    dispatch: d,
                    onAck: () => _ack(d.id),
                    onStatus: (s) => _status(d.id, s),
                  );
                },
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: PulseSpace.x12)),
        ],
      ),
    );
  }
}

class _DispatchCard extends StatelessWidget {
  final Dispatch dispatch;
  final VoidCallback onAck;
  final ValueChanged<String> onStatus;
  const _DispatchCard({required this.dispatch, required this.onAck, required this.onStatus});

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (dispatch.priority) {
      'urgent' => PulseColors.crimson,
      'high' => PulseColors.amber,
      _ => PulseColors.signal,
    };
    final idShort = dispatch.id.length > 12 ? dispatch.id.substring(0, 12) : dispatch.id;
    final etaMin = ((dispatch.etaS ?? 0) ~/ 60);
    final severity = dispatch.incidentSeverity ?? 3;
    
    return Container(
      decoration: BoxDecoration(
        color: PulseColors.ink800,
        border: Border.all(color: dispatch.priority == 'urgent' ? PulseColors.crimson : PulseColors.hairlineStrong, width: dispatch.priority == 'urgent' ? 1.5 : 1),
        borderRadius: BorderRadius.circular(PulseRadii.xxl),
        boxShadow: dispatch.priority == 'urgent'
            ? [BoxShadow(color: PulseColors.crimson.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))]
            : const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(PulseSpace.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              StatusPill.priority(dispatch.priority),
              const Spacer(),
              Text(idShort, style: PulseTheme.dataXs()),
            ]),
            const SizedBox(height: PulseSpace.x3),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SeverityPill(
                  severity: severity,
                  withLabel: false,
                  pulse: dispatch.priority == 'urgent'),
              const SizedBox(width: PulseSpace.x3),
              Expanded(
                child: Text(
                  'INCIDENT · ${dispatch.incidentId.length > 12 ? dispatch.incidentId.substring(0, 12) : dispatch.incidentId}',
                  style: PulseTheme.label(color: PulseColors.pearl).copyWith(fontSize: 12),
                ),
              ),
            ]),
            const SizedBox(height: PulseSpace.x4),
            Container(height: 1, color: PulseColors.hairlineStrong),
            const SizedBox(height: PulseSpace.x4),
            if (dispatch.destinationDisplay != '—')
              DotLeader(
                label: PulseStrings.get('responder.queue.destination'),
                value: dispatch.destinationDisplay,
                valueColor: PulseColors.signal,
              ),
            DotLeader(
                label: PulseStrings.get('responder.queue.eta'),
                value: '${etaMin}m'),
            DotLeader(
                label: 'status',
                value: dispatch.status,
                valueColor: priorityColor),
            const SizedBox(height: PulseSpace.x4),
            Text(PulseStrings.get('responder.queue.instructions'),
                style: PulseTheme.label()),
            const SizedBox(height: PulseSpace.x2),
            Text(dispatch.instructions,
                style: PulseTheme.data(size: 14, color: PulseColors.pearl)),
            const SizedBox(height: PulseSpace.x5),
            Container(height: 1, color: PulseColors.hairlineStrong),
            const SizedBox(height: PulseSpace.x4),
            Wrap(
              spacing: PulseSpace.x3,
              runSpacing: PulseSpace.x3,
              children: [
                _ActionButton(
                  label: 'ACK',
                  active: dispatch.status == 'acked',
                  primary: dispatch.status == 'issued',
                  onPressed: dispatch.status == 'issued' ? onAck : null,
                ),
                _ActionButton(
                  label: 'EN ROUTE',
                  active: dispatch.status == 'en_route',
                  onPressed: () => onStatus('en_route'),
                ),
                _ActionButton(
                  label: 'ON SCENE',
                  active: dispatch.status == 'on_scene',
                  onPressed: () => onStatus('on_scene'),
                ),
                _ActionButton(
                  label: 'CLEAR',
                  active: dispatch.status == 'clear',
                  onPressed: () => onStatus('clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool active;
  final bool primary;
  final VoidCallback? onPressed;
  const _ActionButton({
    required this.label,
    this.active = false,
    this.primary = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? PulseColors.lime
        : primary
            ? PulseColors.signal
            : PulseColors.stone;
    final disabled = onPressed == null;
    return Semantics(
      button: true,
      label: label,
      enabled: !disabled,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(PulseRadii.xl),
        // Gloved-use friendly: larger tap targets
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56, minWidth: 64),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: PulseSpace.x4, vertical: PulseSpace.x3),
            decoration: BoxDecoration(
              color: active
                  ? color.withValues(alpha: 0.15)
                  : primary
                      ? color.withValues(alpha: 0.10)
                      : Colors.transparent,
              border: Border.all(
                color: disabled
                    ? PulseColors.hairlineStrong
                    : active
                        ? color
                        : primary
                            ? color
                            : PulseColors.hairlineStrong,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(PulseRadii.xl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (primary && !active)
                  Text('▸',
                      style: PulseTheme.data(
                          size: 14, color: color, weight: FontWeight.w800)),
                if (primary && !active) const SizedBox(width: PulseSpace.x2),
                if (active)
                  Text('✓',
                      style: PulseTheme.data(
                          size: 13, color: color, weight: FontWeight.w800)),
                if (active) const SizedBox(width: PulseSpace.x2),
                Text(
                  label,
                  style: PulseTheme.label(color: disabled ? PulseColors.dim : color)
                      .copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
