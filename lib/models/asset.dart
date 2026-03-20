import 'package:flutter/material.dart';

enum AssetStatus { available, assigned, maintenance, retired }

enum AssetCategory { laptop, monitor, phone, furniture, accessory, other }

AssetStatus assetStatusFromString(String s) {
  return AssetStatus.values.firstWhere(
    (e) => e.name == s,
    orElse: () => AssetStatus.available,
  );
}

AssetCategory assetCategoryFromString(String s) {
  return AssetCategory.values.firstWhere(
    (e) => e.name == s,
    orElse: () => AssetCategory.other,
  );
}

class Asset {
  final String id;
  final String name;
  final AssetCategory category;
  final AssetStatus status;
  final String assignedTo;
  final String serialNumber;
  final String location;
  final DateTime purchaseDate;
  final double purchasePrice;
  final String? imageUrl;
  final String? notes;

  const Asset({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.assignedTo,
    required this.serialNumber,
    required this.location,
    required this.purchaseDate,
    required this.purchasePrice,
    this.imageUrl,
    this.notes,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      name: json['name'] as String,
      category: assetCategoryFromString(json['category'] as String),
      status: assetStatusFromString(json['status'] as String),
      assignedTo: json['assigned_to_name'] as String? ?? json['assigned_to'] as String? ?? '',
      serialNumber: json['serial_number'] as String,
      location: json['location'] as String,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      purchasePrice: double.parse(json['purchase_price'].toString()),
      imageUrl: json['image_url'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'status': status.name,
      'assigned_to': assignedTo.isEmpty ? null : assignedTo,
      'serial_number': serialNumber,
      'location': location,
      'purchase_date': purchaseDate.toIso8601String().split('T')[0],
      'purchase_price': purchasePrice,
      'image_url': imageUrl,
      'notes': notes,
    };
  }

  Asset copyWith({
    String? id,
    String? name,
    AssetCategory? category,
    AssetStatus? status,
    String? assignedTo,
    String? serialNumber,
    String? location,
    DateTime? purchaseDate,
    double? purchasePrice,
    String? imageUrl,
    String? notes,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      serialNumber: serialNumber ?? this.serialNumber,
      location: location ?? this.location,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
    );
  }

  IconData get categoryIcon {
    switch (category) {
      case AssetCategory.laptop:
        return Icons.laptop_mac;
      case AssetCategory.monitor:
        return Icons.monitor;
      case AssetCategory.phone:
        return Icons.phone_android;
      case AssetCategory.furniture:
        return Icons.chair;
      case AssetCategory.accessory:
        return Icons.headphones;
      case AssetCategory.other:
        return Icons.devices_other;
    }
  }

  Color get statusColor {
    switch (status) {
      case AssetStatus.available:
        return const Color(0xFF27AE60);
      case AssetStatus.assigned:
        return const Color(0xFF4A90D9);
      case AssetStatus.maintenance:
        return const Color(0xFFE67E22);
      case AssetStatus.retired:
        return const Color(0xFFE74C3C);
    }
  }

  String get statusLabel {
    switch (status) {
      case AssetStatus.available:
        return 'Available';
      case AssetStatus.assigned:
        return 'Assigned';
      case AssetStatus.maintenance:
        return 'Maintenance';
      case AssetStatus.retired:
        return 'Retired';
    }
  }

  String get categoryLabel {
    switch (category) {
      case AssetCategory.laptop:
        return 'Laptop';
      case AssetCategory.monitor:
        return 'Monitor';
      case AssetCategory.phone:
        return 'Phone';
      case AssetCategory.furniture:
        return 'Furniture';
      case AssetCategory.accessory:
        return 'Accessory';
      case AssetCategory.other:
        return 'Other';
    }
  }
}
