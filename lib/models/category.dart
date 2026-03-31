class Category {
  final String id;
  final String name;
  final String? icon;
  final String? color;

  const Category({required this.id, required this.name, this.icon, this.color});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'icon': icon, 'color': color};
  }
}
