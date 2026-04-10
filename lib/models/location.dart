class Location {
  final String id;
  final String name;

  const Location({required this.id, required this.name});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
