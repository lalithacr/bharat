class ReportModel {
  final String id;
  final String ticketNumber;
  final String issueType;
  final String severity;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? description;
  final String? aiSummary;
  final double confidenceScore;
  final String language;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<dynamic> images;

  ReportModel({
    required this.id,
    required this.ticketNumber,
    required this.issueType,
    this.severity = 'medium',
    this.status = 'pending',
    this.latitude,
    this.longitude,
    this.address,
    this.description,
    this.aiSummary,
    this.confidenceScore = 0.0,
    this.language = 'en',
    this.createdAt,
    this.updatedAt,
    this.images = const [],
  });

  /// Safe location string — fixes the nullable double compile error
  String get locationString {
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
    }
    return address ?? 'Location not set';
  }

  String get displayAddress => address?.isNotEmpty == true
      ? address!
      : locationString;

  factory ReportModel.fromJson(Map<String, dynamic> j) => ReportModel(
        id:              j['id']?.toString()            ?? '',
        ticketNumber:    j['ticket_number']?.toString() ?? '',
        issueType:       j['issue_type']?.toString()    ?? 'other',
        severity:        j['severity']?.toString()      ?? 'medium',
        status:          j['status']?.toString()        ?? 'pending',
        latitude:        (j['latitude'] as num?)?.toDouble(),
        longitude:       (j['longitude'] as num?)?.toDouble(),
        address:         j['address']?.toString(),
        description:     j['description']?.toString(),
        aiSummary:       j['ai_summary']?.toString(),
        confidenceScore: (j['confidence_score'] as num?)?.toDouble() ?? 0.0,
        language:        j['language']?.toString() ?? 'en',
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString())
            : null,
        updatedAt: j['updated_at'] != null
            ? DateTime.tryParse(j['updated_at'].toString())
            : null,
        images: (j['images'] as List?)?.toList() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'id':               id,
        'ticket_number':    ticketNumber,
        'issue_type':       issueType,
        'severity':         severity,
        'status':           status,
        'latitude':         latitude,
        'longitude':        longitude,
        'address':          address,
        'description':      description,
        'ai_summary':       aiSummary,
        'confidence_score': confidenceScore,
        'language':         language,
        'created_at':       createdAt?.toIso8601String(),
        'updated_at':       updatedAt?.toIso8601String(),
      };
}
