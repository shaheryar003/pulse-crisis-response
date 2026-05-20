class AlertItem {
  final String id;
  final String incidentId;
  final String channel;
  final String? bodyEn;
  final String? bodyUr;
  final String status;
  final String issuedAt;
  final String? retractedAt;
  final bool requiresHumanApproval;
  final String? incidentType;

  AlertItem({
    required this.id,
    required this.incidentId,
    required this.channel,
    this.bodyEn,
    this.bodyUr,
    required this.status,
    required this.issuedAt,
    this.retractedAt,
    this.requiresHumanApproval = false,
    this.incidentType,
  });

  bool get isRetracted => status == 'retracted';

  factory AlertItem.fromJson(Map<String, dynamic> j) => AlertItem(
        id: j['alert_id'] as String,
        incidentId: j['incident_id'] as String,
        channel: j['channel'] as String,
        bodyEn: j['body_en'] as String?,
        bodyUr: j['body_ur'] as String?,
        status: j['status'] as String? ?? 'staged',
        issuedAt: j['issued_at'] as String? ?? '',
        retractedAt: j['retracted_at'] as String?,
        requiresHumanApproval:
            (j['requires_human_approval'] as bool?) ?? false,
        incidentType: j['incident_type'] as String?,
      );
}
