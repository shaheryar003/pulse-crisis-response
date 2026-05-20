import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';
import '../tokens.dart';
import 'dot_leader.dart';
import 'section_label.dart';

/// Read-only audit chain panel for Tier-7 recall-agent entries.
///
/// Displays the full classification-flip history for a selected incident,
/// including original → revised type/severity, evidence at flip, agent chain,
/// and user impact (recipients notified, responders recalled).
///
/// IMPORTANT: This widget has zero edit or delete affordances.
/// The audit log is append-only; do not add mutation affordances here.
class AuditChainPanel extends StatelessWidget {
  final List<Map<String, dynamic>> auditLog;
  final String locale;

  const AuditChainPanel({
    super.key,
    required this.auditLog,
    this.locale = PulseStrings.en,
  });

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(text: PulseStrings.get('audit.title', locale)),
        const SizedBox(height: PulseSpace.x2),
        if (auditLog.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PulseSpace.x4),
            child: Text(
              PulseStrings.get('audit.no_flips', locale),
              style: PulseTheme.dataSm(color: PulseColors.mist),
            ),
          )
        else
          ...auditLog.map((entry) => _AuditEntry(
                entry: entry,
                fmt: _fmt,
                locale: locale,
              )),
      ],
    );
  }
}

class _AuditEntry extends StatelessWidget {
  final Map<String, dynamic> entry;
  final String Function(int) fmt;
  final String locale;
  const _AuditEntry({
    required this.entry,
    required this.fmt,
    required this.locale,
  });

  String _fmtTs(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final t = DateTime.tryParse(iso.replaceFirst(' ', 'T'));
    if (t == null) return iso;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audit = (entry['audit'] as Map?)?.cast<String, dynamic>() ?? entry;
    final original = (audit['original'] as Map?)?.cast<String, dynamic>() ?? {};
    final revised = (audit['new'] as Map?)?.cast<String, dynamic>() ?? {};
    final userImpact =
        (audit['user_impact'] as Map?)?.cast<String, dynamic>() ?? {};
    final evidenceList =
        (audit['evidence_at_flip'] as List?)?.cast<String>() ?? [];
    final agentChain =
        (audit['responsible_agent_chain'] as List?)?.cast<String>() ?? [];
    final tsFlip = _fmtTs(audit['ts_flip'] as String?);

    final origType = original['type'] as String? ?? '—';
    final origSev = original['severity']?.toString() ?? '—';
    final newType = revised['type'] as String? ?? '—';
    final newSev = revised['severity']?.toString() ?? '—';
    final recipients = userImpact['recipients_of_retraction'] as int?;
    final recalled = userImpact['responders_recalled'] as int?;

    final retraction =
        entry['retraction_message_en'] as String? ??
        audit['retraction_message_en'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: PulseSpace.x3),
      decoration: BoxDecoration(
        color: PulseColors.ink800.withValues(alpha: 0.85),
        border: Border.all(color: PulseColors.hairline),
        borderRadius: BorderRadius.circular(PulseRadii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Container(
            padding: const EdgeInsets.fromLTRB(
                PulseSpace.x3, PulseSpace.x3, PulseSpace.x3, PulseSpace.x2),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: PulseSpace.x2, vertical: PulseSpace.x0_5),
                  decoration: BoxDecoration(
                    border: Border.all(color: PulseColors.mist, width: 1),
                    borderRadius: BorderRadius.circular(PulseRadii.sm),
                  ),
                  child: Text('T7',
                      style: PulseTheme.dataXs(color: PulseColors.mist)),
                ),
                const SizedBox(width: PulseSpace.x2),
                Text('recall-agent',
                    style: PulseTheme.data(
                        size: 12,
                        color: PulseColors.pearl,
                        weight: FontWeight.w600)),
                const Spacer(),
                Text(tsFlip, style: PulseTheme.dataXs()),
              ],
            ),
          ),
          Container(height: 1, color: PulseColors.hairline),
          Padding(
            padding: const EdgeInsets.all(PulseSpace.x3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // type/severity flip
                Row(children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(PulseSpace.x2),
                      decoration: BoxDecoration(
                        color: PulseColors.ink900,
                        borderRadius: BorderRadius.circular(PulseRadii.md),
                        border: Border.all(color: PulseColors.hairline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              PulseStrings.get('audit.original', locale)
                                  .toUpperCase(),
                              style: PulseTheme.label()),
                          const SizedBox(height: 2),
                          Text(
                              origType.replaceAll('_', ' ').toUpperCase(),
                              style: PulseTheme.data(
                                  size: 11,
                                  color: PulseColors.dim)),
                          Text('sev $origSev',
                              style: PulseTheme.dataXs(color: PulseColors.dim)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: PulseSpace.x2),
                    child: Text(
                      '→',
                      style: PulseTheme.data(
                          size: 14,
                          color: PulseColors.signal,
                          weight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(PulseSpace.x2),
                      decoration: BoxDecoration(
                        color: PulseColors.signal.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(PulseRadii.md),
                        border: Border.all(
                            color: PulseColors.signal.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              PulseStrings.get('audit.revised', locale)
                                  .toUpperCase(),
                              style: PulseTheme.label(
                                  color: PulseColors.signal)),
                          const SizedBox(height: 2),
                          Text(
                              newType.replaceAll('_', ' ').toUpperCase(),
                              style: PulseTheme.data(
                                  size: 11,
                                  color: PulseColors.pearl)),
                          Text('sev $newSev',
                              style: PulseTheme.dataXs(
                                  color: PulseColors.signal)),
                        ],
                      ),
                    ),
                  ),
                ]),
                if (retraction != null && retraction.isNotEmpty) ...[
                  const SizedBox(height: PulseSpace.x3),
                  Text('▸ $retraction',
                      style: PulseTheme.data(
                          size: 12, color: PulseColors.stone)),
                ],
                if (recipients != null || recalled != null) ...[
                  const SizedBox(height: PulseSpace.x3),
                  Container(height: 1, color: PulseColors.hairline),
                  const SizedBox(height: PulseSpace.x2),
                  if (recipients != null)
                    DotLeader(
                      label: PulseStrings.get('audit.recipients', locale),
                      value: fmt(recipients),
                    ),
                  if (recalled != null)
                    DotLeader(
                      label: PulseStrings.get(
                          'audit.responders_recalled', locale),
                      value: '$recalled',
                    ),
                ],
                if (evidenceList.isNotEmpty) ...[
                  const SizedBox(height: PulseSpace.x3),
                  Container(height: 1, color: PulseColors.hairline),
                  const SizedBox(height: PulseSpace.x2),
                  ...evidenceList.map((e) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: PulseSpace.x1),
                        child: Text(
                          '╴ $e',
                          style: PulseTheme.dataSm(color: PulseColors.mist),
                        ),
                      )),
                ],
                if (agentChain.isNotEmpty) ...[
                  const SizedBox(height: PulseSpace.x2),
                  Text(
                    agentChain.join(' → '),
                    style: PulseTheme.dataXs(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
