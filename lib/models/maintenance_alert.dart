class MaintenanceAlert {
  final String id;
  final String assetId;
  final String assetName;
  final String? serialNumber;
  final String status;
  final int overdueDays;
  final String message;
  final DateTime createdAt;

  MaintenanceAlert({
    required this.id,
    required this.assetId,
    required this.assetName,
    this.serialNumber,
    required this.status,
    required this.overdueDays,
    required this.message,
    required this.createdAt,
  });

  factory MaintenanceAlert.fromJson(Map<String, dynamic> json) {
    return MaintenanceAlert(
      id: json['id'] as String,
      assetId: json['asset_id'] as String,
      assetName: json['asset_name'] as String? ?? 'Unknown Asset',
      serialNumber: json['serial_number'] as String?,
      status: json['status'] as String,
      overdueDays: json['overdue_days'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  MaintenanceAlert copyWith({
    String? id,
    String? assetId,
    String? assetName,
    String? serialNumber,
    String? status,
    int? overdueDays,
    String? message,
    DateTime? createdAt,
  }) {
    return MaintenanceAlert(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      assetName: assetName ?? this.assetName,
      serialNumber: serialNumber ?? this.serialNumber,
      status: status ?? this.status,
      overdueDays: overdueDays ?? this.overdueDays,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
