class ReportModel {
  final String id;
  final String ticketNumber;
  final String issueType;
  final String severity;
  final String status;
  final double latitude;
  final double longitude;
  final String? address;
  final String? description;
  final String? aiSummary;
  final double confidenceScore;
  final String language;
  final DateTime createdAt;
  final List<Map<String, dynamic>> images;
  final List<Map<String, dynamic>> statusHistory;

  ReportModel({
    required this.id,
    required this.ticketNumber,
    required this.issueType,
    required this.severity,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.address,
    this.description,
    this.aiSummary,
    required this.confidenceScore,
    required this.language,
    required this.createdAt,
    this.images = const [],
    this.statusHistory = const [],
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) => ReportModel(
        id: json['id'] as String,
        ticketNumber: json['ticket_number'] as String,
        issueType: json['issue_type'] as String,
        severity: json['severity'] as String,
        status: json['status'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] as String?,
        description: json['description'] as String?,
        aiSummary: json['ai_summary'] as String?,
        confidenceScore: (json['confidence_score'] as num).toDouble(),
        language: json['language'] as String? ?? 'en',
        createdAt: DateTime.parse(json['created_at'] as String),
        images: List<Map<String, dynamic>>.from(
            json['images'] as List? ?? []),
        statusHistory: List<Map<String, dynamic>>.from(
            json['status_history'] as List? ?? []),
      );

  String get severityEmoji {
    switch (severity) {
      case 'high': return '🔴';
      case 'medium': return '🟡';
      case 'low': return '🟢';
      default: return '⚪';
    }
  }

  String get issueEmoji {
    const emojis = {
      'pothole': '🕳️',
      'garbage': '🗑️',
      'water_leak': '💧',
      'broken_light': '💡',
      'road_damage': '🛣️',
      'drainage': '🚧',
      'flooding': '🌊',
      'property_damage': '🏚️',
    };
    return emojis[issueType] ?? '📍';
  }

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Pending';
      case 'verified': return 'Verified ✓';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved ✅';
      case 'rejected': return 'Rejected';
      default: return status;
    }
  }

  String get issueLabel {
    return issueType.replaceAll('_', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}