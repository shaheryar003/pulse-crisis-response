class Incident {
  final String id;
  final String zone;
  final String type;
  final int severity;
  final double confidence;
  final String status;
  final double? radiusKmP50;
  final int? popP50;
  final int? durationMinP50;

  Incident({
    required this.id,
    required this.zone,
    required this.type,
    required this.severity,
    required this.confidence,
    required this.status,
    this.radiusKmP50,
    this.popP50,
    this.durationMinP50,
  });

  factory Incident.fromJson(Map<String, dynamic> j) => Incident(
        id: j['incident_id'] as String,
        zone: j['zone'] as String,
        type: j['type'] as String,
        severity: j['severity'] as int,
        confidence: (j['confidence'] as num).toDouble(),
        status: j['status'] as String? ?? 'active',
        radiusKmP50: (j['radius_km_p50'] as num?)?.toDouble(),
        popP50: j['pop_p50'] as int?,
        durationMinP50: j['duration_min_p50'] as int?,
      );
}
