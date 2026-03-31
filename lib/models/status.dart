class Status {
  final String id;
  final String name;
  final String? color;

  const Status({
    required this.id,
    required this.name,
    this.color,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }
}
