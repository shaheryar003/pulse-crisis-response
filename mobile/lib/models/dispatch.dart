class Dispatch {
  final String id;
  final String incidentId;
  final String assetId;
  final String priority;
  final int? etaS;
  final String instructions;
  final String status;

  Dispatch({
    required this.id,
    required this.incidentId,
    required this.assetId,
    required this.priority,
    required this.etaS,
    required this.instructions,
    required this.status,
  });

  factory Dispatch.fromJson(Map<String, dynamic> j) => Dispatch(
        id: j['dispatch_id'] as String,
        incidentId: j['incident_id'] as String,
        assetId: j['asset_id'] as String,
        priority: j['priority'] as String? ?? 'normal',
        etaS: j['eta_s'] as int?,
        instructions: j['instructions'] as String? ?? '',
        status: j['status'] as String? ?? 'issued',
      );
}
