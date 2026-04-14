class Ticket {
  final String id;
  final String userId;
  final String type; // 'new_asset_request' | 'return_asset'
  final String? assetId;
  final String? assetName;
  final String status; // 'pending' | 'approved' | 'rejected' | 'closed'
  final String? notes;
  final String? rejectionReason;
  final String? userName;
  final DateTime createdAt;

  const Ticket({
    required this.id,
    required this.userId,
    required this.type,
    this.assetId,
    this.assetName,
    required this.status,
    this.notes,
    this.rejectionReason,
    this.userName,
    required this.createdAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      assetId: json['asset_id'] as String?,
      assetName: json['asset_name'] as String?,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      userName: json['user_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get typeLabel =>
      type == 'new_asset_request' ? 'New Asset Request' : 'Return Asset';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  Ticket copyWith({
    String? status,
    String? notes,
    String? rejectionReason,
  }) {
    return Ticket(
      id: id,
      userId: userId,
      type: type,
      assetId: assetId,
      assetName: assetName,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      userName: userName,
      createdAt: createdAt,
    );
  }
}
