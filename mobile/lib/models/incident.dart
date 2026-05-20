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
  // Tier-4 uncertainty bands
  final int? popP10;
  final int? popP90;
  final double? radiusKmP10;
  final double? radiusKmP90;
  final int? durationMinP10;
  final int? durationMinP90;
  final String? spreadRisk;

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
    this.popP10,
    this.popP90,
    this.radiusKmP10,
    this.radiusKmP90,
    this.durationMinP10,
    this.durationMinP90,
    this.spreadRisk,
  });

  bool get hasBands => popP10 != null && popP90 != null;

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
        popP10: j['pop_p10'] as int?,
        popP90: j['pop_p90'] as int?,
        radiusKmP10: (j['radius_km_p10'] as num?)?.toDouble(),
        radiusKmP90: (j['radius_km_p90'] as num?)?.toDouble(),
        durationMinP10: j['duration_min_p10'] as int?,
        durationMinP90: j['duration_min_p90'] as int?,
        spreadRisk: j['spread_risk'] as String?,
      );
}
