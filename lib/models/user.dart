class AppUser {
  final String id;
  final String name;
  final String email;
  final String department;
  final String role;
  final String phone;
  final String? avatarUrl;
  final int assignedAssets;
  final DateTime joinDate;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    required this.phone,
    this.avatarUrl,
    required this.assignedAssets,
    required this.joinDate,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      department: json['department'] as String? ?? '',
      role: json['role'] as String,
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      assignedAssets: (json['assigned_assets'] as num?)?.toInt() ?? 0,
      joinDate: DateTime.parse(json['join_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'department': department,
      'role': role,
      'phone': phone,
      'avatar_url': avatarUrl,
      'assigned_assets': assignedAssets,
      'join_date': joinDate.toIso8601String().split('T')[0],
    };
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    String? role,
    String? phone,
    String? avatarUrl,
    int? assignedAssets,
    DateTime? joinDate,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      assignedAssets: assignedAssets ?? this.assignedAssets,
      joinDate: joinDate ?? this.joinDate,
    );
  }
}
