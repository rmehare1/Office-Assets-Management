class AssetLog {
  final String id;
  final String assetId;
  final String? userId;
  final String userName;
  final String action;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  AssetLog({
    required this.id,
    required this.assetId,
    this.userId,
    required this.userName,
    required this.action,
    this.details,
    required this.createdAt,
  });

  factory AssetLog.fromJson(Map<String, dynamic> json) {
    return AssetLog(
      id: json['id'] as String,
      assetId: json['asset_id'] as String,
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String,
      action: json['action'] as String,
      details: json['details'] != null ? (json['details'] is String ? null : json['details'] as Map<String, dynamic>) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
